import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../bootstrap.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/archive_file.dart';
import '../../domain/models/attendance.dart';
import '../../domain/models/budget_entry.dart';
import '../../domain/models/catalog_models.dart';
import '../../domain/models/daily_report.dart';
import '../../domain/models/hakedis.dart';
import '../../domain/models/material.dart';
import '../../domain/models/material_movement.dart';
import '../../domain/models/material_request.dart';
import '../../domain/models/page_key.dart';
import '../../domain/models/production.dart';
import '../../domain/models/project.dart';
import '../../domain/models/purchase.dart';
import '../../domain/models/role.dart';
import '../../domain/models/schedule_task.dart';
import '../../domain/models/subcontractor.dart';
import '../../domain/models/survey.dart';
import '../../domain/models/task.dart';
import '../../domain/models/weighbridge.dart';
import '../../domain/models/worker.dart';
import '../../domain/models/workspace_info.dart';
import '../services/workspace_api.dart';

const _stateKey = 'state_v1';
const _workspaceKey = 'santiye_workspace_v1';

String _genId() {
  final now = DateTime.now().millisecondsSinceEpoch;
  final r = Random().nextInt(1 << 32).toRadixString(36);
  return '$now$r';
}

class AppState {
  AppState({
    this.projects = const [],
    this.surveys = const [],
    this.scheduleTasks = const [],
    this.workers = const [],
    this.attendance = const [],
    this.dailyReports = const [],
    this.productions = const [],
    this.tasks = const [],
    this.materials = const [],
    this.materialRequests = const [],
    this.materialMovements = const [],
    this.subcontractors = const [],
    this.archiveFiles = const [],
    this.purchases = const [],
    this.weighbridges = const [],
    this.budget = const [],
    this.hakedisler = const [],
    List<Role>? roles,
    this.appUsers = const [],
    this.currentUserId,
    List<String>? materialCategories,
    List<ConstructionMaterial>? materialList,
    List<UnitOption>? materialUnits,
    this.imalatPozlari = const [],
    this.pozAnalizleri = const [],
    List<String>? professions,
    List<String>? tradeGroups,
    this.loaded = false,
    this.workspaceInfo,
    this.syncStatus = SyncStatus.idle,
    this.lastSyncAt,
  })  : roles = roles ?? Role.defaultRoles(),
        materialCategories =
            materialCategories ?? List.of(defaultMaterialCategories),
        materialList = materialList ?? const [],
        materialUnits = materialUnits ?? List.of(defaultMaterialUnits),
        professions = professions ?? List.of(defaultProfessions),
        tradeGroups = tradeGroups ?? List.of(defaultTradeGroups);

  final List<Project> projects;
  final List<Survey> surveys;
  final List<ScheduleTask> scheduleTasks;
  final List<Worker> workers;
  final List<Attendance> attendance;
  final List<DailyReport> dailyReports;
  final List<Production> productions;
  final List<Task> tasks;
  final List<Material> materials;
  final List<MaterialRequest> materialRequests;
  final List<MaterialMovement> materialMovements;
  final List<Subcontractor> subcontractors;
  final List<ArchiveFile> archiveFiles;
  final List<Purchase> purchases;
  final List<Weighbridge> weighbridges;
  final List<BudgetEntry> budget;
  final List<Hakedis> hakedisler;
  final List<Role> roles;
  final List<AppUser> appUsers;
  final String? currentUserId;
  final List<String> materialCategories;
  final List<ConstructionMaterial> materialList;
  final List<UnitOption> materialUnits;
  final List<ImalatPoz> imalatPozlari;
  final List<PozAnaliz> pozAnalizleri;
  final List<String> professions;
  final List<String> tradeGroups;
  final bool loaded;
  final WorkspaceInfo? workspaceInfo;
  final SyncStatus syncStatus;
  final String? lastSyncAt;

  AppUser? get currentAppUser {
    final id = currentUserId;
    if (id == null) return null;
    for (final u in appUsers) {
      if (u.id == id) return u;
    }
    return null;
  }

  Role? get currentRole {
    final user = currentAppUser;
    if (user == null) return null;
    for (final r in roles) {
      if (r.id == user.roleId) return r;
    }
    return null;
  }

  Permission getPermission(String pageKey) {
    final role = currentRole;
    if (role == null) return Permission.none;
    return role.permissionFor(pageKey);
  }

  AppState copyWith({
    List<Project>? projects,
    List<Survey>? surveys,
    List<ScheduleTask>? scheduleTasks,
    List<Worker>? workers,
    List<Attendance>? attendance,
    List<DailyReport>? dailyReports,
    List<Production>? productions,
    List<Task>? tasks,
    List<Material>? materials,
    List<MaterialRequest>? materialRequests,
    List<MaterialMovement>? materialMovements,
    List<Subcontractor>? subcontractors,
    List<ArchiveFile>? archiveFiles,
    List<Purchase>? purchases,
    List<Weighbridge>? weighbridges,
    List<BudgetEntry>? budget,
    List<Hakedis>? hakedisler,
    List<Role>? roles,
    List<AppUser>? appUsers,
    String? currentUserId,
    bool clearCurrentUserId = false,
    List<String>? materialCategories,
    List<ConstructionMaterial>? materialList,
    List<UnitOption>? materialUnits,
    List<ImalatPoz>? imalatPozlari,
    List<PozAnaliz>? pozAnalizleri,
    List<String>? professions,
    List<String>? tradeGroups,
    bool? loaded,
    WorkspaceInfo? workspaceInfo,
    bool clearWorkspace = false,
    SyncStatus? syncStatus,
    String? lastSyncAt,
  }) {
    return AppState(
      projects: projects ?? this.projects,
      surveys: surveys ?? this.surveys,
      scheduleTasks: scheduleTasks ?? this.scheduleTasks,
      workers: workers ?? this.workers,
      attendance: attendance ?? this.attendance,
      dailyReports: dailyReports ?? this.dailyReports,
      productions: productions ?? this.productions,
      tasks: tasks ?? this.tasks,
      materials: materials ?? this.materials,
      materialRequests: materialRequests ?? this.materialRequests,
      materialMovements: materialMovements ?? this.materialMovements,
      subcontractors: subcontractors ?? this.subcontractors,
      archiveFiles: archiveFiles ?? this.archiveFiles,
      purchases: purchases ?? this.purchases,
      weighbridges: weighbridges ?? this.weighbridges,
      budget: budget ?? this.budget,
      hakedisler: hakedisler ?? this.hakedisler,
      roles: roles ?? this.roles,
      appUsers: appUsers ?? this.appUsers,
      currentUserId:
          clearCurrentUserId ? null : (currentUserId ?? this.currentUserId),
      materialCategories: materialCategories ?? this.materialCategories,
      materialList: materialList ?? this.materialList,
      materialUnits: materialUnits ?? this.materialUnits,
      imalatPozlari: imalatPozlari ?? this.imalatPozlari,
      pozAnalizleri: pozAnalizleri ?? this.pozAnalizleri,
      professions: professions ?? this.professions,
      tradeGroups: tradeGroups ?? this.tradeGroups,
      loaded: loaded ?? this.loaded,
      workspaceInfo:
          clearWorkspace ? null : (workspaceInfo ?? this.workspaceInfo),
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'projects': projects.map((e) => e.toJson()).toList(),
        'surveys': surveys.map((e) => e.toJson()).toList(),
        'scheduleTasks': scheduleTasks.map((e) => e.toJson()).toList(),
        'workers': workers.map((e) => e.toJson()).toList(),
        'attendance': attendance.map((e) => e.toJson()).toList(),
        'dailyReports': dailyReports.map((e) => e.toJson()).toList(),
        'productions': productions.map((e) => e.toJson()).toList(),
        'tasks': tasks.map((e) => e.toJson()).toList(),
        'materials': materials.map((e) => e.toJson()).toList(),
        'materialRequests': materialRequests.map((e) => e.toJson()).toList(),
        'materialMovements': materialMovements.map((e) => e.toJson()).toList(),
        'subcontractors': subcontractors.map((e) => e.toJson()).toList(),
        'archiveFiles': archiveFiles.map((e) => e.toJson()).toList(),
        'purchases': purchases.map((e) => e.toJson()).toList(),
        'weighbridges': weighbridges.map((e) => e.toJson()).toList(),
        'budget': budget.map((e) => e.toJson()).toList(),
        'hakedisler': hakedisler.map((e) => e.toJson()).toList(),
        'roles': roles.map((e) => e.toJson()).toList(),
        'appUsers': appUsers.map((e) => e.toJson()).toList(),
        'currentUserId': currentUserId,
        'materialCategories': materialCategories,
        'materialList': materialList.map((e) => e.toJson()).toList(),
        'materialUnits': materialUnits.map((e) => e.toJson()).toList(),
        'imalatPozlari': imalatPozlari.map((e) => e.toJson()).toList(),
        'pozAnalizleri': pozAnalizleri.map((e) => e.toJson()).toList(),
        'professions': professions,
        'tradeGroups': tradeGroups,
      };

  static AppState fromJson(Map<String, dynamic> json) {
    List<T> listOf<T>(
      String key,
      T Function(Map<String, dynamic>) parse,
    ) {
      final raw = json[key];
      if (raw is! List) return <T>[];
      return raw
          .whereType<Map>()
          .map((e) => parse(Map<String, dynamic>.from(e)))
          .toList();
    }

    var roles = listOf('roles', Role.fromJson);
    if (roles.isEmpty ||
        !roles.any((r) => r.id == 'isveren') ||
        !roles.any((r) => r.id == 'proje-muduru') ||
        !roles.any((r) =>
            r.id == 'santiye-sefi' &&
            r.permissions.values.any((p) => p != Permission.none))) {
      roles = Role.defaultRoles();
    }

    List<String> strList(String key, List<String> fallback) {
      final raw = json[key];
      if (raw is List && raw.isNotEmpty) {
        return raw.map((e) => e.toString()).toList();
      }
      return List.of(fallback);
    }

    return AppState(
      projects: listOf('projects', Project.fromJson),
      surveys: listOf('surveys', Survey.fromJson),
      scheduleTasks: listOf('scheduleTasks', ScheduleTask.fromJson),
      workers: listOf('workers', Worker.fromJson),
      attendance: listOf('attendance', Attendance.fromJson),
      dailyReports: listOf('dailyReports', DailyReport.fromJson),
      productions: listOf('productions', Production.fromJson),
      tasks: listOf('tasks', Task.fromJson),
      materials: listOf('materials', Material.fromJson),
      materialRequests: listOf('materialRequests', MaterialRequest.fromJson),
      materialMovements: listOf('materialMovements', MaterialMovement.fromJson),
      subcontractors: listOf('subcontractors', Subcontractor.fromJson),
      archiveFiles: listOf('archiveFiles', ArchiveFile.fromJson),
      purchases: listOf('purchases', Purchase.fromJson),
      weighbridges: listOf('weighbridges', Weighbridge.fromJson),
      budget: listOf('budget', BudgetEntry.fromJson),
      hakedisler: listOf('hakedisler', Hakedis.fromJson),
      roles: roles,
      appUsers: listOf('appUsers', AppUser.fromJson),
      currentUserId: json['currentUserId']?.toString(),
      materialCategories:
          strList('materialCategories', defaultMaterialCategories),
      materialList: listOf('materialList', ConstructionMaterial.fromJson),
      materialUnits: () {
        final u = listOf('materialUnits', UnitOption.fromJson);
        if (u.isEmpty) return List.of(defaultMaterialUnits);
        return u
            .map((x) {
              if (x.code == 'M2') {
                return const UnitOption(code: 'M²', label: 'M² — Metrekare');
              }
              if (x.code == 'M3') {
                return const UnitOption(code: 'M³', label: 'M³ — Metreküp');
              }
              return x;
            })
            .toList();
      }(),
      imalatPozlari: listOf('imalatPozlari', ImalatPoz.fromJson),
      pozAnalizleri: listOf('pozAnalizleri', PozAnaliz.fromJson),
      professions: strList('professions', defaultProfessions),
      tradeGroups: strList('tradeGroups', defaultTradeGroups),
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier({
    required Box appStateBox,
    required Box workspaceBox,
    WorkspaceApi? api,
  })  : _appStateBox = appStateBox,
        _workspaceBox = workspaceBox,
        _api = api ?? WorkspaceApi(),
        super(AppState()) {
    _loadSync();
  }

  static const _deployChannel =
      String.fromEnvironment('DEPLOY_CHANNEL', defaultValue: '');

  final Box _appStateBox;
  final Box _workspaceBox;
  final WorkspaceApi _api;

  /// Senkron yükleme — ilk frame öncesi loaded/oturum hazır olsun.
  void _loadSync() {
    AppState next = AppState(roles: Role.defaultRoles());
    try {
      final raw = _appStateBox.get(_stateKey);
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            next = AppState.fromJson(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {}
      }

      WorkspaceInfo? ws;
      final wsRaw = _workspaceBox.get(_workspaceKey);
      if (wsRaw is String && wsRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(wsRaw);
          if (decoded is Map) {
            ws = WorkspaceInfo.fromJson(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {}
      }

      state = next.copyWith(loaded: false, workspaceInfo: ws);
      if (_deployChannel == 'staging') {
        ensureStagingSession();
      }
    } catch (_) {
      // Bozuk Hive / beklenmeyen hata — yine de staging oturumu dene.
      if (_deployChannel == 'staging') {
        try {
          ensureStagingSession();
        } catch (_) {}
      }
    }
    _set(state.copyWith(loaded: true));
  }

  /// Staging önizleme: workspace + kullanıcı + roller hazır olsun.
  /// Orphan currentUserId / boş izinli roller modül ızgarasını boşaltıyordu.
  void ensureStagingSession({
    String name = 'Staging Kullanıcı',
    String roleId = 'santiye-sefi',
  }) {
    // Önizlemede her zaman varsayılan roller — Hive'daki bozuk izin tuzağını kır.
    if (!_rolesHaveUsableAccess(state.roles, roleId)) {
      state = state.copyWith(roles: Role.defaultRoles());
    }

    final user = state.currentAppUser;
    Role? role;
    if (user != null) {
      for (final r in state.roles) {
        if (r.id == user.roleId) {
          role = r;
          break;
        }
      }
    }
    final hasAccess = user != null &&
        role != null &&
        role.permissions.values.any((p) => p != Permission.none) &&
        state.workspaceInfo != null;
    if (hasAccess) return;

    applyLocalSessionSync(name: name, roleId: roleId);
  }

  bool _rolesHaveUsableAccess(List<Role> roles, String roleId) {
    for (final r in roles) {
      if (r.id != roleId) continue;
      return r.permissions.values.any((p) => p != Permission.none);
    }
    return false;
  }

  void _persist() {
    _appStateBox.put(_stateKey, jsonEncode(state.toJson()));
  }

  void _set(AppState next) {
    state = next;
    if (next.loaded) _persist();
  }

  // —— Auth / workspace ——

  void login(String userId) =>
      _set(state.copyWith(currentUserId: userId));

  void logout() => _set(state.copyWith(clearCurrentUserId: true));

  Future<void> setWorkspace(WorkspaceInfo? info) async {
    if (info != null) {
      await _workspaceBox.put(_workspaceKey, jsonEncode(info.toJson()));
      _set(state.copyWith(workspaceInfo: info));
    } else {
      await _workspaceBox.delete(_workspaceKey);
      _set(state.copyWith(clearWorkspace: true));
    }
  }

  /// Bellekte yerel oturum (senkron). Hive yazımı fire-and-forget.
  String applyLocalSessionSync({
    String name = 'Kullanıcı',
    String roleId = 'santiye-sefi',
    String pin = '',
    String? existingUserId,
  }) {
    const ws = WorkspaceInfo(
      id: 'local',
      companyName: 'Yerel',
      inviteCode: '',
      apiUrl: '',
    );

    // Rol listesi eksik/bozuksa varsayılanlar — aksi halde getPermission hep none.
    var roles = state.roles;
    if (roles.isEmpty || !_rolesHaveUsableAccess(roles, roleId)) {
      roles = Role.defaultRoles();
    }

    var users = List<AppUser>.from(state.appUsers);
    String userId;
    if (existingUserId != null &&
        users.any((u) => u.id == existingUserId)) {
      userId = existingUserId;
      users = [
        for (final u in users)
          if (u.id == userId) u.copyWith(roleId: roleId) else u,
      ];
    } else {
      final byName = users.where((u) => u.name == name).toList();
      if (byName.isNotEmpty) {
        userId = byName.first.id;
        users = [
          for (final u in users)
            if (u.id == userId) u.copyWith(roleId: roleId) else u,
        ];
      } else {
        userId = _genId();
        users = [
          ...users,
          AppUser(
            id: userId,
            name: name.trim().isEmpty ? 'Kullanıcı' : name.trim(),
            roleId: roleId,
            pin: pin.length == 4 ? pin : '',
            profession: '',
            phone: '',
            address: '',
            company: '',
          ),
        ];
      }
    }

    _set(state.copyWith(
      roles: roles,
      appUsers: users,
      currentUserId: userId,
      workspaceInfo: ws,
    ));
    // ignore: unawaited_futures
    _workspaceBox.put(_workspaceKey, jsonEncode(ws.toJson())).then((_) {},
        onError: (_) {});
    return userId;
  }

  /// Yerel oturum: workspace + kullanıcı + login tek atomik state güncellemesi.
  Future<String> startLocalSession({
    String name = 'Kullanıcı',
    String roleId = 'santiye-sefi',
    String pin = '',
    String? existingUserId,
  }) async {
    return applyLocalSessionSync(
      name: name,
      roleId: roleId,
      pin: pin,
      existingUserId: existingUserId,
    );
  }

  /// Mevcut kullanıcıyı yerel workspace ile oturum açtırır (tek yazım).
  Future<void> completeLocalOnboarding(String userId) async {
    await startLocalSession(existingUserId: userId);
  }

  Future<void> pushToCloud() async {
    final ws = state.workspaceInfo;
    if (ws == null || ws.isLocal) return;
    _set(state.copyWith(syncStatus: SyncStatus.syncing));
    try {
      final payload = state.toJson()..['currentUserId'] = null;
      final result = await _api.push(workspace: ws, statePayload: payload);
      if (result.status == SyncStatus.conflict ||
          result.status == SyncStatus.authError ||
          result.status == SyncStatus.error) {
        _set(state.copyWith(syncStatus: result.status));
        Future<void>.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            _set(state.copyWith(syncStatus: SyncStatus.idle));
          }
        });
        return;
      }
      var nextWs = ws;
      if (result.revision != null) {
        nextWs = ws.copyWith(revision: result.revision);
        await _workspaceBox.put(_workspaceKey, jsonEncode(nextWs.toJson()));
      }
      _set(state.copyWith(
        workspaceInfo: nextWs,
        syncStatus: SyncStatus.success,
        lastSyncAt: DateTime.now().toIso8601String(),
      ));
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) _set(state.copyWith(syncStatus: SyncStatus.idle));
      });
    } catch (_) {
      _set(state.copyWith(syncStatus: SyncStatus.error));
      Future<void>.delayed(const Duration(seconds: 4), () {
        if (mounted) _set(state.copyWith(syncStatus: SyncStatus.idle));
      });
    }
  }

  Future<void> pullFromCloud() async {
    final ws = state.workspaceInfo;
    if (ws == null || ws.isLocal) return;
    _set(state.copyWith(syncStatus: SyncStatus.syncing));
    try {
      final result = await _api.pull(workspace: ws);
      if (result.status == SyncStatus.authError ||
          result.status == SyncStatus.error) {
        _set(state.copyWith(syncStatus: result.status));
        Future<void>.delayed(const Duration(seconds: 4), () {
          if (mounted) _set(state.copyWith(syncStatus: SyncStatus.idle));
        });
        return;
      }
      var next = state;
      if (result.data != null) {
        final prevUserId = state.currentUserId;
        final incoming = AppState.fromJson(result.data!);
        final still =
            prevUserId != null && incoming.appUsers.any((u) => u.id == prevUserId);
        next = incoming.copyWith(
          loaded: true,
          workspaceInfo: ws,
          currentUserId: still ? prevUserId : null,
          clearCurrentUserId: !still,
        );
      }
      var nextWs = ws;
      if (result.revision != null) {
        nextWs = ws.copyWith(revision: result.revision);
        await _workspaceBox.put(_workspaceKey, jsonEncode(nextWs.toJson()));
      }
      _set(next.copyWith(
        workspaceInfo: nextWs,
        syncStatus: SyncStatus.success,
        lastSyncAt: DateTime.now().toIso8601String(),
      ));
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) _set(state.copyWith(syncStatus: SyncStatus.idle));
      });
    } catch (_) {
      _set(state.copyWith(syncStatus: SyncStatus.error));
      Future<void>.delayed(const Duration(seconds: 4), () {
        if (mounted) _set(state.copyWith(syncStatus: SyncStatus.idle));
      });
    }
  }

  // —— Generic CRUD helpers ——

  String _addEntity<T>(
    List<T> Function(AppState) getter,
    AppState Function(List<T>) setter,
    T Function(String id) build,
  ) {
    final id = _genId();
    final list = List<T>.from(getter(state))..add(build(id));
    _set(setter(list));
    return id;
  }

  void _updateEntity<T>(
    List<T> Function(AppState) getter,
    AppState Function(List<T>) setter,
    bool Function(T) match,
    T Function(T) patch,
  ) {
    final list = getter(state).map((e) => match(e) ? patch(e) : e).toList();
    _set(setter(list));
  }

  void _deleteEntity<T>(
    List<T> Function(AppState) getter,
    AppState Function(List<T>) setter,
    bool Function(T) match,
  ) {
    final list = getter(state).where((e) => !match(e)).toList();
    _set(setter(list));
  }

  // Projects
  String addProject(Project p) => _addEntity(
        (s) => s.projects,
        (l) => state.copyWith(projects: l),
        (id) => p.copyWith(id: id),
      );

  void updateProject(String id, Project Function(Project) patch) =>
      _updateEntity(
        (s) => s.projects,
        (l) => state.copyWith(projects: l),
        (e) => e.id == id,
        patch,
      );

  void deleteProject(String id) {
    _set(state.copyWith(
      projects: state.projects.where((e) => e.id != id).toList(),
      surveys: state.surveys.where((e) => e.projectId != id).toList(),
      scheduleTasks:
          state.scheduleTasks.where((e) => e.projectId != id).toList(),
      workers: state.workers.where((e) => e.projectId != id).toList(),
      attendance: state.attendance.where((e) => e.projectId != id).toList(),
      dailyReports:
          state.dailyReports.where((e) => e.projectId != id).toList(),
      productions: state.productions.where((e) => e.projectId != id).toList(),
      tasks: state.tasks.where((e) => e.projectId != id).toList(),
      materials: state.materials.where((e) => e.projectId != id).toList(),
      materialRequests:
          state.materialRequests.where((e) => e.projectId != id).toList(),
      materialMovements:
          state.materialMovements.where((e) => e.projectId != id).toList(),
      subcontractors:
          state.subcontractors.where((e) => e.projectId != id).toList(),
      archiveFiles:
          state.archiveFiles.where((e) => e.projectId != id).toList(),
      purchases: state.purchases.where((e) => e.projectId != id).toList(),
      weighbridges:
          state.weighbridges.where((e) => e.projectId != id).toList(),
      budget: state.budget.where((e) => e.projectId != id).toList(),
      hakedisler: state.hakedisler.where((e) => e.projectId != id).toList(),
    ));
  }

  String addSurvey(Survey s) => _addEntity(
        (x) => x.surveys,
        (l) => state.copyWith(surveys: l),
        (id) => s.copyWith(id: id),
      );
  void updateSurvey(String id, Survey Function(Survey) p) => _updateEntity(
        (x) => x.surveys,
        (l) => state.copyWith(surveys: l),
        (e) => e.id == id,
        p,
      );
  void deleteSurvey(String id) => _deleteEntity(
        (x) => x.surveys,
        (l) => state.copyWith(surveys: l),
        (e) => e.id == id,
      );

  String addScheduleTask(ScheduleTask t) => _addEntity(
        (x) => x.scheduleTasks,
        (l) => state.copyWith(scheduleTasks: l),
        (id) => t.copyWith(id: id),
      );
  void updateScheduleTask(String id, ScheduleTask Function(ScheduleTask) p) =>
      _updateEntity(
        (x) => x.scheduleTasks,
        (l) => state.copyWith(scheduleTasks: l),
        (e) => e.id == id,
        p,
      );
  void deleteScheduleTask(String id) => _deleteEntity(
        (x) => x.scheduleTasks,
        (l) => state.copyWith(scheduleTasks: l),
        (e) => e.id == id,
      );

  String addWorker(Worker w) => _addEntity(
        (x) => x.workers,
        (l) => state.copyWith(workers: l),
        (id) => w.copyWith(id: id),
      );
  void updateWorker(String id, Worker Function(Worker) p) => _updateEntity(
        (x) => x.workers,
        (l) => state.copyWith(workers: l),
        (e) => e.id == id,
        p,
      );
  void deleteWorker(String id) => _deleteEntity(
        (x) => x.workers,
        (l) => state.copyWith(workers: l),
        (e) => e.id == id,
      );

  String addAttendance(Attendance a) => _addEntity(
        (x) => x.attendance,
        (l) => state.copyWith(attendance: l),
        (id) => a.copyWith(id: id),
      );
  void updateAttendance(String id, Attendance Function(Attendance) p) =>
      _updateEntity(
        (x) => x.attendance,
        (l) => state.copyWith(attendance: l),
        (e) => e.id == id,
        p,
      );
  void deleteAttendance(String id) => _deleteEntity(
        (x) => x.attendance,
        (l) => state.copyWith(attendance: l),
        (e) => e.id == id,
      );

  String addDailyReport(DailyReport r) => _addEntity(
        (x) => x.dailyReports,
        (l) => state.copyWith(dailyReports: l),
        (id) => r.copyWith(id: id),
      );
  void updateDailyReport(String id, DailyReport Function(DailyReport) p) =>
      _updateEntity(
        (x) => x.dailyReports,
        (l) => state.copyWith(dailyReports: l),
        (e) => e.id == id,
        p,
      );
  void deleteDailyReport(String id) => _deleteEntity(
        (x) => x.dailyReports,
        (l) => state.copyWith(dailyReports: l),
        (e) => e.id == id,
      );

  String addProduction(Production p) => _addEntity(
        (x) => x.productions,
        (l) => state.copyWith(productions: l),
        (id) => p.copyWith(id: id),
      );
  void updateProduction(String id, Production Function(Production) p) =>
      _updateEntity(
        (x) => x.productions,
        (l) => state.copyWith(productions: l),
        (e) => e.id == id,
        p,
      );
  void deleteProduction(String id) => _deleteEntity(
        (x) => x.productions,
        (l) => state.copyWith(productions: l),
        (e) => e.id == id,
      );

  String addTask(Task t) => _addEntity(
        (x) => x.tasks,
        (l) => state.copyWith(tasks: l),
        (id) => t.copyWith(id: id),
      );
  void updateTask(String id, Task Function(Task) p) => _updateEntity(
        (x) => x.tasks,
        (l) => state.copyWith(tasks: l),
        (e) => e.id == id,
        p,
      );
  void deleteTask(String id) => _deleteEntity(
        (x) => x.tasks,
        (l) => state.copyWith(tasks: l),
        (e) => e.id == id,
      );

  String addMaterial(Material m) {
    final id = _genId();
    final willBridge = m.writeToKantar == true && m.kantarSlipId == null;
    final slipId = willBridge ? _genId() : null;
    final created = m.copyWith(id: id, kantarSlipId: slipId);
    var weighbridges = List<Weighbridge>.from(state.weighbridges);
    if (willBridge && slipId != null) {
      weighbridges.add(Weighbridge(
        id: slipId,
        projectId: created.projectId,
        date: created.deliveryDate.isNotEmpty
            ? created.deliveryDate
            : DateTime.now().toIso8601String().substring(0, 10),
        materialId: id,
        materialName: created.name,
        category: created.category,
        supplier: created.supplier,
        plate: '',
        driver: '',
        irsaliyeNo: created.waybillNo ?? '',
        grossWeight: 0,
        tareWeight: 0,
        netWeight: 0,
        unit: 'ton',
        notes: "Gelen Malzeme'den otomatik oluşturuldu",
      ));
    }
    _set(state.copyWith(
      materials: [...state.materials, created],
      weighbridges: weighbridges,
    ));
    return id;
  }

  void updateMaterial(String id, Material Function(Material) patch) {
    final before = state.materials.where((m) => m.id == id).firstOrNull;
    if (before == null) return;
    final after = patch(before);
    var materials = state.materials.map((m) => m.id == id ? after : m).toList();
    var weighbridges = List<Weighbridge>.from(state.weighbridges);

    final turningOn = after.writeToKantar == true && before.writeToKantar != true;
    final turningOff =
        after.writeToKantar != true && before.writeToKantar == true;

    if (turningOn && after.kantarSlipId == null) {
      final slipId = _genId();
      weighbridges.add(Weighbridge(
        id: slipId,
        projectId: after.projectId,
        date: after.deliveryDate.isNotEmpty
            ? after.deliveryDate
            : DateTime.now().toIso8601String().substring(0, 10),
        materialId: id,
        materialName: after.name,
        category: after.category,
        supplier: after.supplier,
        plate: '',
        driver: '',
        irsaliyeNo: after.waybillNo ?? '',
        grossWeight: 0,
        tareWeight: 0,
        netWeight: 0,
        unit: 'ton',
        notes: "Gelen Malzeme'den otomatik oluşturuldu",
      ));
      materials =
          materials.map((m) => m.id == id ? after.copyWith(kantarSlipId: slipId) : m).toList();
    } else if (turningOff && before.kantarSlipId != null) {
      final slipId = before.kantarSlipId!;
      weighbridges = weighbridges.where((w) => w.id != slipId).toList();
      materials = materials
          .map((m) => m.id == id ? after.copyWith(clearKantarSlipId: true) : m)
          .toList();
    }

    _set(state.copyWith(materials: materials, weighbridges: weighbridges));
  }

  void deleteMaterial(String id) {
    final target = state.materials.where((m) => m.id == id).firstOrNull;
    final slipId = target?.kantarSlipId;
    _set(state.copyWith(
      materials: state.materials.where((m) => m.id != id).toList(),
      weighbridges: slipId == null
          ? state.weighbridges
          : state.weighbridges.where((w) => w.id != slipId).toList(),
    ));
  }

  String addMaterialRequest(MaterialRequest r) => _addEntity(
        (x) => x.materialRequests,
        (l) => state.copyWith(materialRequests: l),
        (id) => r.copyWith(id: id),
      );
  void updateMaterialRequest(
          String id, MaterialRequest Function(MaterialRequest) p) =>
      _updateEntity(
        (x) => x.materialRequests,
        (l) => state.copyWith(materialRequests: l),
        (e) => e.id == id,
        p,
      );
  void deleteMaterialRequest(String id) => _deleteEntity(
        (x) => x.materialRequests,
        (l) => state.copyWith(materialRequests: l),
        (e) => e.id == id,
      );

  String addMaterialMovement(MaterialMovement m) => _addEntity(
        (x) => x.materialMovements,
        (l) => state.copyWith(materialMovements: l),
        (id) => m.copyWith(id: id),
      );
  void updateMaterialMovement(
          String id, MaterialMovement Function(MaterialMovement) p) =>
      _updateEntity(
        (x) => x.materialMovements,
        (l) => state.copyWith(materialMovements: l),
        (e) => e.id == id,
        p,
      );
  void deleteMaterialMovement(String id) => _deleteEntity(
        (x) => x.materialMovements,
        (l) => state.copyWith(materialMovements: l),
        (e) => e.id == id,
      );

  String addSubcontractor(Subcontractor s) => _addEntity(
        (x) => x.subcontractors,
        (l) => state.copyWith(subcontractors: l),
        (id) => s.copyWith(id: id),
      );
  void updateSubcontractor(String id, Subcontractor Function(Subcontractor) p) =>
      _updateEntity(
        (x) => x.subcontractors,
        (l) => state.copyWith(subcontractors: l),
        (e) => e.id == id,
        p,
      );
  void deleteSubcontractor(String id) => _deleteEntity(
        (x) => x.subcontractors,
        (l) => state.copyWith(subcontractors: l),
        (e) => e.id == id,
      );

  String addArchiveFile(ArchiveFile f) => _addEntity(
        (x) => x.archiveFiles,
        (l) => state.copyWith(archiveFiles: l),
        (id) => f.copyWith(id: id),
      );
  void updateArchiveFile(String id, ArchiveFile Function(ArchiveFile) p) =>
      _updateEntity(
        (x) => x.archiveFiles,
        (l) => state.copyWith(archiveFiles: l),
        (e) => e.id == id,
        p,
      );
  void deleteArchiveFile(String id) => _deleteEntity(
        (x) => x.archiveFiles,
        (l) => state.copyWith(archiveFiles: l),
        (e) => e.id == id,
      );

  String addPurchase(Purchase p) => _addEntity(
        (x) => x.purchases,
        (l) => state.copyWith(purchases: l),
        (id) => p.copyWith(id: id),
      );
  void updatePurchase(String id, Purchase Function(Purchase) p) =>
      _updateEntity(
        (x) => x.purchases,
        (l) => state.copyWith(purchases: l),
        (e) => e.id == id,
        p,
      );
  void deletePurchase(String id) => _deleteEntity(
        (x) => x.purchases,
        (l) => state.copyWith(purchases: l),
        (e) => e.id == id,
      );

  String addWeighbridge(Weighbridge w) => _addEntity(
        (x) => x.weighbridges,
        (l) => state.copyWith(weighbridges: l),
        (id) => w.copyWith(id: id),
      );
  void updateWeighbridge(String id, Weighbridge Function(Weighbridge) p) =>
      _updateEntity(
        (x) => x.weighbridges,
        (l) => state.copyWith(weighbridges: l),
        (e) => e.id == id,
        p,
      );
  void deleteWeighbridge(String id) => _deleteEntity(
        (x) => x.weighbridges,
        (l) => state.copyWith(weighbridges: l),
        (e) => e.id == id,
      );

  String addBudget(BudgetEntry b) => _addEntity(
        (x) => x.budget,
        (l) => state.copyWith(budget: l),
        (id) => b.copyWith(id: id),
      );
  void updateBudget(String id, BudgetEntry Function(BudgetEntry) p) =>
      _updateEntity(
        (x) => x.budget,
        (l) => state.copyWith(budget: l),
        (e) => e.id == id,
        p,
      );
  void deleteBudget(String id) => _deleteEntity(
        (x) => x.budget,
        (l) => state.copyWith(budget: l),
        (e) => e.id == id,
      );

  String addHakedis(Hakedis h) => _addEntity(
        (x) => x.hakedisler,
        (l) => state.copyWith(hakedisler: l),
        (id) => h.copyWith(id: id),
      );
  void updateHakedis(String id, Hakedis Function(Hakedis) p) => _updateEntity(
        (x) => x.hakedisler,
        (l) => state.copyWith(hakedisler: l),
        (e) => e.id == id,
        p,
      );
  void deleteHakedis(String id) => _deleteEntity(
        (x) => x.hakedisler,
        (l) => state.copyWith(hakedisler: l),
        (e) => e.id == id,
      );

  String addRole(Role r) => _addEntity(
        (x) => x.roles,
        (l) => state.copyWith(roles: l),
        (id) => r.copyWith(id: id),
      );
  void updateRole(String id, Role Function(Role) p) => _updateEntity(
        (x) => x.roles,
        (l) => state.copyWith(roles: l),
        (e) => e.id == id,
        p,
      );
  void deleteRole(String id) => _deleteEntity(
        (x) => x.roles,
        (l) => state.copyWith(roles: l),
        (e) => e.id == id,
      );

  String addAppUser(AppUser u) => _addEntity(
        (x) => x.appUsers,
        (l) => state.copyWith(appUsers: l),
        (id) => u.copyWith(id: id),
      );
  void updateAppUser(String id, AppUser Function(AppUser) p) => _updateEntity(
        (x) => x.appUsers,
        (l) => state.copyWith(appUsers: l),
        (e) => e.id == id,
        p,
      );
  void deleteAppUser(String id) => _deleteEntity(
        (x) => x.appUsers,
        (l) => state.copyWith(appUsers: l),
        (e) => e.id == id,
      );

  // Catalogs
  void addMaterialCategory(String name) {
    if (state.materialCategories.contains(name)) return;
    _set(state.copyWith(
      materialCategories: [...state.materialCategories, name],
    ));
  }

  void deleteMaterialCategory(String name) {
    _set(state.copyWith(
      materialCategories:
          state.materialCategories.where((e) => e != name).toList(),
    ));
  }

  void addMaterialItem(ConstructionMaterial item) {
    _set(state.copyWith(materialList: [...state.materialList, item]));
  }

  void deleteMaterialItem(String name) {
    _set(state.copyWith(
      materialList: state.materialList.where((e) => e.name != name).toList(),
    ));
  }

  void addMaterialUnit(UnitOption unit) {
    _set(state.copyWith(materialUnits: [...state.materialUnits, unit]));
  }

  void deleteMaterialUnit(String code) {
    _set(state.copyWith(
      materialUnits: state.materialUnits.where((e) => e.code != code).toList(),
    ));
  }

  void addProfession(String name) {
    if (state.professions.contains(name)) return;
    _set(state.copyWith(professions: [...state.professions, name]));
  }

  void updateProfession(String oldName, String newName) {
    _set(state.copyWith(
      professions:
          state.professions.map((e) => e == oldName ? newName : e).toList(),
    ));
  }

  void deleteProfession(String name) {
    _set(state.copyWith(
      professions: state.professions.where((e) => e != name).toList(),
    ));
  }

  void addTradeGroup(String name) {
    if (state.tradeGroups.contains(name)) return;
    _set(state.copyWith(tradeGroups: [...state.tradeGroups, name]));
  }

  void updateTradeGroup(String oldName, String newName) {
    _set(state.copyWith(
      tradeGroups:
          state.tradeGroups.map((e) => e == oldName ? newName : e).toList(),
    ));
  }

  void deleteTradeGroup(String name) {
    _set(state.copyWith(
      tradeGroups: state.tradeGroups.where((e) => e != name).toList(),
    ));
  }

  void resetTradeGroups() {
    _set(state.copyWith(tradeGroups: List.of(defaultTradeGroups)));
  }

  void addImalatPoz(ImalatPoz poz) {
    _set(state.copyWith(imalatPozlari: [...state.imalatPozlari, poz]));
  }

  void updateImalatPoz(String code, ImalatPoz Function(ImalatPoz) patch) {
    _set(state.copyWith(
      imalatPozlari: state.imalatPozlari
          .map((e) => e.code == code ? patch(e) : e)
          .toList(),
    ));
  }

  void deleteImalatPoz(String code) {
    _set(state.copyWith(
      imalatPozlari:
          state.imalatPozlari.where((e) => e.code != code).toList(),
    ));
  }

  void addPozAnaliz(PozAnaliz a) {
    final id = a.id.isEmpty ? _genId() : a.id;
    final now = DateTime.now().toIso8601String();
    _set(state.copyWith(
      pozAnalizleri: [
        ...state.pozAnalizleri,
        a.copyWith(
          id: id,
          olusturmaTarihi:
              a.olusturmaTarihi.isEmpty ? now : a.olusturmaTarihi,
          guncellemeTarihi: now,
        ),
      ],
    ));
  }

  void updatePozAnaliz(String id, PozAnaliz Function(PozAnaliz) patch) {
    final now = DateTime.now().toIso8601String();
    _set(state.copyWith(
      pozAnalizleri: state.pozAnalizleri
          .map((e) =>
              e.id == id ? patch(e).copyWith(guncellemeTarihi: now) : e)
          .toList(),
    ));
  }

  void deletePozAnaliz(String id) {
    _set(state.copyWith(
      pozAnalizleri: state.pozAnalizleri.where((e) => e.id != id).toList(),
    ));
  }

  /// Tüm iş verisini sıfırlar; çalışma alanı oturumu korunur.
  void clearAllData() {
    _set(AppState(
      roles: Role.defaultRoles(),
      loaded: true,
      workspaceInfo: state.workspaceInfo,
      syncStatus: state.syncStatus,
      lastSyncAt: state.lastSyncAt,
    ));
  }

  String exportData() {
    return jsonEncode({
      'version': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': state.toJson(),
    });
  }

  ({bool ok, Map<String, int>? counts, String? error}) importData(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) {
        return (ok: false, counts: null, error: 'Geçersiz JSON');
      }
      final map = Map<String, dynamic>.from(decoded);
      final data = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      final incoming = AppState.fromJson(data);
      final counts = <String, int>{
        'projects': incoming.projects.length,
        'workers': incoming.workers.length,
        'materials': incoming.materials.length,
        'appUsers': incoming.appUsers.length,
      };
      _set(incoming.copyWith(
        loaded: true,
        workspaceInfo: state.workspaceInfo,
        syncStatus: state.syncStatus,
      ));
      return (ok: true, counts: counts, error: null);
    } catch (e) {
      return (ok: false, counts: null, error: e.toString());
    }
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier(
    appStateBox: ref.watch(appStateBoxProvider),
    workspaceBox: ref.watch(workspaceBoxProvider),
  );
});

final workspaceApiProvider = Provider<WorkspaceApi>((ref) => WorkspaceApi());
