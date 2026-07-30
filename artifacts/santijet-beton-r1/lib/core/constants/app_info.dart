/// Uygulama kimlik ve sabit metinleri — BETON R1 (mevcut BETON'dan ayrı).
abstract final class AppInfo {
  static const String displayName = 'ŞantiJET BETON R1';
  static const String legalName = 'ŞantiJET BETON R1';
  static const String productLabel = 'BETON R1';
  static const String tagline =
      'Döküm planı, sipariş ve kalite — şantiye beton yönetimi (R1).';
  static const String supportEmail = 'destek@santijet.com';
  static const String version = '0.1.0';

  static const String localDataNote =
      'Projeler, döküm planı, günlük döküm, sipariş ve kalite kayıtları '
      'yalnızca cihazınızda saklanır. Mevcut BETON uygulamasından bağımsızdır.';

  static const concreteClasses = <String>[
    'C16/20',
    'C20/25',
    'C25/30',
    'C30/37',
    'C35/45',
    'C40/50',
  ];
}
