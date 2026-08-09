import 'package:equatable/equatable.dart';

/// Hive typeId plan: 9 — Pro RN `Material` (Gelen / teslim / irsaliye).
class Delivery extends Equatable {
  const Delivery({
    required this.id,
    required this.projectId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.date,
    this.category = '',
    this.supplier = '',
    this.waybillNo = '',
    this.invoiceNo = '',
    this.materialRequestId,
    this.irsaliyeQty,
    this.kantarEnabled = false,
    this.pozCode = '',
    this.notes = '',
    this.fotoPath,
  });

  final String id;
  final String projectId;
  final String name;
  final String category;
  final String unit;
  final double quantity;
  final DateTime date;
  final String supplier;
  final String waybillNo;
  final String invoiceNo;
  final String? materialRequestId;
  final double? irsaliyeQty;
  final bool kantarEnabled;
  final String pozCode;
  final String notes;
  final String? fotoPath;

  bool get fromRequest => materialRequestId != null;

  Delivery copyWith({
    String? id,
    String? projectId,
    String? name,
    String? category,
    String? unit,
    double? quantity,
    DateTime? date,
    String? supplier,
    String? waybillNo,
    String? invoiceNo,
    String? materialRequestId,
    double? irsaliyeQty,
    bool? kantarEnabled,
    String? pozCode,
    String? notes,
    String? fotoPath,
  }) {
    return Delivery(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      supplier: supplier ?? this.supplier,
      waybillNo: waybillNo ?? this.waybillNo,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      materialRequestId: materialRequestId ?? this.materialRequestId,
      irsaliyeQty: irsaliyeQty ?? this.irsaliyeQty,
      kantarEnabled: kantarEnabled ?? this.kantarEnabled,
      pozCode: pozCode ?? this.pozCode,
      notes: notes ?? this.notes,
      fotoPath: fotoPath ?? this.fotoPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'category': category,
        'unit': unit,
        'quantity': quantity,
        'date': date.toIso8601String(),
        'supplier': supplier,
        'waybillNo': waybillNo,
        'invoiceNo': invoiceNo,
        'materialRequestId': materialRequestId,
        'irsaliyeQty': irsaliyeQty,
        'kantarEnabled': kantarEnabled,
        'pozCode': pozCode,
        'notes': notes,
        'fotoPath': fotoPath,
      };

  factory Delivery.fromJson(Map<String, dynamic> json) {
    // Eski Delivery (lines + irsaliyeNo) → yeni Gelen modeli.
    final lines = json['lines'] as List?;
    final firstLine = lines != null && lines.isNotEmpty
        ? Map<String, dynamic>.from(lines.first as Map)
        : null;
    return Delivery(
      id: json['id'] as String,
      projectId: json['projectId'] as String? ?? '',
      name: json['name'] as String? ??
          firstLine?['materialName'] as String? ??
          '',
      category: json['category'] as String? ?? '',
      unit: json['unit'] as String? ?? firstLine?['birim'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ??
          (firstLine?['quantity'] as num?)?.toDouble() ??
          0,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      supplier: json['supplier'] as String? ??
          json['supplierName'] as String? ??
          '',
      waybillNo: json['waybillNo'] as String? ??
          json['irsaliyeNo'] as String? ??
          '',
      invoiceNo: json['invoiceNo'] as String? ?? '',
      materialRequestId: json['materialRequestId'] as String? ??
          json['requestId'] as String?,
      irsaliyeQty: (json['irsaliyeQty'] as num?)?.toDouble(),
      kantarEnabled: json['kantarEnabled'] as bool? ?? false,
      pozCode: json['pozCode'] as String? ??
          firstLine?['pozNo'] as String? ??
          '',
      notes: json['notes'] as String? ?? '',
      fotoPath: json['fotoPath'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        name,
        category,
        unit,
        quantity,
        date,
        supplier,
        waybillNo,
        invoiceNo,
        materialRequestId,
        irsaliyeQty,
        kantarEnabled,
        pozCode,
        notes,
        fotoPath,
      ];
}
