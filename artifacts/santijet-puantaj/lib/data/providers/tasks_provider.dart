import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/utils/id_gen.dart';
import '../../core/utils/puantaj_date.dart';
import '../../domain/catalogs/task_categories.dart';
import '../../domain/catalogs/task_tags.dart';
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

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

bool _isBeforeToday(String dateTr) {
  final d = PuantajDate.tryParse(dateTr);
  if (d == null) return false;
  final day = DateTime(d.year, d.month, d.day);
  return day.isBefore(_today());
}

class TasksNotifier extends StateNotifier<List<SiteTask>> {
  TasksNotifier(this._box) : super(_loadAndPromote(_box));

  final Box _box;
  static const _key = 'items';

  static List<SiteTask> _loadAndPromote(Box box) {
    final loaded =
        _readList(box, _key).map(SiteTask.fromJson).toList(growable: false);
    final promoted = _promoteStartedTasks(loaded);
    final changed = promoted.length != loaded.length ||
        List.generate(loaded.length, (i) => loaded[i] != promoted[i])
            .any((e) => e);
    if (changed) {
      _writeList(box, _key, promoted.map((e) => e.toJson()).toList());
    }
    return List<SiteTask>.from(promoted);
  }

  /// Başlandı + gerçekleşen başlangıç dünden önceyse → Devam ediyor.
  static List<SiteTask> _promoteStartedTasks(List<SiteTask> items) {
    final now = DateTime.now();
    return [
      for (final t in items)
        if (t.status == TaskStatus.started &&
            (t.actualStartDate.trim().isEmpty ||
                _isBeforeToday(t.actualStartDate)))
          t.copyWith(
            status: TaskStatus.doing,
            updatedAt: now,
          )
        else
          t,
    ];
  }

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  void _replace(String id, SiteTask next) {
    state = [
      for (final t in state)
        if (t.id == id) next else t,
    ];
    _persist();
  }

  /// Durum + gerçekleşen tarihleri uygular; onay kuyruğunu temizler.
  static SiteTask applyStatusChange(
    SiteTask task, {
    required TaskStatus status,
    String? actualStartDate,
    String? actualDeliveryDate,
  }) {
    final now = DateTime.now();
    var next = task.clearPending().copyWith(
          status: status,
          updatedAt: now,
        );

    if (status == TaskStatus.todo) {
      next = next.copyWith(
        actualStartDate: '',
        actualDeliveryDate: '',
      );
    } else if (status == TaskStatus.started) {
      final start = (actualStartDate ?? '').trim().isNotEmpty
          ? actualStartDate!.trim()
          : PuantajDate.today();
      next = next.copyWith(
        actualStartDate: start,
        actualDeliveryDate: '',
      );
      if (_isBeforeToday(start)) {
        next = next.copyWith(status: TaskStatus.doing);
      }
    } else if (status == TaskStatus.doing) {
      next = next.copyWith(actualDeliveryDate: '');
      // Başlangıç yoksa bugünü yaz (manuel Devam — nadir; sıra started→doing).
      if (next.actualStartDate.trim().isEmpty) {
        next = next.copyWith(actualStartDate: PuantajDate.today());
      }
    } else if (status == TaskStatus.done) {
      final end = (actualDeliveryDate ?? '').trim().isNotEmpty
          ? actualDeliveryDate!.trim()
          : PuantajDate.today();
      next = next.copyWith(actualDeliveryDate: end);
      if (next.actualStartDate.trim().isEmpty) {
        next = next.copyWith(actualStartDate: end);
      }
    }
    return next;
  }

  SiteTask add({
    required String projectId,
    required String title,
    required Person assigner,
    required Person assignee,
    String description = '',
    required String category,
    required String tag,
    String earliestStart = '',
    String dueDate = '',
    List<TaskPhoto> photos = const [],
  }) {
    if (!RoleDegree.canAssignTasks(assigner)) {
      throw StateError('Yalnızca 1. derece roller görev atayabilir.');
    }
    final cat = category.trim();
    final normalizedTag = TaskTagCatalog.normalize(tag);
    if (cat.isEmpty) {
      throw ArgumentError('Görev kategorisi zorunludur.');
    }
    if (normalizedTag.isEmpty || !TaskTagCatalog.isKnown(normalizedTag)) {
      throw ArgumentError('Görev etiketi zorunludur (İnşaat / Elektrik / Mekanik).');
    }
    final now = DateTime.now();
    final task = SiteTask(
      id: IdGen.make('tsk'),
      projectId: projectId,
      title: title.trim(),
      description: description.trim(),
      category: cat,
      tag: normalizedTag,
      assignee: assignee.name.trim(),
      assigneePersonId: assignee.id,
      assignerPersonId: assigner.id,
      assignerName: assigner.name.trim(),
      earliestStart: earliestStart.trim(),
      dueDate: dueDate.trim(),
      status: TaskStatus.todo,
      photos: List<TaskPhoto>.from(photos),
      createdAt: now,
      updatedAt: now,
    );
    state = [...state, task];
    _persist();
    return task;
  }

  SiteTask upsert(SiteTask task) {
    final cat = task.category.trim();
    final normalizedTag = TaskTagCatalog.normalize(task.tag);
    if (cat.isEmpty) {
      throw ArgumentError('Görev kategorisi zorunludur.');
    }
    if (normalizedTag.isEmpty || !TaskTagCatalog.isKnown(normalizedTag)) {
      throw ArgumentError('Görev etiketi zorunludur (İnşaat / Elektrik / Mekanik).');
    }
    final now = DateTime.now();
    final idx = state.indexWhere((t) => t.id == task.id);
    final next = task.copyWith(
      category: cat,
      tag: normalizedTag,
      updatedAt: now,
    );
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

  /// Atayan: doğrudan uygular. Atanan: onay kuyruğuna yazar.
  /// Dönüş: `applied` | `pending` | `rejected` (geçiş yasak / tarih yok).
  String applyOrRequestStatus({
    required String id,
    required TaskStatus status,
    required Person actor,
    String? actualStartDate,
    String? actualDeliveryDate,
  }) {
    final idx = state.indexWhere((t) => t.id == id);
    if (idx < 0) return 'rejected';
    final task = state[idx];
    if (!TaskStatusRules.canTransition(task.status, status)) {
      return 'rejected';
    }
    if (TaskStatusRules.needsActualDate(status)) {
      final date = status == TaskStatus.started
          ? (actualStartDate ?? '').trim()
          : (actualDeliveryDate ?? '').trim();
      if (date.isEmpty) return 'rejected';
    }

    final isAssigner = task.isAssigner(actor);
    final isAssignee = task.isAssignee(actor);
    if (!isAssigner && !isAssignee) return 'rejected';

    if (isAssigner) {
      _replace(
        id,
        applyStatusChange(
          task,
          status: status,
          actualStartDate: actualStartDate,
          actualDeliveryDate: actualDeliveryDate,
        ),
      );
      return 'applied';
    }

    // Yalnız atanan → onay bekler.
    final pending = task.copyWith(
      pendingStatusRaw: status.storage,
      pendingActualStartDate: (actualStartDate ?? '').trim(),
      pendingActualDeliveryDate: (actualDeliveryDate ?? '').trim(),
      updatedAt: DateTime.now(),
    );
    _replace(id, pending);
    return 'pending';
  }

  bool approvePending({required String id, required Person actor}) {
    final idx = state.indexWhere((t) => t.id == id);
    if (idx < 0) return false;
    final task = state[idx];
    if (!task.isAssigner(actor)) return false;
    final pending = task.pendingStatus;
    if (pending == null) return false;
    if (!TaskStatusRules.canTransition(task.status, pending)) {
      _replace(id, task.clearPending());
      return false;
    }
    _replace(
      id,
      applyStatusChange(
        task,
        status: pending,
        actualStartDate: task.pendingActualStartDate,
        actualDeliveryDate: task.pendingActualDeliveryDate,
      ),
    );
    return true;
  }

  bool rejectPending({required String id, required Person actor}) {
    final idx = state.indexWhere((t) => t.id == id);
    if (idx < 0) return false;
    final task = state[idx];
    if (!task.isAssigner(actor)) return false;
    if (!task.hasPendingStatusChange) return false;
    _replace(id, task.clearPending().copyWith(updatedAt: DateTime.now()));
    return true;
  }

  @Deprecated('applyOrRequestStatus kullanın')
  void setStatus(String id, TaskStatus status) {
    final idx = state.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    if (!TaskStatusRules.canTransition(state[idx].status, status)) return;
    _replace(id, applyStatusChange(state[idx], status: status));
  }

  void delete(String id) {
    state = state.where((t) => t.id != id).toList();
    _persist();
  }

  int reassignCategory(String from, String to) {
    final oldName = from.trim();
    final newName = to.trim();
    if (oldName.isEmpty || newName.isEmpty || oldName == newName) return 0;
    final oldKey = oldName.toLowerCase();
    final now = DateTime.now();
    var count = 0;
    final next = <SiteTask>[];
    for (final t in state) {
      if (t.category.trim().toLowerCase() == oldKey) {
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

  int clearCategory(String name) {
    final target = name.trim();
    if (target.isEmpty) return 0;
    final now = DateTime.now();
    var count = 0;
    final next = <SiteTask>[];
    for (final t in state) {
      if (t.category.trim() == target) {
        next.add(t.copyWith(category: 'Saha', updatedAt: now));
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
    state = _promoteStartedTasks(List<SiteTask>.from(items));
    _persist();
  }
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, List<SiteTask>>((ref) {
  return TasksNotifier(ref.watch(tasksBoxProvider));
});

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

typedef UrgentTaskTagSummary = ({String tag, int count});

final urgentTaskTagSummariesProvider =
    Provider<List<UrgentTaskTagSummary>>((ref) {
  final urgent = ref.watch(upcomingUrgentTasksProvider);
  final counts = {for (final t in TaskTagCatalog.all) t: 0};
  for (final task in urgent) {
    final tag = TaskTagCatalog.normalize(task.tag);
    if (tag.isNotEmpty && counts.containsKey(tag)) {
      counts[tag] = counts[tag]! + 1;
    }
  }
  return [
    for (final tag in TaskTagCatalog.all) (tag: tag, count: counts[tag]!),
  ];
});
