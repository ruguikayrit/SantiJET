import 'package:equatable/equatable.dart';

class ConcreteDiscoveryItem extends Equatable {
  const ConcreteDiscoveryItem({
    required this.id,
    required this.projectId,
    required this.elementName,
    required this.plannedM3,
    this.location = '',
    this.concreteClass = 'C30/37',
    this.sortOrder = 0,
  });

  final String id;
  final String projectId;
  final String elementName;
  final double plannedM3;
  final String location;
  final String concreteClass;
  final int sortOrder;

  ConcreteDiscoveryItem copyWith({
    String? id,
    String? projectId,
    String? elementName,
    double? plannedM3,
    String? location,
    String? concreteClass,
    int? sortOrder,
  }) {
    return ConcreteDiscoveryItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      elementName: elementName ?? this.elementName,
      plannedM3: plannedM3 ?? this.plannedM3,
      location: location ?? this.location,
      concreteClass: concreteClass ?? this.concreteClass,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'elementName': elementName,
        'plannedM3': plannedM3,
        'location': location,
        'concreteClass': concreteClass,
        'sortOrder': sortOrder,
      };

  factory ConcreteDiscoveryItem.fromJson(Map<String, dynamic> json) =>
      ConcreteDiscoveryItem(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        elementName: json['elementName'] as String? ?? '',
        plannedM3: (json['plannedM3'] as num?)?.toDouble() ?? 0,
        location: json['location'] as String? ?? '',
        concreteClass: json['concreteClass'] as String? ?? 'C30/37',
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  @override
  List<Object?> get props =>
      [id, projectId, elementName, plannedM3, location, concreteClass, sortOrder];
}
