import 'package:flutter_test/flutter_test.dart';
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
}
