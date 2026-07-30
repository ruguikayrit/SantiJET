import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_list_item.dart';
import '../../core/design_system/sj_modal.dart';
import '../../core/design_system/sj_status_badge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_date.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/entities/pour_plan.dart';

/// Döküm planı listesi ve CRUD.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  static String _m3(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  Color _statusColor(PourPlanStatus s) => switch (s) {
        PourPlanStatus.planned => AppColors.info,
        PourPlanStatus.completed => AppColors.success,
        PourPlanStatus.cancelled => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final plans = ref.watch(activePourPlansProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SantijetHeader(subtitle: 'Döküm Planı', avatarInitial: 'SJ'),
            Expanded(
              child: project == null
                  ? const SJEmptyState(
                      title: 'Proje seçin',
                      message: 'Plan eklemek için aktif bir proje gerekir.',
                      icon: Icons.apartment_outlined,
                    )
                  : plans.isEmpty
                      ? SJEmptyState(
                          title: 'Plan yok',
                          message: 'Günlük / haftalık döküm planı ekleyin.',
                          icon: Icons.event_note_outlined,
                          actionLabel: 'Plan Ekle',
                          onAction: () => _openEditor(context, ref),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            88,
                          ),
                          itemCount: plans.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final p = plans[index];
                            return SJListItem(
                              title: p.location.isEmpty
                                  ? 'Lokasyon yok'
                                  : p.location,
                              subtitle:
                                  '${p.date} · ${p.concreteClass}',
                              leadingIcon: Icons.event_note_outlined,
                              accentColor: _statusColor(p.status),
                              trailing: SJStatusBadge(
                                label: p.status.label,
                                color: _statusColor(p.status),
                              ),
                              onTap: () =>
                                  _openEditor(context, ref, existing: p),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: project == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Plan Ekle'),
            ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    PourPlan? existing,
  }) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;

    final dateCtrl = TextEditingController(
      text: existing?.date ?? AppDate.format(AppDate.today()),
    );
    final locationCtrl =
        TextEditingController(text: existing?.location ?? '');
    final m3Ctrl = TextEditingController(
      text: existing == null ? '' : _m3(existing.plannedM3),
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var concreteClass = existing?.concreteClass ?? 'C30/37';
    var status = existing?.status ?? PourPlanStatus.planned;

    final saved = await SJModal.showSheet<bool>(
      context: context,
      title: existing == null ? 'Yeni döküm planı' : 'Planı düzenle',
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tarih (gg.aa.yyyy)',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(labelText: 'Lokasyon'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: concreteClass,
                  decoration: const InputDecoration(labelText: 'Beton sınıfı'),
                  items: [
                    for (final c in AppInfo.concreteClasses)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setLocal(() => concreteClass = v);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: m3Ctrl,
                  decoration: const InputDecoration(labelText: 'Planlanan m³'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<PourPlanStatus>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Durum'),
                  items: [
                    for (final s in PourPlanStatus.values)
                      DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setLocal(() => status = v);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Not'),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () {
                    final m3 = double.tryParse(
                      m3Ctrl.text.trim().replaceAll(',', '.'),
                    );
                    if (m3 == null || m3 <= 0) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Kaydet'),
                ),
                if (existing != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () async {
                      final ok = await SJModal.confirm(
                        context: ctx,
                        title: 'Planı sil',
                        message: 'Bu döküm planı silinsin mi?',
                        confirmLabel: 'Sil',
                        destructive: true,
                      );
                      if (!ok || !ctx.mounted) return;
                      ref.read(pourPlansProvider.notifier).delete(existing.id);
                      Navigator.pop(ctx, false);
                    },
                    child: Text(
                      'Sil',
                      style: TextStyle(color: AppColors.critical),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );

    if (saved != true) return;
    final m3 = double.tryParse(m3Ctrl.text.trim().replaceAll(',', '.')) ?? 0;
    final draft = PourPlan(
      id: existing?.id ?? '',
      projectId: project.id,
      date: dateCtrl.text.trim(),
      location: locationCtrl.text.trim(),
      concreteClass: concreteClass,
      plannedM3: m3,
      status: status,
      notes: notesCtrl.text.trim(),
    );
    if (existing == null) {
      ref.read(pourPlansProvider.notifier).add(draft);
    } else {
      ref.read(pourPlansProvider.notifier).update(draft);
    }
  }
}
