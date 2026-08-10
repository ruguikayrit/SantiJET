import 'package:equatable/equatable.dart';

class Production extends Equatable {
  const Production({
    required this.id,
    required this.projectId,
    required this.name,
    required this.unit,
    required this.plannedQty,
    required this.completedQty,
    required this.unitPrice,
    required this.date,
    this.pozCode,
    this.pozCategory,
    this.description,
    this.images,
    this.mixerCount,
    this.pumpCount,
    this.pumpInfo,
  });

  final String id;
  final String projectId;
  final String name;
  final String unit;
  final double plannedQty;
  final double completedQty;
  final double unitPrice;
  final String date;
  final String? pozCode;
  final String? pozCategory;
  final String? description;
  final List<String>? images;
  final String? mixerCount;
  final String? pumpCount;
  final String? pumpInfo;

  Production copyWith({
    String? id,
    String? projectId,
    String? name,
    String? unit,
    double? plannedQty,
    double? completedQty,
    double? unitPrice,
    String? date,
    String? pozCode,
    String? pozCategory,
    String? description,
    List<String>? images,
    String? mixerCount,
    String? pumpCount,
    String? pumpInfo,
  }) {
    return Production(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      plannedQty: plannedQty ?? this.plannedQty,
      completedQty: completedQty ?? this.completedQty,
      unitPrice: unitPrice ?? this.unitPrice,
      date: date ?? this.date,
      pozCode: pozCode ?? this.pozCode,
      pozCategory: pozCategory ?? this.pozCategory,
      description: description ?? this.description,
      images: images ?? this.images,
      mixerCount: mixerCount ?? this.mixerCount,
      pumpCount: pumpCount ?? this.pumpCount,
      pumpInfo: pumpInfo ?? this.pumpInfo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'unit': unit,
        'plannedQty': plannedQty,
        'completedQty': completedQty,
        'unitPrice': unitPrice,
        'date': date,
        if (pozCode != null) 'pozCode': pozCode,
        if (pozCategory != null) 'pozCategory': pozCategory,
        if (description != null) 'description': description,
        if (images != null) 'images': images,
        if (mixerCount != null) 'mixerCount': mixerCount,
        if (pumpCount != null) 'pumpCount': pumpCount,
        if (pumpInfo != null) 'pumpInfo': pumpInfo,
      };

  factory Production.fromJson(Map<String, dynamic> json) {
    return Production(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      plannedQty: (json['plannedQty'] as num?)?.toDouble() ?? 0,
      completedQty: (json['completedQty'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      date: json['date']?.toString() ?? '',
      pozCode: json['pozCode']?.toString(),
      pozCategory: json['pozCategory']?.toString(),
      description: json['description']?.toString(),
      images: json['images'] is List
          ? (json['images'] as List).map((e) => e.toString()).toList()
          : null,
      mixerCount: json['mixerCount']?.toString(),
      pumpCount: json['pumpCount']?.toString(),
      pumpInfo: json['pumpInfo']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        name,
        unit,
        plannedQty,
        completedQty,
        unitPrice,
        date,
        pozCode,
        pozCategory,
        description,
        images,
        mixerCount,
        pumpCount,
        pumpInfo,
      ];
}
