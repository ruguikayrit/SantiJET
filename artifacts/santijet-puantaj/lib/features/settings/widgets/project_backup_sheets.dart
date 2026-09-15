import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sj_modal.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/providers/app_data_provider.dart';
import '../../../data/providers/daily_report_provider.dart';
import '../../../data/providers/production_provider.dart';
import '../../../data/providers/tasks_provider.dart';
import '../../../data/services/puantaj_backup_service.dart';
import '../../../domain/entities/project.dart';

/// Dışa aktarılacak şantiye(ler)i seçtirir.
Future<Set<String>?> pickProjectsForExport(
  BuildContext context,
  WidgetRef ref,
) async {
  final projects = ref.read(projectsProvider);
  if (projects.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dışa aktarılacak şantiye yok')),
    );
    return null;
  }

  final selected = <String>{};
  if (projects.length == 1) {
    selected.add(projects.first.id);
  } else {
    final active = ref.read(activeProjectIdProvider);
    if (active != null && projects.any((p) => p.id == active)) {
      selected.add(active);
    }
  }

  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: SJModal.sheetSurface,
    builder: (ctx) {
      final sheetTheme = SJModal.sheetThemeOf(ctx);
      return Theme(
        data: sheetTheme,
        child: StatefulBuilder(
          builder: (context, setLocal) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  bottom: MediaQuery.viewInsetsOf(context).bottom +
                      AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Hangi şantiye dışa aktarılsın?',
                      style: sheetTheme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Yalnızca seçtiğiniz şantiyenin puantaj, imalat, görev '
                      've rapor kayıtları JSON dosyasına yazılır.',
                      style: sheetTheme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final p in projects)
                            CheckboxListTile(
                              value: selected.contains(p.id),
                              onChanged: (v) {
                                setLocal(() {
                                  if (v == true) {
                                    selected.add(p.id);
                                  } else {
                                    selected.remove(p.id);
                                  }
                                });
                              },
                              title: Text(p.name),
                              subtitle: Text(
                                _exportSubtitle(ref, p),
                                style: sheetTheme.textTheme.labelSmall,
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () => Navigator.pop(ctx, Set<String>.from(selected)),
                      child: Text(
                        selected.isEmpty
                            ? 'Şantiye seçin'
                            : 'Dışa aktar (${selected.length})',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

String _exportSubtitle(WidgetRef ref, Project p) {
  final pid = p.id;
  final people =
      ref.read(personnelProvider).where((e) => e.projectId == pid).length;
  final tasks = ref.read(tasksProvider).where((e) => e.projectId == pid).length;
  final reports =
      ref.read(dailyReportsProvider).where((e) => e.projectId == pid).length;
  final imalat =
      ref.read(productionProvider).where((e) => e.projectId == pid).length;
  return '$people personel · $tasks görev · $reports rapor · $imalat imalat';
}

/// Yedek dosyasından içe aktarılacak şantiyeyi seçtirir.
Future<String?> pickProjectForImport(
  BuildContext context,
  PuantajBackupPayload payload,
) async {
  final projects = payload.projects;
  if (projects.isEmpty) {
    throw PuantajBackupException('Yedek dosyasında şantiye kaydı yok');
  }
  if (projects.length == 1) {
    return projects.first['id'] as String?;
  }

  final sheetTheme = SJModal.sheetThemeOf(context);
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: SJModal.sheetSurface,
    builder: (ctx) => Theme(
      data: sheetTheme,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hangi şantiye içe aktarılsın?',
                style: sheetTheme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Seçilen şantiye cihazınıza birleştirilir; diğer şantiyeler '
                've kayıtları değişmez.',
                style: sheetTheme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final raw in projects) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    (raw['name'] as String?)?.trim().isNotEmpty == true
                        ? raw['name'] as String
                        : 'Şantiye',
                  ),
                  subtitle: Text(
                    _importSubtitle(payload, raw['id'] as String? ?? ''),
                    style: sheetTheme.textTheme.labelSmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(ctx, raw['id'] as String?),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

String _importSubtitle(PuantajBackupPayload payload, String projectId) {
  int count(Iterable<Map<String, dynamic>> list) =>
      list.where((j) => j['projectId'] == projectId).length;
  return '${count(payload.personnel)} personel · '
      '${count(payload.tasks)} görev · '
      '${count(payload.dailyReports)} rapor';
}
