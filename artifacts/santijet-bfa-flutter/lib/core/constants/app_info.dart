/// Uygulama kimlik ve sabit metinleri.
///
/// React Native `constants/appInfo.ts` dosyasından taşınan çekirdek etiketler.
abstract final class AppInfo {
  static const String displayName = 'ŞantiJET Birim Fiyat Analizleri';
  static const String legalName = 'ŞantiJET BFA';
  /// Kısa ürün kodu — header / compact marka satırı.
  static const String productLabel = 'BFA';
  /// Açılış ekranı ürün adı — Demir/Beton/Puantaj splash satırı.
  static const String splashProductLabel = 'BİRİM FİYAT ANALİZİ';
  static const String tagline = 'Birim fiyat analizlerini yönetin, keşif hazırlayın.';
  static const String dataSourceLabel = 'ÇŞB YFK 2026';
  static const String dataUpdateLabel = 'Ocak 2026';
  static const String supportEmail = 'destek@santijet.com';
  static const String version = '1.1.0';

  static const String localDataNote =
      'Özel analizler, favoriler ve keşif projeleri yalnızca cihazınızda saklanır.';
}
