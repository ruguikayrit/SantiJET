import 'package:equatable/equatable.dart';

/// Planlı beton siparişi (program / WhatsApp paylaşımı).
class ConcreteOrder extends Equatable {
  const ConcreteOrder({
    required this.id,
    required this.projectId,
    required this.plannedDate,
    required this.plannedM3,
    this.elementName = '',
    this.location = '',
    this.concreteClass = 'C30/37',
    this.supplier = '',
    this.plannedStartHour = '',
    this.notes = '',
    this.sharedViaWhatsApp = false,
  });

  final String id;
  final String projectId;

  /// gg.aa.yyyy
  final String plannedDate;
  final double plannedM3;
  final String elementName;
  final String location;
  final String concreteClass;
  final String supplier;
  final String plannedStartHour;
  final String notes;
  final bool sharedViaWhatsApp;

  ConcreteOrder copyWith({
    String? id,
    String? projectId,
    String? plannedDate,
    double? plannedM3,
    String? elementName,
    String? location,
    String? concreteClass,
    String? supplier,
    String? plannedStartHour,
    String? notes,
    bool? sharedViaWhatsApp,
  }) {
    return ConcreteOrder(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      plannedDate: plannedDate ?? this.plannedDate,
      plannedM3: plannedM3 ?? this.plannedM3,
      elementName: elementName ?? this.elementName,
      location: location ?? this.location,
      concreteClass: concreteClass ?? this.concreteClass,
      supplier: supplier ?? this.supplier,
      plannedStartHour: plannedStartHour ?? this.plannedStartHour,
      notes: notes ?? this.notes,
      sharedViaWhatsApp: sharedViaWhatsApp ?? this.sharedViaWhatsApp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'plannedDate': plannedDate,
        'plannedM3': plannedM3,
        'elementName': elementName,
        'location': location,
        'concreteClass': concreteClass,
        'supplier': supplier,
        'plannedStartHour': plannedStartHour,
        'notes': notes,
        'sharedViaWhatsApp': sharedViaWhatsApp,
      };

  factory ConcreteOrder.fromJson(Map<String, dynamic> json) => ConcreteOrder(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        plannedDate: json['plannedDate'] as String? ??
            json['orderDate'] as String? ??
            '',
        plannedM3: (json['plannedM3'] as num?)?.toDouble() ??
            (json['orderedM3'] as num?)?.toDouble() ??
            0,
        elementName: json['elementName'] as String? ?? '',
        location: json['location'] as String? ?? '',
        concreteClass: json['concreteClass'] as String? ?? 'C30/37',
        supplier: json['supplier'] as String? ?? '',
        plannedStartHour: json['plannedStartHour'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        sharedViaWhatsApp: json['sharedViaWhatsApp'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        plannedDate,
        plannedM3,
        elementName,
        location,
        concreteClass,
        supplier,
        plannedStartHour,
        notes,
        sharedViaWhatsApp,
      ];
}
