import 'package:equatable/equatable.dart';

/// Hive typeId plan: 10
class DeliveryLine extends Equatable {
  const DeliveryLine({
    required this.id,
    required this.materialName,
    required this.birim,
    required this.quantity,
    this.requestLineId,
    this.kesifLineId,
    this.pozNo = '',
    this.fotoPath,
  });

  final String id;
  final String materialName;
  final String birim;
  final double quantity;
  final String? requestLineId;
  final String? kesifLineId;
  final String pozNo;
  final String? fotoPath;

  DeliveryLine copyWith({
    String? id,
    String? materialName,
    String? birim,
    double? quantity,
    String? requestLineId,
    String? kesifLineId,
    String? pozNo,
    String? fotoPath,
  }) {
    return DeliveryLine(
      id: id ?? this.id,
      materialName: materialName ?? this.materialName,
      birim: birim ?? this.birim,
      quantity: quantity ?? this.quantity,
      requestLineId: requestLineId ?? this.requestLineId,
      kesifLineId: kesifLineId ?? this.kesifLineId,
      pozNo: pozNo ?? this.pozNo,
      fotoPath: fotoPath ?? this.fotoPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'materialName': materialName,
        'birim': birim,
        'quantity': quantity,
        'requestLineId': requestLineId,
        'kesifLineId': kesifLineId,
        'pozNo': pozNo,
        'fotoPath': fotoPath,
      };

  factory DeliveryLine.fromJson(Map<String, dynamic> json) => DeliveryLine(
        id: json['id'] as String,
        materialName: json['materialName'] as String? ?? '',
        birim: json['birim'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        requestLineId: json['requestLineId'] as String?,
        kesifLineId: json['kesifLineId'] as String?,
        pozNo: json['pozNo'] as String? ?? '',
        fotoPath: json['fotoPath'] as String?,
      );

  @override
  List<Object?> get props => [
        id,
        materialName,
        birim,
        quantity,
        requestLineId,
        kesifLineId,
        pozNo,
        fotoPath,
      ];
}
