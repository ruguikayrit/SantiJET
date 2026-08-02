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

/// Laboratuvar beton basınç dayanım rapor kayıtları.
class QualityScreen extends ConsumerWidget {
  const QualityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final samples = ref.watch(activeQualityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Basınç Dayanım Raporları'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.ayarlar);
            }
          },
        ),
      ),
      floatingActionButton: project == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Rapor Ekle'),
            ),
      body: project == null
          ? const SJEmptyState(
              title: 'Proje seçin',
              message: 'Basınç dayanım raporları proje kapsamında tutulur.',
              icon: Icons.apartment_outlined,
            )
          : samples.isEmpty
              ? SJEmptyState(
                  title: 'Rapor yok',
                  message:
                      'Laboratuvar basınç dayanım raporundaki önemli alanları '
                      'Temel / Kolon & Perde / Döşeme gruplarında kaydedin.',
                  icon: Icons.science_outlined,
                  actionLabel: 'Rapor Ekle',
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
                        : 'Ort. ${s.strengthMpa!.toStringAsFixed(1)} MPa';
                    final min = s.minStrengthMpa == null
                        ? null
                        : 'Min ${s.minStrengthMpa!.toStringAsFixed(1)} MPa';
                    final compliance = switch (s.isCompliant) {
                      true => 'Uygun',
                      false => 'Uygunsuz',
                      null => s.isPending ? 'Bekliyor' : 'Karar yok',
                    };
                    return SJListItem(
                      title: s.sampleCode.isEmpty
                          ? (s.labReportNo.isEmpty
                              ? s.elementGroup.label
                              : s.labReportNo)
                          : s.sampleCode,
                      subtitle: [
                        '${s.elementGroup.label} · ${s.concreteClass}',
                        '${s.sampleDate} · ${s.ageDays} gün · $strength',
                        if (min != null) min,
                        if (s.labReportNo.isNotEmpty)
                          'Rapor: ${s.labReportNo}',
                      ].join('\n'),
                      leadingIcon: Icons.science_outlined,
                      accentColor: switch (s.isCompliant) {
                        true => AppColors.success,
                        false => AppColors.critical,
                        null =>
                          s.isPending ? AppColors.partial : AppColors.info,
                      },
                      trailing: SJStatusBadge(
                        label: compliance,
                        color: switch (s.isCompliant) {
                          true => AppColors.success,
                          false => AppColors.critical,
                          null =>
                            s.isPending ? AppColors.partial : AppColors.info,
                        },
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
    final reportCtrl =
        TextEditingController(text: existing?.labReportNo ?? '');
    final classCtrl =
        TextEditingController(text: existing?.concreteClass ?? 'C30/37');
    final strengthCtrl = TextEditingController(
      text: existing?.strengthMpa?.toStringAsFixed(1) ?? '',
    );
    final minCtrl = TextEditingController(
      text: existing?.minStrengthMpa?.toStringAsFixed(1) ?? '',
    );
    final slagCtrl = TextEditingController(text: existing?.slagNote ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var ageDays = existing?.ageDays ?? 28;
    var elementGroup = existing?.elementGroup ?? ConcreteElementGroup.temel;
    var compliance = existing?.isCompliant; // null / true / false

    final saved = await SJModal.showSheet<bool>(
      context: context,
      title: existing == null ? 'Yeni basınç raporu' : 'Raporu düzenle',
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<ConcreteElementGroup>(
                value: elementGroup,
                decoration: const InputDecoration(
                  labelText: 'Yapısal eleman grubu',
                ),
                items: [
                  for (final g in ConcreteElementGroup.values)
                    DropdownMenuItem(value: g, child: Text(g.label)),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setLocal(() => elementGroup = v);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: reportCtrl,
                decoration: const InputDecoration(
                  labelText: 'Laboratuvar rapor no',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Numune kodu',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Numune / deney tarihi (gg.aa.yyyy)',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: classCtrl,
                decoration: const InputDecoration(
                  labelText: 'Beton sınıfı',
                  hintText: 'C30/37',
                ),
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
                  labelText: 'Ortalama basınç dayanımı (MPa)',
                  hintText: 'Boş = bekliyor',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: minCtrl,
                decoration: const InputDecoration(
                  labelText: 'En düşük deney sonucu (MPa)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: switch (compliance) {
                  true => 'pass',
                  false => 'fail',
                  null => 'pending',
                },
                decoration: const InputDecoration(
                  labelText: 'Rapor sonucu',
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Bekliyor')),
                  DropdownMenuItem(value: 'pass', child: Text('Uygun')),
                  DropdownMenuItem(value: 'fail', child: Text('Uygunsuz')),
                ],
                onChanged: (v) {
                  setLocal(() {
                    compliance = switch (v) {
                      'pass' => true,
                      'fail' => false,
                      _ => null,
                    };
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: slagCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cüruf / katkı notu (opsiyonel)',
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
                  if (codeCtrl.text.trim().isEmpty &&
                      reportCtrl.text.trim().isEmpty) {
                    return;
                  }
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
                      title: 'Raporu sil',
                      message: 'Bu basınç dayanım kaydı silinsin mi?',
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
    final minRaw = minCtrl.text.trim().replaceAll(',', '.');
    final minStrength = minRaw.isEmpty ? null : double.tryParse(minRaw);
    final code = codeCtrl.text.trim().isEmpty
        ? reportCtrl.text.trim()
        : codeCtrl.text.trim();

    var draft = QualitySample(
      id: existing?.id ?? '',
      projectId: project.id,
      pourRecordId: existing?.pourRecordId,
      elementGroup: elementGroup,
      labReportNo: reportCtrl.text.trim(),
      sampleDate: dateCtrl.text.trim(),
      sampleCode: code,
      concreteClass: classCtrl.text.trim().isEmpty
          ? 'C30/37'
          : classCtrl.text.trim(),
      ageDays: ageDays,
      strengthMpa: strength,
      minStrengthMpa: minStrength,
      isCompliant: compliance,
      slagNote: slagCtrl.text.trim(),
      notes: notesCtrl.text.trim(),
    );

    if (existing == null) {
      ref.read(qualityProvider.notifier).add(draft);
    } else {
      ref.read(qualityProvider.notifier).update(
            draft.copyWith(
              clearStrength: strength == null,
              clearMinStrength: minStrength == null,
              clearCompliance: compliance == null,
            ),
          );
    }
  }
}
