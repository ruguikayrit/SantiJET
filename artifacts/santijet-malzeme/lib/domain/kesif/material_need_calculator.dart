import '../entities/kesif_line.dart';
import '../entities/unit_consumption.dart';

/// Keşif metrajı × birim sarfiyat → malzeme ihtiyacı.
class MaterialNeed {
  const MaterialNeed({
    required this.id,
    required this.kesifLine,
    required this.consumption,
    required this.quantity,
  });

  /// Seçim anahtarı: `sarfiyatId|kesifLineId`.
  final String id;
  final KesifLine kesifLine;
  final UnitConsumption consumption;

  /// Hesaplanan malzeme miktarı.
  final double quantity;

  String get materialName => consumption.materialName;
  String get materialUnit => consumption.materialUnit;
  double get metraj => kesifLine.miktar;
  double get rate => consumption.rate;
  String get pozNo => kesifLine.pozNo;
}

/// Poz eşleşmesiyle ihtiyaç listesi üretir.
List<MaterialNeed> computeMaterialNeeds({
  required List<KesifLine> lines,
  required List<UnitConsumption> consumptions,
}) {
  final byPoz = <String, List<UnitConsumption>>{};
  for (final c in consumptions) {
    final key = c.pozNo.trim();
    if (key.isEmpty) continue;
    byPoz.putIfAbsent(key, () => []).add(c);
  }

  final needs = <MaterialNeed>[];
  for (final line in lines) {
    final matched = byPoz[line.pozNo.trim()] ?? const <UnitConsumption>[];
    for (final c in matched) {
      needs.add(
        MaterialNeed(
          id: '${c.id}|${line.id}',
          kesifLine: line,
          consumption: c,
          quantity: line.miktar * c.rate,
        ),
      );
    }
  }
  return needs;
}
