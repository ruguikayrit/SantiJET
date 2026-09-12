/// Merkezi birim dönüşümü. Motor içi hesaplar mm / mm².
abstract final class Units {
  static const areaEpsilon = 1e-6;
  static const lengthEpsilon = 1e-9;

  static double cmToMm(double cm) => cm * 10;
  static double mmToCm(double mm) => mm / 10;
  static double mToMm(double m) => m * 1000;
  static double mmToM(double mm) => mm / 1000;

  static bool nearlyEqual(double a, double b, [double epsilon = areaEpsilon]) =>
      (a - b).abs() <= epsilon;

  static bool atLeast(double value, double minimum, [double epsilon = areaEpsilon]) =>
      value + epsilon >= minimum;

  static bool atMost(double value, double maximum, [double epsilon = areaEpsilon]) =>
      value <= maximum + epsilon;
}
