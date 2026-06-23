/// Uygulama rota yolları — Demir konvansiyonuyla (abstract final class).
///
/// React Native expo-router yapısının Flutter/go_router karşılığı.
abstract final class AppRoutes {
  static const home = '/';
  static const pozlar = '/pozlar';
  static String pozDetay(String id) => '/pozlar/$id';
  static const katalog = '/katalog';
  static const karsilastir = '/karsilastir';
  static const kesif = '/kesif';
  static String kesifDetay(String id) => '/kesif/$id';
  static const ayarlar = '/ayarlar';
}
