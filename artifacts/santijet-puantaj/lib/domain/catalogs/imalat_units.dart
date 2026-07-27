/// İmalat birim seçenekleri — açılır listeden seçilir.
abstract final class ImalatUnitCatalog {
  static const List<String> units = [
    'adet',
    'ton',
    'kg',
    'm',
    'm²',
    'm³',
    'cm',
    'mm',
    'takım',
    'set',
    'lt',
    'saat',
    'gün',
  ];

  static const String defaultUnit = 'adet';
}
