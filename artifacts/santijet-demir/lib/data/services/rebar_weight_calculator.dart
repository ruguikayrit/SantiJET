/// Türkiye'de yaygın kullanılan demir ağırlık formülü: kg/m = d² / 162
class RebarWeightCalculator {
  const RebarWeightCalculator._();

  static const standardDiameters = [8, 10, 12, 14, 16, 18, 20, 22, 25, 28, 32];

  static double kgPerMeter(int diameterMm) {
    if (diameterMm <= 0) return 0;
    return (diameterMm * diameterMm) / 162;
  }

  static double weightKg({
    required int diameterMm,
    required double lengthM,
  }) {
    return kgPerMeter(diameterMm) * lengthM;
  }

  static double tonnage({
    required int diameterMm,
    required double lengthM,
  }) {
    return weightKg(diameterMm: diameterMm, lengthM: lengthM) / 1000;
  }
}
