import 'package:equatable/equatable.dart';

import '../../core/utils/id_gen.dart';
import '../calc/analiz_hesap.dart';
import '../enums/app_enums.dart';
import 'poz_analiz.dart';

/// Keşif satırındaki birim fiyatın kaynağı.
enum KesifFiyatKaynagi {
  analiz,
  katalog,
  manuel;

  String get label => switch (this) {
        KesifFiyatKaynagi.analiz => 'Analiz',
        KesifFiyatKaynagi.katalog => 'Katalog',
        KesifFiyatKaynagi.manuel => 'Manuel',
      };

  static KesifFiyatKaynagi fromJson(String? raw) => switch (raw) {
        'analiz' => KesifFiyatKaynagi.analiz,
        'manuel' => KesifFiyatKaynagi.manuel,
        _ => KesifFiyatKaynagi.katalog,
      };

  String get jsonValue => name;
}

/// Keşif satırı — React Native `KesifSatiri` arayüzünün karşılığı.
class KesifSatiri extends Equatable {
  const KesifSatiri({
    required this.id,
    required this.analizId,
    required this.pozNo,
    required this.analizAdi,
    required this.olcuBirimi,
    required this.birimFiyati,
    required this.miktar,
    required this.tutar,
    this.fiyatKaynagi = KesifFiyatKaynagi.katalog,
    this.metrajNotu = '',
  });

  final String id;
  final String analizId;
  final String pozNo;
  final String analizAdi;
  final String olcuBirimi;
  final double birimFiyati;
  final double miktar;
  final double tutar;
  final KesifFiyatKaynagi fiyatKaynagi;
  final String metrajNotu;

  KesifSatiri copyWith({
    String? id,
    String? analizId,
    String? pozNo,
    String? analizAdi,
    String? olcuBirimi,
    double? birimFiyati,
    double? miktar,
    double? tutar,
    KesifFiyatKaynagi? fiyatKaynagi,
    String? metrajNotu,
  }) {
    return KesifSatiri(
      id: id ?? this.id,
      analizId: analizId ?? this.analizId,
      pozNo: pozNo ?? this.pozNo,
      analizAdi: analizAdi ?? this.analizAdi,
      olcuBirimi: olcuBirimi ?? this.olcuBirimi,
      birimFiyati: birimFiyati ?? this.birimFiyati,
      miktar: miktar ?? this.miktar,
      tutar: tutar ?? this.tutar,
      fiyatKaynagi: fiyatKaynagi ?? this.fiyatKaynagi,
      metrajNotu: metrajNotu ?? this.metrajNotu,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'analizId': analizId,
        'pozNo': pozNo,
        'analizAdi': analizAdi,
        'olcuBirimi': olcuBirimi,
        'birimFiyati': birimFiyati,
        'miktar': miktar,
        'tutar': tutar,
        'fiyatKaynagi': fiyatKaynagi.jsonValue,
        'metrajNotu': metrajNotu,
      };

  factory KesifSatiri.fromJson(Map<dynamic, dynamic> json) {
    final miktar = (json['miktar'] as num?)?.toDouble() ?? 0;
    final birimFiyati = (json['birimFiyati'] as num?)?.toDouble() ?? 0;
    return KesifSatiri(
      id: json['id'] as String? ?? '',
      analizId: json['analizId'] as String? ?? '',
      pozNo: json['pozNo'] as String? ?? '',
      analizAdi: json['analizAdi'] as String? ?? '',
      olcuBirimi: json['olcuBirimi'] as String? ?? '',
      birimFiyati: birimFiyati,
      miktar: miktar,
      tutar: AnalizHesap.satirTutar(miktar, birimFiyati),
      fiyatKaynagi: KesifFiyatKaynagi.fromJson(json['fiyatKaynagi'] as String?),
      metrajNotu: json['metrajNotu'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        analizId,
        pozNo,
        analizAdi,
        olcuBirimi,
        birimFiyati,
        miktar,
        tutar,
        fiyatKaynagi,
        metrajNotu,
      ];
}

/// Keşif projesi — React Native `KesifProject` arayüzünün karşılığı.
///
/// Projelerim kartlarında `kod` / `konum` Demir-Beton ile aynı kurguda kullanılır.
class KesifProject extends Equatable {
  const KesifProject({
    required this.id,
    required this.ad,
    required this.aciklama,
    required this.satirlar,
    required this.olusturmaTarihi,
    required this.guncellemeTarihi,
    this.kod = '',
    this.konum = '',
  });

  final String id;
  final String ad;
  final String aciklama;
  final List<KesifSatiri> satirlar;
  final String olusturmaTarihi;
  final String guncellemeTarihi;
  final String kod;
  final String konum;

  double get toplam => satirlar.fold<double>(0, (sum, row) => sum + row.tutar);

  /// Yaklaşık maliyet — ölçü birimine göre kırılım.
  Map<String, double> get toplamByOlcuBirimi {
    final map = <String, double>{};
    for (final s in satirlar) {
      final key = s.olcuBirimi.trim().isEmpty ? 'Diğer' : s.olcuBirimi.trim();
      map[key] = (map[key] ?? 0) + s.tutar;
    }
    return map;
  }

  KesifProject copyWith({
    String? id,
    String? ad,
    String? aciklama,
    List<KesifSatiri>? satirlar,
    String? olusturmaTarihi,
    String? guncellemeTarihi,
    String? kod,
    String? konum,
  }) {
    return KesifProject(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      aciklama: aciklama ?? this.aciklama,
      satirlar: satirlar ?? this.satirlar,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
      guncellemeTarihi: guncellemeTarihi ?? this.guncellemeTarihi,
      kod: kod ?? this.kod,
      konum: konum ?? this.konum,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        'aciklama': aciklama,
        'satirlar': satirlar.map((s) => s.toJson()).toList(),
        'olusturmaTarihi': olusturmaTarihi,
        'guncellemeTarihi': guncellemeTarihi,
        'kod': kod,
        'konum': konum,
      };

  factory KesifProject.fromJson(Map<dynamic, dynamic> json) {
    final rawSatirlar = json['satirlar'];
    return KesifProject(
      id: json['id'] as String? ?? '',
      ad: (json['ad'] as String? ?? 'Keşif').trim(),
      aciklama: json['aciklama'] as String? ?? '',
      satirlar: rawSatirlar is List
          ? rawSatirlar
              .whereType<Map<dynamic, dynamic>>()
              .map(KesifSatiri.fromJson)
              .where((s) => s.id.isNotEmpty)
              .toList()
          : const [],
      olusturmaTarihi: json['olusturmaTarihi'] as String? ??
          DateTime.now().toIso8601String(),
      guncellemeTarihi: json['guncellemeTarihi'] as String? ??
          DateTime.now().toIso8601String(),
      kod: (json['kod'] as String? ?? '').trim().toUpperCase(),
      konum: (json['konum'] as String? ?? '').trim(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        ad,
        aciklama,
        satirlar,
        olusturmaTarihi,
        guncellemeTarihi,
        kod,
        konum,
      ];
}

KesifSatiri buildKesifSatiri(PozAnaliz analiz, double miktar) {
  final hesap = AnalizHesap.hesapla(analiz);
  final birimFiyati =
      hesap.birimFiyati > 0 ? hesap.birimFiyati : analiz.birimFiyati;
  final kaynak = analiz.kaynakTip == KaynakTip.sistem
      ? KesifFiyatKaynagi.katalog
      : KesifFiyatKaynagi.analiz;
  return KesifSatiri(
    id: IdGen.make('ks'),
    analizId: analiz.id,
    pozNo: analiz.pozNo,
    analizAdi: analiz.analizAdi,
    olcuBirimi: analiz.olcuBirimi,
    birimFiyati: birimFiyati,
    miktar: miktar.isFinite ? miktar : 0,
    tutar: AnalizHesap.satirTutar(miktar, birimFiyati),
    fiyatKaynagi: kaynak,
  );
}
