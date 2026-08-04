import 'package:equatable/equatable.dart';

import '../enums/task_status.dart';
import '../permissions/role_degree.dart';
import 'person.dart';

/// Proje kapsamındaki saha görevi — atayan + atanan görünür.
class SiteTask extends Equatable {
  const SiteTask({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.assignee = '',
    this.assigneePersonId = '',
    this.assignerPersonId = '',
    this.assignerName = '',
    this.dueDate = '',
    this.status = TaskStatus.todo,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;

  /// Atanan personel görünen adı (önbellek).
  final String assignee;

  /// Atanan personel id — görünürlük için zorunlu.
  final String assigneePersonId;

  /// Görevi oluşturup atayan 1. derece personel id.
  final String assignerPersonId;

  /// Atayan görünen adı (önbellek).
  final String assignerName;

  /// TR tarih: `dd.MM.yyyy` (boş olabilir).
  final String dueDate;
  final TaskStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Görüntüleyen yalnızca atayan veya atanan ise görür.
  /// Eski kayıtlarda id yoksa yalnızca 1. derece görür (yeniden atama için).
  bool isVisibleTo(Person viewer) {
    if (assigneePersonId.isNotEmpty || assignerPersonId.isNotEmpty) {
      return viewer.id == assigneePersonId || viewer.id == assignerPersonId;
    }
    return RoleDegree.isFirstDegree(viewer);
  }

  SiteTask copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? assignee,
    String? assigneePersonId,
    String? assignerPersonId,
    String? assignerName,
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
      assigneePersonId: assigneePersonId ?? this.assigneePersonId,
      assignerPersonId: assignerPersonId ?? this.assignerPersonId,
      assignerName: assignerName ?? this.assignerName,
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
        'assigneePersonId': assigneePersonId,
        'assignerPersonId': assignerPersonId,
        'assignerName': assignerName,
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
        assigneePersonId: json['assigneePersonId'] as String? ?? '',
        assignerPersonId: json['assignerPersonId'] as String? ?? '',
        assignerName: json['assignerName'] as String? ?? '',
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
        assigneePersonId,
        assignerPersonId,
        assignerName,
        dueDate,
        status,
        createdAt,
        updatedAt,
      ];
}
