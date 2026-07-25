import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/utils/puantaj_date.dart';
import '../../domain/entities/work_schedule_plan.dart';
import '../../domain/enums/attendance_status.dart';
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

  double? get workerEfficiency {
    final planned = item.plannedWorkerCount;
    if (planned == null || planned <= 0) return null;
    // Planlanan adam × gün aralığı yerine bugünkü / dönemsel
    // gerçekleşen adam-gün / planlanan adam oranı.
    return actualWorkerDays / planned;
  }

  double? get qtyEfficiency {
    final planned = item.plannedQty;
    if (planned == null || planned <= 0) return null;
    return actualQty / planned;
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
  final totalWorkerDays = projectAtt.fold<double>(0, (sum, a) {
    if (a.status == AttendanceStatus.present) return sum + 1;
    if (a.status == AttendanceStatus.half) return sum + 0.5;
    return sum;
  });

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
      .fold<double>(0, (sum, a) {
    if (a.status == AttendanceStatus.present) return sum + 1;
    if (a.status == AttendanceStatus.half) return sum + 0.5;
    return sum;
  });
});
