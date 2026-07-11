import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/field_count/field_count_calculator.dart';

void main() {
  group('computePlannedUsageByDiameter', () {
    test('applies diameter line progress percent to each line', () {
      const imalats = [
        SurveyImalat(
          id: 'a',
          name: 'Kolon',
          totalTonnage: 100,
          progressPercent: 50,
          diameters: [16, 20],
          diameterLines: [
            DiameterLine(
              diameter: 16,
              planned: 60,
              ordered: 0,
              delivered: 0,
              progressPercent: 50,
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
        SurveyImalat(
          id: 'b',
          name: 'Kiriş',
          totalTonnage: 200,
          progressPercent: 25,
          diameters: [16],
          diameterLines: [
            DiameterLine(
              diameter: 16,
              planned: 200,
              ordered: 0,
              delivered: 0,
              progressPercent: 25,
            ),
          ],
          planned: 200,
          ordered: 0,
          delivered: 0,
          pending: 0,
        ),
      ];

      final usage = computePlannedUsageByDiameter(imalats);

      expect(usage[16], closeTo(30 + 50, 0.001));
      expect(usage[20], closeTo(20, 0.001));
    });
  });

  group('computeExpectedStockByDiameter', () {
    test('subtracts planned usage from delivered tonnage', () {
      final expected = computeExpectedStockByDiameter(
        deliveredByDiameter: {16: 360, 20: 300},
        plannedUsageByDiameter: {16: 80, 20: 50},
      );

      expect(expected[16], 280);
      expect(expected[20], 250);
    });
  });

  group('ReconciliationRow firePercent', () {
    test('computes fire as percent of planned usage', () {
      const row = ReconciliationRow(
        diameter: 16,
        survey: 100,
        ordered: 80,
        delivered: 80,
        plannedUsage: 50,
        expectedStock: 30,
        counted: 20,
        used: 60,
      );

      expect(row.fire, 10);
      expect(row.firePercent, 20);
    });

    test('positive fire when actual usage exceeds planned', () {
      const row = ReconciliationRow(
        diameter: 16,
        survey: 200,
        ordered: 120,
        delivered: 120,
        plannedUsage: 100,
        expectedStock: 20,
        counted: 10,
        used: 105,
      );

      expect(row.fire, 5);
      expect(row.firePercent, 5);
      expect(row.status, 'critical');
    });

    test('negative fire means survey overestimate not waste', () {
      const row = ReconciliationRow(
        diameter: 10,
        survey: 100,
        ordered: 80,
        delivered: 80,
        plannedUsage: 100,
        expectedStock: 0,
        counted: 25,
        used: 55,
      );

      expect(row.fire, closeTo(-45, 0.001));
      expect(row.surveyOverestimate, closeTo(45, 0.001));
      expect(row.status, 'normal');
    });

    test('returns zero percent when planned usage is zero', () {
      const row = ReconciliationRow(
        diameter: 12,
        survey: 0,
        ordered: 0,
        delivered: 0,
        plannedUsage: 0,
        expectedStock: 0,
        counted: 0,
        used: 0,
      );

      expect(row.firePercent, 0);
    });
  });
}
