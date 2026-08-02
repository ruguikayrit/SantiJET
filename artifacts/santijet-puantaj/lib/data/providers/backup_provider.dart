import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/attendance.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/production.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/kesif_plan.dart';
import '../../domain/entities/work_schedule_plan.dart';
import '../services/puantaj_backup_service.dart';
import 'app_data_provider.dart';
import 'catalog_provider.dart';
import 'production_provider.dart';
import 'verim_provider.dart';

final puantajBackupControllerProvider =
    Provider<PuantajBackupController>((ref) {
  return PuantajBackupController(ref);
});

class PuantajBackupController {
  PuantajBackupController(this._ref);

  final Ref _ref;

  Future<void> exportAll() async {
    final projects = _ref.read(projectsProvider);
    final personnel = _ref.read(personnelProvider);
    final attendance = _ref.read(attendanceProvider);
    final productions = _ref.read(productionProvider);
    final professions = _ref.read(professionsProvider);
    final teams = _ref.read(teamsProvider);
    final activeId = _ref.read(activeProjectIdProvider);
    final verim = _ref.read(verimProvider);

    final payload = PuantajBackupPayload(
      version: puantajBackupVersion,
      exportedAt: DateTime.now(),
      activeProjectId: activeId,
      projects: projects.map((e) => e.toJson()).toList(),
      personnel: personnel.map((e) => e.toJson()).toList(),
      attendance: attendance.map((e) => e.toJson()).toList(),
      productions: productions.map((e) => e.toJson()).toList(),
      professions: professions,
      teams: teams,
      workSchedule: verim.schedule?.toJson(),
      kesif: verim.kesif?.toJson(),
    );

    await puantajBackupService.exportBackup(payload);
  }

  /// Mevcut verinin üzerine yazar. İptalde null döner.
  Future<PuantajBackupPayload?> importAll() async {
    final payload = await puantajBackupService.pickAndParse();
    if (payload == null) return null;

    _ref.read(projectsProvider.notifier).replaceAll(
          payload.projects.map(Project.fromJson).toList(),
        );
    _ref.read(personnelProvider.notifier).replaceAll(
          payload.personnel.map(Person.fromJson).toList(),
        );
    _ref.read(attendanceProvider.notifier).replaceAll(
          payload.attendance.map(Attendance.fromJson).toList(),
        );
    _ref.read(productionProvider.notifier).replaceAll(
          payload.productions.map(Production.fromJson).toList(),
        );

    if (payload.professions.isNotEmpty) {
      _ref.read(professionsProvider.notifier).replaceAll(payload.professions);
    }
    if (payload.teams.isNotEmpty) {
      _ref.read(teamsProvider.notifier).replaceAll(payload.teams);
    }

    final projects = _ref.read(projectsProvider);
    final wanted = payload.activeProjectId;
    if (wanted != null && projects.any((p) => p.id == wanted)) {
      _ref.read(activeProjectIdProvider.notifier).set(wanted);
    } else if (projects.isNotEmpty) {
      _ref.read(activeProjectIdProvider.notifier).set(projects.first.id);
    } else {
      _ref.read(activeProjectIdProvider.notifier).set(null);
    }

    if (payload.workSchedule != null) {
      try {
        final snap = WorkScheduleSnapshot.fromJson(payload.workSchedule!);
        _ref.read(isProgramiCloudServiceProvider).cacheSnapshot(snap);
      } catch (_) {
        // İş Programı önbelleği opsiyonel.
      }
    }
    if (payload.kesif != null) {
      try {
        final snap = KesifSnapshot.fromJson(payload.kesif!);
        _ref.read(kesifCloudServiceProvider).cacheSnapshot(snap);
      } catch (_) {
        // Keşif önbelleği opsiyonel.
      }
    }
    if (payload.workSchedule != null || payload.kesif != null) {
      _ref.read(verimProvider.notifier).reloadForActiveProject();
    }

    return payload;
  }
}
