import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/utils/id_gen.dart';
import '../../core/utils/puantaj_date.dart';
import '../../domain/catalogs/task_categories.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/site_task.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/permissions/role_degree.dart';
import 'active_operator_provider.dart';
import 'app_data_provider.dart';
import 'catalog_provider.dart';

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

  /// Tamamlanınca gerçek teslim tarihi yazar; diğer durumlarda temizler.
  static SiteTask applyStatus(SiteTask task, TaskStatus status) {
    final actual = status == TaskStatus.done
        ? (task.actualDeliveryDate.trim().isNotEmpty
            ? task.actualDeliveryDate.trim()
            : PuantajDate.today())
        : '';
    return task.copyWith(
      status: status,
      actualDeliveryDate: actual,
      updatedAt: DateTime.now(),
    );
  }

  SiteTask add({
    required String projectId,
    required String title,
    required Person assigner,
    required Person assignee,
    String description = '',
    String category = '',
    String earliestStart = '',
    String dueDate = '',
    TaskStatus status = TaskStatus.todo,
    List<TaskPhoto> photos = const [],
  }) {
    if (!RoleDegree.canAssignTasks(assigner)) {
      throw StateError('Yalnızca 1. derece roller görev atayabilir.');
    }
    final now = DateTime.now();
    var task = SiteTask(
      id: IdGen.make('tsk'),
      projectId: projectId,
      title: title.trim(),
      description: description.trim(),
      category: category.trim(),
      assignee: assignee.name.trim(),
      assigneePersonId: assignee.id,
      assignerPersonId: assigner.id,
      assignerName: assigner.name.trim(),
      earliestStart: earliestStart.trim(),
      dueDate: dueDate.trim(),
      status: status,
      photos: List<TaskPhoto>.from(photos),
      createdAt: now,
      updatedAt: now,
    );
    task = applyStatus(task, status);
    state = [...state, task];
    _persist();
    return task;
  }

  SiteTask upsert(SiteTask task) {
    final now = DateTime.now();
    final idx = state.indexWhere((t) => t.id == task.id);
    final prev = idx >= 0 ? state[idx] : null;
    var next = task.copyWith(updatedAt: now);
    if (next.status == TaskStatus.done) {
      final existing = next.actualDeliveryDate.trim().isNotEmpty
          ? next.actualDeliveryDate.trim()
          : (prev?.actualDeliveryDate.trim() ?? '');
      next = next.copyWith(
        actualDeliveryDate:
            existing.isNotEmpty ? existing : PuantajDate.today(),
      );
    } else {
      next = next.copyWith(actualDeliveryDate: '');
    }
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
        if (i == idx) applyStatus(state[i], status) else state[i],
    ];
    _persist();
  }

  void delete(String id) {
    state = state.where((t) => t.id != id).toList();
    _persist();
  }

  /// Katalog yeniden adlandırıldığında görevlerdeki kategori etiketini günceller.
  int reassignCategory(String from, String to) {
    final oldName = from.trim();
    final newName = to.trim();
    if (oldName.isEmpty || newName.isEmpty || oldName == newName) return 0;
    final now = DateTime.now();
    var count = 0;
    final next = <SiteTask>[];
    for (final t in state) {
      if (t.category.trim() == oldName) {
        next.add(t.copyWith(category: newName, updatedAt: now));
        count++;
      } else {
        next.add(t);
      }
    }
    if (count == 0) return 0;
    state = next;
    _persist();
    return count;
  }

  /// Katalogdan silinen kategoriyi görevlerden temizler.
  int clearCategory(String name) {
    final target = name.trim();
    if (target.isEmpty) return 0;
    final now = DateTime.now();
    var count = 0;
    final next = <SiteTask>[];
    for (final t in state) {
      if (t.category.trim() == target) {
        next.add(t.copyWith(category: '', updatedAt: now));
        count++;
      } else {
        next.add(t);
      }
    }
    if (count == 0) return 0;
    state = next;
    _persist();
    return count;
  }

  void deleteForProject(String projectId) {
    state = state.where((t) => t.projectId != projectId).toList();
    _persist();
  }

  void replaceAll(List<SiteTask> items) {
    state = List<SiteTask>.from(items);
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
      // Yapılacak → Devam → Tamamlandı (tamamlananlar en altta).
      final byStatus = a.status.index.compareTo(b.status.index);
      if (byStatus != 0) return byStatus;
      return (b.updatedAt ?? b.createdAt ?? DateTime(1970))
          .compareTo(a.updatedAt ?? a.createdAt ?? DateTime(1970));
    });
  return list;
});

/// Ana sayfa — teslimatı 7 gün içinde (veya gecikmiş) açık görevler, aciliyet sırası.
final upcomingUrgentTasksProvider = Provider<List<SiteTask>>((ref) {
  final tasks = ref.watch(visibleProjectTasksProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekEnd = today.add(const Duration(days: 7));

  final list = tasks.where((t) {
    if (t.status == TaskStatus.done) return false;
    final due = t.latestDeliveryDate;
    if (due == null) return false;
    final day = DateTime(due.year, due.month, due.day);
    return !day.isAfter(weekEnd);
  }).toList()
    ..sort((a, b) {
      final da = a.latestDeliveryDate!;
      final db = b.latestDeliveryDate!;
      final byDue = DateTime(da.year, da.month, da.day)
          .compareTo(DateTime(db.year, db.month, db.day));
      if (byDue != 0) return byDue;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
  return list;
});

/// Acil görevler — kategori başına adet (katalog sırası + özel kategoriler).
typedef UrgentTaskCategorySummary = ({String category, int count});

final urgentTaskCategorySummariesProvider =
    Provider<List<UrgentTaskCategorySummary>>((ref) {
  final urgent = ref.watch(upcomingUrgentTasksProvider);
  final catalog = ref.watch(taskCategoriesProvider);

  final counts = <String, int>{};
  for (final t in urgent) {
    final cat = t.category.trim().isEmpty
        ? TaskCategoryCatalog.uncategorized
        : t.category.trim();
    counts[cat] = (counts[cat] ?? 0) + 1;
  }
  if (counts.isEmpty) return const [];

  final ordered = <UrgentTaskCategorySummary>[];
  for (final c in catalog) {
    final n = counts.remove(c);
    if (n != null) ordered.add((category: c, count: n));
  }
  final rest = counts.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  for (final e in rest) {
    ordered.add((category: e.key, count: e.value));
  }
  return ordered;
});
