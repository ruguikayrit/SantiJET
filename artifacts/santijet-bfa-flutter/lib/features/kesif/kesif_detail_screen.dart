import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../data/providers/kesif_provider.dart';
import '../../data/services/kesif_export_service.dart';
import '../../domain/entities/kesif.dart';
import '../export/export_format_sheet.dart';
import 'kesif_import_flow.dart';
import 'kesif_poz_picker_sheet.dart';

/// Keşif detayı — satırlar + Metraj + Yaklaşık Maliyet (Keşif içinde).
class KesifDetailScreen extends ConsumerWidget {
  const KesifDetailScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(kesifProvider).where((p) => p.id == projectId);
    final kesif = project.isEmpty ? null : project.first;

    if (kesif == null) {
      return const Scaffold(
        body: SafeArea(
          child: SJEmptyState(
            title: 'Keşif bulunamadı',
            message: 'Bu proje silinmiş veya taşınmış olabilir.',
            icon: Icons.error_outline,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final byUnit = kesif.toplamByOlcuBirimi.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
                    'Yaklaşık Maliyet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SJStatCard(
                    label: 'Genel Toplam',
                    value: AppFormat.currency(kesif.toplam),
                    unit: '',
                    accentColor: AppColors.moduleKesif,
                  ),
                  if (byUnit.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SJCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ölçü birimi kırılımı',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.cardTextPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          for (final e in byUnit)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      e.key,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: AppColors.cardTextSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    AppFormat.currency(e.value),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      color: AppColors.cardTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
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
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Metraj',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Satıra bağlı ölçü notu ve miktar (CAD sonraki faz).',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (kesif.satirlar.isEmpty)
                    SJCard(
                      child: Text(
                        'Poz eklendikçe metraj notları burada düzenlenir.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.cardTextMuted,
                        ),
                      ),
                    )
                  else
                    for (final satir in kesif.satirlar) ...[
                      _MetrajCard(projectId: projectId, satir: satir),
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

    return SJCard(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
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
          );
        },
      ),
    );
  }
}

class _MetrajCard extends ConsumerStatefulWidget {
  const _MetrajCard({required this.projectId, required this.satir});

  final String projectId;
  final KesifSatiri satir;

  @override
  ConsumerState<_MetrajCard> createState() => _MetrajCardState();
}

class _MetrajCardState extends ConsumerState<_MetrajCard> {
  late final TextEditingController _noteController;
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.satir.metrajNotu);
    _qtyController = TextEditingController(
      text: AppFormat.decimal(widget.satir.miktar, fractionDigits: 2),
    );
  }

  @override
  void didUpdateWidget(covariant _MetrajCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.satir.metrajNotu != widget.satir.metrajNotu) {
      _noteController.text = widget.satir.metrajNotu;
    }
    if (oldWidget.satir.miktar != widget.satir.miktar) {
      _qtyController.text =
          AppFormat.decimal(widget.satir.miktar, fractionDigits: 2);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final satir = widget.satir;
    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${satir.pozNo} · ${satir.analizAdi}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.cardTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _qtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Miktar (${satir.olcuBirimi})',
              isDense: true,
            ),
            onSubmitted: (raw) {
              final value = double.tryParse(raw.replaceAll(',', '.')) ?? 0;
              ref.read(kesifProvider.notifier).updateMiktar(
                    widget.projectId,
                    satir.id,
                    value,
                  );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Ölçü notu',
              hintText: 'Örn. 12×3.20 m döşeme',
              isDense: true,
            ),
            onEditingComplete: () {
              ref.read(kesifProvider.notifier).updateMetrajNotu(
                    widget.projectId,
                    satir.id,
                    _noteController.text,
                  );
            },
          ),
        ],
      ),
    );
  }
}
