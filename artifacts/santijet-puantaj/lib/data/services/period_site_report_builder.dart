import '../../core/utils/puantaj_date.dart';
import '../../domain/entities/attendance.dart';
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

/// Haftalık / aylık saha raporu — puantaj + imalat + verim.
class PeriodSiteReportData {
  const PeriodSiteReportData({
    required this.periodLabel,
    required this.rangeLabel,
    required this.days,
    required this.personelPuantaj,
    required this.ekipPuantaj,
    required this.imalatRows,
    required this.verimRows,
    required this.fileStem,
  });

  final String periodLabel;
  final String rangeLabel;
  final List<String> days;
  final PuantajReportData personelPuantaj;
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
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final personelPuantaj = PuantajReportBuilder.build(
      projectName: projectName,
      projectId: projectId,
      people: eligible,
      attendance: attendance,
      period: period,
      anchorDate: anchorDate,
      layout: PuantajExportLayout.isim,
      uninsuredTeams: uninsuredTeams,
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
          efficiency = (periodQty / plannedQty) / (periodLabor / plannedAg);
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
      personelPuantaj: personelPuantaj,
      ekipPuantaj: ekipPuantaj,
      imalatRows: imalatRows,
      verimRows: verimRows,
      fileStem: fileStem,
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
