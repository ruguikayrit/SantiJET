import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../data/providers/kesif_provider.dart';
import '../../data/services/kesif_export_service.dart';
import '../../domain/entities/kesif.dart';
import '../../domain/enums/app_enums.dart';
import '../export/export_format_sheet.dart';
import 'kesif_import_flow.dart';
import 'kesif_poz_picker_sheet.dart';
import 'widgets/discipline_section_header.dart';

/// Keşif listesi — poz · tanım · hesaplanan metraj (3 ana başlık).
class KesifListScreen extends ConsumerWidget {
  const KesifListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kesif = ref.watch(activeKesifProvider);
    final theme = Theme.of(context);

    if (kesif == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: const Text('Keşif'),
          actions: [
            IconButton(
              tooltip: 'Ayarlar',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(AppRoutes.ayarlar),
            ),
          ],
        ),
        body: SJEmptyState(
          title: 'Aktif proje yok',
          message: 'Keşif listesi için Projelerim’den bir proje seçin.',
          icon: Icons.description_outlined,
          actionLabel: 'Projelerim',
          onAction: () => context.push(AppRoutes.projeler),
        ),
      );
    }

    final projectId = kesif.id;
    final byDisc = kesif.satirlarByDiscipline;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(kesif.ad),
        actions: [
          IconButton(
            tooltip: 'Dışa Aktar',
            icon: const Icon(Icons.download_outlined),
            onPressed: () async {
              final format = await ExportFormatSheet.pick(context);
              if (format == null || !context.mounted) return;
              if (format == ExportFormat.pdf) {
                await kesifExportService.sharePdf(kesif);
              } else {
                await kesifExportService.shareExcel(kesif);
              }
            },
          ),
          IconButton(
            tooltip: 'Excel İçe Aktar',
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: () => KesifImportFlow.run(
              context,
              ref,
              projectId: projectId,
            ),
          ),
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.ayarlar),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final picked = await KesifPozPickerSheet.show(context);
          if (picked == null) return;
          ref.read(kesifProvider.notifier).addSatir(
                projectId,
                picked.analiz,
                picked.miktar,
              );
        },
        icon: const Icon(Icons.add),
        label: const Text('Poz Ekle'),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Keşif Listesi',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Poz no · poz tanımı · metraj (metraj cetvelinden)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (kesif.satirlar.isEmpty)
                    SizedBox(
                      height: 280,
                      child: SJEmptyState(
                        title: 'Henüz poz yok',
                        message:
                            'Poz Ekle ile katalogdan seçin veya Excel içe aktarın.',
                        icon: Icons.add_circle_outline,
                        actionLabel: 'Poz Ekle',
                        onAction: () async {
                          final picked =
                              await KesifPozPickerSheet.show(context);
                          if (picked == null) return;
                          ref.read(kesifProvider.notifier).addSatir(
                                projectId,
                                picked.analiz,
                                picked.miktar,
                              );
                        },
                      ),
                    )
                  else
                    for (final d in AnalizDiscipline.kesifSirasi) ...[
                      if ((byDisc[d] ?? const []).isNotEmpty) ...[
                        DisciplineSectionHeader(
                          discipline: d,
                          count: byDisc[d]!.length,
                        ),
                        for (final satir in byDisc[d]!) ...[
                          _SatirCard(projectId: projectId, satir: satir),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                      ],
                    ],
                  const SizedBox(height: AppSpacing.xl * 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SatirCard extends ConsumerWidget {
  const _SatirCard({required this.projectId, required this.satir});

  final String projectId;
  final KesifSatiri satir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final metraj = satir.hesaplananMetraj;

    return SJCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  satir.pozNo,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: AppColors.moduleKesif),
                ),
                Text(
                  satir.analizAdi,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.cardTextPrimary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (satir.metrajKalemleri.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${satir.metrajKalemleri.length} cetvel satırı',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.cardTextMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormat.decimal(metraj),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.cardTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                satir.olcuBirimi,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.cardTextMuted,
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Sil',
            onPressed: () => ref
                .read(kesifProvider.notifier)
                .removeSatir(projectId, satir.id),
            icon: Icon(Icons.close, color: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }
}
