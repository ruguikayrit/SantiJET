/// Uygulama kimlik ve sabit metinleri.
///
/// Kod/package yolu (`santijet_bfa` / `santijet-bfa-flutter`) şimdilik değişmez;
/// kullanıcıya görünen marka: **ŞantiJET Maliyet**.
abstract final class AppInfo {
  static const String displayName = 'ŞantiJET Maliyet';
  static const String legalName = 'ŞantiJET Maliyet';
  /// Kısa ürün kodu — header / compact marka satırı.
  static const String productLabel = 'MALİYET';
  /// Açılış ekranı ürün adı — Demir/Beton/Puantaj splash satırı.
  static const String splashProductLabel = 'MALİYET';
  static const String tagline =
      'Birim fiyat analizi, keşif, metraj ve yaklaşık maliyet.';
  static const String dataSourceLabel = 'ÇŞB YFK 2026';
  static const String dataUpdateLabel = 'Ocak 2026';
  static const String supportEmail = 'destek@santijet.com';
  static const String version = '1.1.0';

  /// Yeni yedek yazımlarında kullanılan uygulama kimliği.
  static const String backupAppId = 'santijet-maliyet';
  /// Geriye dönük yedek okuma — eski BFA kimlikleri.
  static const List<String> legacyBackupAppIds = [
    'santijet-bfa-flutter',
    'santijet-bfa',
  ];

  static const String localDataNote =
      'Özel analizler, favoriler ve keşif projeleri yalnızca cihazınızda saklanır.';
}
