import 'dart:convert';

import '../../domain/entities/kesif_plan.dart';
import '../../domain/entities/santijet_plan_pack.dart';
import '../../domain/entities/work_schedule_plan.dart';
import 'backup_file_access_stub.dart'
    if (dart.library.html) 'backup_file_access_web.dart'
    if (dart.library.io) 'backup_file_access_io.dart' as file_access;
import 'is_programi_cloud_service.dart';
import 'kesif_cloud_service.dart';

List<int> _utf8(String text) => utf8.encode(text);

/// Offline plan paketi — dosyadan içe / örnek dışa aktarma.
class PlanPackService {
  PlanPackService({
    required KesifCloudService kesif,
    required IsProgramiCloudService schedule,
  })  : _kesif = kesif,
        _schedule = schedule;

  final KesifCloudService _kesif;
  final IsProgramiCloudService _schedule;

  SantijetPlanPack parseText(String text) {
    late final dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      throw SantijetPlanPackException('Dosya geçerli JSON değil.');
    }
    if (decoded is! Map) {
      throw SantijetPlanPackException('Paket kökü bir JSON nesnesi olmalı.');
    }
    return SantijetPlanPack.fromJson(Map<String, dynamic>.from(decoded));
  }

  /// Dosya seçer, parse eder; [null] = kullanıcı iptal.
  Future<SantijetPlanPack?> pickAndParse() async {
    final text = await file_access.pickJsonText();
    if (text == null || text.trim().isEmpty) return null;
    return parseText(text);
  }

  /// Paketi aktif SAHA projesinin önbelleğine yazar.
  ///
  /// [localProjectId]: SAHA proje id (paketteki id kullanılmaz).
  ({KesifSnapshot? kesif, WorkScheduleSnapshot? schedule}) applyToCache({
    required SantijetPlanPack pack,
    required String localProjectId,
  }) {
    KesifSnapshot? kesif;
    WorkScheduleSnapshot? schedule;

    if (pack.kind == SantijetPlanPackKind.kesif || pack.hasKesif) {
      kesif = KesifSnapshot(
        projectId: localProjectId,
        updatedAt: pack.exportedAt,
        source: pack.sourceApp.isNotEmpty
            ? 'file:${pack.sourceApp}'
            : 'file:kesif_pack',
        items: pack.kesifItems,
      );
      _kesif.cacheSnapshot(kesif);
    }
    if (pack.kind == SantijetPlanPackKind.program || pack.hasProgram) {
      schedule = WorkScheduleSnapshot(
        projectId: localProjectId,
        updatedAt: pack.exportedAt,
        source: pack.sourceApp.isNotEmpty
            ? 'file:${pack.sourceApp}'
            : 'file:program_pack',
        items: pack.programItems,
      );
      _schedule.cacheSnapshot(schedule);
    }
    if (pack.kind == SantijetPlanPackKind.combined) {
      if (!pack.hasKesif && !pack.hasProgram) {
        throw SantijetPlanPackException('Birleşik pakette satır yok.');
      }
    }
    return (kesif: kesif, schedule: schedule);
  }

  /// Aktif proje için örnek birleşik paket indirir (şema testi / demo).
  Future<void> exportSampleCombined({
    required String projectId,
    String projectCode = '',
    String projectName = '',
  }) async {
    final kesif = await _kesif.syncDemo(
      projectId: projectId,
      projectName: projectName.isEmpty ? null : projectName,
    );
    final schedule = await _schedule.syncDemo(
      projectId: projectId,
      projectName: projectName.isEmpty ? null : projectName,
    );
    final pack = SantijetPlanPack(
      format: SantijetPlanPackFormats.combined,
      version: SantijetPlanPackFormats.version,
      exportedAt: DateTime.now(),
      kind: SantijetPlanPackKind.combined,
      projectCode: projectCode,
      projectName: projectName,
      sourceApp: 'santijet-saha-sample',
      kesifItems: kesif.items,
      programItems: schedule.items,
    );
    final code = projectCode.isNotEmpty ? projectCode : 'ornek';
    final bytes = _utf8(
      const JsonEncoder.withIndent('  ').convert(pack.toJson()),
    );
    await file_access.downloadJsonFile(
      fileName: 'santijet-plan-$code.json',
      bytes: bytes,
    );
  }

  /// Önbellekteki keşif/programı ayrı paket olarak dışa aktarır.
  Future<void> exportCached({
    required String projectId,
    String projectCode = '',
    String projectName = '',
    required SantijetPlanPackKind kind,
  }) async {
    final kesif = _kesif.cachedFor(projectId);
    final schedule = _schedule.cachedFor(projectId);
    final code = projectCode.isNotEmpty ? projectCode : 'proje';

    switch (kind) {
      case SantijetPlanPackKind.kesif:
        if (kesif == null || kesif.items.isEmpty) {
          throw SantijetPlanPackException('Dışa aktarılacak keşif önbelleği yok.');
        }
        final kesifPack = SantijetPlanPack(
          format: SantijetPlanPackFormats.kesif,
          version: SantijetPlanPackFormats.version,
          exportedAt: DateTime.now(),
          kind: SantijetPlanPackKind.kesif,
          projectCode: projectCode,
          projectName: projectName,
          sourceApp: 'santijet-saha',
          kesifItems: kesif.items,
        );
        await file_access.downloadJsonFile(
          fileName: 'santijet-kesif-$code.json',
          bytes: _utf8(
            const JsonEncoder.withIndent('  ').convert(kesifPack.toJson()),
          ),
        );
        return;
      case SantijetPlanPackKind.program:
        if (schedule == null || schedule.items.isEmpty) {
          throw SantijetPlanPackException(
            'Dışa aktarılacak iş programı önbelleği yok.',
          );
        }
        final programPack = SantijetPlanPack(
          format: SantijetPlanPackFormats.program,
          version: SantijetPlanPackFormats.version,
          exportedAt: DateTime.now(),
          kind: SantijetPlanPackKind.program,
          projectCode: projectCode,
          projectName: projectName,
          sourceApp: 'santijet-saha',
          programItems: schedule.items,
        );
        await file_access.downloadJsonFile(
          fileName: 'santijet-program-$code.json',
          bytes: _utf8(
            const JsonEncoder.withIndent('  ').convert(programPack.toJson()),
          ),
        );
        return;
      case SantijetPlanPackKind.combined:
        if ((kesif == null || kesif.items.isEmpty) &&
            (schedule == null || schedule.items.isEmpty)) {
          throw SantijetPlanPackException('Dışa aktarılacak plan önbelleği yok.');
        }
        final combinedPack = SantijetPlanPack(
          format: SantijetPlanPackFormats.combined,
          version: SantijetPlanPackFormats.version,
          exportedAt: DateTime.now(),
          kind: SantijetPlanPackKind.combined,
          projectCode: projectCode,
          projectName: projectName,
          sourceApp: 'santijet-saha',
          kesifItems: kesif?.items ?? const [],
          programItems: schedule?.items ?? const [],
        );
        await file_access.downloadJsonFile(
          fileName: 'santijet-plan-$code.json',
          bytes: _utf8(
            const JsonEncoder.withIndent('  ').convert(combinedPack.toJson()),
          ),
        );
    }
  }
}
