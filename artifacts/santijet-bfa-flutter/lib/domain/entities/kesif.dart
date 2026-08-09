import 'package:equatable/equatable.dart';

import '../../core/utils/id_gen.dart';
import '../calc/analiz_hesap.dart';
import '../enums/app_enums.dart';
import 'metraj_kalemi.dart';
import 'poz_analiz.dart';

export 'metraj_kalemi.dart';

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

/// Keşif satırı — poz + metraj cetveli kalemleri + fiyat.
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
    this.discipline = AnalizDiscipline.insaat,
    this.metrajKalemleri = const [],
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
  final AnalizDiscipline discipline;
  final List<MetrajKalemi> metrajKalemleri;

  /// Cetvel kalemleri varsa toplamları; yoksa elle girilen miktar.
  double get hesaplananMetraj {
    if (metrajKalemleri.isEmpty) return miktar;
    return metrajKalemleri.fold<double>(0, (s, k) => s + k.miktar);
  }

  KesifSatiri withMetrajRollup() {
    final m = hesaplananMetraj;
    return copyWith(
      miktar: m,
      tutar: AnalizHesap.satirTutar(m, birimFiyati),
    );
  }

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
    AnalizDiscipline? discipline,
    List<MetrajKalemi>? metrajKalemleri,
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
      discipline: discipline ?? this.discipline,
      metrajKalemleri: metrajKalemleri ?? this.metrajKalemleri,
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
        'discipline': discipline.jsonValue,
        'metrajKalemleri': metrajKalemleri.map((k) => k.toJson()).toList(),
      };

  factory KesifSatiri.fromJson(Map<dynamic, dynamic> json) {
    final miktar = (json['miktar'] as num?)?.toDouble() ?? 0;
    final birimFiyati = (json['birimFiyati'] as num?)?.toDouble() ?? 0;
    final pozNo = json['pozNo'] as String? ?? '';
    final rawKalem = json['metrajKalemleri'];
    final kalemler = rawKalem is List
        ? rawKalem
            .whereType<Map<dynamic, dynamic>>()
            .map(MetrajKalemi.fromJson)
            .where((k) => k.id.isNotEmpty)
            .toList()
        : const <MetrajKalemi>[];
    final discipline = json['discipline'] != null
        ? AnalizDiscipline.fromJson(json['discipline'] as String?)
        : AnalizDiscipline.fromPozNo(pozNo);
    var row = KesifSatiri(
      id: json['id'] as String? ?? '',
      analizId: json['analizId'] as String? ?? '',
      pozNo: pozNo,
      analizAdi: json['analizAdi'] as String? ?? '',
      olcuBirimi: json['olcuBirimi'] as String? ?? '',
      birimFiyati: birimFiyati,
      miktar: miktar,
      tutar: AnalizHesap.satirTutar(miktar, birimFiyati),
      fiyatKaynagi: KesifFiyatKaynagi.fromJson(json['fiyatKaynagi'] as String?),
      metrajNotu: json['metrajNotu'] as String? ?? '',
      discipline: discipline,
      metrajKalemleri: kalemler,
    );
    if (kalemler.isNotEmpty) row = row.withMetrajRollup();
    return row;
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
        discipline,
        metrajKalemleri,
      ];
}

/// Keşif projesi — React Native `KesifProject` arayüzünün karşılığı.
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

  Map<String, double> get toplamByOlcuBirimi {
    final map = <String, double>{};
    for (final s in satirlar) {
      final key = s.olcuBirimi.trim().isEmpty ? 'Diğer' : s.olcuBirimi.trim();
      map[key] = (map[key] ?? 0) + s.tutar;
    }
    return map;
  }

  /// Disipline göre gruplanmış satırlar (boş disiplinler atlanır).
  Map<AnalizDiscipline, List<KesifSatiri>> get satirlarByDiscipline {
    final map = <AnalizDiscipline, List<KesifSatiri>>{
      for (final d in AnalizDiscipline.kesifSirasi) d: <KesifSatiri>[],
    };
    for (final s in satirlar) {
      map.putIfAbsent(s.discipline, () => <KesifSatiri>[]).add(s);
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
  final discipline =
      analiz.discipline ?? AnalizDiscipline.fromPozNo(analiz.pozNo);
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
    discipline: discipline,
  );
}
