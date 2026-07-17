import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/entities/prediction_models.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/domain/entities/work_schedule.dart';
import 'package:santijet_demir/domain/entities/workforce.dart';
import 'package:santijet_demir/features/prediction/prediction_calculator.dart';
import 'package:santijet_demir/features/prediction/prediction_narrator.dart';

class PredictionEngine {
  const PredictionEngine();

  PredictionSnapshot run({
    required String projectId,
    required PredictionConfig config,
    required SurveyProject survey,
    required List<FieldCountRecord> fieldCounts,
    required List<WorkScheduleDay> scheduleDays,
    required List<WorkforceEntry> workforce,
    required List<OrderItem> orders,
    required List<DeliveryItem> deliveries,
    required int supplierLeadDays,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();

    final plannedByD = <int, double>{};
    final orderedByD = <int, double>{};
    final deliveredByD = <int, double>{};
    for (final imalat in survey.imalats) {
      for (final line in imalat.diameterLines) {
        plannedByD[line.diameter] =
            (plannedByD[line.diameter] ?? 0) + line.planned;
        orderedByD[line.diameter] =
            (orderedByD[line.diameter] ?? 0) + line.ordered;
        deliveredByD[line.diameter] =
            (deliveredByD[line.diameter] ?? 0) + line.delivered;
      }
    }

    // Order/delivery lists reserved for future PO-level lead times.
    // Cumulative quantities come from survey diameter lines.
    final _ = (orders.length, deliveries.length);

    final stockSeries = fieldCounts
        .where((c) => c.lines.isNotEmpty)
        .map(
          (c) => PredictionStockPoint(
            date: c.date,
            stockByDiameter: {
              for (final line in c.lines) line.diameter: line.actual,
            },
          ),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final plannedDailyByD = _averagePlannedDaily(scheduleDays);
    final workerUnits = workforce.fold<double>(
      0,
      (s, e) => s + e.workerDayUnits,
    );

    final allGaps = PredictionNarrator.buildGaps(
      hasSurveyDiameters: plannedByD.isNotEmpty,
      fieldCountCount: stockSeries.length,
      hasWorkSchedule: scheduleDays.isNotEmpty,
      hasWorkforce: workforce.isNotEmpty,
    );
    final canPredict = PredictionNarrator.canPredictFromGaps(allGaps);

    if (!canPredict) {
      final incomplete = PredictionSnapshot(
        id: 'pred-${now.millisecondsSinceEpoch}',
        projectId: projectId,
        createdAt: now,
        dataGaps: allGaps,
        canPredict: false,
      );
      return _withNarratives(
        incomplete,
        PredictionNarrator.narrate(incomplete),
      );
    }

    final result = PredictionCalculator.compute(
      PredictionCalculatorInput(
        projectId: projectId,
        config: config,
        plannedByDiameter: plannedByD,
        orderedByDiameter: orderedByD,
        deliveredByDiameter: deliveredByD,
        stockSeries: stockSeries,
        plannedDailyByDiameter: plannedDailyByD,
        workerDayUnitsInWindow: workerUnits,
        supplierLeadDays: supplierLeadDays,
        asOf: now,
      ),
    );

    final snapshot = PredictionSnapshot(
      id: 'pred-${now.millisecondsSinceEpoch}',
      projectId: projectId,
      createdAt: now,
      dataGaps: allGaps
          .where((g) => g.kind == PredictionDataGapKind.workforce)
          .toList(),
      canPredict: true,
      actualDailyConsumption: result.actualDaily,
      plannedDailyConsumption: result.plannedDaily,
      predictedDepletionDate: result.depletionDate,
      tonsPerWorkerDay: result.tonsPerWorkerDay,
      deviationPercent: result.deviationPercent,
      overallRisk: result.overallRisk,
      diameters: result.diameters,
      purchase: result.purchase,
      warnings: result.warnings,
    );

    return _withNarratives(snapshot, PredictionNarrator.narrate(snapshot));
  }

  static PredictionSnapshot _withNarratives(
    PredictionSnapshot snapshot,
    List<String> narratives,
  ) {
    return PredictionSnapshot(
      id: snapshot.id,
      projectId: snapshot.projectId,
      createdAt: snapshot.createdAt,
      dataGaps: snapshot.dataGaps,
      canPredict: snapshot.canPredict,
      actualDailyConsumption: snapshot.actualDailyConsumption,
      plannedDailyConsumption: snapshot.plannedDailyConsumption,
      predictedDepletionDate: snapshot.predictedDepletionDate,
      tonsPerWorkerDay: snapshot.tonsPerWorkerDay,
      deviationPercent: snapshot.deviationPercent,
      overallRisk: snapshot.overallRisk,
      diameters: snapshot.diameters,
      purchase: snapshot.purchase,
      warnings: snapshot.warnings,
      narratives: narratives,
    );
  }

  static Map<int, double> _averagePlannedDaily(List<WorkScheduleDay> days) {
    if (days.isEmpty) return {};
    final totals = <int, double>{};
    for (final day in days) {
      day.plannedTonnageByDiameter.forEach((d, t) {
        totals[d] = (totals[d] ?? 0) + t;
      });
    }
    final n = days.length.toDouble();
    return totals.map((d, t) => MapEntry(d, t / n));
  }
}
