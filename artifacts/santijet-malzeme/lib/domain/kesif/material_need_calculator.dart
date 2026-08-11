import '../entities/kesif_line.dart';
import '../entities/material_request.dart';
import '../entities/unit_consumption.dart';
import '../enums/request_status.dart';

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

  /// Hesaplanan toplam malzeme ihtiyacı.
  final double quantity;

  String get materialName => consumption.materialName;
  String get materialUnit => consumption.materialUnit;
  double get metraj => kesifLine.miktar;
  double get rate => consumption.rate;
  String get pozNo => kesifLine.pozNo;
}

/// Toplam ihtiyaç − mevcut talepler = kalan sipariş penceresi.
class MaterialNeedBalance {
  const MaterialNeedBalance({
    required this.need,
    required this.orderedQty,
  });

  final MaterialNeed need;
  final double orderedQty;

  double get fullQty => need.quantity;

  double get remainingQty {
    final r = fullQty - orderedQty;
    return r < 0 ? 0 : r;
  }

  bool get isFullyOrdered => remainingQty <= 1e-9;

  double get orderedPercentOfFull =>
      fullQty <= 0 ? 0 : (orderedQty / fullQty * 100).clamp(0, 100);
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

bool requestMatchesNeed(MaterialRequest request, MaterialNeed need) {
  if (request.status == RequestStatus.rejected) return false;

  final ucId = request.unitConsumptionId;
  if (ucId != null && ucId.isNotEmpty) {
    if (ucId != need.consumption.id) return false;
    if (request.kesifLineId != null &&
        request.kesifLineId!.isNotEmpty &&
        request.kesifLineId != need.kesifLine.id) {
      return false;
    }
    return true;
  }

  if (request.kesifLineId != need.kesifLine.id) return false;
  return request.displayName.trim().toLowerCase() ==
      need.materialName.trim().toLowerCase();
}

double orderedQuantityForNeed(
  MaterialNeed need,
  Iterable<MaterialRequest> requests,
) {
  var sum = 0.0;
  for (final r in requests) {
    if (requestMatchesNeed(r, need)) sum += r.quantity;
  }
  return sum;
}

List<MaterialNeedBalance> computeMaterialNeedBalances({
  required List<MaterialNeed> needs,
  required List<MaterialRequest> requests,
}) {
  return [
    for (final n in needs)
      MaterialNeedBalance(
        need: n,
        orderedQty: orderedQuantityForNeed(n, requests),
      ),
  ];
}
