import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/puantaj_date.dart';
import '../../domain/entities/production.dart';
import '../../domain/models/production_metrics.dart';
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
    required this.teamName,
    required this.actualWorkerDays,
    required this.plannedWorkerDays,
    required this.actualQty,
    required this.plannedQty,
    required this.planLineCount,
  });

  final String teamName;
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

  final plannedAgByTeam = <String, double>{};
  final actualAgByTeam = <String, double>{};
  final plannedQtyByTeam = <String, double>{};
  final actualQtyByTeam = <String, double>{};
  final linesByTeam = <String, int>{};

  for (final row in rows) {
    final team = row.teamName;
    plannedAgByTeam[team] =
        (plannedAgByTeam[team] ?? 0) + row.plannedWorkerDays;
    actualAgByTeam[team] =
        (actualAgByTeam[team] ?? 0) + row.actualWorkerDays;
    plannedQtyByTeam[team] =
        (plannedQtyByTeam[team] ?? 0) + (row.plannedQty ?? 0);
    actualQtyByTeam[team] = (actualQtyByTeam[team] ?? 0) + row.actualQty;
    linesByTeam[team] = (linesByTeam[team] ?? 0) + 1;
  }

  final teams = plannedAgByTeam.keys.toList()
    ..sort((a, b) {
      final aEff = ProductionMetrics.computeUnitEfficiency(
        plannedQty: plannedQtyByTeam[a] ?? 0,
        plannedWorkerDays: plannedAgByTeam[a] ?? 0,
        actualQty: actualQtyByTeam[a] ?? 0,
        actualWorkerDays: actualAgByTeam[a] ?? 0,
      );
      final bEff = ProductionMetrics.computeUnitEfficiency(
        plannedQty: plannedQtyByTeam[b] ?? 0,
        plannedWorkerDays: plannedAgByTeam[b] ?? 0,
        actualQty: actualQtyByTeam[b] ?? 0,
        actualWorkerDays: actualAgByTeam[b] ?? 0,
      );
      if (aEff != null && bEff != null && aEff != bEff) {
        return bEff.compareTo(aEff);
      }
      return a.toLowerCase().compareTo(b.toLowerCase());
    });

  return [
    for (final team in teams)
      TeamVerimSummary(
        teamName: team,
        actualWorkerDays: actualAgByTeam[team] ?? 0,
        plannedWorkerDays: plannedAgByTeam[team] ?? 0,
        actualQty: actualQtyByTeam[team] ?? 0,
        plannedQty: plannedQtyByTeam[team] ?? 0,
        planLineCount: linesByTeam[team] ?? 0,
      ),
  ];
});
