import '../../core/utils/puantaj_date.dart';
import '../../domain/attendance/attendance_display.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/uninsured_team_entry.dart';
import '../../domain/enums/attendance_status.dart';

enum PuantajReportPeriod { daily, weekly, monthly }

/// Puantaj AL çıktı türü.
enum PuantajExportLayout {
  /// Sigortalı kişiler satır satır (mevcut cetvel).
  isim,

  /// Sigorta ettiren firma + ekip + çalışan sayısı.
  ekip,
}

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
    this.plainTable = false,
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

  /// Ekip puantajı gibi düz tablo PDF (firma bandı / rozet yok).
  final bool plainTable;
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
    this.statusCounts = const [],
    this.team = '',
    this.hours = '',
    this.overtime = '',
    this.yevmiye = '',
    this.note = '',
    this.totalLabel = '',
    this.hireDateLine = '',
    this.leaveDateLine = '',
  });

  final String name;

  /// Matris: gün sayısı kadar; günlük: tek eleman (null = boş).
  final List<AttendanceStatus?> statuses;

  /// Matris özet sütunları; [AttendanceStatus.values] sırasındadır.
  final List<int> statusCounts;
  final String team;
  final String hours;
  final String overtime;
  final String yevmiye;
  final String note;
  final String totalLabel;

  /// Örn. `Giriş: 07.04.2026`
  final String hireDateLine;

  /// Örn. `Çıkış: 20.07.2026`
  final String leaveDateLine;

  List<String> get employmentDateLines => [
        if (hireDateLine.isNotEmpty) hireDateLine,
        if (leaveDateLine.isNotEmpty) leaveDateLine,
      ];
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
    PuantajExportLayout layout = PuantajExportLayout.isim,
    List<UninsuredTeamEntry> uninsuredTeams = const [],
  }) {
    if (layout == PuantajExportLayout.ekip) {
      return buildEkip(
        projectName: projectName,
        projectId: projectId,
        people: people,
        attendance: attendance,
        period: period,
        anchorDate: anchorDate,
        uninsuredTeams: uninsuredTeams,
      );
    }

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

  /// Firma + ekip + çalışan sayısı (M/Y/G/Ç); sigortasız ayrı bölüm.
  static PuantajReportData buildEkip({
    required String projectName,
    required String projectId,
    required List<Person> people,
    required List<Attendance> attendance,
    required PuantajReportPeriod period,
    required String anchorDate,
    List<UninsuredTeamEntry> uninsuredTeams = const [],
  }) {
    final days = PuantajDate.daysForReportPeriod(
      anchorDate: anchorDate,
      daily: period == PuantajReportPeriod.daily,
      weekly: period == PuantajReportPeriod.weekly,
    );
    final projectAtt = attendance
        .where((a) => a.projectId == projectId && days.contains(a.date))
        .toList(growable: false);
    final projectUninsured = uninsuredTeams
        .where((e) => e.projectId == projectId && days.contains(e.date))
        .toList(growable: false);

    return switch (period) {
      PuantajReportPeriod.daily => _ekipDaily(
          projectName: projectName,
          people: people,
          attendance: projectAtt,
          uninsured: projectUninsured,
          date: anchorDate,
        ),
      PuantajReportPeriod.weekly => _ekipMatrix(
          projectName: projectName,
          people: people,
          attendance: projectAtt,
          uninsured: projectUninsured,
          days: days,
          periodLabel: 'Haftalık',
          rangeLabel: PuantajDate.weekLabel(days),
          fileStem: 'ekip-haftalik-${_fileDate(anchorDate)}',
          dayHeader: _weekDayHeader,
        ),
      PuantajReportPeriod.monthly => _ekipMatrix(
          projectName: projectName,
          people: people,
          attendance: projectAtt,
          uninsured: projectUninsured,
          days: days,
          periodLabel: 'Aylık',
          rangeLabel: PuantajDate.monthLabel(anchorDate),
          fileStem: 'ekip-aylik-${_fileMonth(anchorDate)}',
          dayHeader: _monthDayHeader,
        ),
    };
  }

  static PuantajReportData _ekipDaily({
    required String projectName,
    required List<Person> people,
    required List<Attendance> attendance,
    required List<UninsuredTeamEntry> uninsured,
    required String date,
  }) {
    final byPerson = <String, Attendance>{};
    for (final a in attendance) {
      if (a.date == date) byPerson[a.personId] = a;
    }

    final insuredGroups = <(String, String), int>{};
    for (final p in people) {
      final recorded = byPerson[p.id];
      final status = AttendanceDisplay.resolve(
        person: p,
        date: date,
        recorded: recorded?.status,
      );
      if (status == null || !status.countsInTeamHeadcount) continue;
      final company = p.company.trim().isEmpty ? 'Diğer' : p.company.trim();
      final team = p.team.trim().isEmpty ? 'Ekipsiz' : p.team.trim();
      final key = (company, team);
      insuredGroups[key] = (insuredGroups[key] ?? 0) + 1;
    }

    final headers = [
      'Bölüm',
      'Sigorta ettiren firma',
      'Ekip',
      'Çalışan sayısı',
    ];
    final rows = <List<String>>[];
    var insuredTotal = 0;
    final insuredKeys = insuredGroups.keys.toList()
      ..sort((a, b) {
        final c = a.$1.compareTo(b.$1);
        return c != 0 ? c : a.$2.compareTo(b.$2);
      });
    for (final key in insuredKeys) {
      final n = insuredGroups[key]!;
      insuredTotal += n;
      rows.add(['Sigortalı', key.$1, key.$2, '$n']);
    }

    var uninsuredTotal = 0;
    final dayUninsured = uninsured.where((e) => e.date == date).toList()
      ..sort((a, b) => a.teamName.compareTo(b.teamName));
    for (final e in dayUninsured) {
      uninsuredTotal += e.workerCount;
      rows.add(['Sigortasız', '—', e.teamName, '${e.workerCount}']);
    }

    return PuantajReportData(
      title: 'Ekip Puantajı — Günlük',
      subtitle: '$projectName · $date',
      headers: headers,
      rows: rows,
      summaryLines: [
        'Sigortalı toplam: $insuredTotal kişi',
        'Sigortasız toplam: $uninsuredTotal kişi',
        'Genel toplam: ${insuredTotal + uninsuredTotal} kişi',
        'Sayım: Mevcut, Yarım, Giriş, Çıkış',
      ],
      landscape: false,
      fileStem: 'ekip-gunluk-${_fileDate(date)}',
      visual: const PuantajReportVisual(
        isMatrix: false,
        dayHeaders: [],
        companies: [],
      ),
      plainTable: true,
    );
  }

  static PuantajReportData _ekipMatrix({
    required String projectName,
    required List<Person> people,
    required List<Attendance> attendance,
    required List<UninsuredTeamEntry> uninsured,
    required List<String> days,
    required String periodLabel,
    required String rangeLabel,
    required String fileStem,
    required String Function(String date) dayHeader,
  }) {
    final lookup = <String, Attendance>{};
    for (final a in attendance) {
      lookup['${a.personId}|${a.date}'] = a;
    }

    final dayHeaders = [for (final d in days) dayHeader(d)];
    final teamKeys = <(String, String)>{};
    for (final p in people) {
      final company = p.company.trim().isEmpty ? 'Diğer' : p.company.trim();
      final team = p.team.trim().isEmpty ? 'Ekipsiz' : p.team.trim();
      teamKeys.add((company, team));
    }
    final sortedTeams = teamKeys.toList()
      ..sort((a, b) {
        final c = a.$1.compareTo(b.$1);
        return c != 0 ? c : a.$2.compareTo(b.$2);
      });

    final uninsuredNames = <String>{
      for (final e in uninsured) e.teamName,
    }.toList()
      ..sort();

    final headers = [
      'Bölüm',
      'Sigorta ettiren firma',
      'Ekip',
      ...dayHeaders,
      'Toplam',
    ];
    final rows = <List<String>>[];
    var grandInsured = 0;
    var grandUninsured = 0;

    for (final key in sortedTeams) {
      final members = people.where((p) {
        final company = p.company.trim().isEmpty ? 'Diğer' : p.company.trim();
        final team = p.team.trim().isEmpty ? 'Ekipsiz' : p.team.trim();
        return company == key.$1 && team == key.$2;
      }).toList();
      final dayCounts = <int>[];
      var rowSum = 0;
      for (final d in days) {
        var n = 0;
        for (final p in members) {
          final a = lookup['${p.id}|$d'];
          final status = AttendanceDisplay.resolve(
            person: p,
            date: d,
            recorded: a?.status,
          );
          if (status != null && status.countsInTeamHeadcount) n++;
        }
        dayCounts.add(n);
        rowSum += n;
      }
      if (rowSum == 0) continue;
      grandInsured += rowSum;
      rows.add([
        'Sigortalı',
        key.$1,
        key.$2,
        ...dayCounts.map((e) => '$e'),
        '$rowSum',
      ]);
    }

    for (final name in uninsuredNames) {
      final dayCounts = <int>[];
      var rowSum = 0;
      for (final d in days) {
        final n = uninsured
            .where((e) => e.date == d && e.teamName == name)
            .fold<int>(0, (s, e) => s + e.workerCount);
        dayCounts.add(n);
        rowSum += n;
      }
      if (rowSum == 0) continue;
      grandUninsured += rowSum;
      rows.add([
        'Sigortasız',
        '—',
        name,
        ...dayCounts.map((e) => '$e'),
        '$rowSum',
      ]);
    }

    return PuantajReportData(
      title: 'Ekip Puantajı — $periodLabel',
      subtitle: '$projectName · $rangeLabel',
      headers: headers,
      rows: rows,
      summaryLines: [
        'Sigortalı gün-kişi toplamı: $grandInsured',
        'Sigortasız gün-kişi toplamı: $grandUninsured',
        'Sayım: Mevcut, Yarım, Giriş, Çıkış',
      ],
      landscape: true,
      fileStem: fileStem,
      visual: PuantajReportVisual(
        isMatrix: false,
        dayHeaders: dayHeaders,
        companies: const [],
      ),
      plainTable: true,
    );
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
      'Giriş',
      'Çıkış',
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
        final status = AttendanceDisplay.resolve(
          person: p,
          date: date,
          recorded: a?.status,
        );
        final hireLine = AttendanceDisplay.hireDateLine(p);
        final leaveLine = AttendanceDisplay.leaveDateLine(p);
        final hireLabel = _employmentPart(p.hireDate);
        final leaveLabel = _employmentPart(p.leaveDate);
        if (status == null) {
          none++;
          rows.add([
            p.name,
            group.company,
            p.team,
            hireLabel,
            leaveLabel,
            '—',
            '',
            '',
            '',
            '',
          ]);
          visualRows.add(
            PuantajVisualPersonRow(
              name: p.name,
              statuses: const [null],
              team: p.team,
              hireDateLine: hireLine,
              leaveDateLine: leaveLine,
            ),
          );
          continue;
        }
        counts[status] = (counts[status] ?? 0) + 1;
        final hours = a?.hours ?? status.hours;
        final ot = a?.overtimeHours ?? 0;
        final yev = a?.yevmiye ?? 0;
        totalAg += yev;
        rows.add([
          p.name,
          group.company,
          p.team,
          hireLabel,
          leaveLabel,
          status.label,
          hours.toString(),
          _fmtNum(ot),
          _fmtNum(yev),
          a?.note ?? '',
        ]);
        visualRows.add(
          PuantajVisualPersonRow(
            name: p.name,
            statuses: [status],
            team: p.team,
            hours: hours.toString(),
            overtime: _fmtNum(ot),
            yevmiye: _fmtNum(yev),
            note: a?.note ?? '',
            hireDateLine: hireLine,
            leaveDateLine: leaveLine,
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
      'Giriş',
      'Çıkış',
      ...dayHeaders,
      for (final s in AttendanceStatus.values) s.label,
      'Genel Toplam',
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
        final cells = <String>[];
        final statuses = <AttendanceStatus?>[];
        final rowStatusCounts = <AttendanceStatus, int>{
          for (final s in AttendanceStatus.values) s: 0,
        };
        final hireLine = AttendanceDisplay.hireDateLine(p);
        final leaveLine = AttendanceDisplay.leaveDateLine(p);
        final hireLabel = _employmentPart(p.hireDate);
        final leaveLabel = _employmentPart(p.leaveDate);
        for (var di = 0; di < days.length; di++) {
          final d = days[di];
          final a = lookup['${p.id}|$d'];
          final status = AttendanceDisplay.resolve(
            person: p,
            date: d,
            recorded: a?.status,
          );
          if (status == null) {
            noneCells++;
            cells.add('');
            statuses.add(null);
          } else {
            counts[status] = (counts[status] ?? 0) + 1;
            rowStatusCounts[status] = (rowStatusCounts[status] ?? 0) + 1;
            rowAg += a?.yevmiye ?? 0;
            cells.add(status.short);
            statuses.add(status);
            if (status.isWorkedDay) {
              footer[di]++;
            }
          }
        }
        totalAg += rowAg;
        final generalTotal = AttendanceStatus.values
            .where((s) => s.countsInGeneralTotal)
            .fold<int>(0, (sum, s) => sum + (rowStatusCounts[s] ?? 0));
        rows.add([
          p.name,
          group.company,
          p.team,
          hireLabel,
          leaveLabel,
          ...cells,
          for (final s in AttendanceStatus.values) '${rowStatusCounts[s] ?? 0}',
          '$generalTotal',
        ]);
        visualRows.add(
          PuantajVisualPersonRow(
            name: p.name,
            statuses: statuses,
            statusCounts: [
              for (final s in AttendanceStatus.values) rowStatusCounts[s] ?? 0,
            ],
            team: p.team,
            totalLabel: generalTotal > 0 ? '$generalTotal' : '–',
            yevmiye: _fmtNum(rowAg),
            hireDateLine: hireLine,
            leaveDateLine: leaveLine,
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

  static String _employmentPart(String raw) {
    final d = Person.parseEmploymentDate(raw);
    if (d == null) return '';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
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
