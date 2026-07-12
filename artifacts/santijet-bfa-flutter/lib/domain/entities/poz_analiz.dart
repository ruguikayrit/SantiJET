import 'package:equatable/equatable.dart';

import '../enums/app_enums.dart';
import 'analiz_kalemi.dart';

/// Birim fiyat analizi kaydı.
///
/// React Native `PozAnaliz` arayüzünün birebir karşılığı. Demir konvansiyonuyla
/// elle yazılmış değişmez sınıf (equatable + copyWith + JSON).
class PozAnaliz extends Equatable {
  const PozAnaliz({
    required this.id,
    required this.pozNo,
    required this.analizAdi,
    required this.olcuBirimi,
    required this.kategori,
    this.kalemler = const [],
    this.pozTarifi = '',
    this.yapimSartlari = '',
    this.olcusu = '',
    this.malzemeIscilikToplami = 0,
    this.yukleniciKarOrani = 0,
    this.yukleniciKarTutari = 0,
    this.birimFiyati = 0,
    this.olusturmaTarihi = '',
    this.guncellemeTarihi = '',
    this.kaynakTip = KaynakTip.sistem,
    this.discipline,
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
  final KaynakTip kaynakTip;
  final AnalizDiscipline? discipline;
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
    KaynakTip? kaynakTip,
    AnalizDiscipline? discipline,
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
      discipline: discipline ?? this.discipline,
      notlar: notlar ?? this.notlar,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pozNo': pozNo,
        'analizAdi': analizAdi,
        'olcuBirimi': olcuBirimi,
        'kategori': kategori,
        'kalemler': kalemler.map((k) => k.toJson()).toList(),
        'pozTarifi': pozTarifi,
        'yapimSartlari': yapimSartlari,
        'olcusu': olcusu,
        'malzemeIscilikToplami': malzemeIscilikToplami,
        'yukleniciKarOrani': yukleniciKarOrani,
        'yukleniciKarTutari': yukleniciKarTutari,
        'birimFiyati': birimFiyati,
        'olusturmaTarihi': olusturmaTarihi,
        'guncellemeTarihi': guncellemeTarihi,
        'kaynakTip': kaynakTip.jsonValue,
        'discipline': discipline?.jsonValue,
        'notlar': notlar,
      };

  factory PozAnaliz.fromJson(Map<dynamic, dynamic> json) {
    final rawKalemler = json['kalemler'];
    return PozAnaliz(
      id: json['id'] as String? ?? '',
      pozNo: json['pozNo'] as String? ?? '',
      analizAdi: json['analizAdi'] as String? ?? '',
      olcuBirimi: json['olcuBirimi'] as String? ?? '',
      kategori: json['kategori'] as String? ?? '',
      kalemler: rawKalemler is List
          ? rawKalemler
              .whereType<Map<dynamic, dynamic>>()
              .map(AnalizKalemi.fromJson)
              .toList()
          : const [],
      pozTarifi: json['pozTarifi'] as String? ?? '',
      yapimSartlari: json['yapimSartlari'] as String? ?? '',
      olcusu: json['olcusu'] as String? ?? '',
      malzemeIscilikToplami:
          (json['malzemeIscilikToplami'] as num?)?.toDouble() ?? 0,
      yukleniciKarOrani: (json['yukleniciKarOrani'] as num?)?.toDouble() ?? 0,
      yukleniciKarTutari: (json['yukleniciKarTutari'] as num?)?.toDouble() ?? 0,
      birimFiyati: (json['birimFiyati'] as num?)?.toDouble() ?? 0,
      olusturmaTarihi: json['olusturmaTarihi'] as String? ?? '',
      guncellemeTarihi: json['guncellemeTarihi'] as String? ?? '',
      kaynakTip: KaynakTip.fromJson(json['kaynakTip'] as String?),
      discipline: json['discipline'] != null
          ? AnalizDiscipline.fromJson(json['discipline'] as String?)
          : null,
      notlar: json['notlar'] as String?,
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
        discipline,
        notlar,
      ];
}
