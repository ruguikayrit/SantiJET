import 'package:equatable/equatable.dart';

import '../enums/attendance_status.dart';

/// Günlük personel puantaj kaydı — santiye-takip `Attendance` ile birebir.
///
/// Mantıksal tekillik: `(projectId, personId, date)`.
class Attendance extends Equatable {
  const Attendance({
    required this.id,
    required this.projectId,
    required this.personId,
    required this.personName,
    required this.date,
    required this.status,
    required this.hours,
    this.note = '',
  });

  final String id;
  final String projectId;
  final String personId;
  final String personName;

  /// TR tarih: `dd.MM.yyyy`
  final String date;
  final AttendanceStatus status;
  final int hours;
  final String note;

  Attendance copyWith({
    String? id,
    String? projectId,
    String? personId,
    String? personName,
    String? date,
    AttendanceStatus? status,
    int? hours,
    String? note,
  }) {
    return Attendance(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      date: date ?? this.date,
      status: status ?? this.status,
      hours: hours ?? this.hours,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'personId': personId,
        'personName': personName,
        'date': date,
        'status': status.jsonValue,
        'hours': hours,
        'note': note,
      };

  factory Attendance.fromJson(Map<String, dynamic> json) {
    final status = AttendanceStatus.parse(json['status'] as String? ?? 'absent');
    return Attendance(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      personId: (json['personId'] ?? json['workerId']) as String,
      personName: (json['personName'] ?? json['workerName']) as String? ?? '',
      date: json['date'] as String,
      status: status,
      hours: (json['hours'] as num?)?.toInt() ?? status.hours,
      note: json['note'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [id, projectId, personId, personName, date, status, hours, note];
}
