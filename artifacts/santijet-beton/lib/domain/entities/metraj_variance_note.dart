import 'package:equatable/equatable.dart';

class MetrajVarianceNote extends Equatable {
  const MetrajVarianceNote({
    required this.id,
    required this.projectId,
    required this.date,
    required this.plannedM3,
    required this.actualM3,
    required this.reason,
    this.elementName = '',
    this.detail = '',
  });

  final String id;
  final String projectId;
  final String date;
  final double plannedM3;
  final double actualM3;
  final String reason;
  final String elementName;
  final String detail;

  double get deltaM3 => actualM3 - plannedM3;

  MetrajVarianceNote copyWith({
    String? id,
    String? projectId,
    String? date,
    double? plannedM3,
    double? actualM3,
    String? reason,
    String? elementName,
    String? detail,
  }) {
    return MetrajVarianceNote(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      plannedM3: plannedM3 ?? this.plannedM3,
      actualM3: actualM3 ?? this.actualM3,
      reason: reason ?? this.reason,
      elementName: elementName ?? this.elementName,
      detail: detail ?? this.detail,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'date': date,
        'plannedM3': plannedM3,
        'actualM3': actualM3,
        'reason': reason,
        'elementName': elementName,
        'detail': detail,
      };

  factory MetrajVarianceNote.fromJson(Map<String, dynamic> json) =>
      MetrajVarianceNote(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        date: json['date'] as String? ?? '',
        plannedM3: (json['plannedM3'] as num?)?.toDouble() ?? 0,
        actualM3: (json['actualM3'] as num?)?.toDouble() ?? 0,
        reason: json['reason'] as String? ?? '',
        elementName: json['elementName'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
      );

  @override
  List<Object?> get props =>
      [id, projectId, date, plannedM3, actualM3, reason, elementName, detail];
}
