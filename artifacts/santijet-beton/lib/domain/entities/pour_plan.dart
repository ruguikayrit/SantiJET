import 'package:equatable/equatable.dart';

/// Döküm planı durumu.
enum PourPlanStatus {
  planned,
  completed,
  cancelled;

  String get label => switch (this) {
        PourPlanStatus.planned => 'Planlandı',
        PourPlanStatus.completed => 'Tamamlandı',
        PourPlanStatus.cancelled => 'İptal',
      };

  static PourPlanStatus fromStorage(String? raw) => switch (raw) {
        'completed' => PourPlanStatus.completed,
        'cancelled' => PourPlanStatus.cancelled,
        _ => PourPlanStatus.planned,
      };

  String get storage => name;
}

/// Planlanan döküm — tarih / lokasyon / sınıf / m³.
class PourPlan extends Equatable {
  const PourPlan({
    required this.id,
    required this.projectId,
    required this.date,
    required this.plannedM3,
    this.location = '',
    this.concreteClass = 'C30/37',
    this.status = PourPlanStatus.planned,
    this.notes = '',
  });

  final String id;
  final String projectId;

  /// gg.aa.yyyy
  final String date;
  final String location;
  final String concreteClass;
  final double plannedM3;
  final PourPlanStatus status;
  final String notes;

  PourPlan copyWith({
    String? id,
    String? projectId,
    String? date,
    String? location,
    String? concreteClass,
    double? plannedM3,
    PourPlanStatus? status,
    String? notes,
  }) {
    return PourPlan(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      location: location ?? this.location,
      concreteClass: concreteClass ?? this.concreteClass,
      plannedM3: plannedM3 ?? this.plannedM3,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'date': date,
        'location': location,
        'concreteClass': concreteClass,
        'plannedM3': plannedM3,
        'status': status.storage,
        'notes': notes,
      };

  factory PourPlan.fromJson(Map<String, dynamic> json) => PourPlan(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        date: json['date'] as String? ?? '',
        location: json['location'] as String? ?? '',
        concreteClass: json['concreteClass'] as String? ?? 'C30/37',
        plannedM3: (json['plannedM3'] as num?)?.toDouble() ?? 0,
        status: PourPlanStatus.fromStorage(json['status'] as String?),
        notes: json['notes'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        date,
        location,
        concreteClass,
        plannedM3,
        status,
        notes,
      ];
}
