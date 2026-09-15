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
import 'plan_cloud_sync_provider.dart';
import 'production_provider.dart';
import 'tasks_provider.dart';
import 'uninsured_teams_provider.dart';
import 'yevmiyeli_is_provider.dart';

final puantajBackupControllerProvider =
    Provider<PuantajBackupController>((ref) {
  return PuantajBackupController(ref);
});

class PuantajBackupController {
  PuantajBackupController(this._ref);

  final Ref _ref;

  Future<void> exportProjects(Set<String> projectIds) async {
    if (projectIds.isEmpty) {
      throw PuantajBackupException('En az bir şantiye seçin');
    }
    final payload = _buildPayload(projectIds: projectIds);
    final projects = payload.projects.map(Project.fromJson).toList();
    final fileName = _exportFileName(projects, payload.exportedAt);
    await puantajBackupService.exportBackup(
      payload,
      downloadFileName: fileName,
    );
  }

  @Deprecated('Use exportProjects')
  Future<void> exportAll() async {
    final ids = _ref.read(projectsProvider).map((p) => p.id).toSet();
    await exportProjects(ids);
  }

  /// Dosyadan yalnızca seçilen şantiyeyi birleştirir; diğer projelere dokunmaz.
  Future<Project?> importProject(
    PuantajBackupPayload payload,
    String projectId,
  ) async {
    Map<String, dynamic>? projectJson;
    for (final raw in payload.projects) {
      if (raw['id'] == projectId) {
        projectJson = raw;
        break;
      }
    }
    if (projectJson == null) {
      throw PuantajBackupException('Yedekte bu şantiye bulunamadı');
    }
    final project = Project.fromJson(projectJson);

    _purgeProjectData(projectId);

    _ref.read(projectsProvider.notifier).upsert(project);

    final personnel = payload.personnel
        .where((j) => j['projectId'] == projectId)
        .map(Person.fromJson)
        .toList();
    _ref.read(personnelProvider.notifier).addAll(personnel);

    _mergeProjectRecords(
      projectId: projectId,
      attendance: payload.attendance,
      productions: payload.productions,
      tasks: payload.tasks,
      dailyReports: payload.dailyReports,
      yevmiyeliIs: payload.yevmiyeliIs,
      uninsuredTeams: payload.uninsuredTeams,
    );

    _mergeCatalogs(payload);
    _restoreVerimCachesForProject(payload, projectId);

    final activeId = _ref.read(activeProjectIdProvider);
    if (activeId == null || activeId == projectId) {
      _ref.read(activeProjectIdProvider.notifier).set(project.id);
    }

    return project;
  }

  /// Mevcut verinin tamamının üzerine yazar (eski davranış).
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
      } catch (_) {}
    }

    if (payload.dailyReportExportSections != null) {
      try {
        _ref.read(dailyReportExportSectionsProvider.notifier).save(
              DailyReportExportSections.fromJson(
                payload.dailyReportExportSections!,
              ),
            );
      } catch (_) {}
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

  Future<PuantajBackupPayload?> pickBackupFile() =>
      puantajBackupService.pickAndParse();

  PuantajBackupPayload _buildPayload({required Set<String> projectIds}) {
    final projects = _ref
        .read(projectsProvider)
        .where((p) => projectIds.contains(p.id))
        .toList();
    if (projects.isEmpty) {
      throw PuantajBackupException('Seçilen şantiyeler bulunamadı');
    }

    final activeId = _ref.read(activeProjectIdProvider);
    final scopeActive =
        activeId != null && projectIds.contains(activeId) ? activeId : projects.first.id;

    final scheduleService = _ref.read(isProgramiCloudServiceProvider);
    final kesifService = _ref.read(kesifCloudServiceProvider);

    final workSchedulesByProject = <String, Map<String, dynamic>>{};
    final kesifByProject = <String, Map<String, dynamic>>{};
    for (final id in projectIds) {
      final schedule = scheduleService.cachedFor(id);
      if (schedule != null) {
        workSchedulesByProject[id] = schedule.toJson();
      }
      final kesif = kesifService.cachedFor(id);
      if (kesif != null) {
        kesifByProject[id] = kesif.toJson();
      }
    }

    final company = _ref.read(companyInfoProvider);
    final exportSections = _ref.read(dailyReportExportSectionsProvider);

    final personnel = _ref
        .read(personnelProvider)
        .where((e) => projectIds.contains(e.projectId))
        .map((e) => e.toJson())
        .toList();

    final professions = _professionsForExport(projectIds);
    final teams = _teamsForExport(projectIds);
    final taskCategories = _taskCategoriesForExport(projectIds);

    return PuantajBackupPayload(
      version: puantajBackupVersion,
      exportedAt: DateTime.now(),
      activeProjectId: scopeActive,
      scopeProjectIds: projectIds.toList()..sort(),
      projects: projects.map((e) => e.toJson()).toList(),
      personnel: personnel,
      attendance: _ref
          .read(attendanceProvider)
          .where((e) => projectIds.contains(e.projectId))
          .map((e) => e.toJson())
          .toList(),
      productions: _ref
          .read(productionProvider)
          .where((e) => projectIds.contains(e.projectId))
          .map((e) => e.toJson())
          .toList(),
      professions: professions,
      teams: teams,
      taskCategories: taskCategories,
      tasks: _ref
          .read(tasksProvider)
          .where((e) => projectIds.contains(e.projectId))
          .map((e) => e.toJson())
          .toList(),
      dailyReports: _ref
          .read(dailyReportsProvider)
          .where((e) => projectIds.contains(e.projectId))
          .map((e) => e.toJson())
          .toList(),
      yevmiyeliIs: _ref
          .read(yevmiyeliIsProvider)
          .where((e) => projectIds.contains(e.projectId))
          .map((e) => e.toJson())
          .toList(),
      uninsuredTeams: _ref
          .read(uninsuredTeamsProvider)
          .where((e) => projectIds.contains(e.projectId))
          .map((e) => e.toJson())
          .toList(),
      companyInfo: company.isEmpty ? null : company.toJson(),
      dailyReportExportSections: exportSections.toJson(),
      workSchedule: workSchedulesByProject[scopeActive],
      kesif: kesifByProject[scopeActive],
      workSchedulesByProject: workSchedulesByProject,
      kesifByProject: kesifByProject,
    );
  }

  List<String> _professionsForExport(Set<String> projectIds) {
    return _ref
        .read(personnelProvider)
        .where((p) => projectIds.contains(p.projectId))
        .map((p) => p.profession.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _teamsForExport(Set<String> projectIds) {
    return _ref
        .read(personnelProvider)
        .where((p) => projectIds.contains(p.projectId))
        .map((p) => p.team.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _taskCategoriesForExport(Set<String> projectIds) {
    return _ref
        .read(tasksProvider)
        .where((t) => projectIds.contains(t.projectId))
        .map((t) => t.category.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  void _purgeProjectData(String projectId) {
    _ref.read(personnelProvider.notifier).deleteForProject(projectId);
    _ref.read(attendanceProvider.notifier).deleteForProject(projectId);
    _ref.read(productionProvider.notifier).deleteForProject(projectId);
    _ref.read(tasksProvider.notifier).deleteForProject(projectId);
    _ref.read(dailyReportsProvider.notifier).deleteForProject(projectId);
    _ref.read(yevmiyeliIsProvider.notifier).deleteForProject(projectId);
    _ref.read(uninsuredTeamsProvider.notifier).deleteForProject(projectId);

    final scheduleBox = _ref.read(workScheduleCacheBoxProvider);
    final kesifBox = _ref.read(kesifCacheBoxProvider);
    scheduleBox.delete('schedule:$projectId');
    kesifBox.delete('kesif:$projectId');
  }

  void _mergeProjectRecords({
    required String projectId,
    required List<Map<String, dynamic>> attendance,
    required List<Map<String, dynamic>> productions,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> dailyReports,
    required List<Map<String, dynamic>> yevmiyeliIs,
    required List<Map<String, dynamic>> uninsuredTeams,
  }) {
    bool match(Map<String, dynamic> j) => j['projectId'] == projectId;

    final att = [
      ..._ref.read(attendanceProvider),
      ...attendance.where(match).map(Attendance.fromJson),
    ];
    _ref.read(attendanceProvider.notifier).replaceAll(att);

    final prod = [
      ..._ref.read(productionProvider),
      ...productions.where(match).map(Production.fromJson),
    ];
    _ref.read(productionProvider.notifier).replaceAll(prod);

    final taskList = [
      ..._ref.read(tasksProvider),
      ...tasks.where(match).map(SiteTask.fromJson),
    ];
    _ref.read(tasksProvider.notifier).replaceAll(taskList);

    final reports = [
      ..._ref.read(dailyReportsProvider),
      ...dailyReports.where(match).map(DailyReport.fromJson),
    ];
    _ref.read(dailyReportsProvider.notifier).replaceAll(reports);

    final yev = [
      ..._ref.read(yevmiyeliIsProvider),
      ...yevmiyeliIs.where(match).map(YevmiyeliIsKaydi.fromJson),
    ];
    _ref.read(yevmiyeliIsProvider.notifier).replaceAll(yev);

    final teams = [
      ..._ref.read(uninsuredTeamsProvider),
      ...uninsuredTeams.where(match).map(UninsuredTeamEntry.fromJson),
    ];
    _ref.read(uninsuredTeamsProvider.notifier).replaceAll(teams);
  }

  void _mergeCatalogs(PuantajBackupPayload payload) {
    if (payload.professions.isNotEmpty) {
      final merged = {
        ..._ref.read(professionsProvider),
        ...payload.professions,
      }.toList()
        ..sort();
      _ref.read(professionsProvider.notifier).replaceAll(merged);
    }
    if (payload.teams.isNotEmpty) {
      final merged = {..._ref.read(teamsProvider), ...payload.teams}.toList()
        ..sort();
      _ref.read(teamsProvider.notifier).replaceAll(merged);
    }
    if (payload.taskCategories.isNotEmpty) {
      final merged = {
        ..._ref.read(taskCategoriesProvider),
        ...payload.taskCategories,
      }.toList()
        ..sort();
      _ref.read(taskCategoriesProvider.notifier).replaceAll(merged);
    }
  }

  void _restoreVerimCachesForProject(
    PuantajBackupPayload payload,
    String projectId,
  ) {
    final scheduleService = _ref.read(isProgramiCloudServiceProvider);
    final kesifService = _ref.read(kesifCloudServiceProvider);

    final scheduleRaw = payload.workSchedulesByProject[projectId] ??
        (payload.activeProjectId == projectId ? payload.workSchedule : null);
    if (scheduleRaw != null) {
      try {
        scheduleService.cacheSnapshot(WorkScheduleSnapshot.fromJson(scheduleRaw));
      } catch (_) {}
    }

    final kesifRaw = payload.kesifByProject[projectId] ??
        (payload.activeProjectId == projectId ? payload.kesif : null);
    if (kesifRaw != null) {
      try {
        kesifService.cacheSnapshot(KesifSnapshot.fromJson(kesifRaw));
      } catch (_) {}
    }
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
  }
}

String _exportFileName(List<Project> projects, DateTime stamp) {
  final date =
      '${stamp.year}${stamp.month.toString().padLeft(2, '0')}${stamp.day.toString().padLeft(2, '0')}';
  if (projects.length == 1) {
    final slug = _fileSlug(projects.first.name);
    return 'santijet-puantaj-$slug-$date.json';
  }
  return 'santijet-puantaj-${projects.length}-santiye-$date.json';
}

String _fileSlug(String name) {
  var s = name.trim().toLowerCase();
  const map = {
    'ı': 'i',
    'ğ': 'g',
    'ü': 'u',
    'ş': 's',
    'ö': 'o',
    'ç': 'c',
    'İ': 'i',
    ' ': '-',
  };
  final b = StringBuffer();
  for (final rune in s.runes) {
    final c = String.fromCharCode(rune);
    if (map.containsKey(c)) {
      b.write(map[c]);
    } else if (RegExp(r'[a-z0-9\-]').hasMatch(c)) {
      b.write(c);
    }
  }
  final out = b.toString().replaceAll(RegExp(r'-+'), '-');
  return out.isEmpty ? 'santiye' : out;
}
