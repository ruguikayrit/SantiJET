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

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  static String m3(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Color _color(PourPlanStatus s) => switch (s) {
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
          children: [
            const SantijetHeader(subtitle: 'Döküm Planı', avatarInitial: 'R1'),
            Expanded(
              child: project == null
                  ? const SJEmptyState(
                      title: 'Proje seçin',
                      message: 'Plan için aktif proje gerekir.',
                      icon: Icons.apartment_outlined,
                    )
                  : plans.isEmpty
                      ? SJEmptyState(
                          title: 'Plan yok',
                          message: 'Günlük döküm planı ekleyin.',
                          icon: Icons.event_note_outlined,
                          actionLabel: 'Plan Ekle',
                          onAction: () => _edit(context, ref),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                          itemCount: plans.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final p = plans[i];
                            return SJListItem(
                              title: p.location.isEmpty ? 'Lokasyon yok' : p.location,
                              subtitle: '${p.date} · ${p.concreteClass}',
                              leadingIcon: Icons.event_note_outlined,
                              accentColor: _color(p.status),
                              trailing: SJStatusBadge(
                                label: p.status.label,
                                color: _color(p.status),
                              ),
                              onTap: () => _edit(context, ref, existing: p),
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
              onPressed: () => _edit(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Plan Ekle'),
            ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, {PourPlan? existing}) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;
    final dateCtrl = TextEditingController(text: existing?.date ?? AppDate.format(AppDate.today()));
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    final m3Ctrl = TextEditingController(text: existing == null ? '' : m3(existing.plannedM3));
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var concreteClass = existing?.concreteClass ?? 'C30/37';
    var status = existing?.status ?? PourPlanStatus.planned;

    final saved = await SJModal.showSheet<bool>(
      context: context,
      title: existing == null ? 'Yeni döküm planı' : 'Planı düzenle',
      child: StatefulBuilder(builder: (ctx, setLocal) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Tarih (gg.aa.yyyy)')),
              const SizedBox(height: AppSpacing.sm),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Lokasyon')),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: concreteClass,
                decoration: const InputDecoration(labelText: 'Beton sınıfı'),
                items: [for (final c in AppInfo.concreteClasses) DropdownMenuItem(value: c, child: Text(c))],
                onChanged: (v) { if (v != null) setLocal(() => concreteClass = v); },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(controller: m3Ctrl, decoration: const InputDecoration(labelText: 'Planlanan m³'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<PourPlanStatus>(
                value: status,
                decoration: const InputDecoration(labelText: 'Durum'),
                items: [for (final s in PourPlanStatus.values) DropdownMenuItem(value: s, child: Text(s.label))],
                onChanged: (v) { if (v != null) setLocal(() => status = v); },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Not'), maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () {
                  final v = double.tryParse(m3Ctrl.text.trim().replaceAll(',', '.'));
                  if (v == null || v <= 0) return;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Kaydet'),
              ),
              if (existing != null) ...[
                TextButton(
                  onPressed: () async {
                    final ok = await SJModal.confirm(context: ctx, title: 'Sil', message: 'Plan silinsin mi?', confirmLabel: 'Sil', destructive: true);
                    if (!ok || !ctx.mounted) return;
                    ref.read(pourPlansProvider.notifier).delete(existing.id);
                    Navigator.pop(ctx, false);
                  },
                  child: Text('Sil', style: TextStyle(color: AppColors.critical)),
                ),
              ],
            ],
          ),
        );
      }),
    );
    if (saved != true) return;
    final v = double.tryParse(m3Ctrl.text.trim().replaceAll(',', '.')) ?? 0;
    final draft = PourPlan(
      id: existing?.id ?? '',
      projectId: project.id,
      date: dateCtrl.text.trim(),
      location: locCtrl.text.trim(),
      concreteClass: concreteClass,
      plannedM3: v,
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
