import 'package:equatable/equatable.dart';

class DailyReport extends Equatable {
  const DailyReport({
    required this.id,
    required this.projectId,
    required this.date,
    required this.weather,
    required this.temperature,
    required this.workerCount,
    required this.activities,
    required this.issues,
    required this.createdBy,
  });

  final String id;
  final String projectId;
  final String date;
  final String weather;
  final String temperature;
  final int workerCount;
  final String activities;
  final String issues;
  final String createdBy;

  DailyReport copyWith({
    String? id,
    String? projectId,
    String? date,
    String? weather,
    String? temperature,
    int? workerCount,
    String? activities,
    String? issues,
    String? createdBy,
  }) {
    return DailyReport(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      weather: weather ?? this.weather,
      temperature: temperature ?? this.temperature,
      workerCount: workerCount ?? this.workerCount,
      activities: activities ?? this.activities,
      issues: issues ?? this.issues,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'date': date,
        'weather': weather,
        'temperature': temperature,
        'workerCount': workerCount,
        'activities': activities,
        'issues': issues,
        'createdBy': createdBy,
      };

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      weather: json['weather']?.toString() ?? '',
      temperature: json['temperature']?.toString() ?? '',
      workerCount: (json['workerCount'] as num?)?.toInt() ?? 0,
      activities: json['activities']?.toString() ?? '',
      issues: json['issues']?.toString() ?? '',
      createdBy: json['createdBy']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        date,
        weather,
        temperature,
        workerCount,
        activities,
        issues,
        createdBy,
      ];
}
