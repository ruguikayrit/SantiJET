import '../../core/utils/puantaj_date.dart';
import '../../domain/attendance/attendance_display.dart';
import '../../domain/daily_report/attendance_snapshot_builder.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/daily_report.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/production.dart';
import '../../domain/entities/production_day_entry.dart';
import '../../domain/entities/uninsured_team_entry.dart';
import '../providers/verim_provider.dart';
import 'puantaj_report_builder.dart';

/// İmalat — dönem içi gerçekleşen (İmalat sekmesi kaynakları).
class PeriodImalatRow {
  const PeriodImalatRow({
    required this.name,
    required this.unit,
    required this.location,
    required this.teamName,
    required this.periodQty,
    required this.periodLaborDays,
    required this.totalQty,
    required this.plannedQty,
    required this.progressPct,
  });

  final String name;
  final String unit;
  final String location;
  final String teamName;
  final double periodQty;
  final double periodLaborDays;
  final double totalQty;
  final double plannedQty;
  final double progressPct;
}

/// Verim — dönem gerçekleşen + plan (Verim sekmesi mantığı).
class PeriodVerimRow {
  const PeriodVerimRow({
    required this.imalatName,
    this.unit,
    required this.plannedWorkerDays,
    required this.periodActualWorkerDays,
    this.plannedQty,
    required this.periodActualQty,
    this.unitEfficiency,
  });

  final String imalatName;
  final String? unit;
  final double plannedWorkerDays;
  final double periodActualWorkerDays;
  final double? plannedQty;
  final double periodActualQty;
  final double? unitEfficiency;
}

/// Haftalık / aylık personel özeti — günlük rapor formatı (DURUM yok).
class PeriodPersonelSummaryRow {
  const PeriodPersonelSummaryRow({
    required this.personId,
    required this.personName,
    required this.profession,
    required this.team,
    required this.yevmiye,
    required this.adamSaat,
  });

  final String personId;
  final String personName;
  final String profession;
  final String team;
  final double yevmiye;
  final double adamSaat;
}

class PeriodPersonelSummary {
  const PeriodPersonelSummary({
    required this.subtitle,
    required this.rows,
    required this.totalYevmiye,
    required this.totalAdamSaat,
    required this.summaryLines,
  });

  final String subtitle;
  final List<PeriodPersonelSummaryRow> rows;
  final double totalYevmiye;
  final double totalAdamSaat;
  final List<String> summaryLines;

  static const headers = [
    'Personel',
    'Meslek',
    'Ekip',
    'YV',
  ];

  List<List<String>> get exportRows => [
        for (final r in rows)
          [
            r.personName,
            r.profession.isEmpty ? '—' : r.profession,
            r.team.isEmpty ? '—' : r.team,
            _fmtYv(r.yevmiye),
          ],
      ];

  static String _fmtYv(double v) {
    if (v <= 0) return '—';
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

/// Haftalık / aylık saha raporu — puantaj + imalat + verim.
class PeriodSiteReportData {
  const PeriodSiteReportData({
    required this.periodLabel,
    required this.rangeLabel,
    required this.days,
    required this.personelSummary,
    required this.ekipPuantaj,
    required this.imalatRows,
    required this.verimRows,
    required this.fileStem,
  });

  final String periodLabel;
  final String rangeLabel;
  final List<String> days;
  final PeriodPersonelSummary personelSummary;
  final PuantajReportData ekipPuantaj;
  final List<PeriodImalatRow> imalatRows;
  final List<PeriodVerimRow> verimRows;
  final String fileStem;

  bool get hasImalat => imalatRows.isNotEmpty;
  bool get hasVerim => verimRows.isNotEmpty;
}

abstract final class PeriodSiteReportBuilder {
  static PeriodSiteReportData build({
    required String projectId,
    required String projectName,
    required List<Person> people,
    required List<Attendance> attendance,
    required List<UninsuredTeamEntry> uninsuredTeams,
    required List<Production> productions,
    required VerimState verim,
    required PuantajReportPeriod period,
    required String anchorDate,
  }) {
    final days = PuantajDate.daysForReportPeriod(
      anchorDate: anchorDate,
      daily: period == PuantajReportPeriod.daily,
      weekly: period == PuantajReportPeriod.weekly,
    );
    final daySet = days.toSet();
    final rangeLabel = switch (period) {
      PuantajReportPeriod.daily => anchorDate,
      PuantajReportPeriod.weekly =>
        PuantajDate.weekLabel(PuantajDate.weekDays(anchorDate)),
      PuantajReportPeriod.monthly => PuantajDate.monthLabel(anchorDate),
    };
    final periodLabel = switch (period) {
      PuantajReportPeriod.daily => 'Günlük',
      PuantajReportPeriod.weekly => 'Haftalık',
      PuantajReportPeriod.monthly => 'Aylık',
    };
    final fileStem = switch (period) {
      PuantajReportPeriod.daily => 'saha-gunluk-${_fileDate(anchorDate)}',
      PuantajReportPeriod.weekly => 'saha-haftalik-${_fileDate(anchorDate)}',
      PuantajReportPeriod.monthly => 'saha-aylik-${_fileMonth(anchorDate)}',
    };

    final eligible = people
        .where((p) => p.projectId == projectId && p.wasEmployedInPeriod(days))
        .toList();

    final personelSummary = _buildPersonelSummary(
      projectName: projectName,
      rangeLabel: rangeLabel,
      people: eligible,
      attendance: attendance
          .where((a) => a.projectId == projectId && daySet.contains(a.date))
          .toList(),
      days: days,
    );

    final ekipPuantaj = PuantajReportBuilder.build(
      projectName: projectName,
      projectId: projectId,
      people: eligible,
      attendance: attendance,
      period: period,
      anchorDate: anchorDate,
      layout: PuantajExportLayout.ekip,
      uninsuredTeams: uninsuredTeams,
    );

    final projectProductions = productions
        .where((p) => p.projectId == projectId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final imalatRows = <PeriodImalatRow>[];
    for (final p in projectProductions) {
      final periodEntries =
          p.dailyEntries.where((e) => daySet.contains(e.date)).toList();
      if (periodEntries.isEmpty) continue;
      final periodQty =
          periodEntries.fold<double>(0, (s, e) => s + e.completedQty);
      final periodLabor =
          periodEntries.fold<double>(0, (s, e) => s + e.laborDays);
      imalatRows.add(
        PeriodImalatRow(
          name: p.name,
          unit: p.unit,
          location: p.locationLabel,
          teamName: p.teamName,
          periodQty: periodQty,
          periodLaborDays: periodLabor,
          totalQty: p.completedQty,
          plannedQty: p.plannedQty,
          progressPct: p.progressPct,
        ),
      );
    }

    final verimRows = <PeriodVerimRow>[];
    final schedule = verim.schedule;
    final kesif = verim.kesif;
    if (schedule != null &&
        kesif != null &&
        schedule.items.isNotEmpty &&
        kesif.items.isNotEmpty) {
      for (final item in schedule.items) {
        final kesifItem = matchKesifItem(kesif.items, item);
        final prod = _matchProduction(projectProductions, item.imalatName);
        final periodEntries = prod == null
            ? const <ProductionDayEntry>[]
            : prod.dailyEntries.where((e) => daySet.contains(e.date)).toList();
        final periodQty =
            periodEntries.fold<double>(0, (s, e) => s + e.completedQty);
        final periodLabor =
            periodEntries.fold<double>(0, (s, e) => s + e.laborDays);

        final workers = (item.plannedWorkerCount ?? 0).toDouble();
        final duration = item.durationDays;
        final plannedAg = workers <= 0
            ? 0.0
            : (duration != null && duration > 0 ? workers * duration : workers);
        final plannedQty = kesifItem?.plannedQty;

        double? efficiency;
        if (plannedQty != null &&
            plannedQty > 0 &&
            plannedAg > 0 &&
            periodLabor > 0 &&
            periodQty > 0) {
          // (dönem metraj / dönem AG) / (plan metraj / plan AG)
          final periodRate = periodQty / periodLabor;
          final planRate = plannedQty / plannedAg;
          efficiency = periodRate / planRate;
        }

        if (periodQty <= 0 && periodLabor <= 0 && plannedAg <= 0) continue;

        verimRows.add(
          PeriodVerimRow(
            imalatName: item.imalatName,
            unit: (kesifItem?.unit.trim().isNotEmpty == true)
                ? kesifItem!.unit
                : item.unit,
            plannedWorkerDays: plannedAg,
            periodActualWorkerDays: periodLabor,
            plannedQty: plannedQty,
            periodActualQty: periodQty,
            unitEfficiency: efficiency,
          ),
        );
      }
    }

    return PeriodSiteReportData(
      periodLabel: periodLabel,
      rangeLabel: rangeLabel,
      days: days,
      personelSummary: personelSummary,
      ekipPuantaj: ekipPuantaj,
      imalatRows: imalatRows,
      verimRows: verimRows,
      fileStem: fileStem,
    );
  }

  /// Günlük rapor personel özeti gibi; dönem YV toplamı, DURUM yok.
  static PeriodPersonelSummary _buildPersonelSummary({
    required String projectName,
    required String rangeLabel,
    required List<Person> people,
    required List<Attendance> attendance,
    required List<String> days,
  }) {
    final lookup = <String, Attendance>{};
    for (final a in attendance) {
      lookup['${a.personId}|${a.date}'] = a;
    }

    final rows = <PeriodPersonelSummaryRow>[];
    var totalYv = 0.0;
    var totalAs = 0.0;

    for (final p in people) {
      var yevmiye = 0.0;
      var adamSaat = 0.0;
      for (final d in days) {
        final a = lookup['${p.id}|$d'];
        final status = AttendanceDisplay.resolve(
          person: p,
          date: d,
          recorded: a?.status,
        );
        if (status == null) continue;
        final hours = (a?.hours ?? status.hours).toDouble();
        final overtime = a?.overtimeHours ?? 0.0;
        adamSaat += hours + overtime;
        yevmiye += (hours + overtime) / 8.0;
      }
      rows.add(
        PeriodPersonelSummaryRow(
          personId: p.id,
          personName: p.name,
          profession: p.profession.trim(),
          team: p.team.trim(),
          yevmiye: yevmiye,
          adamSaat: adamSaat,
        ),
      );
      totalYv += yevmiye;
      totalAs += adamSaat;
    }

    rows.sort(
      (a, b) => AttendanceSnapshotBuilder.compareByRoleRank(
        DailyReportAttendancePerson(
          personId: a.personId,
          personName: a.personName,
          profession: a.profession,
          team: a.team,
          status: '',
          hours: 0,
        ),
        DailyReportAttendancePerson(
          personId: b.personId,
          personName: b.personName,
          profession: b.profession,
          team: b.team,
          status: '',
          hours: 0,
        ),
      ),
    );

    String fmt(double v) {
      if (v == v.roundToDouble()) return v.toStringAsFixed(0);
      return v.toStringAsFixed(1);
    }

    return PeriodPersonelSummary(
      subtitle: '$projectName · $rangeLabel',
      rows: rows,
      totalYevmiye: totalYv,
      totalAdamSaat: totalAs,
      summaryLines: [
        'Özet — ${rows.length} personel · Toplam adam-saat: ${fmt(totalAs)} · '
            'Toplam YV: ${PeriodPersonelSummary._fmtYv(totalYv)}',
      ],
    );
  }

  static Production? _matchProduction(
    List<Production> items,
    String imalatName,
  ) {
    final target = imalatName.toLowerCase().trim();
    if (target.isEmpty) return null;
    for (final p in items) {
      if (p.name.toLowerCase().trim() == target) return p;
    }
    final token = target.split(RegExp(r'\s+')).first;
    for (final p in items) {
      if (p.name.toLowerCase().contains(token)) return p;
    }
    return null;
  }

  static String _fileDate(String date) {
    final p = date.split('.');
    if (p.length != 3) return date.replaceAll('.', '-');
    return '${p[2]}-${p[1]}-${p[0]}';
  }

  static String _fileMonth(String date) {
    final p = date.split('.');
    if (p.length != 3) return date.replaceAll('.', '-');
    return '${p[2]}-${p[1]}';
  }
}
