import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/utils/id_gen.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/site_task.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/permissions/role_degree.dart';
import 'active_operator_provider.dart';
import 'app_data_provider.dart';

final tasksBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('tasksBoxProvider override edilmeli'),
);

List<Map<String, dynamic>> _readList(Box box, String key) {
  final raw = box.get(key);
  if (raw is String && raw.isNotEmpty) {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }
  if (raw is List) {
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
}

void _writeList(Box box, String key, List<Map<String, dynamic>> items) {
  box.put(key, jsonEncode(items));
}

class TasksNotifier extends StateNotifier<List<SiteTask>> {
  TasksNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<SiteTask> _load(Box box) =>
      _readList(box, _key).map(SiteTask.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  SiteTask add({
    required String projectId,
    required String title,
    required Person assigner,
    required Person assignee,
    String description = '',
    String dueDate = '',
    TaskStatus status = TaskStatus.todo,
  }) {
    if (!RoleDegree.canAssignTasks(assigner)) {
      throw StateError('Yalnızca 1. derece roller görev atayabilir.');
    }
    final now = DateTime.now();
    final task = SiteTask(
      id: IdGen.make('tsk'),
      projectId: projectId,
      title: title.trim(),
      description: description.trim(),
      assignee: assignee.name.trim(),
      assigneePersonId: assignee.id,
      assignerPersonId: assigner.id,
      assignerName: assigner.name.trim(),
      dueDate: dueDate.trim(),
      status: status,
      createdAt: now,
      updatedAt: now,
    );
    state = [...state, task];
    _persist();
    return task;
  }

  SiteTask upsert(SiteTask task) {
    final now = DateTime.now();
    final next = task.copyWith(updatedAt: now);
    final idx = state.indexWhere((t) => t.id == next.id);
    if (idx >= 0) {
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == idx) next else state[i],
      ];
    } else {
      state = [...state, next.copyWith(createdAt: next.createdAt ?? now)];
    }
    _persist();
    return next;
  }

  void setStatus(String id, TaskStatus status) {
    final idx = state.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == idx)
          state[i].copyWith(status: status, updatedAt: DateTime.now())
        else
          state[i],
    ];
    _persist();
  }

  void delete(String id) {
    state = state.where((t) => t.id != id).toList();
    _persist();
  }

  void deleteForProject(String projectId) {
    state = state.where((t) => t.projectId != projectId).toList();
    _persist();
  }
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, List<SiteTask>>((ref) {
  return TasksNotifier(ref.watch(tasksBoxProvider));
});

/// Aktif operatörün görebileceği görevler (atanan veya atayan).
final visibleProjectTasksProvider = Provider<List<SiteTask>>((ref) {
  final project = ref.watch(activeProjectProvider);
  final operator = ref.watch(activeOperatorProvider);
  final tasks = ref.watch(tasksProvider);
  if (project == null || operator == null) return const [];

  final list = tasks
      .where(
        (t) => t.projectId == project.id && t.isVisibleTo(operator),
      )
      .toList()
    ..sort((a, b) {
      final byStatus = a.status.index.compareTo(b.status.index);
      if (byStatus != 0) return byStatus;
      return (b.updatedAt ?? b.createdAt ?? DateTime(1970))
          .compareTo(a.updatedAt ?? a.createdAt ?? DateTime(1970));
    });
  return list;
});
