/// Tek kasa hareketi — Excel satırı ile birebir alanlar.
class KasaHareket {
  const KasaHareket({
    required this.id,
    required this.tarih,
    required this.aciklama,
    this.tedarikci = '',
    this.gelir,
    this.gider,
    this.odemeSekli = '',
    this.belgeTuru = '',
    this.santiye = '',
    this.ekAciklama = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime tarih;
  final String tedarikci;
  final String aciklama;
  final double? gelir;
  final double? gider;
  final String odemeSekli;
  final String belgeTuru;
  final String santiye;
  final String ekAciklama;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isGelir => gelir != null && gelir! > 0;
  bool get isGider => gider != null && gider! > 0;

  double get tutar => isGelir ? gelir! : (isGider ? gider! : 0);

  KasaHareket copyWith({
    String? id,
    DateTime? tarih,
    String? tedarikci,
    String? aciklama,
    double? gelir,
    double? gider,
    bool clearGelir = false,
    bool clearGider = false,
    String? odemeSekli,
    String? belgeTuru,
    String? santiye,
    String? ekAciklama,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KasaHareket(
      id: id ?? this.id,
      tarih: tarih ?? this.tarih,
      tedarikci: tedarikci ?? this.tedarikci,
      aciklama: aciklama ?? this.aciklama,
      gelir: clearGelir ? null : (gelir ?? this.gelir),
      gider: clearGider ? null : (gider ?? this.gider),
      odemeSekli: odemeSekli ?? this.odemeSekli,
      belgeTuru: belgeTuru ?? this.belgeTuru,
      santiye: santiye ?? this.santiye,
      ekAciklama: ekAciklama ?? this.ekAciklama,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tarih': tarih.toIso8601String(),
        'tedarikci': tedarikci,
        'aciklama': aciklama,
        'gelir': gelir,
        'gider': gider,
        'odemeSekli': odemeSekli,
        'belgeTuru': belgeTuru,
        'santiye': santiye,
        'ekAciklama': ekAciklama,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory KasaHareket.fromJson(Map raw) {
    double? asDouble(Object? v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return KasaHareket(
      id: raw['id']?.toString() ?? '',
      tarih: DateTime.tryParse(raw['tarih']?.toString() ?? '') ??
          DateTime.now(),
      tedarikci: raw['tedarikci']?.toString() ?? '',
      aciklama: raw['aciklama']?.toString() ?? '',
      gelir: asDouble(raw['gelir']),
      gider: asDouble(raw['gider']),
      odemeSekli: raw['odemeSekli']?.toString() ?? '',
      belgeTuru: raw['belgeTuru']?.toString() ?? '',
      santiye: raw['santiye']?.toString() ?? '',
      ekAciklama: raw['ekAciklama']?.toString() ?? '',
      createdAt: DateTime.tryParse(raw['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(raw['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
