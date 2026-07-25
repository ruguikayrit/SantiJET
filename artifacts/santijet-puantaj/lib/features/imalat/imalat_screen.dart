import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/puantaj_date.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/production_provider.dart';
import '../../domain/entities/production.dart';

/// Günlük imalat miktar girişi.
class ImalatScreen extends ConsumerWidget {
  const ImalatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final project = ref.watch(activeProjectProvider);
    final items = ref.watch(activeProductionProvider);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('İmalat')),
        body: SJEmptyState(
          title: 'Önce proje ekleyin',
          message: 'İmalat kayıtları proje kapsamında tutulur.',
          icon: Icons.apartment_outlined,
          actionLabel: 'Projelere Git',
          onAction: () => context.go(AppRoutes.projeler),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('İmalat'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Center(
              child: Text(
                project.name,
                style: theme.textTheme.labelMedium,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref, projectId: project.id),
        icon: const Icon(Icons.add),
        label: const Text('İmalat Ekle'),
      ),
      body: items.isEmpty
          ? SJEmptyState(
              title: 'Henüz imalat yok',
              message: 'Günlük üretim miktarını buradan girin.',
              icon: Icons.precision_manufacturing_outlined,
              actionLabel: 'İmalat Ekle',
              onAction: () =>
                  _openEditor(context, ref, projectId: project.id),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                88,
              ),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final p = items[i];
                final pct = p.progressPct;
                final color = pct >= 80
                    ? AppColors.success
                    : pct >= 50
                        ? AppColors.warning
                        : AppColors.critical;
                return SJCard(
                  onTap: () => _openEditor(
                    context,
                    ref,
                    projectId: project.id,
                    existing: p,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Text(p.date, style: theme.textTheme.labelSmall),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${_fmt(p.completedQty)} / ${_fmt(p.plannedQty)} ${p.unit}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: color.withValues(alpha: 0.15),
                          color: color,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '%${pct.toStringAsFixed(0)} tamamlandı',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    required String projectId,
    Production? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'adet');
    final plannedCtrl = TextEditingController(
      text: existing != null ? _fmt(existing.plannedQty) : '',
    );
    final doneCtrl = TextEditingController(
      text: existing != null ? _fmt(existing.completedQty) : '',
    );
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    var date = existing?.date ?? PuantajDate.today();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.sm,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null ? 'Yeni imalat' : 'İmalatı düzenle',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'İmalat adı',
                      hintText: 'Örn. Kolon demiri',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: plannedCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Plan'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: doneCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Gerçekleşen'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 88,
                        child: TextField(
                          controller: unitCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Birim'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: PuantajDate.parse(date),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModal(() => date = PuantajDate.format(picked));
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(date),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Not'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      if (existing != null)
                        TextButton(
                          onPressed: () {
                            ref
                                .read(productionProvider.notifier)
                                .delete(existing.id);
                            Navigator.pop(ctx, true);
                          },
                          child: const Text('Sil',
                              style: TextStyle(color: AppColors.critical)),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          final draft = Production(
                            id: existing?.id ?? '',
                            projectId: projectId,
                            name: name,
                            date: date,
                            unit: unitCtrl.text.trim().isEmpty
                                ? 'adet'
                                : unitCtrl.text.trim(),
                            plannedQty:
                                double.tryParse(plannedCtrl.text.trim()) ?? 0,
                            completedQty:
                                double.tryParse(doneCtrl.text.trim()) ?? 0,
                            note: noteCtrl.text.trim(),
                          );
                          final notifier =
                              ref.read(productionProvider.notifier);
                          if (existing == null) {
                            notifier.add(draft);
                          } else {
                            notifier.update(draft);
                          }
                          Navigator.pop(ctx, true);
                        },
                        child: const Text('Kaydet'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    unitCtrl.dispose();
    plannedCtrl.dispose();
    doneCtrl.dispose();
    noteCtrl.dispose();
    if (saved == true && context.mounted) {
      // list refreshes via provider
    }
  }
}
