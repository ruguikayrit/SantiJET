import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/repositories/project_data_repository.dart';
import 'package:santijet_demir/data/services/project_backup_service.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_storage_provider.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

final projectBackupControllerProvider = Provider<ProjectBackupController>((ref) {
  return ProjectBackupController(ref);
});

class ProjectBackupController {
  ProjectBackupController(this._ref);

  final Ref _ref;

  ProjectDataRepository get _dataRepo =>
      _ref.read(projectDataRepositoryProvider);

  Future<void> exportProject({bool includeSettings = true}) async {
    final projectId = _ref.read(activeProjectIdProvider);
    final project = _ref.read(activeProjectProvider);
    if (projectId == null || project == null) {
      throw BackupParseException('Aktif proje bulunamadı');
    }

    final payload = BackupPayload(
      scope: includeSettings ? BackupScope.full : BackupScope.project,
      version: backupVersion,
      exportedAt: DateTime.now(),
      projectId: projectId,
      projectName: project.name,
      domains: _dataRepo.exportDomains(projectId),
      settings: includeSettings ? _ref.read(appSettingsProvider).toJson() : null,
    );

    await projectBackupService.shareBackup(payload);
  }

  Future<void> exportSurvey() async {
    final projectId = _ref.read(activeProjectIdProvider);
    final project = _ref.read(activeProjectProvider);
    if (projectId == null || project == null) {
      throw BackupParseException('Aktif proje bulunamadı');
    }

    final survey = _ref.read(surveyProjectProvider);

    final payload = BackupPayload(
      scope: BackupScope.survey,
      version: backupVersion,
      exportedAt: DateTime.now(),
      projectId: projectId,
      projectName: project.name,
      domains: {'survey': survey.toJson()},
    );

    await projectBackupService.shareBackup(payload);
  }

  Future<ImportSummary> importBackup({
    required BackupScope expectedScope,
  }) async {
    final projectId = _ref.read(activeProjectIdProvider);
    if (projectId == null) {
      throw BackupParseException('İçe aktarmak için proje seçin');
    }

    final payload = await projectBackupService.pickAndParseBackup();
    if (payload == null) {
      return ImportSummary.cancelled();
    }

    _validateScope(payload.scope, expectedScope);

    if (expectedScope == BackupScope.survey &&
        !payload.domains.containsKey('survey')) {
      throw BackupParseException('Dosyada keşif verisi bulunamadı');
    }

    final domainsToImport = expectedScope == BackupScope.survey
        ? {'survey': payload.domains['survey']!}
        : payload.domains;

    await _dataRepo.importDomains(projectId, domainsToImport);

    if (payload.settings != null &&
        (expectedScope == BackupScope.full || expectedScope == BackupScope.project)) {
      await _ref
          .read(appSettingsProvider.notifier)
          .restoreBackup(payload.settings!);
    }

    _reloadProviders(projectId, domainsToImport);

    return ImportSummary(
      scope: payload.scope,
      projectName: payload.projectName,
      domainCount: domainsToImport.length,
      cancelled: false,
    );
  }

  void _validateScope(BackupScope fileScope, BackupScope expectedScope) {
    switch (expectedScope) {
      case BackupScope.survey:
        if (fileScope != BackupScope.survey) {
          throw BackupParseException(
            'Bu dosya keşif yedeği değil. Proje yedeği Ayarlar ekranından içe aktarılabilir.',
          );
        }
      case BackupScope.project:
      case BackupScope.full:
        if (fileScope == BackupScope.survey) {
          throw BackupParseException(
            'Bu dosya yalnızca keşif yedeği. Keşif sayfasından içe aktarın.',
          );
        }
    }
  }

  void _reloadProviders(
    String projectId,
    Map<String, Map<String, dynamic>> domains,
  ) {
    if (domains.containsKey('survey')) {
      _ref.read(surveyProjectProvider.notifier).reloadForProject(projectId);
    }
    if (domains.containsKey('orders')) {
      _ref.read(ordersProvider.notifier).loadForProject(projectId);
    }
    if (domains.containsKey('deliveries')) {
      _ref.read(deliveriesProvider.notifier).loadForProject(projectId);
    }
    if (domains.containsKey('field_counts')) {
      _ref.read(fieldCountsProvider.notifier).loadForProject(projectId);
    }
    if (domains.containsKey('rebar_metraj')) {
      _ref.read(savedRebarMetrajProvider.notifier).loadForProject(projectId);
    }
  }
}

class ImportSummary {
  const ImportSummary({
    required this.scope,
    required this.projectName,
    required this.domainCount,
    required this.cancelled,
  });

  factory ImportSummary.cancelled() => const ImportSummary(
        scope: null,
        projectName: null,
        domainCount: 0,
        cancelled: true,
      );

  final BackupScope? scope;
  final String? projectName;
  final int domainCount;
  final bool cancelled;
}
