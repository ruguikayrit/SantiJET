import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/utils/puantaj_date.dart';
import '../../domain/entities/kesif_plan.dart';
import '../../domain/entities/production.dart';
import '../../domain/entities/work_schedule_plan.dart';
import '../services/is_programi_cloud_service.dart';
import '../services/kesif_cloud_service.dart';
import 'app_data_provider.dart';
import 'production_provider.dart';

final workScheduleCacheBoxProvider = Provider<Box>(
  (ref) =>
      throw UnimplementedError('workScheduleCacheBoxProvider override edilmeli'),
);

final kesifCacheBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('kesifCacheBoxProvider override edilmeli'),
);

final isProgramiCloudServiceProvider = Provider<IsProgramiCloudService>((ref) {
  return IsProgramiCloudService(ref.watch(workScheduleCacheBoxProvider));
});

final kesifCloudServiceProvider = Provider<KesifCloudService>((ref) {
  return KesifCloudService(ref.watch(kesifCacheBoxProvider));
});

enum VerimSyncStatus { idle, syncing, ready, unavailable, error }

class VerimState {
  const VerimState({
    this.schedule,
    this.kesif,
    this.status = VerimSyncStatus.idle,
    this.message,
  });

  /// Plan süre / iş gücü — İş Programı bulutu.
  final WorkScheduleSnapshot? schedule;

  /// Plan metraj — Keşif bulutu.
  final KesifSnapshot? kesif;

  final VerimSyncStatus status;
  final String? message;

  bool get hasSchedulePlan =>
      schedule != null && schedule!.items.isNotEmpty;

  bool get hasKesifPlan => kesif != null && kesif!.items.isNotEmpty;

  /// Verim satırları için İş Programı + Keşif planı gerekir.
  bool get hasCloudPlan => hasSchedulePlan && hasKesifPlan;

  /// Geriye dönük: eski kod `snapshot` bekliyorsa İş Programı’nı döner.
  WorkScheduleSnapshot? get snapshot => schedule;

  VerimState copyWith({
    WorkScheduleSnapshot? schedule,
    KesifSnapshot? kesif,
    VerimSyncStatus? status,
    String? message,
    bool clearMessage = false,
    bool clearSchedule = false,
    bool clearKesif = false,
  }) {
    return VerimState(
      schedule: clearSchedule ? null : (schedule ?? this.schedule),
      kesif: clearKesif ? null : (kesif ?? this.kesif),
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

/// Tek bir imalat satırı için plan vs gerçekleşen (İmalat sekmesi kaynaklı).
class VerimRow {
  const VerimRow({required this.production});

  final Production production;

  String get imalatName => production.name;
  String get unit => production.unit;
  String get teamName =>
      production.teamName.trim().isEmpty ? 'Diğer' : production.teamName.trim();
  String get locationLabel => production.locationLabel;

  /// Planlanan adam-gün — iş gücü × gün.
  double get plannedWorkerDays => production.plannedWorkerDays;

  /// Plan metraj — imalat formundaki planlanan miktar.
  double? get plannedQty {
    final q = production.plannedQty;
    if (q > 0) return q;
    return null;
  }

  double get actualWorkerDays => production.actualLaborDays;
  double get actualQty => production.completedQty;

  /// Birim verim =
  /// (gerçek metraj / gerçek adam-gün) / (plan metraj / plan adam-gün).
  double? get unitEfficiency {
    final pQty = plannedQty;
    final pAg = plannedWorkerDays;
    if (pQty == null || pQty <= 0) return null;
    if (pAg <= 0 || actualWorkerDays <= 0) return null;
    final actualRate = actualQty / actualWorkerDays;
    final planRate = pQty / pAg;
    if (planRate <= 0) return null;
    return actualRate / planRate;
  }
}

String _normName(String s) => s
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ');

KesifItem? matchKesifItem(List<KesifItem> items, WorkScheduleItem schedule) {
  final id = schedule.imalatId.trim();
  if (id.isNotEmpty) {
    for (final k in items) {
      if (k.imalatId.trim() == id) return k;
    }
  }
  final target = _normName(schedule.imalatName);
  if (target.isEmpty) return null;
  for (final k in items) {
    if (_normName(k.imalatName) == target) return k;
  }
  for (final k in items) {
    final n = _normName(k.imalatName);
    if (n.contains(target) || target.contains(n)) return k;
  }
  return null;
}

class VerimNotifier extends StateNotifier<VerimState> {
  VerimNotifier(this._ref) : super(const VerimState()) {
    _loadCache();
  }

  final Ref _ref;

  IsProgramiCloudService get _scheduleService =>
      _ref.read(isProgramiCloudServiceProvider);

  KesifCloudService get _kesifService =>
      _ref.read(kesifCloudServiceProvider);

  void _loadCache() {
    final project = _ref.read(activeProjectProvider);
    if (project == null) {
      state = const VerimState(status: VerimSyncStatus.idle);
      return;
    }
    final schedule = _scheduleService.cachedFor(project.id);
    final kesif = _kesifService.cachedFor(project.id);
    final hasS = schedule != null && schedule.items.isNotEmpty;
    final hasK = kesif != null && kesif.items.isNotEmpty;

    if (hasS && hasK) {
      state = VerimState(
        schedule: schedule,
        kesif: kesif,
        status: VerimSyncStatus.ready,
        message:
            'İş Programı: ${_fmt(schedule.updatedAt)} · Keşif: ${_fmt(kesif.updatedAt)}',
      );
    } else if (hasS || hasK) {
      final missing = [
        if (!hasS) 'İş Programı (süre)',
        if (!hasK) 'Keşif (metraj)',
      ].join(' + ');
      state = VerimState(
        schedule: schedule,
        kesif: kesif,
        status: VerimSyncStatus.unavailable,
        message: 'Eksik bulut planı: $missing. Senkron gerekli.',
      );
    } else {
      state = const VerimState(
        status: VerimSyncStatus.unavailable,
        message:
            'Verim için İş Programı (süre) ve Keşif (plan metraj) bulut verisi gerekir.',
      );
    }
  }

  void reloadForActiveProject() => _loadCache();

  void clear() {
    state = const VerimState(status: VerimSyncStatus.idle);
  }

  /// İş Programı + Keşif bulutunu birlikte çeker.
  Future<void> syncFromCloud({bool demoFallback = false}) async {
    final project = _ref.read(activeProjectProvider);
    if (project == null) {
      state = state.copyWith(
        status: VerimSyncStatus.error,
        message: 'Önce bir proje seçin (Ayarlar → Projeler).',
      );
      return;
    }

    state = state.copyWith(
      status: VerimSyncStatus.syncing,
      clearMessage: true,
    );

    WorkScheduleSnapshot? schedule;
    KesifSnapshot? kesif;
    final errors = <String>[];

    try {
      schedule = demoFallback
          ? await _scheduleService.syncDemo(
              projectId: project.id,
              projectName: project.name,
            )
          : await _scheduleService.sync(
              projectId: project.id,
              projectCode: project.code,
              projectName: project.name,
            );
    } on IsProgramiCloudException catch (e) {
      schedule = _scheduleService.cachedFor(project.id);
      errors.add(e.message);
    } catch (e) {
      schedule = _scheduleService.cachedFor(project.id);
      errors.add('İş Programı: $e');
    }

    try {
      kesif = demoFallback
          ? await _kesifService.syncDemo(
              projectId: project.id,
              projectName: project.name,
            )
          : await _kesifService.sync(
              projectId: project.id,
              projectCode: project.code,
              projectName: project.name,
            );
    } on KesifCloudException catch (e) {
      kesif = _kesifService.cachedFor(project.id);
      errors.add(e.message);
    } catch (e) {
      kesif = _kesifService.cachedFor(project.id);
      errors.add('Keşif: $e');
    }

    final hasS = schedule != null && schedule.items.isNotEmpty;
    final hasK = kesif != null && kesif.items.isNotEmpty;

    if (hasS && hasK) {
      state = VerimState(
        schedule: schedule,
        kesif: kesif,
        status: VerimSyncStatus.ready,
        message: demoFallback
            ? 'Demo İş Programı + Keşif yüklendi'
            : 'Senkron tamam — süre: İş Programı, metraj: Keşif',
      );
      return;
    }

    state = VerimState(
      schedule: schedule,
      kesif: kesif,
      status: (hasS || hasK)
          ? VerimSyncStatus.unavailable
          : VerimSyncStatus.error,
      message: errors.isEmpty
          ? 'Bulut planı eksik (İş Programı ve/veya Keşif).'
          : errors.join('\n'),
    );
  }

  static String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year} $hh:$mi';
  }
}

final verimProvider =
    StateNotifierProvider<VerimNotifier, VerimState>((ref) {
  final notifier = VerimNotifier(ref);
  ref.listen(activeProjectIdProvider, (_, __) {
    notifier.reloadForActiveProject();
  });
  return notifier;
});

/// Plan + gerçekleşen ← İmalat sekmesi (planlanan miktar / gün / iş gücü + günlük kayıtlar).
final verimRowsProvider = Provider<List<VerimRow>>((ref) {
  final project = ref.watch(activeProjectProvider);
  if (project == null) return const [];

  final productions = ref
      .watch(productionProvider)
      .where((p) => p.projectId == project.id)
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return [
    for (final p in productions) VerimRow(production: p),
  ];
});

/// Bugünkü toplam gerçekleşen adam-gün (aktif proje).
final todayWorkerDaysProvider = Provider<double>((ref) {
  final project = ref.watch(activeProjectProvider);
  if (project == null) return 0;
  final today = PuantajDate.today();
  final attendance = ref.watch(attendanceProvider);
  return attendance
      .where((a) => a.projectId == project.id && a.date == today)
      .fold<double>(0, (sum, a) => sum + a.yevmiye);
});

/// Ana sayfa Özet Verim — ekip bazında toplu birim verim.
class TeamVerimSummary {
  const TeamVerimSummary({
    required this.teamName,
    required this.actualWorkerDays,
    required this.plannedWorkerDays,
    required this.actualQty,
    required this.plannedQty,
    required this.planLineCount,
  });

  final String teamName;
  final double actualWorkerDays;
  final double plannedWorkerDays;
  final double actualQty;
  final double plannedQty;
  final int planLineCount;

  double? get unitEfficiency {
    if (plannedQty <= 0 || plannedWorkerDays <= 0) return null;
    if (actualWorkerDays <= 0) return null;
    // (gerçek metraj / gerçek AG) / (plan metraj / plan AG)
    final actualRate = actualQty / actualWorkerDays;
    final planRate = plannedQty / plannedWorkerDays;
    if (planRate <= 0) return null;
    return actualRate / planRate;
  }
}

final teamVerimSummariesProvider = Provider<List<TeamVerimSummary>>((ref) {
  final rows = ref.watch(verimRowsProvider);
  if (rows.isEmpty) return const [];

  final plannedAgByTeam = <String, double>{};
  final actualAgByTeam = <String, double>{};
  final plannedQtyByTeam = <String, double>{};
  final actualQtyByTeam = <String, double>{};
  final linesByTeam = <String, int>{};

  for (final row in rows) {
    final team = row.teamName;
    plannedAgByTeam[team] =
        (plannedAgByTeam[team] ?? 0) + row.plannedWorkerDays;
    actualAgByTeam[team] =
        (actualAgByTeam[team] ?? 0) + row.actualWorkerDays;
    plannedQtyByTeam[team] =
        (plannedQtyByTeam[team] ?? 0) + (row.plannedQty ?? 0);
    actualQtyByTeam[team] = (actualQtyByTeam[team] ?? 0) + row.actualQty;
    linesByTeam[team] = (linesByTeam[team] ?? 0) + 1;
  }

  final teams = plannedAgByTeam.keys.toList()..sort();
  return [
    for (final team in teams)
      TeamVerimSummary(
        teamName: team,
        actualWorkerDays: actualAgByTeam[team] ?? 0,
        plannedWorkerDays: plannedAgByTeam[team] ?? 0,
        actualQty: actualQtyByTeam[team] ?? 0,
        plannedQty: plannedQtyByTeam[team] ?? 0,
        planLineCount: linesByTeam[team] ?? 0,
      ),
  ];
});
