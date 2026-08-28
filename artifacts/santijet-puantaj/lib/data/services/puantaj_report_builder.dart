import '../../core/utils/puantaj_date.dart';
import '../../domain/attendance/attendance_display.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/uninsured_team_entry.dart';
import '../../domain/entities/yevmiyeli_is_kaydi.dart';
import '../../domain/enums/attendance_status.dart';

enum PuantajReportPeriod { daily, weekly, monthly }

/// Puantaj AL çıktı türü.
enum PuantajExportLayout {
  /// Kayıtlı personel satır satır (mevcut cetvel).
  isim,

  /// Firma Adı + Ekip Adı + toplam / gün / ortalama çalışan.
  ekip,

  /// Taşeron yevmiyeli parça iş tablosu.
  yevmiyeli,
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
    this.sumColumnIndexes = const {},
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

  /// Alt toplam satırında toplanacak sütun indeksleri.
  final Set<int> sumColumnIndexes;

  /// Satırlar + (varsa) Toplam satırı — ekran, PDF ve Excel ortak.
  List<List<String>> get rowsWithTotals {
    if (rows.isEmpty || sumColumnIndexes.isEmpty) return rows;
    final total = List<String>.filled(headers.length, '');
    if (headers.isNotEmpty) total[0] = 'Toplam';
    for (final i in sumColumnIndexes) {
      if (i < 0 || i >= headers.length) continue;
      total[i] = formatNumericColumnSum(rows, i);
    }
    return [...rows, total];
  }
}

String formatNumericColumnSum(List<List<String>> rows, int columnIndex) {
  var sum = 0.0;
  for (final row in rows) {
    if (columnIndex >= row.length) continue;
    final t = row[columnIndex].trim().replaceAll(',', '.').replaceAll('—', '');
    if (t.isEmpty || t == '-') continue;
    final n = double.tryParse(t);
    if (n != null) sum += n;
  }
  if (sum == sum.roundToDouble()) return sum.toStringAsFixed(0);
  return sum.toStringAsFixed(1);
}

/// PDF’de renkli rozet + firma bandı için yapılandırılmış veri.
class PuantajReportVisual {
  const PuantajReportVisual({
    required this.isMatrix,
    required this.dayHeaders,
    required this.companies,
    this.footerPresentCounts = const [],
    this.firstColumnLabel = 'Personel',
  });

  final bool isMatrix;

  /// Haftalık/aylık gün başlıkları (ör. `01`, `Pzt 3`).
  final List<String> dayHeaders;
  final List<PuantajVisualCompany> companies;

  /// Matris altı “Mevcut” satırı (gün başına çalışılan kişi).
  final List<int> footerPresentCounts;

  /// Matris ilk sütun başlığı (`Personel` / `Ekip Adı`).
  final String firstColumnLabel;
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
    this.dayLabels = const [],
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

  /// Ekip puantajı: gün başına çalışan sayısı metni (doluysa rozet yerine bu).
  final List<String> dayLabels;
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

  bool get usesDayLabels => dayLabels.isNotEmpty;
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
    List<YevmiyeliIsKaydi> yevmiyeliEntries = const [],
  }) {
    if (layout == PuantajExportLayout.yevmiyeli) {
      return buildYevmiyeli(
        projectName: projectName,
        projectId: projectId,
        period: period,
        anchorDate: anchorDate,
        entries: yevmiyeliEntries,
      );
    }
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

  /// Yevmiyeli iş tablosu — taşeron / meslek / iş tanımı / manuel yevmiye.
  static PuantajReportData buildYevmiyeli({
    required String projectName,
    required String projectId,
    required PuantajReportPeriod period,
    required String anchorDate,
    List<YevmiyeliIsKaydi> entries = const [],
  }) {
    final days = PuantajDate.daysForReportPeriod(
      anchorDate: anchorDate,
      daily: period == PuantajReportPeriod.daily,
      weekly: period == PuantajReportPeriod.weekly,
    );
    final daySet = days.toSet();
    final filtered = entries
        .where((e) => e.projectId == projectId && daySet.contains(e.date))
        .toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        final byCo = a.company.compareTo(b.company);
        if (byCo != 0) return byCo;
        return a.personName.compareTo(b.personName);
      });

    final periodLabel = switch (period) {
      PuantajReportPeriod.daily => 'Günlük',
      PuantajReportPeriod.weekly => 'Haftalık',
      PuantajReportPeriod.monthly => 'Aylık',
    };
    final rangeLabel = switch (period) {
      PuantajReportPeriod.daily => anchorDate,
      PuantajReportPeriod.weekly =>
        PuantajDate.weekLabel(PuantajDate.weekDays(anchorDate)),
      PuantajReportPeriod.monthly => PuantajDate.monthLabel(anchorDate),
    };
    final fileStem = switch (period) {
      PuantajReportPeriod.daily => 'yevmiyeli-gunluk-${_fileDate(anchorDate)}',
      PuantajReportPeriod.weekly =>
        'yevmiyeli-haftalik-${_fileDate(anchorDate)}',
      PuantajReportPeriod.monthly =>
        'yevmiyeli-aylik-${_fileMonth(anchorDate)}',
    };

    String fmtYv(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

    final headers = period == PuantajReportPeriod.daily
        ? [
            '#',
            'Ad Soyad',
            'Taşeron',
            'Meslek',
            'Ekip',
            'İş tanımı',
            'Yevmiye',
          ]
        : [
            '#',
            'Tarih',
            'Ad Soyad',
            'Taşeron',
            'Meslek',
            'Ekip',
            'İş tanımı',
            'Yevmiye',
          ];

    final rows = <List<String>>[];
    var total = 0.0;
    final byCompany = <String, double>{};
    for (var i = 0; i < filtered.length; i++) {
      final e = filtered[i];
      total += e.yevmiyeCount;
      final co = e.company.isEmpty ? 'Diğer' : e.company;
      byCompany[co] = (byCompany[co] ?? 0) + e.yevmiyeCount;
      if (period == PuantajReportPeriod.daily) {
        rows.add([
          '${i + 1}',
          e.personName,
          e.company,
          e.profession,
          e.team,
          e.workDescription,
          fmtYv(e.yevmiyeCount),
        ]);
      } else {
        rows.add([
          '${i + 1}',
          e.date,
          e.personName,
          e.company,
          e.profession,
          e.team,
          e.workDescription,
          fmtYv(e.yevmiyeCount),
        ]);
      }
    }

    final companyLines = byCompany.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final summary = <String>[
      'Kayıt: ${filtered.length}',
      'Toplam yevmiye: ${fmtYv(total)}',
      for (final c in companyLines)
        '${c.key}: ${fmtYv(c.value)} yv',
    ];

    return PuantajReportData(
      title: 'Yevmiyeli İşler — $periodLabel',
      subtitle: '$projectName · $rangeLabel',
      headers: headers,
      rows: rows,
      summaryLines: summary,
      landscape: period != PuantajReportPeriod.daily,
      fileStem: fileStem,
      visual: const PuantajReportVisual(
        isMatrix: false,
        dayHeaders: [],
        companies: [],
      ),
      plainTable: true,
      sumColumnIndexes: {headers.length - 1},
    );
  }

  /// Firma Adı + Ekip Adı + çalışan sayısı (M/Y/G/Ç); personel cetveli düzeni.
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
      PuantajReportPeriod.daily => _ekipTable(
          projectName: projectName,
          people: people,
          attendance: projectAtt,
          uninsured: projectUninsured,
          days: [anchorDate],
          period: period,
          periodLabel: 'Günlük',
          rangeLabel: anchorDate,
          fileStem: 'ekip-gunluk-${_fileDate(anchorDate)}',
          landscape: false,
        ),
      PuantajReportPeriod.weekly => _ekipTable(
          projectName: projectName,
          people: people,
          attendance: projectAtt,
          uninsured: projectUninsured,
          days: days,
          period: period,
          periodLabel: 'Haftalık',
          rangeLabel: PuantajDate.weekLabel(days),
          fileStem: 'ekip-haftalik-${_fileDate(anchorDate)}',
          landscape: true,
        ),
      PuantajReportPeriod.monthly => _ekipTable(
          projectName: projectName,
          people: people,
          attendance: projectAtt,
          uninsured: projectUninsured,
          days: days,
          period: period,
          periodLabel: 'Aylık',
          rangeLabel: PuantajDate.monthLabel(anchorDate),
          fileStem: 'ekip-aylik-${_fileMonth(anchorDate)}',
          landscape: true,
        ),
    };
  }

  static String _ekipCompanyLabel(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return 'Diğer';
    return t;
  }

  static String _ekipTeamLabel(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return 'Ekipsiz';
    return t;
  }

  /// Firma · Ekip · adam.gün · çalışılan gün · ortalama çalışan.
  ///
  /// - Toplam çalışan (= adam.gün/hafta veya /ay): dönemde ekibin harcadığı
  ///   toplam adam.gün.
  /// - Çalışılan gün: ekibin iş için çalıştığı gün sayısı.
  /// - Ortalama: adam.gün / çalışılan gün.
  static PuantajReportData _ekipTable({
    required String projectName,
    required List<Person> people,
    required List<Attendance> attendance,
    required List<UninsuredTeamEntry> uninsured,
    required List<String> days,
    required PuantajReportPeriod period,
    required String periodLabel,
    required String rangeLabel,
    required String fileStem,
    required bool landscape,
  }) {
    final lookup = <String, Attendance>{};
    for (final a in attendance) {
      lookup['${a.personId}|${a.date}'] = a;
    }

    /// Firma Adı → Ekip Adı → gün baş sayıları
    final dailyCounts = <String, Map<String, List<int>>>{};

    void ensureTeam(String company, String team) {
      dailyCounts
          .putIfAbsent(company, () => {})
          .putIfAbsent(team, () => List<int>.filled(days.length, 0));
    }

    void addDaily(String company, String team, int dayIndex, int n) {
      if (n <= 0) return;
      ensureTeam(company, team);
      dailyCounts[company]![team]![dayIndex] += n;
    }

    for (var di = 0; di < days.length; di++) {
      final d = days[di];
      for (final p in people) {
        final a = lookup['${p.id}|$d'];
        final status = AttendanceDisplay.resolve(
          person: p,
          date: d,
          recorded: a?.status,
        );
        if (status == null || !status.countsInTeamHeadcount) continue;
        final company = _ekipCompanyLabel(p.company);
        final team = _ekipTeamLabel(p.team);
        addDaily(company, team, di, 1);
      }
      for (final e in uninsured.where((e) => e.date == d)) {
        addDaily(
          _ekipCompanyLabel(e.company),
          _ekipTeamLabel(e.teamName),
          di,
          e.workerCount,
        );
      }
    }

    final companyNames = dailyCounts.keys.toList()
      ..sort((a, b) {
        if (a == 'Diğer' && b != 'Diğer') return 1;
        if (a != 'Diğer' && b == 'Diğer') return -1;
        return a.compareTo(b);
      });

    final headers = switch (period) {
      PuantajReportPeriod.daily => const [
          'Firma\nAdı',
          'Ekip\nAdı',
          'Adam.gün\n/gün',
          'Çalışılan\ngün',
          'Ortalama\nçalışan',
        ],
      PuantajReportPeriod.weekly => const [
          'Firma\nAdı',
          'Ekip\nAdı',
          'Haftalık\nadam.gün',
          'Haftalık\nçalışılan gün',
          'Günlük\nortalama adam',
        ],
      PuantajReportPeriod.monthly => const [
          'Firma\nAdı',
          'Ekip\nAdı',
          'Aylık\nadam.gün',
          'Aylık\nçalışılan gün',
          'Günlük\nortalama adam',
        ],
    };
    final rows = <List<String>>[];
    var grandPersonDays = 0;
    var grandDaysWorked = 0;

    String fmtAvg(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

    for (final company in companyNames) {
      final teams = dailyCounts[company]!.keys.toList()..sort();
      for (final team in teams) {
        final counts = dailyCounts[company]![team]!;
        // Adam.gün = dönemde harcanan toplam adam.gün.
        final personDays = counts.fold<int>(0, (s, n) => s + n);
        if (personDays == 0) continue;

        // Çalışma olan gün sayısı.
        final daysWorked = counts.where((n) => n > 0).length;
        // Günlük ortalama adam = adam.gün / çalışılan gün.
        final avg = daysWorked > 0 ? personDays / daysWorked : 0.0;

        grandPersonDays += personDays;
        grandDaysWorked += daysWorked;

        rows.add([
          company,
          team,
          '$personDays',
          '$daysWorked',
          fmtAvg(avg),
        ]);
      }
    }

    final singleDay = days.length == 1;
    return PuantajReportData(
      title: 'Ekip Puantajı — $periodLabel',
      subtitle: '$projectName · $rangeLabel',
      headers: headers,
      rows: rows,
      summaryLines: [
        if (singleDay)
          'Genel toplam: $grandPersonDays kişi'
        else ...[
          'Toplam adam.gün: $grandPersonDays',
          'Toplam çalışılan gün (satır toplamı): $grandDaysWorked',
        ],
        'Ortalama = adam.gün ÷ çalışılan gün (= günlük ortalama adam)',
        'Sayım: Mevcut, Yarım, Giriş, Çıkış (ekip kaydı çalışan sayısı dahil)',
      ],
      landscape: landscape,
      fileStem: fileStem,
      visual: const PuantajReportVisual(
        isMatrix: false,
        dayHeaders: [],
        companies: [],
      ),
      plainTable: true,
      sumColumnIndexes: const {2},
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
