import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/puantaj_date.dart';
import '../../domain/entities/production.dart';
import '../../domain/models/production_metrics.dart';
import '../../domain/models/production_team_group.dart';
import 'app_data_provider.dart';
import 'production_provider.dart';

/// Tek bir imalat satırı — metrikler [Production.metrics] üzerinden.
class VerimRow {
  const VerimRow({required this.production});

  final Production production;

  ProductionMetrics get metrics => production.metrics;

  String get imalatName => production.name;
  String get unit => production.unit;
  String get teamName =>
      production.teamName.trim().isEmpty ? 'Diğer' : production.teamName.trim();

  String get summaryGroupKey =>
      ProductionTeamGroup.fromProduction(production).groupKey;
  String get locationLabel => production.locationLabel;

  double get plannedWorkerDays => metrics.labor.planned;
  double? get plannedQty => metrics.metraj.hasPlan ? metrics.metraj.planned : null;
  double get actualWorkerDays => metrics.labor.actual;
  double get actualQty => metrics.metraj.actual;

  double? get unitEfficiency => metrics.unitEfficiency;
}

/// Plan + gerçekleşen ← İmalat sekmesi (planlanan miktar / gün / iş gücü + günlük kayıtlar).
final verimRowsProvider = Provider<List<VerimRow>>((ref) {
  final project = ref.watch(activeProjectProvider);
  if (project == null) return const [];

  final productions = ref
      .watch(productionProvider)
      .where((p) => p.projectId == project.id)
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return [
    for (final p in productions) VerimRow(production: p),
  ];
});

/// Bugünkü toplam gerçekleşen adam-gün (aktif proje).
final todayWorkerDaysProvider = Provider<double>((ref) {
  final project = ref.watch(activeProjectProvider);
  if (project == null) return 0;
  final today = PuantajDate.today();
  final attendance = ref.watch(attendanceProvider);
  return attendance
      .where((a) => a.projectId == project.id && a.date == today)
      .fold<double>(0, (sum, a) => sum + a.yevmiye);
});

/// Ekip bazında toplu birim verim.
class TeamVerimSummary {
  const TeamVerimSummary({
    required this.groupKey,
    required this.teamName,
    required this.unit,
    required this.actualWorkerDays,
    required this.plannedWorkerDays,
    required this.actualQty,
    required this.plannedQty,
    required this.planLineCount,
  });

  final String groupKey;
  final String teamName;
  final String unit;
  final double actualWorkerDays;
  final double plannedWorkerDays;
  final double actualQty;
  final double plannedQty;
  final int planLineCount;

  double? get unitEfficiency => ProductionMetrics.computeUnitEfficiency(
        plannedQty: plannedQty,
        plannedWorkerDays: plannedWorkerDays,
        actualQty: actualQty,
        actualWorkerDays: actualWorkerDays,
      );
}

final teamVerimSummariesProvider = Provider<List<TeamVerimSummary>>((ref) {
  final rows = ref.watch(verimRowsProvider);
  if (rows.isEmpty) return const [];

  final plannedAgByGroup = <String, double>{};
  final actualAgByGroup = <String, double>{};
  final plannedQtyByGroup = <String, double>{};
  final actualQtyByGroup = <String, double>{};
  final linesByGroup = <String, int>{};
  final groupMeta = <String, ProductionTeamGroup>{};

  for (final row in rows) {
    final group = ProductionTeamGroup.fromProduction(row.production);
    final key = group.groupKey;
    groupMeta[key] = group;
    plannedAgByGroup[key] =
        (plannedAgByGroup[key] ?? 0) + row.plannedWorkerDays;
    actualAgByGroup[key] =
        (actualAgByGroup[key] ?? 0) + row.actualWorkerDays;
    plannedQtyByGroup[key] =
        (plannedQtyByGroup[key] ?? 0) + (row.plannedQty ?? 0);
    actualQtyByGroup[key] = (actualQtyByGroup[key] ?? 0) + row.actualQty;
    linesByGroup[key] = (linesByGroup[key] ?? 0) + 1;
  }

  final teams = plannedAgByGroup.keys.toList()
    ..sort((a, b) {
      final aEff = ProductionMetrics.computeUnitEfficiency(
        plannedQty: plannedQtyByGroup[a] ?? 0,
        plannedWorkerDays: plannedAgByGroup[a] ?? 0,
        actualQty: actualQtyByGroup[a] ?? 0,
        actualWorkerDays: actualAgByGroup[a] ?? 0,
      );
      final bEff = ProductionMetrics.computeUnitEfficiency(
        plannedQty: plannedQtyByGroup[b] ?? 0,
        plannedWorkerDays: plannedAgByGroup[b] ?? 0,
        actualQty: actualQtyByGroup[b] ?? 0,
        actualWorkerDays: actualAgByGroup[b] ?? 0,
      );
      if (aEff != null && bEff != null && aEff != bEff) {
        return bEff.compareTo(aEff);
      }
      return a.toLowerCase().compareTo(b.toLowerCase());
    });

  return [
    for (final key in teams)
      TeamVerimSummary(
        groupKey: key,
        teamName: groupMeta[key]!.cardTitle,
        unit: groupMeta[key]!.unit,
        actualWorkerDays: actualAgByGroup[key] ?? 0,
        plannedWorkerDays: plannedAgByGroup[key] ?? 0,
        actualQty: actualQtyByGroup[key] ?? 0,
        plannedQty: plannedQtyByGroup[key] ?? 0,
        planLineCount: linesByGroup[key] ?? 0,
      ),
  ];
});
