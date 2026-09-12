import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_tahvil/domain/engine/engine.dart';

void main() {
  group('RebarMath', () {
    test('single bar area is πØ²/4', () {
      expect(RebarMath.barAreaMm2(16), closeTo(math.pi * 64, 1e-6));
    });

    test('4Ø16 totals 804 mm² class', () {
      final as = RebarMath.totalAreaMm2(diameterMm: 16, count: 4);
      expect(as, closeTo(804.2, 0.5));
    });

    test('bars per meter and As/m for Ø10/20', () {
      expect(RebarMath.barsPerMeter(200), 5);
      expect(
        RebarMath.areaPerMeterMm2(diameterMm: 10, spacingMm: 200),
        closeTo(392.7, 0.2),
      );
    });

    test('Ø8/12.5 As/m exceeds Ø10/20', () {
      final project = RebarMath.areaPerMeterMm2(diameterMm: 10, spacingMm: 200);
      final next = RebarMath.areaPerMeterMm2(diameterMm: 8, spacingMm: 125);
      expect(next, greaterThanOrEqualTo(project - 1e-6));
      expect(next, closeTo(402.1, 0.2));
    });
  });
}
