import 'package:equatable/equatable.dart';

class Material extends Equatable {
  const Material({
    required this.id,
    required this.projectId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.usedQty,
    required this.supplier,
    required this.deliveryDate,
    required this.unitPrice,
    this.category,
    this.recordDetail,
    this.description,
    this.code,
    this.pozCode,
    this.pozCategory,
    this.shippingMethod,
    this.waybillNo,
    this.invoiceNo,
    this.kantarEnabled,
    this.writeToKantar,
    this.kantarSlipId,
    this.supplierKantarSlip,
    this.weighApproved,
    this.materialRequestId,
    this.irsaliyePhoto,
    this.irsaliyeQty,
  });

  final String id;
  final String projectId;
  final String name;
  final String? category;
  final String unit;
  final double quantity;
  final double usedQty;
  final String supplier;
  final String deliveryDate;
  final double unitPrice;
  final String? recordDetail;
  final String? description;
  final String? code;
  final String? pozCode;
  final String? pozCategory;
  final String? shippingMethod;
  final String? waybillNo;
  final String? invoiceNo;
  final bool? kantarEnabled;
  final bool? writeToKantar;
  final String? kantarSlipId;
  final bool? supplierKantarSlip;
  final bool? weighApproved;
  final String? materialRequestId;
  final String? irsaliyePhoto;
  final double? irsaliyeQty;

  Material copyWith({
    String? id,
    String? projectId,
    String? name,
    String? category,
    String? unit,
    double? quantity,
    double? usedQty,
    String? supplier,
    String? deliveryDate,
    double? unitPrice,
    String? recordDetail,
    String? description,
    String? code,
    String? pozCode,
    String? pozCategory,
    String? shippingMethod,
    String? waybillNo,
    String? invoiceNo,
    bool? kantarEnabled,
    bool? writeToKantar,
    String? kantarSlipId,
    bool? supplierKantarSlip,
    bool? weighApproved,
    String? materialRequestId,
    String? irsaliyePhoto,
    double? irsaliyeQty,
    bool clearKantarSlipId = false,
  }) {
    return Material(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      usedQty: usedQty ?? this.usedQty,
      supplier: supplier ?? this.supplier,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      unitPrice: unitPrice ?? this.unitPrice,
      recordDetail: recordDetail ?? this.recordDetail,
      description: description ?? this.description,
      code: code ?? this.code,
      pozCode: pozCode ?? this.pozCode,
      pozCategory: pozCategory ?? this.pozCategory,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      waybillNo: waybillNo ?? this.waybillNo,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      kantarEnabled: kantarEnabled ?? this.kantarEnabled,
      writeToKantar: writeToKantar ?? this.writeToKantar,
      kantarSlipId:
          clearKantarSlipId ? null : (kantarSlipId ?? this.kantarSlipId),
      supplierKantarSlip: supplierKantarSlip ?? this.supplierKantarSlip,
      weighApproved: weighApproved ?? this.weighApproved,
      materialRequestId: materialRequestId ?? this.materialRequestId,
      irsaliyePhoto: irsaliyePhoto ?? this.irsaliyePhoto,
      irsaliyeQty: irsaliyeQty ?? this.irsaliyeQty,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        if (category != null) 'category': category,
        'unit': unit,
        'quantity': quantity,
        'usedQty': usedQty,
        'supplier': supplier,
        'deliveryDate': deliveryDate,
        'unitPrice': unitPrice,
        if (recordDetail != null) 'recordDetail': recordDetail,
        if (description != null) 'description': description,
        if (code != null) 'code': code,
        if (pozCode != null) 'pozCode': pozCode,
        if (pozCategory != null) 'pozCategory': pozCategory,
        if (shippingMethod != null) 'shippingMethod': shippingMethod,
        if (waybillNo != null) 'waybillNo': waybillNo,
        if (invoiceNo != null) 'invoiceNo': invoiceNo,
        if (kantarEnabled != null) 'kantarEnabled': kantarEnabled,
        if (writeToKantar != null) 'writeToKantar': writeToKantar,
        if (kantarSlipId != null) 'kantarSlipId': kantarSlipId,
        if (supplierKantarSlip != null) 'supplierKantarSlip': supplierKantarSlip,
        if (weighApproved != null) 'weighApproved': weighApproved,
        if (materialRequestId != null) 'materialRequestId': materialRequestId,
        if (irsaliyePhoto != null) 'irsaliyePhoto': irsaliyePhoto,
        if (irsaliyeQty != null) 'irsaliyeQty': irsaliyeQty,
      };

  factory Material.fromJson(Map<String, dynamic> json) {
    return Material(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString(),
      unit: json['unit']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      usedQty: (json['usedQty'] as num?)?.toDouble() ?? 0,
      supplier: json['supplier']?.toString() ?? '',
      deliveryDate: json['deliveryDate']?.toString() ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      recordDetail: json['recordDetail']?.toString(),
      description: json['description']?.toString(),
      code: json['code']?.toString(),
      pozCode: json['pozCode']?.toString(),
      pozCategory: json['pozCategory']?.toString(),
      shippingMethod: json['shippingMethod']?.toString(),
      waybillNo: json['waybillNo']?.toString(),
      invoiceNo: json['invoiceNo']?.toString(),
      kantarEnabled: json['kantarEnabled'] as bool?,
      writeToKantar: json['writeToKantar'] as bool?,
      kantarSlipId: json['kantarSlipId']?.toString(),
      supplierKantarSlip: json['supplierKantarSlip'] as bool?,
      weighApproved: json['weighApproved'] as bool?,
      materialRequestId: json['materialRequestId']?.toString(),
      irsaliyePhoto: json['irsaliyePhoto']?.toString(),
      irsaliyeQty: (json['irsaliyeQty'] as num?)?.toDouble(),
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
        usedQty,
        supplier,
        deliveryDate,
        unitPrice,
        recordDetail,
        description,
        code,
        pozCode,
        pozCategory,
        shippingMethod,
        waybillNo,
        invoiceNo,
        kantarEnabled,
        writeToKantar,
        kantarSlipId,
        supplierKantarSlip,
        weighApproved,
        materialRequestId,
        irsaliyePhoto,
        irsaliyeQty,
      ];
}
