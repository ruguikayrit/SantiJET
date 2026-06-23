import 'package:freezed_annotation/freezed_annotation.dart';

part 'poz_analiz.freezed.dart';
part 'poz_analiz.g.dart';

/// Kaydın kaynağı. React Native `PozAnaliz.kaynakTip` ile birebir.
enum KaynakTip { sistem, kullanici, kopya }

/// Analiz disiplini. React Native `discipline` ile birebir.
enum AnalizDiscipline { insaat, mekanik, elektrik }

/// Analiz kalemi tipi.
enum AnalizKalemTip { malzeme, iscilik, ekipman }

/// Bir analize ait tek bir malzeme/işçilik/ekipman kalemi.
/// React Native `AnalizKalemi` arayüzünün birebir karşılığıdır.
@freezed
abstract class AnalizKalemi with _$AnalizKalemi {
  const factory AnalizKalemi({
    required String id,
    required AnalizKalemTip tip,
    required String pozNo,
    required String tanim,
    required String olcuBirimi,
    required double miktar,
    required double birimFiyati,
    required double tutar,
  }) = _AnalizKalemi;

  factory AnalizKalemi.fromJson(Map<String, dynamic> json) =>
      _$AnalizKalemiFromJson(json);
}

/// Birim fiyat analizi kaydı.
/// React Native `PozAnaliz` arayüzünün birebir karşılığıdır.
@freezed
abstract class PozAnaliz with _$PozAnaliz {
  const factory PozAnaliz({
    required String id,
    required String pozNo,
    required String analizAdi,
    required String olcuBirimi,
    required String kategori,
    @Default(<AnalizKalemi>[]) List<AnalizKalemi> kalemler,
    @Default('') String pozTarifi,
    @Default('') String yapimSartlari,
    @Default('') String olcusu,
    @Default(0) double malzemeIscilikToplami,
    @Default(0) double yukleniciKarOrani,
    @Default(0) double yukleniciKarTutari,
    @Default(0) double birimFiyati,
    @Default('') String olusturmaTarihi,
    @Default('') String guncellemeTarihi,
    @Default(KaynakTip.sistem) KaynakTip kaynakTip,
    AnalizDiscipline? discipline,
    String? notlar,
  }) = _PozAnaliz;

  factory PozAnaliz.fromJson(Map<String, dynamic> json) =>
      _$PozAnalizFromJson(json);
}
