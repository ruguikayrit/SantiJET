import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/entities/prediction_models.dart';
import 'package:santijet_demir/features/prediction/prediction_calculator.dart';
import 'package:santijet_demir/features/prediction/prediction_narrator.dart';

void main() {
  group('PredictionCalculator', () {
    test('520→445 over 5 days = 15 t/day', () {
      final series = [
        PredictionStockPoint(
          date: DateTime(2026, 7, 1),
          stockByDiameter: const {16: 520},
        ),
        PredictionStockPoint(
          date: DateTime(2026, 7, 6),
          stockByDiameter: const {16: 445},
        ),
      ];
      final daily =
          PredictionCalculator.actualDailyConsumptionByDiameter(series);
      expect(daily[16], closeTo(15, 0.01));
    });

    test('critical diameter risk when days remaining low', () {
      const config = PredictionConfig(
        criticalDays: 3,
        purchaseSoonDays: 7,
        safetyStockDays: 0,
      );
      final result = PredictionCalculator.compute(
        PredictionCalculatorInput(
          projectId: 'p1',
          config: config,
          plannedByDiameter: const {16: 100, 12: 50},
          orderedByDiameter: const {16: 40, 12: 20},
          deliveredByDiameter: const {16: 40, 12: 20},
          stockSeries: [
            PredictionStockPoint(
              date: DateTime(2026, 7, 1),
              stockByDiameter: const {16: 46, 12: 30},
            ),
            PredictionStockPoint(
              date: DateTime(2026, 7, 5),
              stockByDiameter: const {16: 18, 12: 25},
            ),
          ],
          plannedDailyByDiameter: const {16: 5, 12: 1},
          workerDayUnitsInWindow: 20,
          supplierLeadDays: 5,
          asOf: DateTime(2026, 7, 5),
        ),
      );

      final d16 = result.diameters.firstWhere((d) => d.diameter == 16);
      // 46→18 over 4 days = 7 t/day; 18/7 ≈ 2.57 days → red
      expect(d16.actualDailyConsumption, closeTo(7, 0.01));
      expect(d16.daysRemaining, closeTo(18 / 7, 0.05));
      expect(d16.risk, PredictionRiskLevel.red);
      expect(result.overallRisk, PredictionRiskLevel.red);
    });

    test('narrator gaps block prediction without inventing numbers', () {
      final gaps = PredictionNarrator.buildGaps(
        hasSurveyDiameters: true,
        fieldCountCount: 1,
        hasWorkSchedule: false,
        hasWorkforce: false,
      );
      expect(PredictionNarrator.canPredictFromGaps(gaps), isFalse);
      expect(
        gaps.any((g) => g.kind == PredictionDataGapKind.fieldCounts),
        isTrue,
      );
      expect(
        gaps.any((g) => g.kind == PredictionDataGapKind.workSchedule),
        isTrue,
      );
    });

    test('purchase recommendation uses remaining - stock - inTransit', () {
      const config = PredictionConfig(safetyStockDays: 0);
      final result = PredictionCalculator.compute(
        PredictionCalculatorInput(
          projectId: 'p1',
          config: config,
          plannedByDiameter: const {16: 100},
          orderedByDiameter: const {16: 60},
          deliveredByDiameter: const {16: 40},
          stockSeries: [
            PredictionStockPoint(
              date: DateTime(2026, 7, 1),
              stockByDiameter: const {16: 50},
            ),
            PredictionStockPoint(
              date: DateTime(2026, 7, 6),
              stockByDiameter: const {16: 30},
            ),
          ],
          plannedDailyByDiameter: const {16: 4},
          workerDayUnitsInWindow: 0,
          supplierLeadDays: 5,
          asOf: DateTime(2026, 7, 6),
        ),
      );

      final d16 = result.diameters.firstWhere((d) => d.diameter == 16);
      // used = delivered - stock = 40 - 30 = 10; remaining = 100 - 10 = 90
      // inTransit = 60 - 40 = 20; recommended = 90 - 30 - 20 = 40
      expect(d16.remainingRequirement, closeTo(90, 0.01));
      expect(d16.inTransit, closeTo(20, 0.01));
      expect(d16.recommendedPurchase, closeTo(40, 0.01));
    });
  });
}
