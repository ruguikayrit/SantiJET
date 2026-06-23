// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poz_analiz.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnalizKalemi _$AnalizKalemiFromJson(Map<String, dynamic> json) =>
    _AnalizKalemi(
      id: json['id'] as String,
      tip: $enumDecode(_$AnalizKalemTipEnumMap, json['tip']),
      pozNo: json['pozNo'] as String,
      tanim: json['tanim'] as String,
      olcuBirimi: json['olcuBirimi'] as String,
      miktar: (json['miktar'] as num).toDouble(),
      birimFiyati: (json['birimFiyati'] as num).toDouble(),
      tutar: (json['tutar'] as num).toDouble(),
    );

Map<String, dynamic> _$AnalizKalemiToJson(_AnalizKalemi instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tip': _$AnalizKalemTipEnumMap[instance.tip]!,
      'pozNo': instance.pozNo,
      'tanim': instance.tanim,
      'olcuBirimi': instance.olcuBirimi,
      'miktar': instance.miktar,
      'birimFiyati': instance.birimFiyati,
      'tutar': instance.tutar,
    };

const _$AnalizKalemTipEnumMap = {
  AnalizKalemTip.malzeme: 'malzeme',
  AnalizKalemTip.iscilik: 'iscilik',
  AnalizKalemTip.ekipman: 'ekipman',
};

_PozAnaliz _$PozAnalizFromJson(Map<String, dynamic> json) => _PozAnaliz(
  id: json['id'] as String,
  pozNo: json['pozNo'] as String,
  analizAdi: json['analizAdi'] as String,
  olcuBirimi: json['olcuBirimi'] as String,
  kategori: json['kategori'] as String,
  kalemler:
      (json['kalemler'] as List<dynamic>?)
          ?.map((e) => AnalizKalemi.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AnalizKalemi>[],
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
  kaynakTip:
      $enumDecodeNullable(_$KaynakTipEnumMap, json['kaynakTip']) ??
      KaynakTip.sistem,
  discipline: $enumDecodeNullable(
    _$AnalizDisciplineEnumMap,
    json['discipline'],
  ),
  notlar: json['notlar'] as String?,
);

Map<String, dynamic> _$PozAnalizToJson(_PozAnaliz instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pozNo': instance.pozNo,
      'analizAdi': instance.analizAdi,
      'olcuBirimi': instance.olcuBirimi,
      'kategori': instance.kategori,
      'kalemler': instance.kalemler,
      'pozTarifi': instance.pozTarifi,
      'yapimSartlari': instance.yapimSartlari,
      'olcusu': instance.olcusu,
      'malzemeIscilikToplami': instance.malzemeIscilikToplami,
      'yukleniciKarOrani': instance.yukleniciKarOrani,
      'yukleniciKarTutari': instance.yukleniciKarTutari,
      'birimFiyati': instance.birimFiyati,
      'olusturmaTarihi': instance.olusturmaTarihi,
      'guncellemeTarihi': instance.guncellemeTarihi,
      'kaynakTip': _$KaynakTipEnumMap[instance.kaynakTip]!,
      'discipline': _$AnalizDisciplineEnumMap[instance.discipline],
      'notlar': instance.notlar,
    };

const _$KaynakTipEnumMap = {
  KaynakTip.sistem: 'sistem',
  KaynakTip.kullanici: 'kullanici',
  KaynakTip.kopya: 'kopya',
};

const _$AnalizDisciplineEnumMap = {
  AnalizDiscipline.insaat: 'insaat',
  AnalizDiscipline.mekanik: 'mekanik',
  AnalizDiscipline.elektrik: 'elektrik',
};
