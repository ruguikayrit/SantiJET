import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_list_item.dart';
import '../../core/design_system/sj_modal.dart';
import '../../core/design_system/sj_status_badge.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_date.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/entities/quality_sample.dart';

/// Numune / basınç dayanımı kayıtları.
class QualityScreen extends ConsumerWidget {
  const QualityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final samples = ref.watch(activeQualityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalite / Numune'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.ayarlar),
        ),
      ),
      floatingActionButton: project == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Numune Ekle'),
            ),
      body: project == null
          ? const SJEmptyState(
              title: 'Proje seçin',
              message: 'Numune kayıtları proje kapsamında tutulur.',
              icon: Icons.apartment_outlined,
            )
          : samples.isEmpty
              ? SJEmptyState(
                  title: 'Numune yok',
                  message:
                      'Basınç dayanımı (MPa) ve opsiyonel cüruf notu ekleyin.',
                  icon: Icons.science_outlined,
                  actionLabel: 'Numune Ekle',
                  onAction: () => _openEditor(context, ref),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    88,
                  ),
                  itemCount: samples.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final s = samples[index];
                    final strength = s.strengthMpa == null
                        ? 'Sonuç bekleniyor'
                        : '${s.strengthMpa!.toStringAsFixed(1)} MPa';
                    final slag = s.slagNote.isEmpty
                        ? null
                        : 'Cüruf: ${s.slagNote}';
                    return SJListItem(
                      title: s.sampleCode,
                      subtitle: [
                        '${s.sampleDate} · ${s.ageDays} gün · $strength',
                        if (slag != null) slag,
                      ].join('\n'),
                      leadingIcon: Icons.science_outlined,
                      accentColor: s.isPending
                          ? AppColors.partial
                          : AppColors.success,
                      trailing: SJStatusBadge(
                        label: s.isPending ? 'Bekliyor' : 'Sonuçlu',
                        color: s.isPending
                            ? AppColors.partial
                            : AppColors.success,
                      ),
                      onTap: () => _openEditor(context, ref, existing: s),
                    );
                  },
                ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    QualitySample? existing,
  }) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;

    final dateCtrl = TextEditingController(
      text: existing?.sampleDate ?? AppDate.format(AppDate.today()),
    );
    final codeCtrl =
        TextEditingController(text: existing?.sampleCode ?? '');
    final strengthCtrl = TextEditingController(
      text: existing?.strengthMpa?.toStringAsFixed(1) ?? '',
    );
    final slagCtrl = TextEditingController(text: existing?.slagNote ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var ageDays = existing?.ageDays ?? 28;

    final saved = await SJModal.showSheet<bool>(
      context: context,
      title: existing == null ? 'Yeni numune' : 'Numuneyi düzenle',
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Numune tarihi (gg.aa.yyyy)',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Numune kodu'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int>(
                  value: ageDays,
                  decoration: const InputDecoration(labelText: 'Yaş (gün)'),
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7')),
                    DropdownMenuItem(value: 28, child: Text('28')),
                    DropdownMenuItem(value: 56, child: Text('56')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setLocal(() => ageDays = v);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: strengthCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Basınç dayanımı (MPa)',
                    hintText: 'Boş = bekliyor',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: slagCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cüruf notu (opsiyonel)',
                  ),
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
                    if (codeCtrl.text.trim().isEmpty) return;
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
                        title: 'Numuneyi sil',
                        message: 'Bu kalite kaydı silinsin mi?',
                        confirmLabel: 'Sil',
                        destructive: true,
                      );
                      if (!ok || !ctx.mounted) return;
                      ref.read(qualityProvider.notifier).delete(existing.id);
                      Navigator.pop(ctx, false);
                    },
                    child: Text(
                      'Sil',
                      style: TextStyle(color: AppColors.critical),
                    ),
                  ),
                ],
              ],
            );
        },
      ),
    );

    if (saved != true) return;
    final strengthRaw = strengthCtrl.text.trim().replaceAll(',', '.');
    final strength =
        strengthRaw.isEmpty ? null : double.tryParse(strengthRaw);
    final draft = QualitySample(
      id: existing?.id ?? '',
      projectId: project.id,
      pourRecordId: existing?.pourRecordId,
      sampleDate: dateCtrl.text.trim(),
      sampleCode: codeCtrl.text.trim(),
      ageDays: ageDays,
      strengthMpa: strength,
      slagNote: slagCtrl.text.trim(),
      notes: notesCtrl.text.trim(),
    );
    if (existing == null) {
      ref.read(qualityProvider.notifier).add(draft);
    } else {
      ref.read(qualityProvider.notifier).update(
            strength == null
                ? draft.copyWith(clearStrength: true)
                : draft,
          );
    }
  }
}
