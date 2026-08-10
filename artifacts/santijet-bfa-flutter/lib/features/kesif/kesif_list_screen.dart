import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/kesif_provider.dart';
import '../../data/services/kesif_export_service.dart';
import '../../domain/entities/kesif.dart';
import '../../domain/enums/app_enums.dart';
import '../export/export_format_sheet.dart';
import 'kesif_import_flow.dart';
import 'kesif_poz_picker_sheet.dart';
import 'widgets/discipline_section_header.dart';

/// Keşif listesi — poz · tanım · hesaplanan metraj (3 ana başlık).
class KesifListScreen extends ConsumerStatefulWidget {
  const KesifListScreen({super.key});

  @override
  ConsumerState<KesifListScreen> createState() => _KesifListScreenState();
}

class _KesifListScreenState extends ConsumerState<KesifListScreen> {
  final Set<AnalizDiscipline> _collapsed = {};

  Future<void> _addPoz(String projectId) async {
    final picked = await KesifPozPickerSheet.show(context);
    if (picked == null) return;
    ref.read(kesifProvider.notifier).addSatir(
          projectId,
          picked.analiz,
          picked.miktar,
        );
  }

  Future<void> _export(KesifProject kesif) async {
    final format = await ExportFormatSheet.pick(context);
    if (format == null || !mounted) return;
    if (format == ExportFormat.pdf) {
      await kesifExportService.sharePdf(kesif);
    } else {
      await kesifExportService.shareExcel(kesif);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kesif = ref.watch(activeKesifProvider);
    final theme = Theme.of(context);

    if (kesif == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SantijetHeader(subtitle: 'Keşif'),
              Expanded(
                child: SJEmptyState(
                  title: 'Aktif proje yok',
                  message: 'Keşif listesi için Projelerim’den bir proje seçin.',
                  icon: Icons.description_outlined,
                  actionLabel: 'Projelerim',
                  onAction: () => context.push(AppRoutes.projeler),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final projectId = kesif.id;
    final byDisc = kesif.satirlarByDiscipline;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPoz(projectId),
        icon: const Icon(Icons.add),
        label: const Text('Poz Ekle'),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SantijetHeader(
                subtitle: 'Keşif',
                actions: [
                  IconButton(
                    tooltip: 'Dışa Aktar',
                    onPressed: () => _export(kesif),
                    icon: const Icon(Icons.download_outlined),
                  ),
                  IconButton(
                    tooltip: 'Excel İçe Aktar',
                    onPressed: () => KesifImportFlow.run(
                      context,
                      ref,
                      projectId: projectId,
                    ),
                    icon: const Icon(Icons.upload_file_outlined),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList.list(
                children: [
                  Text(
                    kesif.ad,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Keşif Listesi',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
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
                        onAction: () => _addPoz(projectId),
                      ),
                    )
                  else
                    for (final d in AnalizDiscipline.kesifSirasi) ...[
                      if ((byDisc[d] ?? const []).isNotEmpty) ...[
                        DisciplineSectionHeader(
                          discipline: d,
                          count: byDisc[d]!.length,
                          expanded: !_collapsed.contains(d),
                          onToggle: () {
                            setState(() {
                              if (_collapsed.contains(d)) {
                                _collapsed.remove(d);
                              } else {
                                _collapsed.add(d);
                              }
                            });
                          },
                        ),
                        if (!_collapsed.contains(d))
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

  Future<void> _showFullTanim(BuildContext context) async {
    await SJModal.showSheet<void>(
      context: context,
      title: satir.pozNo,
      child: Text(
        satir.analizAdi,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.cardTextPrimary,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final metraj = satir.hesaplananMetraj;
    final birim =
        satir.olcuBirimi.trim().isEmpty ? 'ad' : satir.olcuBirimi.trim();

    return Dismissible(
      key: ValueKey(satir.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final ok = await SJModal.confirm(
          context: context,
          title: 'Satırı sil',
          message: '${satir.pozNo} keşif listesinden kaldırılsın mı?',
          confirmLabel: 'Sil',
          destructive: true,
        );
        if (!ok) return false;
        ref.read(kesifProvider.notifier).removeSatir(projectId, satir.id);
        return true;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.critical.withValues(alpha: 0.15),
          borderRadius: AppRadii.md,
          border: Border.all(
            color: AppColors.critical.withValues(alpha: 0.35),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: AppColors.critical),
            SizedBox(width: 8),
            Text('Sil', style: TextStyle(color: AppColors.critical)),
          ],
        ),
      ),
      child: SJCard(
        onTap: () => _showFullTanim(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${AppFormat.decimal(metraj)} $birim',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.cardTextPrimary,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}
