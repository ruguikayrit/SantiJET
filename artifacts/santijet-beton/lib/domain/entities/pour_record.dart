import 'package:equatable/equatable.dart';

/// Fiili günlük döküm kaydı.
class PourRecord extends Equatable {
  const PourRecord({
    required this.id,
    required this.projectId,
    required this.date,
    required this.actualM3,
    this.planId,
    this.concreteClass = 'C30/37',
    this.location = '',
    this.mixerNote = '',
    this.pumpNote = '',
    this.notes = '',
  });

  final String id;
  final String projectId;
  final String? planId;
  final String date;
  final double actualM3;
  final String concreteClass;
  final String location;
  final String mixerNote;
  final String pumpNote;
  final String notes;

  PourRecord copyWith({
    String? id,
    String? projectId,
    String? planId,
    String? date,
    double? actualM3,
    String? concreteClass,
    String? location,
    String? mixerNote,
    String? pumpNote,
    String? notes,
  }) {
    return PourRecord(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      planId: planId ?? this.planId,
      date: date ?? this.date,
      actualM3: actualM3 ?? this.actualM3,
      concreteClass: concreteClass ?? this.concreteClass,
      location: location ?? this.location,
      mixerNote: mixerNote ?? this.mixerNote,
      pumpNote: pumpNote ?? this.pumpNote,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'planId': planId,
        'date': date,
        'actualM3': actualM3,
        'concreteClass': concreteClass,
        'location': location,
        'mixerNote': mixerNote,
        'pumpNote': pumpNote,
        'notes': notes,
      };

  factory PourRecord.fromJson(Map<String, dynamic> json) => PourRecord(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        planId: json['planId'] as String?,
        date: json['date'] as String? ?? '',
        actualM3: (json['actualM3'] as num?)?.toDouble() ?? 0,
        concreteClass: json['concreteClass'] as String? ?? 'C30/37',
        location: json['location'] as String? ?? '',
        mixerNote: json['mixerNote'] as String? ?? '',
        pumpNote: json['pumpNote'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        planId,
        date,
        actualM3,
        concreteClass,
        location,
        mixerNote,
        pumpNote,
        notes,
      ];
}
