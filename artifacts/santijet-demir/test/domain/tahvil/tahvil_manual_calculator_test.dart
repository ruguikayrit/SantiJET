import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/tahvil/tahvil_manual_calculator.dart';

void main() {
  group('manual tahvil calculator', () {
    test('returns empty when spacing is missing', () {
      final results = computeManualTahvilResults(
        fromDiameter: 12,
        fromQuantity: 10,
        fromSpacingCm: null,
      );

      expect(results, isEmpty);
    });

    test('uses 100 cm reference when quantity is omitted', () {
      final results = computeManualTahvilResults(
        fromDiameter: 12,
        fromSpacingCm: 10,
      );

      final toTen = results.firstWhere((item) => item.toDiameter == 10);
      expect(toTen.isAllowed, isTrue);
      expect(toTen.equivalentQuantity, 14);
      expect(toTen.resultingSpacingCm, closeTo(100 / 14, 0.01));
      expect(toTen.fromTonnage, isNull);
      expect(toTen.toTonnage, isNull);
    });

    test('computes tonnage comparison when length is provided', () {
      final results = computeManualTahvilResults(
        fromDiameter: 12,
        fromSpacingCm: 10,
        lengthCm: 200,
      );

      final toTen = results.firstWhere((item) => item.toDiameter == 10);
      expect(toTen.fromTonnage, isNotNull);
      expect(toTen.toTonnage, isNotNull);
      expect(toTen.fromTonnage, greaterThan(0));
      expect(toTen.toTonnage, greaterThan(0));
    });

    test('computes quantity and spacing for valid target diameter', () {
      final results = computeManualTahvilResults(
        fromDiameter: 16,
        fromQuantity: 1978,
        fromSpacingCm: 15,
      );

      final toTwelve = results.firstWhere((item) => item.toDiameter == 12);
      expect(toTwelve.isAllowed, isTrue);
      expect(toTwelve.equivalentQuantity, 3516);
      expect(toTwelve.resultingSpacingCm, closeTo(8.4, 0.1));
    });

    test('includes rejected diameters with concise reasons', () {
      final results = computeManualTahvilResults(
        fromDiameter: 16,
        fromQuantity: 100,
        fromSpacingCm: 25,
      );

      final toEighteen = results.firstWhere((item) => item.toDiameter == 18);
      expect(toEighteen.isAllowed, isFalse);
      expect(toEighteen.rejectReason, contains('Aralık'));
      expect(toEighteen.rejectReason, contains('31.7'));

      final toTwentyTwo = results.firstWhere((item) => item.toDiameter == 22);
      expect(toTwentyTwo.isAllowed, isFalse);
      expect(toTwentyTwo.rejectReason, contains('±4 mm çap'));
    });

    test('rejects target when spacing exceeds limit', () {
      final results = computeManualTahvilResults(
        fromDiameter: 12,
        fromQuantity: 52,
        fromSpacingCm: 15,
      );

      final toSixteen = results.firstWhere((item) => item.toDiameter == 16);
      expect(toSixteen.isAllowed, isFalse);
      expect(toSixteen.rejectReason, isNotNull);
    });

    test('lists all allowed tahvil results sorted by area deviation', () {
      final allowed = computeAllowedManualTahvilResults(
        fromDiameter: 16,
        fromQuantity: 1978,
        fromSpacingCm: 15,
      );

      expect(allowed, isNotEmpty);
      expect(allowed.every((item) => item.isAllowed), isTrue);
      expect(allowed.first.toDiameter, 20);

      for (var i = 1; i < allowed.length; i++) {
        expect(
          allowed[i - 1].areaDeviationPercent,
          lessThanOrEqualTo(allowed[i].areaDeviationPercent),
        );
      }
    });

    test('picks optimal tahvil with lowest area deviation', () {
      final optimal = computeOptimalManualTahvilResult(
        fromDiameter: 16,
        fromQuantity: 1978,
        fromSpacingCm: 15,
      );

      expect(optimal, isNotNull);
      expect(optimal!.isAllowed, isTrue);
      expect(optimal.toDiameter, 20);
      expect(optimal.areaDeviationPercent, lessThan(1));
    });

    test('returns null when no allowed tahvil exists', () {
      final optimal = computeOptimalManualTahvilResult(
        fromDiameter: 8,
        fromQuantity: 1,
        fromSpacingCm: 15,
      );

      expect(optimal, isNull);
    });

    test('input row requires diameter and spacing only', () {
      expect(
        const TahvilManualInputRow(diameter: 12, spacingCm: 10).isComplete,
        isTrue,
      );
      expect(
        const TahvilManualInputRow(diameter: 12, quantity: 100).isComplete,
        isFalse,
      );
      expect(
        const TahvilManualInputRow(diameter: 12, spacingCm: 10, lengthCm: 200)
            .effectiveQuantity,
        10,
      );
    });

    test('findManualInputForDiameter returns matching complete row', () {
      const rows = [
        TahvilManualInputRow(diameter: 16, quantity: 100, spacingCm: 15),
        TahvilManualInputRow(diameter: 12, quantity: 50, spacingCm: 20),
      ];

      final found = findManualInputForDiameter(rows, 12);
      expect(found?.quantity, 50);
      expect(found?.spacingCm, 20);
    });
  });
}
