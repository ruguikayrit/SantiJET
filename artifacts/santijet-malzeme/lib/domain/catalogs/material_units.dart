/// Malzeme birimleri — ŞantiJET Pro RN `MATERIAL_UNITS` ile hizalı.
abstract final class MaterialUnits {
  static const List<String> codes = [
    'MT',
    'M²',
    'M³',
    'KG',
    'TON',
    'ADET',
    'TORBA',
    'PAKET',
    'TOP',
    'BOY',
    'RULO',
    'LT',
    'ÇİFT',
    'TAKIM',
    'KUTU',
    'PALET',
  ];

  static const Map<String, String> labels = {
    'MT': 'MT — Metre',
    'M²': 'M² — Metrekare',
    'M³': 'M³ — Metreküp',
    'KG': 'KG — Kilogram',
    'TON': 'TON — Ton',
    'ADET': 'ADET',
    'TORBA': 'TORBA',
    'PAKET': 'PAKET',
    'TOP': 'TOP',
    'BOY': 'BOY',
    'RULO': 'RULO',
    'LT': 'LT — Litre',
    'ÇİFT': 'ÇİFT',
    'TAKIM': 'TAKIM',
    'KUTU': 'KUTU',
    'PALET': 'PALET',
  };

  static String labelOf(String code) => labels[code] ?? code;

  /// Eski seed / serbest metin → katalog kodu.
  static String normalize(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return 'ADET';
    final upper = t.toUpperCase();
    if (codes.contains(upper)) return upper;
    if (codes.contains(t)) return t;
    switch (upper) {
      case 'M':
      case 'METRE':
        return 'MT';
      case 'M2':
      case 'M²':
      case 'MÂ²':
        return 'M²';
      case 'M3':
      case 'M³':
        return 'M³';
      case 'KG':
      case 'KILOGRAM':
        return 'KG';
      case 'LT':
      case 'L':
      case 'LITRE':
      case 'LİTRE':
        return 'LT';
      case 'AD':
      case 'ADET':
      case 'PCS':
        return 'ADET';
      case 'TON':
      case 'TN':
        return 'TON';
      default:
        return t;
    }
  }

  /// Dropdown için geçerli değer: katalogda yoksa null (ilk öğe seçilir).
  static String? dropdownValue(String? raw) {
    final n = normalize(raw);
    return codes.contains(n) ? n : null;
  }
}
