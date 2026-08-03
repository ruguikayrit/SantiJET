/// Hadde çelik profil kesit özellikleri.
class SteelProfile {
  const SteelProfile({
    required this.series,
    required this.designation,
    required this.depthMm,
    required this.widthMm,
    required this.webThicknessMm,
    required this.flangeThicknessMm,
    required this.rootRadiusMm,
    required this.areaCm2,
    required this.ixCm4,
    required this.iyCm4,
    required this.wxCm3,
    required this.wyCm3,
    required this.wplxCm3,
    required this.wplyCm3,
  });

  /// Örn. `IPE`, `HEB`.
  final String series;

  /// Örn. `IPE 300`, `IPB (HE-B) 260`.
  final String designation;

  final double depthMm;
  final double widthMm;
  final double webThicknessMm;
  final double flangeThicknessMm;
  final double rootRadiusMm;
  final double areaCm2;
  final double ixCm4;
  final double iyCm4;
  final double wxCm3;
  final double wyCm3;
  final double wplxCm3;
  final double wplyCm3;

  /// Gövde yüksekliği h = d − 2·tf − 2·r [mm].
  double get clearWebHeightMm =>
      depthMm - 2 * flangeThicknessMm - 2 * rootRadiusMm;

  /// Gövde alanı Aw = d · tw [mm²].
  double get webAreaMm2 => depthMm * webThicknessMm;

  String get id => designation;
}
