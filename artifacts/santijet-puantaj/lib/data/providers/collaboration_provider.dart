import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/attendance.dart';
import '../../domain/entities/daily_report.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/production.dart';
import '../../domain/entities/project_member.dart';
import '../../domain/entities/site_task.dart';
import '../../domain/enums/project_role.dart';
import '../remote/supabase_project_sync.dart';
import '../remote/supabase_saha_sync.dart';
import '../remote/supabase_service.dart';
import 'app_data_provider.dart';
import 'auth_provider.dart';
import 'daily_report_provider.dart';
import 'production_provider.dart';
import 'tasks_provider.dart';

final membersBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('membersBoxProvider override edilmeli'),
);

final supabaseProjectSyncProvider = Provider<SupabaseProjectSync>((ref) {
  return SupabaseProjectSync();
});

final supabaseSahaSyncProvider = Provider<SupabaseSahaSync>((ref) {
  return SupabaseSahaSync();
});

class ProjectMembersNotifier extends StateNotifier<List<ProjectMember>> {
  ProjectMembersNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<ProjectMember> _load(Box box) {
    final raw = box.get(_key);
    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .cast<Map>()
            .map((e) => ProjectMember.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    if (raw is List) {
      return raw
          .map(
            (e) => ProjectMember.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    }
    return [];
  }

  void _persist() {
    _box.put(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  void upsert(ProjectMember member) {
    final exists = state.any(
      (m) => m.projectId == member.projectId && m.userId == member.userId,
    );
    if (exists) {
      state = [
        for (final m in state)
          if (m.projectId == member.projectId && m.userId == member.userId)
            member
          else
            m,
      ];
    } else {
      state = [...state, member];
    }
    _persist();
  }

  void merge(Iterable<ProjectMember> members) {
    final map = {
      for (final m in state) '${m.projectId}|${m.userId}': m,
    };
    for (final m in members) {
      map['${m.projectId}|${m.userId}'] = m;
    }
    state = map.values.toList();
    _persist();
  }

  void deleteForProject(String projectId) {
    state = state.where((m) => m.projectId != projectId).toList();
    _persist();
  }

  void setCanEdit({
    required String projectId,
    required String memberUserId,
    required bool canEdit,
  }) {
    state = [
      for (final m in state)
        if (m.projectId == projectId && m.userId == memberUserId)
          m.copyWith(
            canEdit: canEdit,
            role: canEdit ? ProjectRole.editor : ProjectRole.viewer,
          )
        else
          m,
    ];
    _persist();
  }
}

final projectMembersListProvider =
    StateNotifierProvider<ProjectMembersNotifier, List<ProjectMember>>((ref) {
  return ProjectMembersNotifier(ref.watch(membersBoxProvider));
});

final projectMembersProvider =
    Provider.family<List<ProjectMember>, String>((ref, projectId) {
  return ref
      .watch(projectMembersListProvider)
      .where((m) => m.projectId == projectId)
      .toList();
});

final activeProjectMembershipProvider = Provider<ProjectMember?>((ref) {
  final auth = ref.watch(authProvider);
  final projectId = ref.watch(activeProjectIdProvider);
  final userId = auth.user?.id;
  if (projectId == null || userId == null) return null;
  final members = ref.watch(projectMembersProvider(projectId));
  for (final m in members) {
    if (m.userId == userId) return m;
  }
  return null;
});

/// Üyelik kaydı varsa rol yetkisi geçerlidir.
/// Üyelik yoksa (yalnızca bu cihazda açılmış iş) tam düzenleme.
final canEditActiveProjectProvider = Provider<bool>((ref) {
  final project = ref.watch(activeProjectProvider);
  if (project == null) return false;

  final membership = ref.watch(activeProjectMembershipProvider);
  if (membership != null) {
    return membership.canEdit || membership.isOwner;
  }

  final userId = ref.watch(authProvider.select((a) => a.user?.id));
  if (userId != null && project.ownerId == userId) return true;

  return true;
});

final collaborationControllerProvider =
    Provider<CollaborationController>((ref) => CollaborationController(ref));

class CollaborationController {
  CollaborationController(this._ref);

  final Ref _ref;

  Future<SupabaseProjectSync?> _projectSync() async {
    if (!SupabaseService.isConfigured) return null;
    await SupabaseService.waitUntilReady(timeout: const Duration(seconds: 10));
    if (!SupabaseService.isReady) return null;
    return _ref.read(supabaseProjectSyncProvider);
  }

  bool _canEditProject(String projectId) {
    final user = _ref.read(authProvider).user;
    final projects = _ref.read(projectsProvider);
    ProjectMember? mine;
    for (final m in _ref.read(projectMembersProvider(projectId))) {
      if (user != null && m.userId == user.id) {
        mine = m;
        break;
      }
    }
    for (final p in projects) {
      if (p.id != projectId) continue;
      if (!p.isShared) return true;
      if (mine?.canEdit == true) return true;
      if (user != null && p.ownerId == user.id) return true;
      return false;
    }
    return false;
  }

  Future<void> pullMyProjects() async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    final sync = await _projectSync();
    if (sync == null) return;

    final rows = await sync.pullUserProjects(user.id);
    if (rows.isEmpty) return;

    _ref.read(projectsProvider.notifier).mergeProjects(rows.map((e) => e.$1));
    _ref.read(projectMembersListProvider.notifier).merge(rows.map((e) => e.$2));

    for (final (project, _) in rows) {
      await pullDomain(project.id);
    }
  }

  Future<void> refreshMembers(String projectId) async {
    final sync = await _projectSync();
    if (sync == null) return;
    final members = await sync.fetchMembers(projectId);
    _ref.read(projectMembersListProvider.notifier).merge(members);
  }

  Future<void> setMemberCanEdit({
    required String projectId,
    required String memberUserId,
    required bool canEdit,
  }) async {
    final sync = await _projectSync();
    if (sync != null) {
      await sync.updateMemberPermissions(
        projectId: projectId,
        memberUserId: memberUserId,
        canEdit: canEdit,
      );
    }
    _ref.read(projectMembersListProvider.notifier).setCanEdit(
          projectId: projectId,
          memberUserId: memberUserId,
          canEdit: canEdit,
        );
  }

  Future<void> pullDomain(String projectId) async {
    if (!SupabaseService.isReady) return;
    final snapshots =
        await _ref.read(supabaseSahaSyncProvider).pullSnapshots(projectId);

    _mergePersonnel(projectId, snapshots['personnel']);
    _mergeAttendance(projectId, snapshots['attendance']);
    _mergeProduction(projectId, snapshots['production']);
    _mergeTasks(projectId, snapshots['tasks']);
    _mergeDailyReports(projectId, snapshots['daily_reports']);
  }

  Future<void> pushDomain(String projectId) async {
    final user = _ref.read(authProvider).user;
    if (user == null || !SupabaseService.isReady) return;
    if (!_canEditProject(projectId)) return;

    final personnel = _ref
        .read(personnelProvider)
        .where((p) => p.projectId == projectId)
        .map((e) => e.toJson())
        .toList();
    final attendance = _ref
        .read(attendanceProvider)
        .where((a) => a.projectId == projectId)
        .map((e) => e.toJson())
        .toList();
    final production = _ref
        .read(productionProvider)
        .where((p) => p.projectId == projectId)
        .map((e) => e.toJson())
        .toList();
    final tasks = _ref
        .read(tasksProvider)
        .where((t) => t.projectId == projectId)
        .map((e) => e.toJson())
        .toList();
    final reports = _ref
        .read(dailyReportsProvider)
        .where((r) => r.projectId == projectId)
        .map((e) => e.toJson())
        .toList();

    await _ref.read(supabaseSahaSyncProvider).pushSnapshots(
      projectId: projectId,
      userId: user.id,
      byKind: {
        'personnel': personnel,
        'attendance': attendance,
        'production': production,
        'tasks': tasks,
        'daily_reports': reports,
      },
    );
  }

  void _mergePersonnel(String projectId, List<Map<String, dynamic>>? remote) {
    if (remote == null) return;
    final notifier = _ref.read(personnelProvider.notifier);
    final others =
        notifier.state.where((p) => p.projectId != projectId).toList();
    final imported = remote.map((e) {
      final map = Map<String, dynamic>.from(e)..['projectId'] = projectId;
      return Person.fromJson(map);
    }).toList();
    notifier.replaceAll([...others, ...imported]);
  }

  void _mergeAttendance(String projectId, List<Map<String, dynamic>>? remote) {
    if (remote == null) return;
    final notifier = _ref.read(attendanceProvider.notifier);
    final others =
        notifier.state.where((a) => a.projectId != projectId).toList();
    final imported = remote.map((e) {
      final map = Map<String, dynamic>.from(e)..['projectId'] = projectId;
      return Attendance.fromJson(map);
    }).toList();
    notifier.replaceAll([...others, ...imported]);
  }

  void _mergeProduction(String projectId, List<Map<String, dynamic>>? remote) {
    if (remote == null) return;
    final notifier = _ref.read(productionProvider.notifier);
    final others =
        notifier.state.where((p) => p.projectId != projectId).toList();
    final imported = remote.map((e) {
      final map = Map<String, dynamic>.from(e)..['projectId'] = projectId;
      return Production.fromJson(map);
    }).toList();
    notifier.replaceAll([...others, ...imported]);
  }

  void _mergeTasks(String projectId, List<Map<String, dynamic>>? remote) {
    if (remote == null) return;
    final notifier = _ref.read(tasksProvider.notifier);
    final others =
        notifier.state.where((t) => t.projectId != projectId).toList();
    final imported = remote.map((e) {
      final map = Map<String, dynamic>.from(e)..['projectId'] = projectId;
      return SiteTask.fromJson(map);
    }).toList();
    notifier.replaceAll([...others, ...imported]);
  }

  void _mergeDailyReports(
    String projectId,
    List<Map<String, dynamic>>? remote,
  ) {
    if (remote == null) return;
    final notifier = _ref.read(dailyReportsProvider.notifier);
    final others =
        notifier.state.where((r) => r.projectId != projectId).toList();
    final imported = remote.map((e) {
      final map = Map<String, dynamic>.from(e)..['projectId'] = projectId;
      return DailyReport.fromJson(map);
    }).toList();
    notifier.replaceAll([...others, ...imported]);
  }
}
