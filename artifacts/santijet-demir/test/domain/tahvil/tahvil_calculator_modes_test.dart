import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/tahvil/tahvil_calculator_modes.dart';

void main() {
  group('tahvil calculator modes', () {
    test('spacing mode matches Excel φ16@250 → φ14@191 example', () {
      const sourceDiameter = 16;
      const sourceSpacingMm = 250.0;

      final sourceAs = computeAsPerMeterMm2(sourceDiameter, sourceSpacingMm);
      expect(sourceAs, closeTo(804.25, 0.1));

      final spacing14 = computeEquivalentSpacingMm(
        sourceDiameter: sourceDiameter,
        sourceSpacingMm: sourceSpacingMm,
        targetDiameter: 14,
      );
      expect(spacing14, closeTo(191, 1));

      final results = computeSpacingTahvilResults(
        sourceDiameter: sourceDiameter,
        sourceSpacingMm: sourceSpacingMm,
      );
      final to14 = results.firstWhere((item) => item.targetDiameter == 14);
      expect(to14.isAllowed, isTrue);
      expect(to14.resultingSpacingMm, closeTo(191, 1));
    });

    test('single quantity mode matches Excel 3φ16 → 4φ14 example', () {
      final results = computeSingleQuantityTahvilResults(
        sourceDiameter: 16,
        sourceQuantity: 3,
      );
      final to14 = results.firstWhere((item) => item.targetDiameter == 14);

      expect(to14.equivalentQuantity, 4);
      expect(to14.sourceAreaMm2, closeTo(603.19, 0.1));
      expect(to14.targetAreaMm2, closeTo(615.75, 0.5));
      expect(to14.isAllowed, isTrue);
    });

    test('dual quantity mode matches Excel mixed reinforcement example', () {
      final comparison = computeDualQuantityComparison(
        sourceQuantityA: 3,
        sourceDiameterA: 16,
        sourceQuantityB: 2,
        sourceDiameterB: 14,
        targetQuantityA: 5,
        targetDiameterA: 14,
        targetQuantityB: 2,
        targetDiameterB: 12,
      );

      expect(comparison, isNotNull);
      expect(comparison!.sourceAreaMm2, closeTo(911.06, 0.5));
      expect(comparison.targetAreaMm2, closeTo(995.88, 1.0));
    });

    test('dual quantity mode suggests tahvil combinations from source', () {
      final suggestions = computeDualQuantityTahvilSuggestions(
        sourceQuantityA: 3,
        sourceDiameterA: 16,
        sourceQuantityB: 2,
        sourceDiameterB: 14,
      );

      expect(suggestions, isNotEmpty);
      expect(suggestions.any((item) => !item.legA.isUnchanged || !item.legB.isUnchanged),
          isTrue);
      expect(
        suggestions.any(
          (item) =>
              item.legA.targetDiameter == 14 &&
              item.legB.targetDiameter == 12,
        ),
        isTrue,
      );
    });

    test('dual comparison reports diameter rule violations on manual entry', () {
      final comparison = computeDualQuantityComparison(
        sourceQuantityA: 3,
        sourceDiameterA: 16,
        sourceQuantityB: 2,
        sourceDiameterB: 14,
        targetQuantityA: 3,
        targetDiameterA: 28,
        targetQuantityB: 2,
        targetDiameterB: 12,
      );

      expect(comparison, isNotNull);
      expect(comparison!.isAllowed, isFalse);
      expect(comparison.diameterRuleViolations, isNotEmpty);
    });

    test('spacing mode rejects diameters outside ±4 mm rule', () {
      final results = computeSpacingTahvilResults(
        sourceDiameter: 16,
        sourceSpacingMm: 250,
      );
      final to28 = results.firstWhere((item) => item.targetDiameter == 28);
      expect(to28.isAllowed, isFalse);
    });
  });
}
