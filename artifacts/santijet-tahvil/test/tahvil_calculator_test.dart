import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_tahvil/domain/tahvil_calculator.dart';
import 'package:santijet_tahvil/domain/tahvil_rules.dart';

void main() {
  group('tahvil rules', () {
    test('allows diameter pairs within 4 mm', () {
      expect(isTahvilDiameterAllowed(20, 16), isTrue);
      expect(isTahvilDiameterAllowed(20, 18), isTrue);
      expect(isTahvilDiameterAllowed(16, 12), isTrue);
    });

    test('rejects diameter pairs beyond 4 mm', () {
      expect(isTahvilDiameterAllowed(28, 12), isFalse);
      expect(isTahvilDiameterAllowed(20, 14), isFalse);
      expect(isTahvilDiameterAllowed(16, 16), isFalse);
    });

    test('computes equivalent quantity from cross-section area', () {
      expect(
        computeTahvilEquivalentQuantity(
          fromDiameter: 16,
          fromQuantity: 1978,
          toDiameter: 12,
        ),
        3516,
      );
    });

    test('derives reference quantity from spacing', () {
      expect(deriveReferenceQuantity(spacingCm: 10), 10);
      expect(deriveReferenceQuantity(spacingCm: 15), 7);
    });
  });

  group('spacing tahvil', () {
    test('Ø16 / 150 mm yields allowed nearby diameters', () {
      final results = computeSpacingTahvilResults(
        sourceDiameter: 16,
        sourceSpacingMm: 150,
      );
      expect(results, isNotEmpty);
      expect(results.any((r) => r.isAllowed), isTrue);
      expect(
        results.where((r) => r.targetDiameter == 12).every((r) => r.isAllowed),
        isTrue,
      );
    });

    test('keeps target As at least source As for allowed rows', () {
      final results = computeSpacingTahvilResults(
        sourceDiameter: 20,
        sourceSpacingMm: 200,
      ).where((r) => r.isAllowed);
      for (final row in results) {
        expect(row.targetAsPerMeterMm2 + 1e-6, greaterThanOrEqualTo(row.sourceAsPerMeterMm2));
      }
    });
  });

  group('quantity tahvil', () {
    test('10×Ø16 has an allowed equivalent', () {
      final results = computeSingleQuantityTahvilResults(
        sourceDiameter: 16,
        sourceQuantity: 10,
      );
      final allowed = results.where((r) => r.isAllowed).toList();
      expect(allowed, isNotEmpty);
      expect(allowed.first.targetAreaMm2, greaterThanOrEqualTo(allowed.first.sourceAreaMm2));
    });

    test('dual suggestions skip the unchanged-unchanged pair', () {
      final suggestions = computeDualQuantityTahvilSuggestions(
        sourceQuantityA: 10,
        sourceDiameterA: 16,
        sourceQuantityB: 8,
        sourceDiameterB: 12,
      );
      expect(suggestions, isNotEmpty);
      expect(
        suggestions.any((s) => s.legA.isUnchanged && s.legB.isUnchanged),
        isFalse,
      );
    });
  });

  group('diameters to Ø50', () {
    test('allows ±4 mm pairs on large bars', () {
      expect(isTahvilDiameterAllowed(32, 36), isTrue);
      expect(isTahvilDiameterAllowed(36, 40), isTrue);
      expect(isTahvilDiameterAllowed(50, 40), isFalse);
    });

    test('spacing tahvil includes Ø36–Ø50 as targets', () {
      final results = computeSpacingTahvilResults(
        sourceDiameter: 32,
        sourceSpacingMm: 200,
      );
      expect(results.any((r) => r.targetDiameter == 36), isTrue);
      expect(results.any((r) => r.targetDiameter == 40), isTrue);
      expect(results.any((r) => r.targetDiameter == 50), isTrue);
    });
  });

  group('dual spacing tahvil', () {
    test('skips the unchanged-unchanged pair', () {
      final suggestions = computeDualSpacingTahvilSuggestions(
        sourceDiameterA: 16,
        sourceSpacingMmA: 150,
        sourceDiameterB: 12,
        sourceSpacingMmB: 200,
      );
      expect(suggestions, isNotEmpty);
      expect(
        suggestions.any((s) => s.legA.isUnchanged && s.legB.isUnchanged),
        isFalse,
      );
    });
  });

  group('display spacing rounding', () {
    test('floors to 0,5 cm steps', () {
      expect(floorSpacingCmToHalfStep(8.9), 8.5);
      expect(floorSpacingCmToHalfStep(8.4), 8.0);
      expect(floorSpacingCmToHalfStep(13.9), 13.5);
      expect(floorSpacingCmToHalfStep(15.0), 15.0);
    });

    test('rounded spacing yields As at least source for allowed rows', () {
      final results = computeSpacingTahvilResults(
        sourceDiameter: 16,
        sourceSpacingMm: 150,
      ).where((r) => r.isAllowed);
      for (final row in results) {
        final displayAs = displayTargetAsPerMeterMm2(
          diameterMm: row.targetDiameter,
          spacingMm: row.resultingSpacingMm,
        );
        expect(
          displayAs + 1e-6,
          greaterThanOrEqualTo(row.sourceAsPerMeterMm2),
        );
      }
    });
  });
}
