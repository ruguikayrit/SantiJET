import '../../core/utils/puantaj_date.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/person.dart';
import '../../domain/enums/attendance_status.dart';

enum PuantajReportPeriod { daily, weekly, monthly }

class PuantajReportData {
  const PuantajReportData({
    required this.title,
    required this.subtitle,
    required this.headers,
    required this.rows,
    required this.summaryLines,
    required this.landscape,
    required this.fileStem,
  });

  final String title;
  final String subtitle;
  final List<String> headers;
  final List<List<String>> rows;
  final List<String> summaryLines;
  final bool landscape;
  final String fileStem;
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
    final counts = <AttendanceStatus, int>{
      for (final s in AttendanceStatus.values) s: 0,
    };
    var none = 0;
    var totalAg = 0.0;

    for (final group in _grouped(people)) {
      for (final p in group.users) {
        final a = byPerson[p.id];
        if (a == null) {
          none++;
          rows.add([
            p.name,
            group.company,
            p.team,
            '—',
            '',
            '',
            '',
            '',
          ]);
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
      }
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

    final headers = [
      'Personel',
      'Firma',
      'Ekip',
      for (final d in days) dayHeader(d),
      'Toplam AG',
    ];
    final rows = <List<String>>[];
    final counts = <AttendanceStatus, int>{
      for (final s in AttendanceStatus.values) s: 0,
    };
    var noneCells = 0;
    var totalAg = 0.0;

    for (final group in _grouped(people)) {
      for (final p in group.users) {
        var rowAg = 0.0;
        final cells = <String>[];
        for (final d in days) {
          final a = lookup['${p.id}|$d'];
          if (a == null) {
            noneCells++;
            cells.add('');
          } else {
            counts[a.status] = (counts[a.status] ?? 0) + 1;
            rowAg += a.yevmiye;
            cells.add(a.status.short);
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
      }
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
    return '$dayName ${d.day}';
  }

  static String _monthDayHeader(String date) {
    final d = PuantajDate.parse(date);
    return '${d.day}';
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
