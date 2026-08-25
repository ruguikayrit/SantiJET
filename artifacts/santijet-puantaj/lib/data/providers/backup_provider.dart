import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/attendance.dart';
import '../../domain/entities/company_info.dart';
import '../../domain/entities/daily_report.dart';
import '../../domain/entities/kesif_plan.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/production.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/site_task.dart';
import '../../domain/entities/uninsured_team_entry.dart';
import '../../domain/entities/work_schedule_plan.dart';
import '../../domain/entities/yevmiyeli_is_kaydi.dart';
import '../services/daily_report_export_sections.dart';
import '../services/puantaj_backup_service.dart';
import 'app_data_provider.dart';
import 'catalog_provider.dart';
import 'company_provider.dart';
import 'daily_report_export_sections_provider.dart';
import 'daily_report_provider.dart';
import 'production_provider.dart';
import 'tasks_provider.dart';
import 'uninsured_teams_provider.dart';
import 'verim_provider.dart';
import 'yevmiyeli_is_provider.dart';

final puantajBackupControllerProvider =
    Provider<PuantajBackupController>((ref) {
  return PuantajBackupController(ref);
});

class PuantajBackupController {
  PuantajBackupController(this._ref);

  final Ref _ref;

  Future<void> exportAll() async {
    final projects = _ref.read(projectsProvider);
    final activeId = _ref.read(activeProjectIdProvider);
    final verim = _ref.read(verimProvider);
    final scheduleService = _ref.read(isProgramiCloudServiceProvider);
    final kesifService = _ref.read(kesifCloudServiceProvider);

    final workSchedulesByProject = <String, Map<String, dynamic>>{};
    final kesifByProject = <String, Map<String, dynamic>>{};
    for (final p in projects) {
      final schedule = scheduleService.cachedFor(p.id);
      if (schedule != null) {
        workSchedulesByProject[p.id] = schedule.toJson();
      }
      final kesif = kesifService.cachedFor(p.id);
      if (kesif != null) {
        kesifByProject[p.id] = kesif.toJson();
      }
    }

    final company = _ref.read(companyInfoProvider);
    final exportSections = _ref.read(dailyReportExportSectionsProvider);

    final payload = PuantajBackupPayload(
      version: puantajBackupVersion,
      exportedAt: DateTime.now(),
      activeProjectId: activeId,
      projects: projects.map((e) => e.toJson()).toList(),
      personnel: _ref.read(personnelProvider).map((e) => e.toJson()).toList(),
      attendance: _ref.read(attendanceProvider).map((e) => e.toJson()).toList(),
      productions:
          _ref.read(productionProvider).map((e) => e.toJson()).toList(),
      professions: _ref.read(professionsProvider),
      teams: _ref.read(teamsProvider),
      taskCategories: _ref.read(taskCategoriesProvider),
      tasks: _ref.read(tasksProvider).map((e) => e.toJson()).toList(),
      dailyReports:
          _ref.read(dailyReportsProvider).map((e) => e.toJson()).toList(),
      yevmiyeliIs:
          _ref.read(yevmiyeliIsProvider).map((e) => e.toJson()).toList(),
      uninsuredTeams:
          _ref.read(uninsuredTeamsProvider).map((e) => e.toJson()).toList(),
      companyInfo: company.isEmpty ? null : company.toJson(),
      dailyReportExportSections: exportSections.toJson(),
      workSchedule: verim.schedule?.toJson(),
      kesif: verim.kesif?.toJson(),
      workSchedulesByProject: workSchedulesByProject,
      kesifByProject: kesifByProject,
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
    _ref.read(tasksProvider.notifier).replaceAll(
          payload.tasks.map(SiteTask.fromJson).toList(),
        );
    _ref.read(dailyReportsProvider.notifier).replaceAll(
          payload.dailyReports.map(DailyReport.fromJson).toList(),
        );
    _ref.read(yevmiyeliIsProvider.notifier).replaceAll(
          payload.yevmiyeliIs.map(YevmiyeliIsKaydi.fromJson).toList(),
        );
    _ref.read(uninsuredTeamsProvider.notifier).replaceAll(
          payload.uninsuredTeams.map(UninsuredTeamEntry.fromJson).toList(),
        );

    if (payload.professions.isNotEmpty) {
      _ref.read(professionsProvider.notifier).replaceAll(payload.professions);
    }
    if (payload.teams.isNotEmpty) {
      _ref.read(teamsProvider.notifier).replaceAll(payload.teams);
    }
    if (payload.taskCategories.isNotEmpty) {
      _ref
          .read(taskCategoriesProvider.notifier)
          .replaceAll(payload.taskCategories);
    }

    if (payload.companyInfo != null) {
      try {
        _ref.read(companyInfoProvider.notifier).replace(
              CompanyInfo.fromJson(payload.companyInfo!),
            );
      } catch (_) {
        // Firma bilgisi opsiyonel.
      }
    }

    if (payload.dailyReportExportSections != null) {
      try {
        _ref.read(dailyReportExportSectionsProvider.notifier).save(
              DailyReportExportSections.fromJson(
                payload.dailyReportExportSections!,
              ),
            );
      } catch (_) {
        // PDF başlık tercihleri opsiyonel.
      }
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

    _restoreVerimCaches(payload);

    return payload;
  }

  void _restoreVerimCaches(PuantajBackupPayload payload) {
    final scheduleService = _ref.read(isProgramiCloudServiceProvider);
    final kesifService = _ref.read(kesifCloudServiceProvider);
    final scheduleBox = _ref.read(workScheduleCacheBoxProvider);
    final kesifBox = _ref.read(kesifCacheBoxProvider);

    for (final key in scheduleBox.keys.toList()) {
      if (key.toString().startsWith('schedule:')) {
        scheduleBox.delete(key);
      }
    }
    for (final key in kesifBox.keys.toList()) {
      if (key.toString().startsWith('kesif:')) {
        kesifBox.delete(key);
      }
    }

    void cacheSchedule(Map<String, dynamic> raw) {
      try {
        scheduleService.cacheSnapshot(WorkScheduleSnapshot.fromJson(raw));
      } catch (_) {}
    }

    void cacheKesif(Map<String, dynamic> raw) {
      try {
        kesifService.cacheSnapshot(KesifSnapshot.fromJson(raw));
      } catch (_) {}
    }

    if (payload.workSchedulesByProject.isNotEmpty) {
      for (final entry in payload.workSchedulesByProject.entries) {
        cacheSchedule(entry.value);
      }
    } else if (payload.workSchedule != null) {
      cacheSchedule(payload.workSchedule!);
    }

    if (payload.kesifByProject.isNotEmpty) {
      for (final entry in payload.kesifByProject.entries) {
        cacheKesif(entry.value);
      }
    } else if (payload.kesif != null) {
      cacheKesif(payload.kesif!);
    }

    _ref.read(verimProvider.notifier).reloadForActiveProject();
  }
}
