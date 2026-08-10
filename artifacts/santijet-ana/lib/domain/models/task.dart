import 'package:equatable/equatable.dart';

class Task extends Equatable {
  const Task({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.assignee,
    required this.deadline,
    required this.priority,
    required this.status,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final String assignee;
  final String deadline;
  final String priority; // low | medium | high
  final String status; // open | in_progress | done

  Task copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? assignee,
    String? deadline,
    String? priority,
    String? status,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'description': description,
        'assignee': assignee,
        'deadline': deadline,
        'priority': priority,
        'status': status,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      assignee: json['assignee']?.toString() ?? '',
      deadline: json['deadline']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'open',
    );
  }

  @override
  List<Object?> get props =>
      [id, projectId, title, description, assignee, deadline, priority, status];
}
