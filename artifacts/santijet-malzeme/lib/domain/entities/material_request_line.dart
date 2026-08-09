import 'package:equatable/equatable.dart';

/// Hive typeId plan: 5
class MaterialRequestLine extends Equatable {
  const MaterialRequestLine({
    required this.id,
    required this.materialName,
    required this.birim,
    required this.miktar,
    this.kesifLineId,
    this.pozNo = '',
    this.materialItemId,
    this.techSheetId,
    this.notes = '',
  });

  final String id;
  final String materialName;
  final String birim;
  final double miktar;
  final String? kesifLineId;
  final String pozNo;
  final String? materialItemId;
  final String? techSheetId;
  final String notes;

  MaterialRequestLine copyWith({
    String? id,
    String? materialName,
    String? birim,
    double? miktar,
    String? kesifLineId,
    String? pozNo,
    String? materialItemId,
    String? techSheetId,
    String? notes,
  }) {
    return MaterialRequestLine(
      id: id ?? this.id,
      materialName: materialName ?? this.materialName,
      birim: birim ?? this.birim,
      miktar: miktar ?? this.miktar,
      kesifLineId: kesifLineId ?? this.kesifLineId,
      pozNo: pozNo ?? this.pozNo,
      materialItemId: materialItemId ?? this.materialItemId,
      techSheetId: techSheetId ?? this.techSheetId,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'materialName': materialName,
        'birim': birim,
        'miktar': miktar,
        'kesifLineId': kesifLineId,
        'pozNo': pozNo,
        'materialItemId': materialItemId,
        'techSheetId': techSheetId,
        'notes': notes,
      };

  factory MaterialRequestLine.fromJson(Map<String, dynamic> json) =>
      MaterialRequestLine(
        id: json['id'] as String,
        materialName: json['materialName'] as String? ?? '',
        birim: json['birim'] as String? ?? '',
        miktar: (json['miktar'] as num?)?.toDouble() ?? 0,
        kesifLineId: json['kesifLineId'] as String?,
        pozNo: json['pozNo'] as String? ?? '',
        materialItemId: json['materialItemId'] as String?,
        techSheetId: json['techSheetId'] as String?,
        notes: json['notes'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        materialName,
        birim,
        miktar,
        kesifLineId,
        pozNo,
        materialItemId,
        techSheetId,
        notes,
      ];
}
