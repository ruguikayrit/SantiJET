import '../../core/utils/id_gen.dart';

/// Metraj cetveli hesap tipi.
enum MetrajHesapTipi {
  manuel,
  enBoy,
  enBoyYukseklik,
  alan,
  cevre;

  String get label => switch (this) {
        MetrajHesapTipi.manuel => 'Manuel',
        MetrajHesapTipi.enBoy => 'En × Boy',
        MetrajHesapTipi.enBoyYukseklik => 'En × Boy × Yükseklik',
        MetrajHesapTipi.alan => 'Alan',
        MetrajHesapTipi.cevre => 'Çevre',
      };

  String get jsonValue => name;

  static MetrajHesapTipi fromJson(String? raw) => switch (raw) {
        'enBoy' => MetrajHesapTipi.enBoy,
        'enBoyYukseklik' => MetrajHesapTipi.enBoyYukseklik,
        'alan' => MetrajHesapTipi.alan,
        'cevre' => MetrajHesapTipi.cevre,
        _ => MetrajHesapTipi.manuel,
      };
}

/// Tek metraj cetveli satırı — boyut girdilerinden miktar üretir.
class MetrajKalemi {
  const MetrajKalemi({
    required this.id,
    required this.aciklama,
    required this.tip,
    this.en = 0,
    this.boy = 0,
    this.yukseklik = 0,
    this.alan = 0,
    this.cevre = 0,
    this.adet = 1,
    this.miktar = 0,
  });

  final String id;
  final String aciklama;
  final MetrajHesapTipi tip;
  final double en;
  final double boy;
  final double yukseklik;
  final double alan;
  final double cevre;
  final double adet;
  final double miktar;

  static double hesapla({
    required MetrajHesapTipi tip,
    double en = 0,
    double boy = 0,
    double yukseklik = 0,
    double alan = 0,
    double cevre = 0,
    double adet = 1,
    double manuelMiktar = 0,
  }) {
    final a = adet.isFinite && adet > 0 ? adet : 1.0;
    final raw = switch (tip) {
      MetrajHesapTipi.manuel => manuelMiktar,
      MetrajHesapTipi.enBoy => en * boy * a,
      MetrajHesapTipi.enBoyYukseklik => en * boy * yukseklik * a,
      MetrajHesapTipi.alan => alan * a,
      MetrajHesapTipi.cevre => cevre * a,
    };
    return raw.isFinite ? raw : 0;
  }

  MetrajKalemi withHesap({double? manuelMiktar}) {
    final m = hesapla(
      tip: tip,
      en: en,
      boy: boy,
      yukseklik: yukseklik,
      alan: alan,
      cevre: cevre,
      adet: adet,
      manuelMiktar: manuelMiktar ?? miktar,
    );
    return copyWith(miktar: m);
  }

  MetrajKalemi copyWith({
    String? id,
    String? aciklama,
    MetrajHesapTipi? tip,
    double? en,
    double? boy,
    double? yukseklik,
    double? alan,
    double? cevre,
    double? adet,
    double? miktar,
  }) {
    return MetrajKalemi(
      id: id ?? this.id,
      aciklama: aciklama ?? this.aciklama,
      tip: tip ?? this.tip,
      en: en ?? this.en,
      boy: boy ?? this.boy,
      yukseklik: yukseklik ?? this.yukseklik,
      alan: alan ?? this.alan,
      cevre: cevre ?? this.cevre,
      adet: adet ?? this.adet,
      miktar: miktar ?? this.miktar,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'aciklama': aciklama,
        'tip': tip.jsonValue,
        'en': en,
        'boy': boy,
        'yukseklik': yukseklik,
        'alan': alan,
        'cevre': cevre,
        'adet': adet,
        'miktar': miktar,
      };

  factory MetrajKalemi.fromJson(Map<dynamic, dynamic> json) {
    final tip = MetrajHesapTipi.fromJson(json['tip'] as String?);
    final en = (json['en'] as num?)?.toDouble() ?? 0;
    final boy = (json['boy'] as num?)?.toDouble() ?? 0;
    final yukseklik = (json['yukseklik'] as num?)?.toDouble() ?? 0;
    final alan = (json['alan'] as num?)?.toDouble() ?? 0;
    final cevre = (json['cevre'] as num?)?.toDouble() ?? 0;
    final adet = (json['adet'] as num?)?.toDouble() ?? 1;
    final stored = (json['miktar'] as num?)?.toDouble() ?? 0;
    final miktar = MetrajKalemi.hesapla(
      tip: tip,
      en: en,
      boy: boy,
      yukseklik: yukseklik,
      alan: alan,
      cevre: cevre,
      adet: adet,
      manuelMiktar: stored,
    );
    return MetrajKalemi(
      id: json['id'] as String? ?? IdGen.make('mk'),
      aciklama: json['aciklama'] as String? ?? '',
      tip: tip,
      en: en,
      boy: boy,
      yukseklik: yukseklik,
      alan: alan,
      cevre: cevre,
      adet: adet,
      miktar: miktar,
    );
  }
}
