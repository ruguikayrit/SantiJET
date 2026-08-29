import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/kesif_plan.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/santijet_plan_pack.dart';
import '../../domain/entities/work_schedule_plan.dart';
import '../services/is_programi_cloud_service.dart';
import '../services/kesif_cloud_service.dart';
import '../services/plan_pack_service.dart';

/// İş Programı + Keşif önbellek kutuları — dosya içe aktarma / demo.
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

final planPackServiceProvider = Provider<PlanPackService>((ref) {
  return PlanPackService(
    kesif: ref.watch(kesifCloudServiceProvider),
    schedule: ref.watch(isProgramiCloudServiceProvider),
  );
});

final planCloudSyncControllerProvider =
    Provider<PlanCloudSyncController>((ref) {
  return PlanCloudSyncController(ref);
});

/// Plan önbelleği — dosya paketi ve demo; İmalat formunda “Dosyadan al”.
class PlanCloudSyncController {
  PlanCloudSyncController(this._ref);

  final Ref _ref;

  IsProgramiCloudService get _schedule =>
      _ref.read(isProgramiCloudServiceProvider);

  KesifCloudService get _kesif => _ref.read(kesifCloudServiceProvider);

  PlanPackService get packService => _ref.read(planPackServiceProvider);

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

  /// Demo: örnek Keşif + İş Programı önbelleğe yazar.
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

  /// Dosya seç → parse → aktif projeye önbellek. [null] = iptal.
  Future<({
    SantijetPlanPack pack,
    KesifSnapshot? kesif,
    WorkScheduleSnapshot? schedule,
  })?> importPackForProject(Project project) async {
    final pack = await packService.pickAndParse();
    if (pack == null) return null;
    final applied = packService.applyToCache(
      pack: pack,
      localProjectId: project.id,
    );
    return (pack: pack, kesif: applied.kesif, schedule: applied.schedule);
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

    return (
      schedule: _schedule.cachedFor(project.id),
      kesif: _kesif.cachedFor(project.id),
    );
  }
}
