/// Uygulama kimlik ve sabit metinleri.
///
/// React Native `constants/appInfo.ts` dosyasından taşınan çekirdek etiketler.
/// Hukuki metinler (Gizlilik/Koşullar) Faz 13'te eklenecektir.
abstract final class AppInfo {
  static const String displayName = 'ŞantiJET Birim Fiyat Analizleri';
  static const String legalName = 'ŞantiJET BFA';
  static const String dataSourceLabel = 'ÇŞB YFK 2026';
  static const String dataUpdateLabel = 'Ocak 2026';
  static const String supportEmail = 'destek@santijet.com';
  static const String version = '1.0.0';

  static const String localDataNote =
      'Özel analizler, favoriler ve keşif projeleri yalnızca cihazınızda saklanır.';
}
