import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_list_item.dart';
import '../../core/design_system/sj_modal.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_date.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/entities/pour_plan.dart';
import '../../domain/entities/pour_record.dart';

class DokumScreen extends ConsumerWidget {
  const DokumScreen({super.key});

  static String m3(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final pours = ref.watch(activePourRecordsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SantijetHeader(subtitle: 'Günlük Döküm', avatarInitial: 'R1'),
            Expanded(
              child: project == null
                  ? const SJEmptyState(title: 'Proje seçin', message: 'Döküm için aktif proje gerekir.', icon: Icons.apartment_outlined)
                  : pours.isEmpty
                      ? SJEmptyState(title: 'Döküm yok', message: 'Fiili döküm m³ kaydı ekleyin.', icon: Icons.water_drop_outlined, actionLabel: 'Döküm Ekle', onAction: () => _edit(context, ref))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                          itemCount: pours.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final p = pours[i];
                            return SJListItem(
                              title: p.location.isEmpty ? 'Lokasyon yok' : p.location,
                              subtitle: '${p.date} · ${p.concreteClass}',
                              leadingIcon: Icons.water_drop_outlined,
                              trailingText: '${m3(p.actualM3)} m³',
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
          : FloatingActionButton.extended(onPressed: () => _edit(context, ref), icon: const Icon(Icons.add), label: const Text('Döküm Ekle')),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, {PourRecord? existing}) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;
    final plans = ref.read(activePourPlansProvider).where((p) => p.status != PourPlanStatus.cancelled).toList();
    final dateCtrl = TextEditingController(text: existing?.date ?? AppDate.format(AppDate.today()));
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    final m3Ctrl = TextEditingController(text: existing == null ? '' : m3(existing.actualM3));
    final mixerCtrl = TextEditingController(text: existing?.mixerNote ?? '');
    final pumpCtrl = TextEditingController(text: existing?.pumpNote ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var concreteClass = existing?.concreteClass ?? 'C30/37';
    String? planId = existing?.planId;

    final saved = await SJModal.showSheet<bool>(
      context: context,
      title: existing == null ? 'Yeni döküm' : 'Dökümü düzenle',
      child: StatefulBuilder(builder: (ctx, setLocal) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Tarih (gg.aa.yyyy)')),
              const SizedBox(height: AppSpacing.sm),
              if (plans.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  value: planId,
                  decoration: const InputDecoration(labelText: 'Bağlı plan'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Yok')),
                    for (final p in plans)
                      DropdownMenuItem(value: p.id, child: Text('${p.date} · ${p.location.isEmpty ? p.concreteClass : p.location}', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) {
                    setLocal(() {
                      planId = v;
                      if (v != null) {
                        final plan = plans.firstWhere((e) => e.id == v);
                        locCtrl.text = plan.location;
                        concreteClass = plan.concreteClass;
                      }
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Lokasyon')),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: concreteClass,
                decoration: const InputDecoration(labelText: 'Beton sınıfı'),
                items: [for (final c in AppInfo.concreteClasses) DropdownMenuItem(value: c, child: Text(c))],
                onChanged: (v) { if (v != null) setLocal(() => concreteClass = v); },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(controller: m3Ctrl, decoration: const InputDecoration(labelText: 'Dökülen m³'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: AppSpacing.sm),
              TextField(controller: mixerCtrl, decoration: const InputDecoration(labelText: 'Mikser notu')),
              const SizedBox(height: AppSpacing.sm),
              TextField(controller: pumpCtrl, decoration: const InputDecoration(labelText: 'Pompa notu')),
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
              if (existing != null)
                TextButton(
                  onPressed: () async {
                    final ok = await SJModal.confirm(context: ctx, title: 'Sil', message: 'Döküm silinsin mi?', confirmLabel: 'Sil', destructive: true);
                    if (!ok || !ctx.mounted) return;
                    ref.read(pourRecordsProvider.notifier).delete(existing.id);
                    Navigator.pop(ctx, false);
                  },
                  child: Text('Sil', style: TextStyle(color: AppColors.critical)),
                ),
            ],
          ),
        );
      }),
    );
    if (saved != true) return;
    final v = double.tryParse(m3Ctrl.text.trim().replaceAll(',', '.')) ?? 0;
    final draft = PourRecord(
      id: existing?.id ?? '',
      projectId: project.id,
      planId: planId,
      date: dateCtrl.text.trim(),
      actualM3: v,
      concreteClass: concreteClass,
      location: locCtrl.text.trim(),
      mixerNote: mixerCtrl.text.trim(),
      pumpNote: pumpCtrl.text.trim(),
      notes: notesCtrl.text.trim(),
    );
    if (existing == null) {
      ref.read(pourRecordsProvider.notifier).add(draft);
    } else {
      ref.read(pourRecordsProvider.notifier).update(draft);
    }
  }
}
