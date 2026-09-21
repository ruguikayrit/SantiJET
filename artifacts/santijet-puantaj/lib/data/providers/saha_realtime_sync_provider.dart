import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/daily_report.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/production.dart';
import '../../domain/entities/site_task.dart';
import '../../domain/entities/uninsured_team_entry.dart';
import '../../domain/entities/yevmiyeli_is_kaydi.dart';
import '../remote/supabase_project_sync.dart';
import '../remote/supabase_row_sync.dart';
import '../remote/supabase_service.dart';
import 'app_data_provider.dart';
import 'auth_provider.dart';
import 'collaboration_provider.dart';
import 'daily_report_provider.dart';
import 'production_provider.dart';
import 'tasks_provider.dart';
import 'uninsured_teams_provider.dart';
import 'yevmiyeli_is_provider.dart';

enum SahaSyncPhase { idle, syncing, live, offline, error }

class SahaSyncState {
  const SahaSyncState({
    this.phase = SahaSyncPhase.idle,
    this.projectId,
    this.message = '',
    this.lastSyncedAt,
  });

  final SahaSyncPhase phase;
  final String? projectId;
  final String message;
  final DateTime? lastSyncedAt;

  String get label => switch (phase) {
        SahaSyncPhase.idle => 'Senkron kapalı',
        SahaSyncPhase.syncing => 'Senkronize ediliyor…',
        SahaSyncPhase.live => 'Canlı',
        SahaSyncPhase.offline => 'Çevrimdışı',
        SahaSyncPhase.error => message.isEmpty ? 'Senkron hatası' : message,
      };

  SahaSyncState copyWith({
    SahaSyncPhase? phase,
    String? projectId,
    String? message,
    DateTime? lastSyncedAt,
  }) {
    return SahaSyncState(
      phase: phase ?? this.phase,
      projectId: projectId ?? this.projectId,
      message: message ?? this.message,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

final supabaseRowSyncProvider = Provider<SupabaseRowSync>((ref) {
  return SupabaseRowSync();
});

final sahaSyncStateProvider =
    StateNotifierProvider<SahaSyncStateNotifier, SahaSyncState>((ref) {
  return SahaSyncStateNotifier();
});

class SahaSyncStateNotifier extends StateNotifier<SahaSyncState> {
  SahaSyncStateNotifier() : super(const SahaSyncState());

  void set(SahaSyncState next) => state = next;
}

/// Aktif proje için satır sync + Realtime.
final sahaRealtimeSyncProvider = Provider<SahaRealtimeSyncController>((ref) {
  final c = SahaRealtimeSyncController(ref);
  c.ensureLocalWriteHooks();
  ref.onDispose(c.dispose);
  return c;
});

/// Aktif proje değişince pull + realtime dinlemeyi başlatır.
final sahaRealtimeSyncBootstrapProvider = Provider<void>((ref) {
  final sync = ref.watch(sahaRealtimeSyncProvider);
  final projectId = ref.watch(activeProjectIdProvider);
  final auth = ref.watch(authProvider);

  if (!auth.isAuthenticated || projectId == null || projectId.isEmpty) {
    unawaited(sync.stop());
    return;
  }
  unawaited(sync.startForProject(projectId));
});

class SahaRealtimeSyncController {
  SahaRealtimeSyncController(this._ref);

  final Ref _ref;
  RealtimeChannel? _channel;
  String? _listeningProjectId;
  final _lastLocalWrite = <String, DateTime>{};
  final _pushTimers = <String, Timer>{};
  bool _applyingRemote = false;
  bool _hooksWired = false;

  SupabaseRowSync get _rows => _ref.read(supabaseRowSyncProvider);

  /// Hive yazılarında debounced bulut push — notifier'lara bir kez bağlanır.
  void ensureLocalWriteHooks() {
    if (_hooksWired) return;
    _hooksWired = true;
    void hook(String projectId) => schedulePushAfterLocalWrite(projectId);
    _ref.read(attendanceProvider.notifier).onLocalProjectChanged = hook;
    _ref.read(personnelProvider.notifier).onLocalProjectChanged = hook;
    _ref.read(productionProvider.notifier).onLocalProjectChanged = hook;
    _ref.read(tasksProvider.notifier).onLocalProjectChanged = hook;
    _ref.read(dailyReportsProvider.notifier).onLocalProjectChanged = hook;
    _ref.read(yevmiyeliIsProvider.notifier).onLocalProjectChanged = hook;
    _ref.read(uninsuredTeamsProvider.notifier).onLocalProjectChanged = hook;
  }

  void dispose() {
    for (final t in _pushTimers.values) {
      t.cancel();
    }
    _pushTimers.clear();
    unawaited(_stopChannel());
  }

  Future<void> _stopChannel() async {
    final ch = _channel;
    _channel = null;
    _listeningProjectId = null;
    if (ch != null) {
      try {
        await _rows.removeChannel(ch);
      } catch (_) {
        try {
          await ch.unsubscribe();
        } catch (_) {}
      }
    }
  }

  bool _canEdit(String projectId) {
    return _ref.read(collaborationControllerProvider).canEditProject(projectId);
  }

  /// Splash / proje değişimi — pull + realtime dinle.
  Future<void> startForProject(String projectId) async {
    if (!SupabaseService.isConfigured) {
      _ref.read(sahaSyncStateProvider.notifier).set(
            const SahaSyncState(
              phase: SahaSyncPhase.offline,
              message: 'Bulut yapılandırılmamış',
            ),
          );
      return;
    }
    await SupabaseService.waitUntilReady(timeout: const Duration(seconds: 8));
    if (!SupabaseService.isReady) {
      _ref.read(sahaSyncStateProvider.notifier).set(
            const SahaSyncState(phase: SahaSyncPhase.offline),
          );
      return;
    }

    // Yerel işi buluta bağla (prj… → UUID)
    try {
      if (_canEdit(projectId) || !isSahaUuid(projectId)) {
        projectId = await _ref
            .read(collaborationControllerProvider)
            .ensureCloudProjectId(projectId);
      }
    } catch (e, st) {
      debugPrint('SahaRealtimeSync ensureCloud: $e\n$st');
      // UUID değilse pull/push zaten başarısız olur; hatayı göster.
      if (!isSahaUuid(projectId)) {
        _ref.read(sahaSyncStateProvider.notifier).set(
              SahaSyncState(
                phase: SahaSyncPhase.error,
                projectId: projectId,
                message: e.toString(),
              ),
            );
        return;
      }
    }

    if (_listeningProjectId == projectId && _channel != null) {
      // Zaten dinliyorken bile taze pull (2. cihaz / yeniden giriş).
      try {
        await pullProject(projectId);
        _ref.read(sahaSyncStateProvider.notifier).set(
              SahaSyncState(
                phase: SahaSyncPhase.live,
                projectId: projectId,
                lastSyncedAt: DateTime.now(),
              ),
            );
      } catch (e, st) {
        debugPrint('SahaRealtimeSync refresh pull: $e\n$st');
      }
      return;
    }

    _ref.read(sahaSyncStateProvider.notifier).set(
          SahaSyncState(
            phase: SahaSyncPhase.syncing,
            projectId: projectId,
          ),
        );

    try {
      await _stopChannel();
      await pullProject(projectId);
      _channel = _rows.subscribeProject(
        projectId: projectId,
        onChange: _onRealtime,
      );
      _listeningProjectId = projectId;
      _ref.read(sahaSyncStateProvider.notifier).set(
            SahaSyncState(
              phase: SahaSyncPhase.live,
              projectId: projectId,
              lastSyncedAt: DateTime.now(),
            ),
          );
    } catch (e, st) {
      debugPrint('SahaRealtimeSync startForProject: $e\n$st');
      _ref.read(sahaSyncStateProvider.notifier).set(
            SahaSyncState(
              phase: SahaSyncPhase.error,
              projectId: projectId,
              message: e.toString(),
            ),
          );
    }
  }

  Future<void> stop() async {
    await _stopChannel();
    _ref.read(sahaSyncStateProvider.notifier).set(const SahaSyncState());
  }

  Future<void> pullProject(String projectId) async {
    if (!SupabaseService.isReady) return;
    _applyingRemote = true;
    try {
      await _pullAttendance(projectId);
      await _pullPersonnel(projectId);
      await _pullProduction(projectId);
      await _pullTasks(projectId);
      await _pullDailyReports(projectId);
      await _pullYevmiyeli(projectId);
      await _pullUninsured(projectId);

      // Geçiş: satır tablolar boşsa eski snapshot'tan doldur (bir kez push).
      await _migrateFromSnapshotsIfNeeded(projectId);
    } finally {
      _applyingRemote = false;
    }
  }

  Future<String> pushProject(String projectId) async {
    final user = _ref.read(authProvider).user;
    if (user == null || !SupabaseService.isReady) return projectId;

    // Yerel prj… id → bulut UUID (veri taşınır)
    projectId = await _ref
        .read(collaborationControllerProvider)
        .ensureCloudProjectId(projectId);

    if (!_canEdit(projectId)) return projectId;

    _ref.read(sahaSyncStateProvider.notifier).set(
          SahaSyncState(
            phase: SahaSyncPhase.syncing,
            projectId: projectId,
          ),
        );
    try {
      final now = DateTime.now().toUtc();
      final att = _ref
          .read(attendanceProvider)
          .where((a) => a.projectId == projectId)
          .toList();
      for (final a in att) {
        _lastLocalWrite[
            'saha_attendance|${a.id}|${a.personId}|${a.date}'] = now;
      }
      await _rows.upsertAttendanceBatch(rows: att, userId: user.id);

      final people = _ref
          .read(personnelProvider)
          .where((p) => p.projectId == projectId)
          .toList();
      for (final p in people) {
        _lastLocalWrite['saha_personnel|${p.id}||'] = now;
      }
      await _rows.upsertPayloadBatch(
        table: 'saha_personnel',
        projectId: projectId,
        userId: user.id,
        rows: [
          for (final p in people)
            (id: p.id, payload: p.toJson(), date: null),
        ],
      );

      final productions = _ref
          .read(productionProvider)
          .where((p) => p.projectId == projectId)
          .toList();
      for (final p in productions) {
        _lastLocalWrite['saha_production|${p.id}||'] = now;
      }
      await _rows.upsertPayloadBatch(
        table: 'saha_production',
        projectId: projectId,
        userId: user.id,
        rows: [
          for (final p in productions)
            (id: p.id, payload: p.toJson(), date: null),
        ],
      );

      final tasks = _ref
          .read(tasksProvider)
          .where((t) => t.projectId == projectId)
          .toList();
      for (final t in tasks) {
        _lastLocalWrite['saha_tasks|${t.id}||'] = now;
      }
      await _rows.upsertPayloadBatch(
        table: 'saha_tasks',
        projectId: projectId,
        userId: user.id,
        rows: [
          for (final t in tasks) (id: t.id, payload: t.toJson(), date: null),
        ],
      );

      final reports = _ref
          .read(dailyReportsProvider)
          .where((r) => r.projectId == projectId)
          .toList();
      for (final r in reports) {
        _lastLocalWrite['saha_daily_reports|${r.id}||'] = now;
      }
      await _rows.upsertPayloadBatch(
        table: 'saha_daily_reports',
        projectId: projectId,
        userId: user.id,
        rows: [
          for (final r in reports)
            (id: r.id, payload: r.toJson(), date: r.date),
        ],
      );

      final yev = _ref
          .read(yevmiyeliIsProvider)
          .where((e) => e.projectId == projectId)
          .toList();
      for (final e in yev) {
        _lastLocalWrite['saha_yevmiyeli|${e.id}||'] = now;
      }
      await _rows.upsertPayloadBatch(
        table: 'saha_yevmiyeli',
        projectId: projectId,
        userId: user.id,
        rows: [
          for (final e in yev) (id: e.id, payload: e.toJson(), date: null),
        ],
      );

      final teams = _ref
          .read(uninsuredTeamsProvider)
          .where((e) => e.projectId == projectId)
          .toList();
      for (final e in teams) {
        _lastLocalWrite['saha_uninsured_teams|${e.id}||'] = now;
      }
      await _rows.upsertPayloadBatch(
        table: 'saha_uninsured_teams',
        projectId: projectId,
        userId: user.id,
        rows: [
          for (final e in teams) (id: e.id, payload: e.toJson(), date: null),
        ],
      );

      // Geriye dönük uyumluluk — snapshot da güncelle.
      await _ref.read(collaborationControllerProvider).pushDomainSnapshotsOnly(
            projectId,
          );

      _ref.read(sahaSyncStateProvider.notifier).set(
            SahaSyncState(
              phase: SahaSyncPhase.live,
              projectId: projectId,
              lastSyncedAt: DateTime.now(),
            ),
          );
      return projectId;
    } catch (e) {
      _ref.read(sahaSyncStateProvider.notifier).set(
            SahaSyncState(
              phase: SahaSyncPhase.error,
              projectId: projectId,
              message: e.toString(),
            ),
          );
      rethrow;
    }
  }

  /// Yerel yazma sonrası debounced push (tek satır / batch).
  void schedulePushAfterLocalWrite(String projectId) {
    if (_applyingRemote) return;
    if (!SupabaseService.isReady) return;
    if (!_canEdit(projectId)) return;

    _pushTimers[projectId]?.cancel();
    _pushTimers[projectId] = Timer(const Duration(milliseconds: 350), () {
      unawaited(_flushLocalWrites(projectId));
    });
  }

  Future<void> _flushLocalWrites(String projectId) async {
    final user = _ref.read(authProvider).user;
    if (user == null || !SupabaseService.isReady) return;
    if (!_canEdit(projectId)) return;
    try {
      // Son yazılan domainleri tam proje push ile güvenceye al (basit + doğru).
      // Debounce sayesinde toplu girişlerde tek istek olur.
      await pushProject(projectId);
    } catch (e, st) {
      debugPrint('SahaRealtimeSync flush: $e\n$st');
      _ref.read(sahaSyncStateProvider.notifier).set(
            SahaSyncState(
              phase: SahaSyncPhase.error,
              projectId: projectId,
              message: e.toString(),
            ),
          );
    }
  }

  void noteLocalWrite(String key) {
    _lastLocalWrite[key] = DateTime.now().toUtc();
  }

  void _onRealtime(String table, PostgresChangePayload payload) {
    if (_applyingRemote) return;
    final event = payload.eventType;
    final row = event == PostgresChangeEvent.delete
        ? payload.oldRecord
        : payload.newRecord;
    if (row.isEmpty) return;

    final updatedAt = DateTime.tryParse('${row['updated_at']}')?.toUtc();
    final projectId = row['project_id'] as String?;
    if (projectId == null) return;

    // Kendi yazmamızın echo'su — çok taze ise atla (aynı cihaz).
    final key = '$table|${row['id'] ?? ''}|${row['person_id'] ?? ''}|${row['date'] ?? ''}';
    final localAt = _lastLocalWrite[key];
    if (localAt != null &&
        updatedAt != null &&
        !updatedAt.isAfter(localAt.add(const Duration(milliseconds: 50)))) {
      return;
    }

    _applyingRemote = true;
    try {
      switch (table) {
        case 'saha_attendance':
          _applyAttendanceRemote(event, row);
        case 'saha_personnel':
          _applyPayloadRemote(
            event,
            row,
            parse: Person.fromJson,
            applyUpsert: (p) =>
                _ref.read(personnelProvider.notifier).upsertRemote(p),
            applyDelete: (id) =>
                _ref.read(personnelProvider.notifier).deleteRemote(id),
          );
        case 'saha_production':
          _applyPayloadRemote(
            event,
            row,
            parse: Production.fromJson,
            applyUpsert: (p) =>
                _ref.read(productionProvider.notifier).upsertRemote(p),
            applyDelete: (id) =>
                _ref.read(productionProvider.notifier).deleteRemote(id),
          );
        case 'saha_tasks':
          _applyPayloadRemote(
            event,
            row,
            parse: SiteTask.fromJson,
            applyUpsert: (t) =>
                _ref.read(tasksProvider.notifier).upsertRemote(t),
            applyDelete: (id) =>
                _ref.read(tasksProvider.notifier).deleteRemote(id),
          );
        case 'saha_daily_reports':
          _applyPayloadRemote(
            event,
            row,
            parse: DailyReport.fromJson,
            applyUpsert: (r) =>
                _ref.read(dailyReportsProvider.notifier).upsertRemote(r),
            applyDelete: (id) =>
                _ref.read(dailyReportsProvider.notifier).deleteRemote(id),
          );
        case 'saha_yevmiyeli':
          _applyPayloadRemote(
            event,
            row,
            parse: YevmiyeliIsKaydi.fromJson,
            applyUpsert: (e) =>
                _ref.read(yevmiyeliIsProvider.notifier).upsertRemote(e),
            applyDelete: (id) =>
                _ref.read(yevmiyeliIsProvider.notifier).deleteRemote(id),
          );
        case 'saha_uninsured_teams':
          _applyPayloadRemote(
            event,
            row,
            parse: UninsuredTeamEntry.fromJson,
            applyUpsert: (e) =>
                _ref.read(uninsuredTeamsProvider.notifier).upsertRemote(e),
            applyDelete: (id) =>
                _ref.read(uninsuredTeamsProvider.notifier).deleteRemote(id),
          );
      }
      _ref.read(sahaSyncStateProvider.notifier).set(
            SahaSyncState(
              phase: SahaSyncPhase.live,
              projectId: projectId,
              lastSyncedAt: DateTime.now(),
            ),
          );
    } catch (e, st) {
      debugPrint('SahaRealtimeSync onRealtime $table: $e\n$st');
    } finally {
      _applyingRemote = false;
    }
  }

  void _applyAttendanceRemote(
    PostgresChangeEvent event,
    Map<String, dynamic> row,
  ) {
    final notifier = _ref.read(attendanceProvider.notifier);
    if (event == PostgresChangeEvent.delete) {
      notifier.deleteRemote(
        projectId: row['project_id'] as String,
        personId: row['person_id'] as String,
        date: row['date'] as String,
      );
      return;
    }
    notifier.upsertRemote(SupabaseRowSync.attendanceFromRow(row));
  }

  void _applyPayloadRemote<T>(
    PostgresChangeEvent event,
    Map<String, dynamic> row, {
    required T Function(Map<String, dynamic>) parse,
    required void Function(T) applyUpsert,
    required void Function(String id) applyDelete,
  }) {
    final id = row['id'] as String? ?? '';
    if (event == PostgresChangeEvent.delete) {
      if (id.isNotEmpty) applyDelete(id);
      return;
    }
    final raw = row['payload'];
    final payload =
        raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    payload['projectId'] = row['project_id'];
    if (payload['id'] == null) payload['id'] = id;
    applyUpsert(parse(payload));
  }

  Future<void> _pullAttendance(String projectId) async {
    final remote = await _rows.pullAttendance(projectId);
    if (remote.isEmpty) return;
    final notifier = _ref.read(attendanceProvider.notifier);
    final others =
        notifier.state.where((a) => a.projectId != projectId).toList();
    notifier.replaceAllQuiet([
      ...others,
      for (final (a, _) in remote) a,
    ]);
  }

  Future<void> _pullPersonnel(String projectId) async {
    final remote = await _rows.pullPayloadTable(
      table: 'saha_personnel',
      projectId: projectId,
    );
    if (remote.isEmpty) return;
    final notifier = _ref.read(personnelProvider.notifier);
    final others =
        notifier.state.where((p) => p.projectId != projectId).toList();
    final byId = <String, Person>{};
    for (final (raw, _) in remote) {
      final person = Person.fromJson(raw);
      byId[person.id] = person;
    }
    notifier.replaceAllQuiet([
      ...others,
      ...byId.values,
    ]);
    notifier.dedupeForProject(projectId);
  }

  Future<void> _pullProduction(String projectId) async {
    final remote = await _rows.pullPayloadTable(
      table: 'saha_production',
      projectId: projectId,
    );
    if (remote.isEmpty) return;
    final notifier = _ref.read(productionProvider.notifier);
    final others =
        notifier.state.where((p) => p.projectId != projectId).toList();
    notifier.replaceAllQuiet([
      ...others,
      for (final (p, _) in remote) Production.fromJson(p),
    ]);
  }

  Future<void> _pullTasks(String projectId) async {
    final remote = await _rows.pullPayloadTable(
      table: 'saha_tasks',
      projectId: projectId,
    );
    if (remote.isEmpty) return;
    final notifier = _ref.read(tasksProvider.notifier);
    final others =
        notifier.state.where((t) => t.projectId != projectId).toList();
    notifier.replaceAllQuiet([
      ...others,
      for (final (t, _) in remote) SiteTask.fromJson(t),
    ]);
  }

  Future<void> _pullDailyReports(String projectId) async {
    final remote = await _rows.pullPayloadTable(
      table: 'saha_daily_reports',
      projectId: projectId,
    );
    if (remote.isEmpty) return;
    final notifier = _ref.read(dailyReportsProvider.notifier);
    final others =
        notifier.state.where((r) => r.projectId != projectId).toList();
    notifier.replaceAllQuiet([
      ...others,
      for (final (r, _) in remote) DailyReport.fromJson(r),
    ]);
  }

  Future<void> _pullYevmiyeli(String projectId) async {
    final remote = await _rows.pullPayloadTable(
      table: 'saha_yevmiyeli',
      projectId: projectId,
    );
    if (remote.isEmpty) return;
    final notifier = _ref.read(yevmiyeliIsProvider.notifier);
    final others =
        notifier.state.where((e) => e.projectId != projectId).toList();
    notifier.replaceAllQuiet([
      ...others,
      for (final (e, _) in remote) YevmiyeliIsKaydi.fromJson(e),
    ]);
  }

  Future<void> _pullUninsured(String projectId) async {
    final remote = await _rows.pullPayloadTable(
      table: 'saha_uninsured_teams',
      projectId: projectId,
    );
    if (remote.isEmpty) return;
    final notifier = _ref.read(uninsuredTeamsProvider.notifier);
    final others =
        notifier.state.where((e) => e.projectId != projectId).toList();
    notifier.replaceAllQuiet([
      ...others,
      for (final (e, _) in remote) UninsuredTeamEntry.fromJson(e),
    ]);
  }

  Future<void> _migrateFromSnapshotsIfNeeded(String projectId) async {
    final attRemote = await _rows.pullAttendance(projectId);
    final peopleRemote = await _rows.pullPayloadTable(
      table: 'saha_personnel',
      projectId: projectId,
    );
    if (attRemote.isNotEmpty || peopleRemote.isNotEmpty) return;

    // Eski snapshot yolu — satırlar boşsa bir kez içe aktar.
    await _ref.read(collaborationControllerProvider).pullDomain(projectId);

    if (!_canEdit(projectId)) return;

    final hasLocal = _ref
            .read(attendanceProvider)
            .any((a) => a.projectId == projectId) ||
        _ref.read(personnelProvider).any((p) => p.projectId == projectId) ||
        _ref.read(productionProvider).any((p) => p.projectId == projectId) ||
        _ref.read(tasksProvider).any((t) => t.projectId == projectId) ||
        _ref.read(dailyReportsProvider).any((r) => r.projectId == projectId);

    // Sahipte yerel veri var, bulut boş → tüm domain'i satır tablolarına yükle.
    if (hasLocal) {
      await pushProject(projectId);
    }
  }
}
