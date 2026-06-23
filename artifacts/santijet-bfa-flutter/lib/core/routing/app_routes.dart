/// Uygulama rota yolları — Demir konvansiyonuyla (abstract final class).
///
/// React Native expo-router yapısının Flutter/go_router karşılığı.
/// Alt navigasyon sekmeleri: home, katalog, kesif, ayarlar.
abstract final class AppRoutes {
  // Alt navigasyon sekmeleri
  static const home = '/';
  static const katalog = '/katalog';
  static const kesif = '/kesif';
  static const ayarlar = '/ayarlar';

  // Kök (tam ekran) rotalar
  static const pozlar = '/pozlar';
  static const pozDetayPattern = '/pozlar/:id';
  static String pozDetay(String id) => '/pozlar/$id';
  static const kesifDetayPattern = '/kesif-detay/:id';
  static String kesifDetay(String id) => '/kesif-detay/$id';
  static const karsilastir = '/karsilastir';
  static const tasarimSistemi = '/tasarim-sistemi';
}
