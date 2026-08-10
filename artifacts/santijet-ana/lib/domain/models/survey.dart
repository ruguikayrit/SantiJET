import 'package:equatable/equatable.dart';

class SurveyItem extends Equatable {
  const SurveyItem({
    required this.id,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    this.pozCode,
    this.pozCategory,
    this.plannedQty,
    this.completedQty,
    this.date,
    this.itemType,
  });

  final String id;
  final String description;
  final String unit;
  final double quantity;
  final double unitPrice;
  final String? pozCode;
  final String? pozCategory;
  final double? plannedQty;
  final double? completedQty;
  final String? date;
  final String? itemType; // malzeme | iscilik

  SurveyItem copyWith({
    String? id,
    String? description,
    String? unit,
    double? quantity,
    double? unitPrice,
    String? pozCode,
    String? pozCategory,
    double? plannedQty,
    double? completedQty,
    String? date,
    String? itemType,
  }) {
    return SurveyItem(
      id: id ?? this.id,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      pozCode: pozCode ?? this.pozCode,
      pozCategory: pozCategory ?? this.pozCategory,
      plannedQty: plannedQty ?? this.plannedQty,
      completedQty: completedQty ?? this.completedQty,
      date: date ?? this.date,
      itemType: itemType ?? this.itemType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'unit': unit,
        'quantity': quantity,
        'unitPrice': unitPrice,
        if (pozCode != null) 'pozCode': pozCode,
        if (pozCategory != null) 'pozCategory': pozCategory,
        if (plannedQty != null) 'plannedQty': plannedQty,
        if (completedQty != null) 'completedQty': completedQty,
        if (date != null) 'date': date,
        if (itemType != null) 'itemType': itemType,
      };

  factory SurveyItem.fromJson(Map<String, dynamic> json) {
    return SurveyItem(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      pozCode: json['pozCode']?.toString(),
      pozCategory: json['pozCategory']?.toString(),
      plannedQty: (json['plannedQty'] as num?)?.toDouble(),
      completedQty: (json['completedQty'] as num?)?.toDouble(),
      date: json['date']?.toString(),
      itemType: json['itemType']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        description,
        unit,
        quantity,
        unitPrice,
        pozCode,
        pozCategory,
        plannedQty,
        completedQty,
        date,
        itemType,
      ];
}

class Survey extends Equatable {
  const Survey({
    required this.id,
    required this.projectId,
    required this.title,
    required this.date,
    required this.location,
    required this.notes,
    required this.items,
  });

  final String id;
  final String projectId;
  final String title;
  final String date;
  final String location;
  final String notes;
  final List<SurveyItem> items;

  Survey copyWith({
    String? id,
    String? projectId,
    String? title,
    String? date,
    String? location,
    String? notes,
    List<SurveyItem>? items,
  }) {
    return Survey(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      date: date ?? this.date,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'date': date,
        'location': location,
        'notes': notes,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory Survey.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return Survey(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => SurveyItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props =>
      [id, projectId, title, date, location, notes, items];
}
