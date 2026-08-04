import '../../core/utils/puantaj_date.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/person.dart';
import '../../domain/enums/attendance_status.dart';

enum PuantajReportPeriod { daily, weekly, monthly }

/// Excel / düz tablo için satır verisi + PDF görsel modeli.
class PuantajReportData {
  const PuantajReportData({
    required this.title,
    required this.subtitle,
    required this.headers,
    required this.rows,
    required this.summaryLines,
    required this.landscape,
    required this.fileStem,
    required this.visual,
  });

  final String title;
  final String subtitle;
  final List<String> headers;
  final List<List<String>> rows;
  final List<String> summaryLines;
  final bool landscape;
  final String fileStem;

  /// Uygulama cetveli ile aynı görsel PDF düzeni.
  final PuantajReportVisual visual;
}

/// PDF’de renkli rozet + firma bandı için yapılandırılmış veri.
class PuantajReportVisual {
  const PuantajReportVisual({
    required this.isMatrix,
    required this.dayHeaders,
    required this.companies,
    this.footerPresentCounts = const [],
  });

  final bool isMatrix;

  /// Haftalık/aylık gün başlıkları (ör. `01`, `Pzt 3`).
  final List<String> dayHeaders;
  final List<PuantajVisualCompany> companies;

  /// Matris altı “Mevcut” satırı (gün başına çalışılan kişi).
  final List<int> footerPresentCounts;
}

class PuantajVisualCompany {
  const PuantajVisualCompany({
    required this.name,
    required this.rows,
  });

  final String name;
  final List<PuantajVisualPersonRow> rows;
}

class PuantajVisualPersonRow {
  const PuantajVisualPersonRow({
    required this.name,
    required this.statuses,
    this.team = '',
    this.hours = '',
    this.overtime = '',
    this.yevmiye = '',
    this.note = '',
    this.totalLabel = '',
  });

  final String name;

  /// Matris: gün sayısı kadar; günlük: tek eleman (null = boş).
  final List<AttendanceStatus?> statuses;
  final String team;
  final String hours;
  final String overtime;
  final String yevmiye;
  final String note;
  final String totalLabel;
}

/// Aktif proje puantajından günlük / haftalık / aylık rapor tablosu üretir.
abstract final class PuantajReportBuilder {
  static PuantajReportData build({
    required String projectName,
    required String projectId,
    required List<Person> people,
    required List<Attendance> attendance,
    required PuantajReportPeriod period,
    required String anchorDate,
  }) {
    final projectAtt = attendance
        .where((a) => a.projectId == projectId)
        .toList(growable: false);

    return switch (period) {
      PuantajReportPeriod.daily => _daily(
          projectName: projectName,
          people: people,
          attendance: projectAtt,
          date: anchorDate,
        ),
      PuantajReportPeriod.weekly => _matrix(
          projectName: projectName,
          people: people,
          attendance: projectAtt,
          days: PuantajDate.weekDays(anchorDate),
          periodLabel: 'Haftalık',
          rangeLabel: PuantajDate.weekLabel(PuantajDate.weekDays(anchorDate)),
          fileStem: 'haftalik-${_fileDate(anchorDate)}',
          dayHeader: _weekDayHeader,
        ),
      PuantajReportPeriod.monthly => _matrix(
          projectName: projectName,
          people: people,
          attendance: projectAtt,
          days: PuantajDate.monthDays(anchorDate),
          periodLabel: 'Aylık',
          rangeLabel: PuantajDate.monthLabel(anchorDate),
          fileStem: 'aylik-${_fileMonth(anchorDate)}',
          dayHeader: _monthDayHeader,
        ),
    };
  }

  static PuantajReportData _daily({
    required String projectName,
    required List<Person> people,
    required List<Attendance> attendance,
    required String date,
  }) {
    final byPerson = <String, Attendance>{};
    for (final a in attendance) {
      if (a.date == date) byPerson[a.personId] = a;
    }

    final headers = [
      'Personel',
      'Firma',
      'Ekip',
      'Durum',
      'Saat',
      'Mesai',
      'Adam-gün',
      'Not',
    ];
    final rows = <List<String>>[];
    final visualCompanies = <PuantajVisualCompany>[];
    final counts = <AttendanceStatus, int>{
      for (final s in AttendanceStatus.values) s: 0,
    };
    var none = 0;
    var totalAg = 0.0;

    for (final group in _grouped(people)) {
      final visualRows = <PuantajVisualPersonRow>[];
      for (final p in group.users) {
        final a = byPerson[p.id];
        if (a == null) {
          none++;
          rows.add([p.name, group.company, p.team, '—', '', '', '', '']);
          visualRows.add(
            PuantajVisualPersonRow(
              name: p.name,
              statuses: const [null],
              team: p.team,
            ),
          );
          continue;
        }
        counts[a.status] = (counts[a.status] ?? 0) + 1;
        totalAg += a.yevmiye;
        rows.add([
          p.name,
          group.company,
          p.team,
          a.status.label,
          a.hours.toString(),
          _fmtNum(a.overtimeHours),
          _fmtNum(a.yevmiye),
          a.note,
        ]);
        visualRows.add(
          PuantajVisualPersonRow(
            name: p.name,
            statuses: [a.status],
            team: p.team,
            hours: a.hours.toString(),
            overtime: _fmtNum(a.overtimeHours),
            yevmiye: _fmtNum(a.yevmiye),
            note: a.note,
          ),
        );
      }
      visualCompanies.add(
        PuantajVisualCompany(name: group.company, rows: visualRows),
      );
    }

    return PuantajReportData(
      title: 'Puantaj — Günlük',
      subtitle: '$projectName · $date',
      headers: headers,
      rows: rows,
      summaryLines: _summaryLines(
        counts: counts,
        none: none,
        totalAg: totalAg,
        legend: false,
      ),
      landscape: false,
      fileStem: 'gunluk-${_fileDate(date)}',
      visual: PuantajReportVisual(
        isMatrix: false,
        dayHeaders: const [],
        companies: visualCompanies,
      ),
    );
  }

  static PuantajReportData _matrix({
    required String projectName,
    required List<Person> people,
    required List<Attendance> attendance,
    required List<String> days,
    required String periodLabel,
    required String rangeLabel,
    required String fileStem,
    required String Function(String date) dayHeader,
  }) {
    final lookup = <String, Attendance>{};
    for (final a in attendance) {
      if (days.contains(a.date)) {
        lookup['${a.personId}|${a.date}'] = a;
      }
    }

    final dayHeaders = [for (final d in days) dayHeader(d)];
    final headers = [
      'Personel',
      'Firma',
      'Ekip',
      ...dayHeaders,
      'Toplam AG',
    ];
    final rows = <List<String>>[];
    final visualCompanies = <PuantajVisualCompany>[];
    final counts = <AttendanceStatus, int>{
      for (final s in AttendanceStatus.values) s: 0,
    };
    var noneCells = 0;
    var totalAg = 0.0;
    final footer = List<int>.filled(days.length, 0);

    for (final group in _grouped(people)) {
      final visualRows = <PuantajVisualPersonRow>[];
      for (final p in group.users) {
        var rowAg = 0.0;
        var workCount = 0;
        final cells = <String>[];
        final statuses = <AttendanceStatus?>[];
        for (var di = 0; di < days.length; di++) {
          final d = days[di];
          final a = lookup['${p.id}|$d'];
          if (a == null) {
            noneCells++;
            cells.add('');
            statuses.add(null);
          } else {
            counts[a.status] = (counts[a.status] ?? 0) + 1;
            rowAg += a.yevmiye;
            cells.add(a.status.short);
            statuses.add(a.status);
            if (a.status.isWorkedDay) {
              workCount++;
              footer[di]++;
            }
          }
        }
        totalAg += rowAg;
        rows.add([
          p.name,
          group.company,
          p.team,
          ...cells,
          _fmtNum(rowAg),
        ]);
        visualRows.add(
          PuantajVisualPersonRow(
            name: p.name,
            statuses: statuses,
            team: p.team,
            totalLabel: workCount > 0 ? '$workCount' : '–',
            yevmiye: _fmtNum(rowAg),
          ),
        );
      }
      visualCompanies.add(
        PuantajVisualCompany(name: group.company, rows: visualRows),
      );
    }

    return PuantajReportData(
      title: 'Puantaj — $periodLabel',
      subtitle: '$projectName · $rangeLabel',
      headers: headers,
      rows: rows,
      summaryLines: _summaryLines(
        counts: counts,
        none: noneCells,
        totalAg: totalAg,
        legend: true,
      ),
      landscape: true,
      fileStem: fileStem,
      visual: PuantajReportVisual(
        isMatrix: true,
        dayHeaders: dayHeaders,
        companies: visualCompanies,
        footerPresentCounts: footer,
      ),
    );
  }

  static List<String> _summaryLines({
    required Map<AttendanceStatus, int> counts,
    required int none,
    required double totalAg,
    required bool legend,
  }) {
    final lines = <String>[
      'Özet — Toplam adam-gün: ${_fmtNum(totalAg)}',
      [
        for (final s in AttendanceStatus.values)
          if ((counts[s] ?? 0) > 0) '${s.label}: ${counts[s]}',
        if (none > 0) 'Boş: $none',
      ].join(' · '),
    ];
    if (legend) {
      lines.add(
        'Kodlar: ${AttendanceStatus.values.map((s) => '${s.short}=${s.label}').join(', ')}',
      );
    }
    return lines;
  }

  static List<({String company, List<Person> users})> _grouped(
    List<Person> people,
  ) {
    final map = <String, List<Person>>{};
    for (final u in people) {
      final key = u.company.trim();
      map.putIfAbsent(key, () => []).add(u);
    }
    final keys = map.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty && b.isNotEmpty) return 1;
        if (a.isNotEmpty && b.isEmpty) return -1;
        return a.compareTo(b);
      });
    return keys
        .map((k) => (company: k.isEmpty ? 'Diğer' : k, users: map[k]!))
        .toList();
  }

  static String _weekDayHeader(String date) {
    final d = PuantajDate.parse(date);
    final dayName = PuantajDate.trDaysShort[d.weekday - 1];
    return '$dayName\n${d.day.toString().padLeft(2, '0')}';
  }

  static String _monthDayHeader(String date) {
    final d = PuantajDate.parse(date);
    return d.day.toString().padLeft(2, '0');
  }

  static String _fmtNum(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  static String _fileDate(String date) {
    final parts = date.split('.');
    if (parts.length != 3) return date.replaceAll('.', '');
    return '${parts[0]}${parts[1]}${parts[2]}';
  }

  static String _fileMonth(String date) {
    final d = PuantajDate.parse(date);
    final mm = d.month.toString().padLeft(2, '0');
    return '$mm${d.year}';
  }
}
