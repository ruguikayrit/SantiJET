/// Uygulama rota yolları — Demir konvansiyonuyla (abstract final class).
///
/// Alt navigasyon: Ana Sayfa · Analiz · Birim Fiyat · Keşif.
/// Ayarlar kök (tam ekran) rotadır — bottom tab değil.
abstract final class AppRoutes {
  /// Ortak açılış ekranı (Demir/Beton/Puantaj ile aynı akış).
  static const splash = '/splash';

  // Alt navigasyon sekmeleri
  static const home = '/';
  static const analiz = '/analiz';
  static const birimFiyat = '/birim-fiyat';
  static const kesif = '/kesif';

  /// Eski Katalog sekmesi — Birim Fiyat'a yönlendirilir.
  static const katalog = '/katalog';

  // Kök (tam ekran) rotalar
  static const ayarlar = '/ayarlar';
  static const pozlar = '/pozlar';
  static const pozDetayPattern = '/pozlar/:id';
  static String pozDetay(String id) => '/pozlar/$id';
  static const kesifDetayPattern = '/kesif-detay/:id';
  static String kesifDetay(String id) => '/kesif-detay/$id';
  static const karsilastir = '/karsilastir';
  static const tasarimSistemi = '/tasarim-sistemi';
  static const legalDocumentPattern = '/hukuki/:id';
  static String legalDocument(String id) => '/hukuki/$id';
  static const sources = '/kaynaklar';
  static const analizYeni = '/pozlar/yeni';
  static const analizDuzenlePattern = '/pozlar/:id/duzenle';
  static String analizDuzenle(String id) => '/pozlar/$id/duzenle';
  static const analizKatalogu = '/analiz-katalogu';
}
