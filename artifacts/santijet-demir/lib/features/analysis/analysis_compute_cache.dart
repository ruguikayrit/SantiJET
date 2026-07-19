import 'package:santijet_demir/domain/entities/cutting_bending.dart';

/// Kesim planı gibi pahalı hesaplamalar için LRU önbellek.
/// Büyük projelerde aynı parça listesi için tekrar paketleme yapılmaz.
abstract final class AnalysisComputeCache {
  static const _maxEntries = 48;

  static final _stockCutPlans = <String, List<StockCutPlan>>{};
  static final _accessOrder = <String>[];

  static String keyForPieces(List<RebarPieceLine> pieces) {
    if (pieces.isEmpty) return 'v2:empty';
    var hash = 17;
    var totalQty = 0;
    for (final piece in pieces) {
      hash = 37 * hash + piece.diameter;
      hash = 37 * hash + piece.lengthM.hashCode;
      hash = 37 * hash + piece.quantity;
      hash = 37 * hash + (piece.elementTypeCode?.hashCode ?? 0);
      hash = 37 * hash + (piece.elementCode?.hashCode ?? 0);
      totalQty += piece.quantity;
    }
    // v2: tüm çubuklar saklanır (eski 120’lik önizleme önbelleğini geçersiz kılar).
    return 'v2:${pieces.length}:$totalQty:$hash';
  }

  static List<StockCutPlan> readStockCutPlans(String key) {
    final cached = _stockCutPlans[key];
    if (cached == null) return const [];
    _touch(key);
    return cached;
  }

  static void storeStockCutPlans(String key, List<StockCutPlan> plans) {
    if (_stockCutPlans.containsKey(key)) {
      _stockCutPlans[key] = plans;
      _touch(key);
      return;
    }
    while (_stockCutPlans.length >= _maxEntries && _accessOrder.isNotEmpty) {
      final evict = _accessOrder.removeAt(0);
      _stockCutPlans.remove(evict);
    }
    _stockCutPlans[key] = plans;
    _accessOrder.add(key);
  }

  static bool hasStockCutPlans(String key) => _stockCutPlans.containsKey(key);

  static void _touch(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  static void clear() {
    _stockCutPlans.clear();
    _accessOrder.clear();
  }
}
