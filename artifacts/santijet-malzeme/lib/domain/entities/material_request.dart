import 'package:equatable/equatable.dart';

import '../enums/request_status.dart';
import 'material_request_line.dart';

/// Hive typeId plan: 4
class MaterialRequest extends Equatable {
  const MaterialRequest({
    required this.id,
    required this.projectId,
    required this.title,
    this.kesifSnapshotId,
    this.status = RequestStatus.taslak,
    this.createdAt,
    this.notes = '',
    this.lines = const [],
  });

  final String id;
  final String projectId;
  final String title;
  final String? kesifSnapshotId;
  final RequestStatus status;
  final DateTime? createdAt;
  final String notes;
  final List<MaterialRequestLine> lines;

  MaterialRequest copyWith({
    String? id,
    String? projectId,
    String? title,
    String? kesifSnapshotId,
    RequestStatus? status,
    DateTime? createdAt,
    String? notes,
    List<MaterialRequestLine>? lines,
  }) {
    return MaterialRequest(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      kesifSnapshotId: kesifSnapshotId ?? this.kesifSnapshotId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      lines: lines ?? this.lines,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'kesifSnapshotId': kesifSnapshotId,
        'status': status.name,
        'createdAt': createdAt?.toIso8601String(),
        'notes': notes,
        'lines': lines.map((e) => e.toJson()).toList(),
      };

  factory MaterialRequest.fromJson(Map<String, dynamic> json) =>
      MaterialRequest(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        kesifSnapshotId: json['kesifSnapshotId'] as String?,
        status: RequestStatus.tryParse(json['status'] as String?) ??
            RequestStatus.taslak,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        notes: json['notes'] as String? ?? '',
        lines: (json['lines'] as List? ?? const [])
            .map(
              (e) => MaterialRequestLine.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        title,
        kesifSnapshotId,
        status,
        createdAt,
        notes,
        lines,
      ];
}
