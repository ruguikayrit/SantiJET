import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';

void main() {
  group('RebarWeightCalculator', () {
    test('calculates kg per meter with standard formula', () {
      expect(RebarWeightCalculator.kgPerMeter(12), closeTo(0.8889, 0.001));
      expect(RebarWeightCalculator.kgPerMeter(16), closeTo(1.5802, 0.001));
    });

    test('calculates total weight for length', () {
      final weight = RebarWeightCalculator.weightKg(
        diameterMm: 12,
        lengthM: 10,
      );
      expect(weight, closeTo(8.889, 0.01));
    });
  });
}
