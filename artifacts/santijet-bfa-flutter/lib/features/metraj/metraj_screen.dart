import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../data/providers/kesif_provider.dart';
import '../../domain/entities/kesif.dart';

/// Metraj yüzeyi — aktif projenin ölçü notları ve miktarları.
class MetrajScreen extends ConsumerWidget {
  const MetrajScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kesif = ref.watch(activeKesifProvider);
    final theme = Theme.of(context);

    if (kesif == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: const Text('Metraj'),
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
          message: 'Metraj için Projelerim’den bir proje seçin.',
          icon: Icons.straighten_outlined,
          actionLabel: 'Projelerim',
          onAction: () => context.push(AppRoutes.projeler),
        ),
      );
    }

    final projectId = kesif.id;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Metraj'),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.ayarlar),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              kesif.ad,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Satıra bağlı ölçü notu ve miktar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (kesif.satirlar.isEmpty)
              SJEmptyState(
                title: 'Henüz poz yok',
                message: 'Keşif sekmesinden poz ekledikçe metraj burada görünür.',
                icon: Icons.straighten_outlined,
                actionLabel: 'Keşif’e Git',
                onAction: () => context.go(AppRoutes.kesif),
              )
            else
              for (final satir in kesif.satirlar) ...[
                _MetrajCard(projectId: projectId, satir: satir),
                const SizedBox(height: AppSpacing.xs),
              ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
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
