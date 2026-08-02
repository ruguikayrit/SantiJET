import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/utils/puantaj_date.dart';
import '../../domain/entities/work_schedule_plan.dart';
import '../services/is_programi_cloud_service.dart';
import 'app_data_provider.dart';
import 'production_provider.dart';

final workScheduleCacheBoxProvider = Provider<Box>(
  (ref) =>
      throw UnimplementedError('workScheduleCacheBoxProvider override edilmeli'),
);

final isProgramiCloudServiceProvider = Provider<IsProgramiCloudService>((ref) {
  return IsProgramiCloudService(ref.watch(workScheduleCacheBoxProvider));
});

enum VerimSyncStatus { idle, syncing, ready, unavailable, error }

class VerimState {
  const VerimState({
    this.snapshot,
    this.status = VerimSyncStatus.idle,
    this.message,
  });

  final WorkScheduleSnapshot? snapshot;
  final VerimSyncStatus status;
  final String? message;

  bool get hasCloudPlan => snapshot != null && snapshot!.items.isNotEmpty;

  VerimState copyWith({
    WorkScheduleSnapshot? snapshot,
    VerimSyncStatus? status,
    String? message,
    bool clearMessage = false,
    bool clearSnapshot = false,
  }) {
    return VerimState(
      snapshot: clearSnapshot ? null : (snapshot ?? this.snapshot),
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

/// Tek bir imalat satırı için plan vs gerçekleşen iş gücü / miktar.
class VerimRow {
  const VerimRow({
    required this.item,
    required this.actualWorkerDays,
    required this.actualQty,
  });

  final WorkScheduleItem item;
  final double actualWorkerDays;
  final double actualQty;

  /// Planlanan adam-gün: planlanan kişi × süre (gün).
  double get plannedWorkerDays {
    final workers = (item.plannedWorkerCount ?? 0).toDouble();
    if (workers <= 0) return 0;
    final days = item.durationDays;
    if (days != null && days > 0) return workers * days;
    return workers;
  }

  double? get plannedQty => item.plannedQty;

  /// Birim verim =
  /// (gerçek metraj / plan metraj) / (gerçek adam-gün / plan adam-gün).
  double? get unitEfficiency {
    final pQty = plannedQty;
    final pAg = plannedWorkerDays;
    if (pQty == null || pQty <= 0) return null;
    if (pAg <= 0 || actualWorkerDays <= 0) return null;
    final qtyRatio = actualQty / pQty;
    final laborRatio = actualWorkerDays / pAg;
    if (laborRatio <= 0) return null;
    return qtyRatio / laborRatio;
  }
}

class VerimNotifier extends StateNotifier<VerimState> {
  VerimNotifier(this._ref) : super(const VerimState()) {
    _loadCache();
  }

  final Ref _ref;

  IsProgramiCloudService get _service =>
      _ref.read(isProgramiCloudServiceProvider);

  void _loadCache() {
    final project = _ref.read(activeProjectProvider);
    if (project == null) {
      state = const VerimState(status: VerimSyncStatus.idle);
      return;
    }
    final cached = _service.cachedFor(project.id);
    if (cached != null && cached.items.isNotEmpty) {
      state = VerimState(
        snapshot: cached,
        status: VerimSyncStatus.ready,
        message: 'Son senkron: ${_fmt(cached.updatedAt)}',
      );
    } else {
      state = const VerimState(
        status: VerimSyncStatus.unavailable,
        message:
            'Verim hesabı için İş Programı uygulamasından bulut verisi gerekir.',
      );
    }
  }

  void reloadForActiveProject() => _loadCache();

  void clear() {
    state = const VerimState(status: VerimSyncStatus.idle);
  }

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

    try {
      final snap = demoFallback
          ? await _service.syncDemo(
              projectId: project.id,
              projectName: project.name,
            )
          : await _service.sync(
              projectId: project.id,
              projectCode: project.code,
              projectName: project.name,
            );
      state = VerimState(
        snapshot: snap,
        status: VerimSyncStatus.ready,
        message: demoFallback
            ? 'Demo bulut verisi yüklendi (${_fmt(snap.updatedAt)})'
            : 'Senkron tamam (${_fmt(snap.updatedAt)})',
      );
    } on IsProgramiCloudException catch (e) {
      final cached = _service.cachedFor(project.id);
      state = VerimState(
        snapshot: cached,
        status: cached != null && cached.items.isNotEmpty
            ? VerimSyncStatus.ready
            : VerimSyncStatus.unavailable,
        message: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: VerimSyncStatus.error,
        message: 'Senkron başarısız: $e',
      );
    }
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

/// Plan (İş Programı bulut) × gerçekleşen (yerel puantaj + imalat).
final verimRowsProvider = Provider<List<VerimRow>>((ref) {
  final verim = ref.watch(verimProvider);
  final snap = verim.snapshot;
  final project = ref.watch(activeProjectProvider);
  if (snap == null || project == null || snap.items.isEmpty) {
    return const [];
  }

  final attendance = ref.watch(attendanceProvider);
  final productions = ref.watch(productionProvider);

  final projectAtt = attendance.where((a) => a.projectId == project.id);
  // Mesai dahil adam-gün: (saat + mesai) / 8
  final totalWorkerDays =
      projectAtt.fold<double>(0, (sum, a) => sum + a.yevmiye);

  // İmalat bazlı dağılım yoksa iş gücünü planlanan adam oranına göre böl.
  final plannedSum = snap.items.fold<int>(
    0,
    (s, i) => s + (i.plannedWorkerCount ?? 0),
  );

  return [
    for (final item in snap.items)
      () {
        final share = plannedSum > 0 && item.plannedWorkerCount != null
            ? item.plannedWorkerCount! / plannedSum
            : (1 / snap.items.length);
        final nameLower = item.imalatName.toLowerCase();
        final qty = productions
            .where((p) =>
                p.projectId == project.id &&
                p.name.toLowerCase().contains(nameLower.split(' ').first))
            .fold<double>(0, (s, p) => s + p.completedQty);
        return VerimRow(
          item: item,
          actualWorkerDays: totalWorkerDays * share,
          actualQty: qty,
        );
      }(),
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

/// Ana sayfa Özet Verim — ekip bazlı birim verim.
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

  /// Birim verim =
  /// (gerçek metraj / plan metraj) / (gerçek adam-gün / plan adam-gün).
  double? get unitEfficiency {
    if (plannedQty <= 0 || plannedWorkerDays <= 0) return null;
    if (actualWorkerDays <= 0) return null;
    final qtyRatio = actualQty / plannedQty;
    final laborRatio = actualWorkerDays / plannedWorkerDays;
    if (laborRatio <= 0) return null;
    return qtyRatio / laborRatio;
  }
}

final teamVerimSummariesProvider = Provider<List<TeamVerimSummary>>((ref) {
  final verim = ref.watch(verimProvider);
  final snap = verim.snapshot;
  final project = ref.watch(activeProjectProvider);
  if (snap == null || project == null || snap.items.isEmpty) {
    return const [];
  }

  final people = ref.watch(activePersonnelProvider);
  final attendance = ref.watch(attendanceProvider);
  final productions = ref
      .watch(productionProvider)
      .where((p) => p.projectId == project.id)
      .toList(growable: false);

  String resolveTeam(WorkScheduleItem item) {
    final nameLower = item.imalatName.toLowerCase().trim();
    if (nameLower.isEmpty) return 'Diğer';
    final token = nameLower.split(RegExp(r'\s+')).first;
    for (final p in productions) {
      final pName = p.name.toLowerCase().trim();
      if (pName.isEmpty) continue;
      if (pName.contains(token) || nameLower.contains(pName.split(' ').first)) {
        final t = p.teamName.trim();
        return t.isEmpty ? 'Diğer' : t;
      }
    }
    return 'Diğer';
  }

  double plannedAdamGun(WorkScheduleItem item) {
    final workers = (item.plannedWorkerCount ?? 0).toDouble();
    if (workers <= 0) return 0;
    final days = item.durationDays;
    if (days != null && days > 0) return workers * days;
    return workers;
  }

  double actualQtyForItem(WorkScheduleItem item) {
    final nameLower = item.imalatName.toLowerCase();
    final token = nameLower.split(RegExp(r'\s+')).first;
    return productions
        .where((p) => p.name.toLowerCase().contains(token))
        .fold<double>(0, (s, p) => s + p.completedQty);
  }

  final plannedAgByTeam = <String, double>{};
  final plannedQtyByTeam = <String, double>{};
  final actualQtyByTeam = <String, double>{};
  final linesByTeam = <String, int>{};
  for (final item in snap.items) {
    final team = resolveTeam(item);
    plannedAgByTeam[team] =
        (plannedAgByTeam[team] ?? 0) + plannedAdamGun(item);
    plannedQtyByTeam[team] =
        (plannedQtyByTeam[team] ?? 0) + (item.plannedQty ?? 0);
    actualQtyByTeam[team] =
        (actualQtyByTeam[team] ?? 0) + actualQtyForItem(item);
    linesByTeam[team] = (linesByTeam[team] ?? 0) + 1;
  }

  final memberIdsByTeam = <String, Set<String>>{};
  for (final p in people) {
    if (!p.active) continue;
    final team = p.team.trim().isEmpty ? 'Diğer' : p.team.trim();
    memberIdsByTeam.putIfAbsent(team, () => <String>{}).add(p.id);
  }

  final actualAgByTeam = <String, double>{
    for (final t in plannedAgByTeam.keys) t: 0,
  };
  for (final a in attendance) {
    if (a.projectId != project.id) continue;
    for (final entry in memberIdsByTeam.entries) {
      if (!entry.value.contains(a.personId)) continue;
      actualAgByTeam[entry.key] = (actualAgByTeam[entry.key] ?? 0) + a.yevmiye;
      break;
    }
  }

  final teams = {
    ...plannedAgByTeam.keys,
    ...actualAgByTeam.keys.where((t) => (actualAgByTeam[t] ?? 0) > 0),
  }.toList()
    ..sort();

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
