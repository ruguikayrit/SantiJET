import 'package:equatable/equatable.dart';

import '../enums/task_status.dart';

/// Proje kapsamındaki saha görevi.
class SiteTask extends Equatable {
  const SiteTask({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.assignee = '',
    this.dueDate = '',
    this.status = TaskStatus.todo,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final String assignee;

  /// TR tarih: `dd.MM.yyyy` (boş olabilir).
  final String dueDate;
  final TaskStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SiteTask copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? assignee,
    String? dueDate,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SiteTask(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'description': description,
        'assignee': assignee,
        'dueDate': dueDate,
        'status': status.storage,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory SiteTask.fromJson(Map<String, dynamic> json) => SiteTask(
        id: json['id'] as String? ?? '',
        projectId: json['projectId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        assignee: json['assignee'] as String? ?? '',
        dueDate: json['dueDate'] as String? ?? '',
        status: TaskStatus.fromStorage(json['status'] as String?),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        title,
        description,
        assignee,
        dueDate,
        status,
        createdAt,
        updatedAt,
      ];
}
