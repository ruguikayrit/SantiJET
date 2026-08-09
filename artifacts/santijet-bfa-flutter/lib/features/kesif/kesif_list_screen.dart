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
import '../export/export_format_sheet.dart';
import 'kesif_import_flow.dart';
import 'kesif_poz_picker_sheet.dart';

/// Keşif yüzeyi — aktif projenin satırları (Metraj ve YM ayrı sekmelerde).
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
          message: 'Keşif satırları için Projelerim’den bir proje seçin.',
          icon: Icons.description_outlined,
          actionLabel: 'Projelerim',
          onAction: () => context.push(AppRoutes.projeler),
        ),
      );
    }

    final projectId = kesif.id;

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
                    'Keşif Satırları',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Poz · tanım · birim fiyat kaynağı · miktar · tutar',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
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
                    for (final satir in kesif.satirlar) ...[
                      _SatirCard(projectId: projectId, satir: satir),
                      const SizedBox(height: AppSpacing.xs),
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

class _SatirCard extends ConsumerStatefulWidget {
  const _SatirCard({required this.projectId, required this.satir});

  final String projectId;
  final KesifSatiri satir;

  @override
  ConsumerState<_SatirCard> createState() => _SatirCardState();
}

class _SatirCardState extends ConsumerState<_SatirCard> {
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: AppFormat.decimal(widget.satir.miktar, fractionDigits: 2),
    );
  }

  @override
  void didUpdateWidget(covariant _SatirCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.satir.miktar != widget.satir.miktar) {
      _qtyController.text =
          AppFormat.decimal(widget.satir.miktar, fractionDigits: 2);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final satir = widget.satir;
    final theme = Theme.of(context);

    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppFormat.currency(satir.birimFiyati)} / ${satir.olcuBirimi} · ${satir.fiyatKaynagi.label}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.cardTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 92,
                child: TextField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.cardTextPrimary,
                  ),
                  onSubmitted: (raw) {
                    final value = double.tryParse(
                          raw.replaceAll('.', '').replaceAll(',', '.'),
                        ) ??
                        0;
                    ref.read(kesifProvider.notifier).updateMiktar(
                          widget.projectId,
                          satir.id,
                          value,
                        );
                  },
                  decoration: InputDecoration(
                    suffixText: satir.olcuBirimi,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                width: 88,
                child: Text(
                  AppFormat.currency(satir.tutar),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.cardTextPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              IconButton(
                tooltip: 'Sil',
                onPressed: () => ref
                    .read(kesifProvider.notifier)
                    .removeSatir(widget.projectId, satir.id),
                icon: Icon(Icons.close, color: theme.colorScheme.error),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
