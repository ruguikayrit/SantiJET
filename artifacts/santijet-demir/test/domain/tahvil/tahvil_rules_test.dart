import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/domain/tahvil/tahvil_rules.dart';

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

    test('rejects tahvil when resulting spacing exceeds 25 cm', () {
      final equivalents = computeTahvilEquivalents(const [
        RebarPieceLine(
          diameter: 12,
          lengthM: 1.90,
          quantity: 52,
          spacingCm: 15,
        ),
        RebarPieceLine(
          diameter: 16,
          lengthM: 1.85,
          quantity: 1978,
          spacingCm: 15,
        ),
      ]);

      final toSixteen = equivalents.where((eq) => eq.toDiameter == 16);
      expect(
        toSixteen.any((eq) => eq.fromDiameter == 12),
        isFalse,
      );
      expect(
        equivalents.any(
          (eq) => eq.fromDiameter == 16 && eq.toDiameter == 12,
        ),
        isTrue,
      );
    });

    test('excludes clusters without valid tahvil pairs', () {
      expect(
        shouldIncludeTahvilCluster(const [
          RebarPieceLine(diameter: 12, lengthM: 2.60, quantity: 2),
          RebarPieceLine(diameter: 28, lengthM: 2.70, quantity: 24),
        ]),
        isFalse,
      );
    });

    test('marks closest diameter as recommended', () {
      final equivalents = computeTahvilEquivalents(const [
        RebarPieceLine(diameter: 16, lengthM: 2.00, quantity: 10),
        RebarPieceLine(diameter: 20, lengthM: 2.05, quantity: 6),
      ]);

      final recommended = equivalents.where((eq) => eq.isRecommended).toList();
      expect(recommended, isNotEmpty);
      for (final item in recommended) {
        expect((item.fromDiameter - item.toDiameter).abs(), lessThanOrEqualTo(4));
      }
    });
  });
}
