/// Uygulama rota yolları ve adları (tek kaynak).
///
/// React Native expo-router yapısının Flutter/go_router karşılığı:
///   index            -> /            (home)
///   imalat-pozlari    -> /pozlar      (+ id ile detay: /pozlar/:id)
///   analiz-katalogu   -> /katalog
///   analiz-karsilastir-> /karsilastir
///   kesif             -> /kesif       (+ /kesif/:id)
///   settings (modal)  -> /ayarlar
class AppRoutes {
  const AppRoutes._();

  static const String home = '/';

  static const String pozlar = '/pozlar';
  static const String pozlarName = 'pozlar';

  static const String pozDetay = '/pozlar/:id';
  static const String pozDetayName = 'poz-detay';

  static const String katalog = '/katalog';
  static const String katalogName = 'katalog';

  static const String karsilastir = '/karsilastir';
  static const String karsilastirName = 'karsilastir';

  static const String kesif = '/kesif';
  static const String kesifName = 'kesif';

  static const String kesifDetay = '/kesif/:id';
  static const String kesifDetayName = 'kesif-detay';

  static const String ayarlar = '/ayarlar';
  static const String ayarlarName = 'ayarlar';
}
