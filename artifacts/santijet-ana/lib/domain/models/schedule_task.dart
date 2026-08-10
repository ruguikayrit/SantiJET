import 'package:equatable/equatable.dart';

class ScheduleTask extends Equatable {
  const ScheduleTask({
    required this.id,
    required this.projectId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.status,
    required this.responsible,
  });

  final String id;
  final String projectId;
  final String name;
  final String startDate;
  final String endDate;
  final double progress;
  final String status; // planned | in_progress | completed | delayed
  final String responsible;

  ScheduleTask copyWith({
    String? id,
    String? projectId,
    String? name,
    String? startDate,
    String? endDate,
    double? progress,
    String? status,
    String? responsible,
  }) {
    return ScheduleTask(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      responsible: responsible ?? this.responsible,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'startDate': startDate,
        'endDate': endDate,
        'progress': progress,
        'status': status,
        'responsible': responsible,
      };

  factory ScheduleTask.fromJson(Map<String, dynamic> json) {
    return ScheduleTask(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'planned',
      responsible: json['responsible']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [id, projectId, name, startDate, endDate, progress, status, responsible];
}
