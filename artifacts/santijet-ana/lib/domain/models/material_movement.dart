import 'package:equatable/equatable.dart';

class MaterialMovement extends Equatable {
  const MaterialMovement({
    required this.id,
    required this.projectId,
    required this.type,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.date,
    required this.person,
    required this.location,
    required this.reason,
    required this.note,
    this.category,
    this.pozCode,
    this.pozCategory,
  });

  final String id;
  final String projectId;
  final String type; // kullanim | giden
  final String name;
  final String? category;
  final String unit;
  final double quantity;
  final String date;
  final String person;
  final String location;
  final String reason;
  final String note;
  final String? pozCode;
  final String? pozCategory;

  MaterialMovement copyWith({
    String? id,
    String? projectId,
    String? type,
    String? name,
    String? category,
    String? unit,
    double? quantity,
    String? date,
    String? person,
    String? location,
    String? reason,
    String? note,
    String? pozCode,
    String? pozCategory,
  }) {
    return MaterialMovement(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      person: person ?? this.person,
      location: location ?? this.location,
      reason: reason ?? this.reason,
      note: note ?? this.note,
      pozCode: pozCode ?? this.pozCode,
      pozCategory: pozCategory ?? this.pozCategory,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'type': type,
        'name': name,
        if (category != null) 'category': category,
        'unit': unit,
        'quantity': quantity,
        'date': date,
        'person': person,
        'location': location,
        'reason': reason,
        'note': note,
        if (pozCode != null) 'pozCode': pozCode,
        if (pozCategory != null) 'pozCategory': pozCategory,
      };

  factory MaterialMovement.fromJson(Map<String, dynamic> json) {
    return MaterialMovement(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'kullanim',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString(),
      unit: json['unit']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      date: json['date']?.toString() ?? '',
      person: json['person']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      pozCode: json['pozCode']?.toString(),
      pozCategory: json['pozCategory']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        type,
        name,
        category,
        unit,
        quantity,
        date,
        person,
        location,
        reason,
        note,
        pozCode,
        pozCategory,
      ];
}
