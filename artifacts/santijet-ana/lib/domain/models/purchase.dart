import 'package:equatable/equatable.dart';

class Purchase extends Equatable {
  const Purchase({
    required this.id,
    required this.projectId,
    required this.date,
    required this.supplier,
    required this.itemName,
    required this.category,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.vatRate,
    required this.status,
    required this.paymentMethod,
    required this.paidDate,
    required this.invoiceNo,
    required this.notes,
    required this.invoiceReceived,
    this.invoicePhoto,
    this.paymentNote,
    this.materialRequestId,
    this.materialId,
  });

  final String id;
  final String projectId;
  final String date;
  final String supplier;
  final String itemName;
  final String category;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final String status; // pending | approved | paid | cancelled
  final String paymentMethod; // nakit | havale | kredi-karti | cek | vadeli
  final String paidDate;
  final String invoiceNo;
  final String notes;
  final bool invoiceReceived;
  final String? invoicePhoto;
  final String? paymentNote;
  final String? materialRequestId;
  final String? materialId;

  Purchase copyWith({
    String? id,
    String? projectId,
    String? date,
    String? supplier,
    String? itemName,
    String? category,
    String? unit,
    double? quantity,
    double? unitPrice,
    double? vatRate,
    String? status,
    String? paymentMethod,
    String? paidDate,
    String? invoiceNo,
    String? notes,
    bool? invoiceReceived,
    String? invoicePhoto,
    String? paymentNote,
    String? materialRequestId,
    String? materialId,
  }) {
    return Purchase(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      supplier: supplier ?? this.supplier,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      vatRate: vatRate ?? this.vatRate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidDate: paidDate ?? this.paidDate,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      notes: notes ?? this.notes,
      invoiceReceived: invoiceReceived ?? this.invoiceReceived,
      invoicePhoto: invoicePhoto ?? this.invoicePhoto,
      paymentNote: paymentNote ?? this.paymentNote,
      materialRequestId: materialRequestId ?? this.materialRequestId,
      materialId: materialId ?? this.materialId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'date': date,
        'supplier': supplier,
        'itemName': itemName,
        'category': category,
        'unit': unit,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'vatRate': vatRate,
        'status': status,
        'paymentMethod': paymentMethod,
        'paidDate': paidDate,
        'invoiceNo': invoiceNo,
        'notes': notes,
        'invoiceReceived': invoiceReceived,
        if (invoicePhoto != null) 'invoicePhoto': invoicePhoto,
        if (paymentNote != null) 'paymentNote': paymentNote,
        if (materialRequestId != null) 'materialRequestId': materialRequestId,
        if (materialId != null) 'materialId': materialId,
      };

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      supplier: json['supplier']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      vatRate: (json['vatRate'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'pending',
      paymentMethod: json['paymentMethod']?.toString() ?? 'nakit',
      paidDate: json['paidDate']?.toString() ?? '',
      invoiceNo: json['invoiceNo']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      invoiceReceived: json['invoiceReceived'] == true,
      invoicePhoto: json['invoicePhoto']?.toString(),
      paymentNote: json['paymentNote']?.toString(),
      materialRequestId: json['materialRequestId']?.toString(),
      materialId: json['materialId']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        date,
        supplier,
        itemName,
        category,
        unit,
        quantity,
        unitPrice,
        vatRate,
        status,
        paymentMethod,
        paidDate,
        invoiceNo,
        notes,
        invoiceReceived,
        invoicePhoto,
        paymentNote,
        materialRequestId,
        materialId,
      ];
}
