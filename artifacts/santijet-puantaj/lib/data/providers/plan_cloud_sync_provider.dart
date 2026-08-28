import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/kesif_plan.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/work_schedule_plan.dart';
import '../services/is_programi_cloud_service.dart';
import '../services/kesif_cloud_service.dart';

/// İş Programı + Keşif önbellek kutuları — yalnızca İmalat “Buluttan al” için.
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

final planCloudSyncControllerProvider =
    Provider<PlanCloudSyncController>((ref) {
  return PlanCloudSyncController(ref);
});

/// Plan bulutu — Verim’den bağımsız; İmalat formu “Buluttan al” ve demo önbelleği.
class PlanCloudSyncController {
  PlanCloudSyncController(this._ref);

  final Ref _ref;

  IsProgramiCloudService get _schedule =>
      _ref.read(isProgramiCloudServiceProvider);

  KesifCloudService get _kesif => _ref.read(kesifCloudServiceProvider);

  WorkScheduleSnapshot? cachedSchedule(String projectId) =>
      _schedule.cachedFor(projectId);

  KesifSnapshot? cachedKesif(String projectId) =>
      _kesif.cachedFor(projectId);

  void clearProjectCaches(String projectId) {
    _schedule.clearCache(projectId);
    _kesif.clearCache(projectId);
  }

  void clearAllCaches() {
    final scheduleBox = _ref.read(workScheduleCacheBoxProvider);
    final kesifBox = _ref.read(kesifCacheBoxProvider);
    for (final key in scheduleBox.keys.toList()) {
      if (key.toString().startsWith('schedule:')) scheduleBox.delete(key);
    }
    for (final key in kesifBox.keys.toList()) {
      if (key.toString().startsWith('kesif:')) kesifBox.delete(key);
    }
  }

  /// Demo / staging: İş Programı + Keşif örneğini önbelleğe yazar.
  Future<void> syncDemoForProject({
    required String projectId,
    String? projectName,
  }) async {
    await _schedule.syncDemo(
      projectId: projectId,
      projectName: projectName,
    );
    await _kesif.syncDemo(
      projectId: projectId,
      projectName: projectName,
    );
  }

  Future<({WorkScheduleSnapshot? schedule, KesifSnapshot? kesif})> syncForProject(
    Project project, {
    bool demoFallback = false,
  }) async {
    if (demoFallback) {
      final schedule = await _schedule.syncDemo(
        projectId: project.id,
        projectName: project.name,
      );
      final kesif = await _kesif.syncDemo(
        projectId: project.id,
        projectName: project.name,
      );
      return (schedule: schedule, kesif: kesif);
    }

    WorkScheduleSnapshot? schedule;
    KesifSnapshot? kesif;

    try {
      schedule = await _schedule.sync(
        projectId: project.id,
        projectCode: project.code,
        projectName: project.name,
      );
    } on IsProgramiCloudException {
      schedule = _schedule.cachedFor(project.id);
    }

    try {
      kesif = await _kesif.sync(
        projectId: project.id,
        projectCode: project.code,
        projectName: project.name,
      );
    } on KesifCloudException {
      kesif = _kesif.cachedFor(project.id);
    }

    return (schedule: schedule, kesif: kesif);
  }
}
