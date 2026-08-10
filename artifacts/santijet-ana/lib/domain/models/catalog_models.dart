import 'package:equatable/equatable.dart';

/// RN ConstructionMaterial / UnitOption / ImalatPoz / PozAnaliz.

class ConstructionMaterial extends Equatable {
  const ConstructionMaterial({
    required this.category,
    required this.name,
    this.defaultUnit,
  });

  final String category;
  final String name;
  final String? defaultUnit;

  Map<String, dynamic> toJson() => {
        'category': category,
        'name': name,
        if (defaultUnit != null) 'defaultUnit': defaultUnit,
      };

  factory ConstructionMaterial.fromJson(Map<String, dynamic> json) {
    return ConstructionMaterial(
      category: json['category']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      defaultUnit: json['defaultUnit']?.toString(),
    );
  }

  @override
  List<Object?> get props => [category, name, defaultUnit];
}

class UnitOption extends Equatable {
  const UnitOption({required this.code, required this.label});

  final String code;
  final String label;

  Map<String, dynamic> toJson() => {'code': code, 'label': label};

  factory UnitOption.fromJson(Map<String, dynamic> json) {
    return UnitOption(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [code, label];
}

class ImalatPoz extends Equatable {
  const ImalatPoz({
    required this.code,
    required this.category,
    required this.name,
    required this.unit,
    this.description,
  });

  final String code;
  final String category;
  final String name;
  final String unit;
  final String? description;

  ImalatPoz copyWith({
    String? code,
    String? category,
    String? name,
    String? unit,
    String? description,
  }) {
    return ImalatPoz(
      code: code ?? this.code,
      category: category ?? this.category,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'category': category,
        'name': name,
        'unit': unit,
        if (description != null) 'description': description,
      };

  factory ImalatPoz.fromJson(Map<String, dynamic> json) {
    return ImalatPoz(
      code: json['code']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  @override
  List<Object?> get props => [code, category, name, unit, description];
}

class AnalizKalemi extends Equatable {
  const AnalizKalemi({
    required this.id,
    required this.ad,
    required this.birim,
    required this.miktar,
    required this.birimFiyat,
    required this.tutar,
  });

  final String id;
  final String ad;
  final String birim;
  final double miktar;
  final double birimFiyat;
  final double tutar;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        'birim': birim,
        'miktar': miktar,
        'birimFiyat': birimFiyat,
        'tutar': tutar,
      };

  factory AnalizKalemi.fromJson(Map<String, dynamic> json) {
    return AnalizKalemi(
      id: json['id']?.toString() ?? '',
      ad: json['ad']?.toString() ?? '',
      birim: json['birim']?.toString() ?? '',
      miktar: (json['miktar'] as num?)?.toDouble() ?? 0,
      birimFiyat: (json['birimFiyat'] as num?)?.toDouble() ?? 0,
      tutar: (json['tutar'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, ad, birim, miktar, birimFiyat, tutar];
}

class PozAnaliz extends Equatable {
  const PozAnaliz({
    required this.id,
    required this.pozNo,
    required this.analizAdi,
    required this.olcuBirimi,
    required this.kategori,
    required this.kalemler,
    required this.pozTarifi,
    required this.yapimSartlari,
    required this.olcusu,
    required this.malzemeIscilikToplami,
    required this.yukleniciKarOrani,
    required this.yukleniciKarTutari,
    required this.birimFiyati,
    required this.olusturmaTarihi,
    required this.guncellemeTarihi,
    required this.kaynakTip,
    this.notlar,
  });

  final String id;
  final String pozNo;
  final String analizAdi;
  final String olcuBirimi;
  final String kategori;
  final List<AnalizKalemi> kalemler;
  final String pozTarifi;
  final String yapimSartlari;
  final String olcusu;
  final double malzemeIscilikToplami;
  final double yukleniciKarOrani;
  final double yukleniciKarTutari;
  final double birimFiyati;
  final String olusturmaTarihi;
  final String guncellemeTarihi;
  final String kaynakTip; // sistem | kullanici | kopya
  final String? notlar;

  PozAnaliz copyWith({
    String? id,
    String? pozNo,
    String? analizAdi,
    String? olcuBirimi,
    String? kategori,
    List<AnalizKalemi>? kalemler,
    String? pozTarifi,
    String? yapimSartlari,
    String? olcusu,
    double? malzemeIscilikToplami,
    double? yukleniciKarOrani,
    double? yukleniciKarTutari,
    double? birimFiyati,
    String? olusturmaTarihi,
    String? guncellemeTarihi,
    String? kaynakTip,
    String? notlar,
  }) {
    return PozAnaliz(
      id: id ?? this.id,
      pozNo: pozNo ?? this.pozNo,
      analizAdi: analizAdi ?? this.analizAdi,
      olcuBirimi: olcuBirimi ?? this.olcuBirimi,
      kategori: kategori ?? this.kategori,
      kalemler: kalemler ?? this.kalemler,
      pozTarifi: pozTarifi ?? this.pozTarifi,
      yapimSartlari: yapimSartlari ?? this.yapimSartlari,
      olcusu: olcusu ?? this.olcusu,
      malzemeIscilikToplami:
          malzemeIscilikToplami ?? this.malzemeIscilikToplami,
      yukleniciKarOrani: yukleniciKarOrani ?? this.yukleniciKarOrani,
      yukleniciKarTutari: yukleniciKarTutari ?? this.yukleniciKarTutari,
      birimFiyati: birimFiyati ?? this.birimFiyati,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
      guncellemeTarihi: guncellemeTarihi ?? this.guncellemeTarihi,
      kaynakTip: kaynakTip ?? this.kaynakTip,
      notlar: notlar ?? this.notlar,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pozNo': pozNo,
        'analizAdi': analizAdi,
        'olcuBirimi': olcuBirimi,
        'kategori': kategori,
        'kalemler': kalemler.map((e) => e.toJson()).toList(),
        'pozTarifi': pozTarifi,
        'yapimSartlari': yapimSartlari,
        'olcusu': olcusu,
        'malzemeIscilikToplami': malzemeIscilikToplami,
        'yukleniciKarOrani': yukleniciKarOrani,
        'yukleniciKarTutari': yukleniciKarTutari,
        'birimFiyati': birimFiyati,
        'olusturmaTarihi': olusturmaTarihi,
        'guncellemeTarihi': guncellemeTarihi,
        'kaynakTip': kaynakTip,
        if (notlar != null) 'notlar': notlar,
      };

  factory PozAnaliz.fromJson(Map<String, dynamic> json) {
    final raw = json['kalemler'];
    return PozAnaliz(
      id: json['id']?.toString() ?? '',
      pozNo: json['pozNo']?.toString() ?? '',
      analizAdi: json['analizAdi']?.toString() ?? '',
      olcuBirimi: json['olcuBirimi']?.toString() ?? '',
      kategori: json['kategori']?.toString() ?? '',
      kalemler: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => AnalizKalemi.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      pozTarifi: json['pozTarifi']?.toString() ?? '',
      yapimSartlari: json['yapimSartlari']?.toString() ?? '',
      olcusu: json['olcusu']?.toString() ?? '',
      malzemeIscilikToplami:
          (json['malzemeIscilikToplami'] as num?)?.toDouble() ?? 0,
      yukleniciKarOrani: (json['yukleniciKarOrani'] as num?)?.toDouble() ?? 0,
      yukleniciKarTutari: (json['yukleniciKarTutari'] as num?)?.toDouble() ?? 0,
      birimFiyati: (json['birimFiyati'] as num?)?.toDouble() ?? 0,
      olusturmaTarihi: json['olusturmaTarihi']?.toString() ?? '',
      guncellemeTarihi: json['guncellemeTarihi']?.toString() ?? '',
      kaynakTip: json['kaynakTip']?.toString() ?? 'kullanici',
      notlar: json['notlar']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        pozNo,
        analizAdi,
        olcuBirimi,
        kategori,
        kalemler,
        pozTarifi,
        yapimSartlari,
        olcusu,
        malzemeIscilikToplami,
        yukleniciKarOrani,
        yukleniciKarTutari,
        birimFiyati,
        olusturmaTarihi,
        guncellemeTarihi,
        kaynakTip,
        notlar,
      ];
}

/// Varsayılan malzeme kategorileri / birimler (RN constants).
const List<String> defaultMaterialCategories = [
  'Beton ve Çimento',
  'Demir ve Çelik',
  'Agrega ve Dolgu',
  'Duvar ve Kagir',
  'Kalıp ve İskele',
  'Su Yalıtımı',
  'Isı Yalıtımı',
  'Alçı Panel ve Profil',
  'Sıva ve Şap',
  'Yapıştırıcı ve Derz',
  'Seramik ve Porselen',
  'Taş ve Mermer',
  'Zemin Kaplamaları',
  'Boya ve Vernik',
  'Doğrama ve Cam',
  'Çatı ve Saçak',
  'Sıhhi Tesisat',
  'Elektrik',
  'Hırdavat ve Bağlantı',
  'Diğer',
];

const List<UnitOption> defaultMaterialUnits = [
  UnitOption(code: 'MT', label: 'MT — Metre'),
  UnitOption(code: 'M²', label: 'M² — Metrekare'),
  UnitOption(code: 'M³', label: 'M³ — Metreküp'),
  UnitOption(code: 'KG', label: 'KG — Kilogram'),
  UnitOption(code: 'TON', label: 'TON — Ton'),
  UnitOption(code: 'ADET', label: 'ADET'),
  UnitOption(code: 'TORBA', label: 'TORBA'),
  UnitOption(code: 'PAKET', label: 'PAKET'),
  UnitOption(code: 'TOP', label: 'TOP'),
  UnitOption(code: 'BOY', label: 'BOY'),
  UnitOption(code: 'RULO', label: 'RULO'),
  UnitOption(code: 'LT', label: 'LT — Litre'),
  UnitOption(code: 'ÇİFT', label: 'ÇİFT'),
  UnitOption(code: 'TAKIM', label: 'TAKIM'),
  UnitOption(code: 'KUTU', label: 'KUTU'),
  UnitOption(code: 'PALET', label: 'PALET'),
];
