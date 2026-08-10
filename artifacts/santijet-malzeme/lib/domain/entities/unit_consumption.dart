import 'package:equatable/equatable.dart';

/// Hive typeId plan: 13
/// Birim sarfiyat — 1 birim keşif işi için gereken malzeme miktarı.
///
/// Malzeme ihtiyacı = keşif metrajı × [rate].
class UnitConsumption extends Equatable {
  const UnitConsumption({
    required this.id,
    required this.projectId,
    required this.materialName,
    required this.materialUnit,
    required this.rate,
    this.pozNo = '',
    this.kesifUnit = '',
    this.category = '',
    this.notes = '',
  });

  final String id;
  final String projectId;

  /// Malzeme adı (talep satırına gider).
  final String materialName;

  /// Malzeme birimi (kg, lt, ad, torba…).
  final String materialUnit;

  /// 1 keşif birimi başına sarfiyat.
  final double rate;

  /// Eşleşecek keşif pozu (boşsa kategori/elle bağlanır).
  final String pozNo;

  /// Keşif ölçü birimi ipucu (m², m, ad…).
  final String kesifUnit;

  final String category;
  final String notes;

  UnitConsumption copyWith({
    String? id,
    String? projectId,
    String? materialName,
    String? materialUnit,
    double? rate,
    String? pozNo,
    String? kesifUnit,
    String? category,
    String? notes,
  }) {
    return UnitConsumption(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      materialName: materialName ?? this.materialName,
      materialUnit: materialUnit ?? this.materialUnit,
      rate: rate ?? this.rate,
      pozNo: pozNo ?? this.pozNo,
      kesifUnit: kesifUnit ?? this.kesifUnit,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'materialName': materialName,
        'materialUnit': materialUnit,
        'rate': rate,
        'pozNo': pozNo,
        'kesifUnit': kesifUnit,
        'category': category,
        'notes': notes,
      };

  factory UnitConsumption.fromJson(Map<String, dynamic> json) =>
      UnitConsumption(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        materialName: json['materialName'] as String? ?? '',
        materialUnit: json['materialUnit'] as String? ?? '',
        rate: (json['rate'] as num?)?.toDouble() ?? 0,
        pozNo: json['pozNo'] as String? ?? '',
        kesifUnit: json['kesifUnit'] as String? ?? '',
        category: json['category'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        materialName,
        materialUnit,
        rate,
        pozNo,
        kesifUnit,
        category,
        notes,
      ];
}
