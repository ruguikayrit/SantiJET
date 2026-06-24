import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../data/providers/kesif_provider.dart';
import '../../domain/entities/kesif.dart';
import 'kesif_import_flow.dart';
import 'kesif_poz_picker_sheet.dart';

/// Keşif detayı — React Native `kesif/[id]` karşılığı.
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
    return Scaffold(
      appBar: AppBar(
        title: Text(kesif.ad),
        actions: [
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
                  SJStatCard(
                    label: 'Genel Toplam',
                    value: AppFormat.currency(kesif.toplam),
                    unit: '',
                    accentColor: AppColors.moduleKesif,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (kesif.satirlar.isEmpty)
                    SizedBox(
                      height: 340,
                      child: SJEmptyState(
                        title: 'Henüz poz yok',
                        message:
                            'Poz Ekle ile katalogdan seçin veya Excel içe aktarın.',
                        icon: Icons.add_circle_outline,
                        actionLabel: 'Poz Ekle',
                        onAction: () async {
                          final picked = await KesifPozPickerSheet.show(context);
                          if (picked == null) return;
                          ref.read(kesifProvider.notifier).addSatir(
                                projectId,
                                picked.analiz,
                                picked.miktar,
                              );
                        },
                      ),
                    )
                  else ...[
                    Text('Pozlar', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    for (final satir in kesif.satirlar) ...[
                      _SatirCard(projectId: projectId, satir: satir),
                      const SizedBox(height: AppSpacing.xs),
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
    final theme = Theme.of(context);
    final satir = widget.satir;

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
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppFormat.currency(satir.birimFiyati)} / ${satir.olcuBirimi}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 92,
            child: TextField(
              controller: _qtyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              onSubmitted: (raw) {
                final value = double.tryParse(
                        raw.replaceAll('.', '').replaceAll(',', '.')) ??
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
              style: theme.textTheme.titleMedium,
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
    );
  }
}
