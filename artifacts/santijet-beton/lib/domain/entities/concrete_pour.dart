import 'package:equatable/equatable.dart';

class ConcretePour extends Equatable {
  const ConcretePour({
    required this.id,
    required this.projectId,
    required this.date,
    required this.volumeM3,
    this.elementName = '',
    this.location = '',
    this.concreteClass = 'C30/37',
    this.supplier = '',
    this.ticketNo = '',
    this.slumpCm,
    this.pourStart,
    this.pourEnd,
    this.notes = '',
    this.orderId,
    this.discoveryItemId,
  });

  final String id;
  final String projectId;
  final String date;
  final double volumeM3;
  final String elementName;
  final String location;
  final String concreteClass;
  final String supplier;
  final String ticketNo;
  final double? slumpCm;
  final DateTime? pourStart;
  final DateTime? pourEnd;
  final String notes;
  final String? orderId;
  final String? discoveryItemId;

  ConcretePour copyWith({
    String? id,
    String? projectId,
    String? date,
    double? volumeM3,
    String? elementName,
    String? location,
    String? concreteClass,
    String? supplier,
    String? ticketNo,
    double? slumpCm,
    DateTime? pourStart,
    DateTime? pourEnd,
    String? notes,
    String? orderId,
    String? discoveryItemId,
  }) {
    return ConcretePour(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      volumeM3: volumeM3 ?? this.volumeM3,
      elementName: elementName ?? this.elementName,
      location: location ?? this.location,
      concreteClass: concreteClass ?? this.concreteClass,
      supplier: supplier ?? this.supplier,
      ticketNo: ticketNo ?? this.ticketNo,
      slumpCm: slumpCm ?? this.slumpCm,
      pourStart: pourStart ?? this.pourStart,
      pourEnd: pourEnd ?? this.pourEnd,
      notes: notes ?? this.notes,
      orderId: orderId ?? this.orderId,
      discoveryItemId: discoveryItemId ?? this.discoveryItemId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'date': date,
        'volumeM3': volumeM3,
        'elementName': elementName,
        'location': location,
        'concreteClass': concreteClass,
        'supplier': supplier,
        'ticketNo': ticketNo,
        'slumpCm': slumpCm,
        'pourStart': pourStart?.toIso8601String(),
        'pourEnd': pourEnd?.toIso8601String(),
        'notes': notes,
        'orderId': orderId,
        'discoveryItemId': discoveryItemId,
      };

  factory ConcretePour.fromJson(Map<String, dynamic> json) => ConcretePour(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        date: json['date'] as String? ?? '',
        volumeM3: (json['volumeM3'] as num?)?.toDouble() ?? 0,
        elementName: json['elementName'] as String? ?? '',
        location: json['location'] as String? ?? '',
        concreteClass: json['concreteClass'] as String? ?? 'C30/37',
        supplier: json['supplier'] as String? ?? '',
        ticketNo: json['ticketNo'] as String? ?? '',
        slumpCm: (json['slumpCm'] as num?)?.toDouble(),
        pourStart: json['pourStart'] != null
            ? DateTime.tryParse(json['pourStart'] as String)
            : null,
        pourEnd: json['pourEnd'] != null
            ? DateTime.tryParse(json['pourEnd'] as String)
            : null,
        notes: json['notes'] as String? ?? '',
        orderId: json['orderId'] as String?,
        discoveryItemId: json['discoveryItemId'] as String?,
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        date,
        volumeM3,
        elementName,
        location,
        concreteClass,
        supplier,
        ticketNo,
        slumpCm,
        pourStart,
        pourEnd,
        notes,
        orderId,
        discoveryItemId,
      ];
}
