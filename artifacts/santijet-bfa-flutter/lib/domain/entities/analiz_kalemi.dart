import 'package:equatable/equatable.dart';

import '../enums/app_enums.dart';

/// Bir analize ait tek bir malzeme/işçilik/ekipman kalemi.
///
/// React Native `AnalizKalemi` arayüzünün birebir karşılığı. Demir
/// konvansiyonuyla elle yazılmış değişmez sınıf (equatable + copyWith + JSON).
class AnalizKalemi extends Equatable {
  const AnalizKalemi({
    required this.id,
    required this.tip,
    required this.pozNo,
    required this.tanim,
    required this.olcuBirimi,
    required this.miktar,
    required this.birimFiyati,
    required this.tutar,
  });

  final String id;
  final AnalizKalemTip tip;
  final String pozNo;
  final String tanim;
  final String olcuBirimi;
  final double miktar;
  final double birimFiyati;
  final double tutar;

  AnalizKalemi copyWith({
    String? id,
    AnalizKalemTip? tip,
    String? pozNo,
    String? tanim,
    String? olcuBirimi,
    double? miktar,
    double? birimFiyati,
    double? tutar,
  }) {
    return AnalizKalemi(
      id: id ?? this.id,
      tip: tip ?? this.tip,
      pozNo: pozNo ?? this.pozNo,
      tanim: tanim ?? this.tanim,
      olcuBirimi: olcuBirimi ?? this.olcuBirimi,
      miktar: miktar ?? this.miktar,
      birimFiyati: birimFiyati ?? this.birimFiyati,
      tutar: tutar ?? this.tutar,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tip': tip.jsonValue,
        'pozNo': pozNo,
        'tanim': tanim,
        'olcuBirimi': olcuBirimi,
        'miktar': miktar,
        'birimFiyati': birimFiyati,
        'tutar': tutar,
      };

  factory AnalizKalemi.fromJson(Map<dynamic, dynamic> json) {
    return AnalizKalemi(
      id: json['id'] as String? ?? '',
      tip: AnalizKalemTip.fromJson(json['tip'] as String?),
      pozNo: json['pozNo'] as String? ?? '',
      tanim: json['tanim'] as String? ?? '',
      olcuBirimi: json['olcuBirimi'] as String? ?? '',
      miktar: (json['miktar'] as num?)?.toDouble() ?? 0,
      birimFiyati: (json['birimFiyati'] as num?)?.toDouble() ?? 0,
      tutar: (json['tutar'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [id, tip, pozNo, tanim, olcuBirimi, miktar, birimFiyati, tutar];
}
