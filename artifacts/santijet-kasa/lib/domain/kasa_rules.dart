import 'kasa_hareket.dart';

/// Gelir / gider karşılıklı dışlama ve tutar kuralları.
class KasaValidationError implements Exception {
  KasaValidationError(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Validasyon sonucu — null ise geçerli.
String? validateHareket({
  required String aciklama,
  double? gelir,
  double? gider,
}) {
  final hasGelir = gelir != null && gelir > 0;
  final hasGider = gider != null && gider > 0;

  if (aciklama.trim().isEmpty) {
    return 'Açıklama gerekli.';
  }
  if (!hasGelir && !hasGider) {
    return 'Gelir veya gider girin.';
  }
  if (hasGelir && hasGider) {
    return 'Bir satırda hem gelir hem gider olamaz.';
  }
  return null;
}

void assertValidHareket(KasaHareket hareket) {
  final err = validateHareket(
    aciklama: hareket.aciklama,
    gelir: hareket.gelir,
    gider: hareket.gider,
  );
  if (err != null) throw KasaValidationError(err);
}

/// Kasa özeti — Excel üst satırı.
class KasaOzet {
  const KasaOzet({
    required this.toplamGelir,
    required this.toplamGider,
  });

  final double toplamGelir;
  final double toplamGider;

  /// Güncel kasa = gelir − gider (negatif olabilir).
  double get guncelKasa => toplamGelir - toplamGider;

  bool get isNegatif => guncelKasa < 0;
}

KasaOzet hesaplaOzet(Iterable<KasaHareket> hareketler) {
  var gelir = 0.0;
  var gider = 0.0;
  for (final h in hareketler) {
    if (h.gelir != null) gelir += h.gelir!;
    if (h.gider != null) gider += h.gider!;
  }
  return KasaOzet(toplamGelir: gelir, toplamGider: gider);
}
