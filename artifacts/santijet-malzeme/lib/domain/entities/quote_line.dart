import 'package:equatable/equatable.dart';

/// Hive typeId plan: 8
class QuoteLine extends Equatable {
  const QuoteLine({
    required this.id,
    required this.requestLineId,
    required this.quantity,
    required this.unitPrice,
    this.selected = false,
    this.pozNo = '',
    this.materialName = '',
    this.birim = '',
  });

  final String id;
  final String requestLineId;
  final double quantity;
  final double unitPrice;

  /// Mukayesede kazanan satır işareti.
  final bool selected;
  final String pozNo;
  final String materialName;
  final String birim;

  double get amount => quantity * unitPrice;

  QuoteLine copyWith({
    String? id,
    String? requestLineId,
    double? quantity,
    double? unitPrice,
    bool? selected,
    String? pozNo,
    String? materialName,
    String? birim,
  }) {
    return QuoteLine(
      id: id ?? this.id,
      requestLineId: requestLineId ?? this.requestLineId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      selected: selected ?? this.selected,
      pozNo: pozNo ?? this.pozNo,
      materialName: materialName ?? this.materialName,
      birim: birim ?? this.birim,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestLineId': requestLineId,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'selected': selected,
        'pozNo': pozNo,
        'materialName': materialName,
        'birim': birim,
      };

  factory QuoteLine.fromJson(Map<String, dynamic> json) => QuoteLine(
        id: json['id'] as String,
        requestLineId: json['requestLineId'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        selected: json['selected'] as bool? ?? false,
        pozNo: json['pozNo'] as String? ?? '',
        materialName: json['materialName'] as String? ?? '',
        birim: json['birim'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        requestLineId,
        quantity,
        unitPrice,
        selected,
        pozNo,
        materialName,
        birim,
      ];
}
