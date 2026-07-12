/// Zaman tabanlı kısa id üretimi.
///
/// React Native BFA `genId` / `genKesifId` davranışına benzer; yerel/offline
/// kullanıcı verisi için yeterli benzersizlik sağlar.
abstract final class IdGen {
  static int _counter = 0;

  static String make(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final seq = (_counter++ % 1296).toRadixString(36).padLeft(2, '0');
    return '$prefix$now$seq';
  }
}
