import 'package:equatable/equatable.dart';

class HakedisItem extends Equatable {
  const HakedisItem({
    required this.id,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
  });

  final String id;
  final String description;
  final String unit;
  final double quantity;
  final double unitPrice;

  HakedisItem copyWith({
    String? id,
    String? description,
    String? unit,
    double? quantity,
    double? unitPrice,
  }) {
    return HakedisItem(
      id: id ?? this.id,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'unit': unit,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory HakedisItem.fromJson(Map<String, dynamic> json) {
    return HakedisItem(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, description, unit, quantity, unitPrice];
}

class Hakedis extends Equatable {
  const Hakedis({
    required this.id,
    required this.projectId,
    required this.number,
    required this.date,
    required this.period,
    required this.contractor,
    required this.status,
    required this.notes,
    required this.items,
  });

  final String id;
  final String projectId;
  final String number;
  final String date;
  final String period;
  final String contractor;
  final String status; // draft | submitted | approved | paid
  final String notes;
  final List<HakedisItem> items;

  Hakedis copyWith({
    String? id,
    String? projectId,
    String? number,
    String? date,
    String? period,
    String? contractor,
    String? status,
    String? notes,
    List<HakedisItem>? items,
  }) {
    return Hakedis(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      number: number ?? this.number,
      date: date ?? this.date,
      period: period ?? this.period,
      contractor: contractor ?? this.contractor,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'number': number,
        'date': date,
        'period': period,
        'contractor': contractor,
        'status': status,
        'notes': notes,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory Hakedis.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return Hakedis(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      period: json['period']?.toString() ?? '',
      contractor: json['contractor']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      notes: json['notes']?.toString() ?? '',
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => HakedisItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props =>
      [id, projectId, number, date, period, contractor, status, notes, items];
}
