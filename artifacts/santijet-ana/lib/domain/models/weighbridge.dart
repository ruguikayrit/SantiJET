import 'package:equatable/equatable.dart';

class Weighbridge extends Equatable {
  const Weighbridge({
    required this.id,
    required this.projectId,
    required this.date,
    required this.materialName,
    required this.supplier,
    required this.plate,
    required this.driver,
    required this.irsaliyeNo,
    required this.grossWeight,
    required this.tareWeight,
    required this.netWeight,
    required this.unit,
    required this.notes,
    this.materialId,
    this.category,
    this.entryTime,
    this.exitTime,
    this.supplierIrsaliyeNo,
    this.supplierTonnage,
    this.supplierGrossWeight,
    this.supplierTareWeight,
  });

  final String id;
  final String projectId;
  final String date;
  final String? materialId;
  final String materialName;
  final String? category;
  final String supplier;
  final String plate;
  final String driver;
  final String irsaliyeNo;
  final double grossWeight;
  final double tareWeight;
  final double netWeight;
  final String unit;
  final String notes;
  final String? entryTime;
  final String? exitTime;
  final String? supplierIrsaliyeNo;
  final double? supplierTonnage;
  final double? supplierGrossWeight;
  final double? supplierTareWeight;

  Weighbridge copyWith({
    String? id,
    String? projectId,
    String? date,
    String? materialId,
    String? materialName,
    String? category,
    String? supplier,
    String? plate,
    String? driver,
    String? irsaliyeNo,
    double? grossWeight,
    double? tareWeight,
    double? netWeight,
    String? unit,
    String? notes,
    String? entryTime,
    String? exitTime,
    String? supplierIrsaliyeNo,
    double? supplierTonnage,
    double? supplierGrossWeight,
    double? supplierTareWeight,
  }) {
    return Weighbridge(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      materialId: materialId ?? this.materialId,
      materialName: materialName ?? this.materialName,
      category: category ?? this.category,
      supplier: supplier ?? this.supplier,
      plate: plate ?? this.plate,
      driver: driver ?? this.driver,
      irsaliyeNo: irsaliyeNo ?? this.irsaliyeNo,
      grossWeight: grossWeight ?? this.grossWeight,
      tareWeight: tareWeight ?? this.tareWeight,
      netWeight: netWeight ?? this.netWeight,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      supplierIrsaliyeNo: supplierIrsaliyeNo ?? this.supplierIrsaliyeNo,
      supplierTonnage: supplierTonnage ?? this.supplierTonnage,
      supplierGrossWeight: supplierGrossWeight ?? this.supplierGrossWeight,
      supplierTareWeight: supplierTareWeight ?? this.supplierTareWeight,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'date': date,
        if (materialId != null) 'materialId': materialId,
        'materialName': materialName,
        if (category != null) 'category': category,
        'supplier': supplier,
        'plate': plate,
        'driver': driver,
        'irsaliyeNo': irsaliyeNo,
        'grossWeight': grossWeight,
        'tareWeight': tareWeight,
        'netWeight': netWeight,
        'unit': unit,
        'notes': notes,
        if (entryTime != null) 'entryTime': entryTime,
        if (exitTime != null) 'exitTime': exitTime,
        if (supplierIrsaliyeNo != null) 'supplierIrsaliyeNo': supplierIrsaliyeNo,
        if (supplierTonnage != null) 'supplierTonnage': supplierTonnage,
        if (supplierGrossWeight != null)
          'supplierGrossWeight': supplierGrossWeight,
        if (supplierTareWeight != null) 'supplierTareWeight': supplierTareWeight,
      };

  factory Weighbridge.fromJson(Map<String, dynamic> json) {
    final gross = (json['grossWeight'] as num?)?.toDouble() ?? 0;
    final tare = (json['tareWeight'] as num?)?.toDouble() ?? 0;
    final netRaw = (json['netWeight'] as num?)?.toDouble();
    return Weighbridge(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      materialId: json['materialId']?.toString(),
      materialName: json['materialName']?.toString() ?? '',
      category: json['category']?.toString(),
      supplier: json['supplier']?.toString() ?? '',
      plate: json['plate']?.toString() ?? '',
      driver: json['driver']?.toString() ?? '',
      irsaliyeNo: json['irsaliyeNo']?.toString() ?? '',
      grossWeight: gross,
      tareWeight: tare,
      netWeight: netRaw ?? (gross - tare).clamp(0, double.infinity),
      unit: json['unit']?.toString() ?? 'kg',
      notes: json['notes']?.toString() ?? '',
      entryTime: json['entryTime']?.toString(),
      exitTime: json['exitTime']?.toString(),
      supplierIrsaliyeNo: json['supplierIrsaliyeNo']?.toString(),
      supplierTonnage: (json['supplierTonnage'] as num?)?.toDouble(),
      supplierGrossWeight: (json['supplierGrossWeight'] as num?)?.toDouble(),
      supplierTareWeight: (json['supplierTareWeight'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        date,
        materialId,
        materialName,
        category,
        supplier,
        plate,
        driver,
        irsaliyeNo,
        grossWeight,
        tareWeight,
        netWeight,
        unit,
        notes,
        entryTime,
        exitTime,
        supplierIrsaliyeNo,
        supplierTonnage,
        supplierGrossWeight,
        supplierTareWeight,
      ];
}
