import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/metraj_cetvel_summary.dart';
import 'package:santijet_demir/data/services/rebar_text_parser.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';

void main() {
  group('MetrajCetvelSummary', () {
    test('ince ve kalın demir ayrımı', () {
      final summary = summarizeCetvel([
        MetrajCetvelEntry(
          elementCode: 'S1',
          elementTypeCode: 'S',
          elementTypeLabel: 'Kolon',
          dimensionText: '100/160',
          benzerCount: 2,
          sourceText: 'S1[100/160] 2 ADET',
          rows: [
            MetrajCetvelRow(
              role: RebarLabelRole.stirrup,
              diameter: 12,
              lengthM: 5.1,
              unitQuantity: 18,
              totalQuantity: 36,
              unitWeightKg: 10,
              totalWeightKg: 20,
              sourceText: 'etr*18Ø12/10 L=510',
            ),
            MetrajCetvelRow(
              role: RebarLabelRole.longitudinal,
              diameter: 28,
              lengthM: 2.8,
              unitQuantity: 42,
              totalQuantity: 84,
              unitWeightKg: 100,
              totalWeightKg: 200,
              sourceText: '42Ø28 L=280',
            ),
          ],
        ),
      ]);

      expect(summary.elementCount, 1);
      expect(summary.rowCount, 2);
      expect(summary.thinTonnage, closeTo(0.02, 0.001));
      expect(summary.thickTonnage, closeTo(0.2, 0.001));
      expect(summary.tonnageByDiameter[12], closeTo(0.02, 0.001));
      expect(summary.tonnageByDiameter[28], closeTo(0.2, 0.001));
    });
  });
}
