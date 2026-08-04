/// Uygulama kimlik ve sabit metinleri.
///
/// Kullanıcıya görünen ürün: **ŞantiJET SAHA** (saha + puantaj birleşik).
/// Klasör/package adı şimdilik `santijet-puantaj` (rename Faz 2).
abstract final class AppInfo {
  static const String displayName = 'ŞantiJET SAHA';
  static const String legalName = 'ŞantiJET SAHA';
  static const String productLabel = 'SAHA';
  static const String tagline = 'Saha operasyonu ve adam-gün puantaj.';
  static const String supportEmail = 'destek@santijet.com';
  static const String version = '0.1.0';

  static const String localDataNote =
      'Projeler, personel, puantaj ve günlük raporlar yalnızca cihazınızda saklanır.';
}
