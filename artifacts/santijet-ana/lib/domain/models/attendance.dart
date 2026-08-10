import 'package:equatable/equatable.dart';

class Attendance extends Equatable {
  const Attendance({
    required this.id,
    required this.projectId,
    required this.workerId,
    required this.workerName,
    required this.date,
    required this.status,
    required this.hours,
    required this.note,
  });

  final String id;
  final String projectId;
  final String workerId;
  final String workerName;
  final String date;
  final String status; // present | absent | half | izinli | raporlu | mazeret | tatil
  final double hours;
  final String note;

  Attendance copyWith({
    String? id,
    String? projectId,
    String? workerId,
    String? workerName,
    String? date,
    String? status,
    double? hours,
    String? note,
  }) {
    return Attendance(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      date: date ?? this.date,
      status: status ?? this.status,
      hours: hours ?? this.hours,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'workerId': workerId,
        'workerName': workerName,
        'date': date,
        'status': status,
        'hours': hours,
        'note': note,
      };

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      workerId: json['workerId']?.toString() ?? '',
      workerName: json['workerName']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'present',
      hours: (json['hours'] as num?)?.toDouble() ?? 0,
      note: json['note']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [id, projectId, workerId, workerName, date, status, hours, note];
}
