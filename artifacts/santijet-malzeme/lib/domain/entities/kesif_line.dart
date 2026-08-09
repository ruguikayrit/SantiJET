import 'package:equatable/equatable.dart';

import '../enums/main_discipline.dart';

/// Hive typeId plan: 2
/// Keşif satırı — poz bazlı malzeme ihtiyacı kaynağı.
class KesifLine extends Equatable {
  const KesifLine({
    required this.id,
    required this.pozNo,
    required this.tanim,
    required this.birim,
    required this.miktar,
    required this.anaGrup,
    this.altGrup = '',
    this.materialHint = '',
  });

  final String id;
  final String pozNo;
  final String tanim;
  final String birim;
  final double miktar;
  final MainDiscipline anaGrup;
  final String altGrup;

  /// Opsiyonel malzeme önerisi / eşleme ipucu.
  final String materialHint;

  KesifLine copyWith({
    String? id,
    String? pozNo,
    String? tanim,
    String? birim,
    double? miktar,
    MainDiscipline? anaGrup,
    String? altGrup,
    String? materialHint,
  }) {
    return KesifLine(
      id: id ?? this.id,
      pozNo: pozNo ?? this.pozNo,
      tanim: tanim ?? this.tanim,
      birim: birim ?? this.birim,
      miktar: miktar ?? this.miktar,
      anaGrup: anaGrup ?? this.anaGrup,
      altGrup: altGrup ?? this.altGrup,
      materialHint: materialHint ?? this.materialHint,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pozNo': pozNo,
        'tanim': tanim,
        'birim': birim,
        'miktar': miktar,
        'anaGrup': anaGrup.name,
        'altGrup': altGrup,
        'materialHint': materialHint,
      };

  factory KesifLine.fromJson(Map<String, dynamic> json) => KesifLine(
        id: json['id'] as String,
        pozNo: json['pozNo'] as String? ?? '',
        tanim: json['tanim'] as String? ?? '',
        birim: json['birim'] as String? ?? '',
        miktar: (json['miktar'] as num?)?.toDouble() ?? 0,
        anaGrup: MainDiscipline.tryParse(json['anaGrup'] as String?) ??
            MainDiscipline.insaat,
        altGrup: json['altGrup'] as String? ?? '',
        materialHint: json['materialHint'] as String? ?? '',
      );

  @override
  List<Object?> get props =>
      [id, pozNo, tanim, birim, miktar, anaGrup, altGrup, materialHint];
}
