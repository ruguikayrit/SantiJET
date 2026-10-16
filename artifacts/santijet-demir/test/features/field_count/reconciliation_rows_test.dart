import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/field_count/field_count_calculator.dart';

void main() {
  group('buildReconciliationRows', () {
    test('lists all survey diameters even without delivery', () {
      const imalats = [
        SurveyImalat(
          id: 'temel',
          name: 'Temel',
          totalTonnage: 100,
          progressPercent: 10,
          diameters: [16, 20],
          diameterLines: [
            DiameterLine(
              diameter: 16,
              planned: 60,
              ordered: 0,
              delivered: 0,
              progressPercent: 10,
            ),
            DiameterLine(
              diameter: 20,
              planned: 40,
              ordered: 0,
              delivered: 0,
              progressPercent: 50,
            ),
          ],
          planned: 100,
          ordered: 0,
          delivered: 0,
          pending: 0,
        ),
      ];

      final rows = buildReconciliationRows(
        imalats: imalats,
        deliveredByDiameter: const {16: 120},
        plannedUsageByDiameter: const {16: 6, 20: 20},
        expectedStockByDiameter: const {16: 114},
        countedByDiameter: const {16: 100},
        usedByDiameter: const {16: 20},
      );

      expect(rows, hasLength(2));
      expect(rows[0].diameter, 16);
      expect(rows[0].survey, 60);
      expect(rows[0].delivered, 120);
      expect(rows[0].plannedUsage, 6);
      expect(rows[0].expectedStock, 114);
      expect(rows[0].counted, 100);
      expect(rows[0].used, 20);
      expect(rows[0].fire, closeTo(14, 0.001));
      expect(
        rows[0].fire,
        closeTo(rows[0].used - rows[0].plannedUsage, 0.001),
      );
      expect(rows[1].diameter, 20);
      expect(rows[1].delivered, 0);
      expect(rows[1].plannedUsage, 20);
    });

    test('clamps negative usage and negative expected stock to zero', () {
      const imalats = [
        SurveyImalat(
          id: 'kolon',
          name: 'Kolon',
          totalTonnage: 40,
          progressPercent: 10,
          diameters: [12],
          diameterLines: [
            DiameterLine(
              diameter: 12,
              planned: 40,
              ordered: 20,
              delivered: 10,
              progressPercent: 10,
            ),
          ],
          planned: 40,
          ordered: 20,
          delivered: 10,
          pending: 10,
        ),
      ];

      final rows = buildReconciliationRows(
        imalats: imalats,
        deliveredByDiameter: const {12: 10},
        plannedUsageByDiameter: const {12: 4},
        expectedStockByDiameter: const {12: -6},
        countedByDiameter: const {12: 24},
        usedByDiameter: const {12: -14},
      );

      expect(rows.single.used, 0);
      expect(rows.single.expectedStock, 0);
    });
  });

  group('computeReconciliationTotals', () {
    test('sums all reconciliation columns including fire', () {
      const rows = [
        ReconciliationRow(
          diameter: 16,
          survey: 60,
          ordered: 50,
          delivered: 120,
          plannedUsage: 6,
          expectedStock: 114,
          counted: 100,
          used: 20,
        ),
        ReconciliationRow(
          diameter: 20,
          survey: 40,
          ordered: 30,
          delivered: 0,
          plannedUsage: 20,
          expectedStock: 0,
          counted: 0,
          used: 0,
        ),
      ];

      final totals = computeReconciliationTotals(rows);

      expect(totals.survey, 100);
      expect(totals.ordered, 80);
      expect(totals.delivered, 120);
      expect(totals.plannedUsage, 26);
      expect(totals.plannedStock, 114);
      expect(totals.fieldCount, 100);
      expect(totals.actualUsage, 20);
      expect(totals.fire, closeTo(-6, 0.001));
    });
  });
}
