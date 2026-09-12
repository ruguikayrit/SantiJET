import 'dart:math' as math;

import '../../data/rebar_weight.dart';
import 'units.dart';

/// Ortak donatı geometrisi. Ağırlık yalnızca bilgilendirmedir.
abstract final class RebarMath {
  static const _piQuarter = math.pi / 4;
  static const referenceStripMm = 1000.0;

  /// Tek donatı alanı: AsØ = π × Ø² / 4 (mm²).
  static double barAreaMm2(double diameterMm) {
    if (diameterMm <= 0) return 0;
    return _piQuarter * diameterMm * diameterMm;
  }

  /// Toplam alan: As = n × AsØ (mm²).
  static double totalAreaMm2({
    required double diameterMm,
    required int count,
  }) {
    if (count <= 0) return 0;
    return count * barAreaMm2(diameterMm);
  }

  /// 1 m şeritte adet: n = 1000 / s.
  static double barsPerMeter(double spacingMm) {
    if (spacingMm <= 0) return 0;
    return referenceStripMm / spacingMm;
  }

  /// 1 m şeritte alan: As/m = n × π × Ø² / 4 (mm²/m).
  static double areaPerMeterMm2({
    required double diameterMm,
    required double spacingMm,
  }) {
    return barsPerMeter(spacingMm) * barAreaMm2(diameterMm);
  }

  static double ratio({
    required double areaMm2,
    required double sectionAreaMm2,
  }) {
    if (sectionAreaMm2 <= 0) return 0;
    return areaMm2 / sectionAreaMm2;
  }

  /// kg/m — karar kriteri değildir.
  static double kgPerMeter(int diameterMm) => RebarWeight.kgPerMeter(diameterMm);

  static String formatArea(double areaMm2) => areaMm2.toStringAsFixed(1);

  static String formatRatioPercent(double ratio) =>
      (ratio * 100).toStringAsFixed(2);

  static String formatCm(double cm) {
    if ((cm - cm.roundToDouble()).abs() < 0.05) return '${cm.round()}';
    return cm.toStringAsFixed(1);
  }

  static double asDelta(double projectAs, double newAs) => newAs - projectAs;

  static double? asDeltaPercent(double projectAs, double newAs) {
    if (projectAs <= Units.areaEpsilon) return null;
    return ((newAs - projectAs) / projectAs) * 100;
  }
}
