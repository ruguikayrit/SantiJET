import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_date.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/beton_progress.dart';
import '../../domain/entities/concrete_pour.dart';

/// Gelen / dökülen beton kayıtları.
class DokumScreen extends ConsumerWidget {
  const DokumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final pours = ref.watch(activePoursProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Döküm Kayıtları')),
      floatingActionButton: project == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Döküm'),
            ),
      body: project == null
          ? const SJEmptyState(
              title: 'Proje seçin',
              message: 'Döküm kaydı için aktif bir proje gerekli.',
              icon: Icons.apartment_outlined,
            )
          : pours.isEmpty
              ? SJEmptyState(
                  title: 'Henüz döküm yok',
                  message:
                      'Şantiyeye gelen betonları buradan kayıt altına alın.',
                  icon: Icons.local_shipping_outlined,
                  actionLabel: 'Döküm Ekle',
                  onAction: () => _openEditor(context, ref),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    88,
                  ),
                  itemCount: pours.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final p = pours[index];
                    return SJCard(
                      onTap: () => _openEditor(context, ref, existing: p),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.elementName.isEmpty
                                      ? 'Element belirtilmedi'
                                      : p.elementName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: AppRadii.sm,
                                ),
                                child: Text(
                                  '${BetonProgress.fmtM3(p.volumeM3)} m³',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${p.date} · ${p.concreteClass}'
                            '${p.supplier.isEmpty ? '' : ' · ${p.supplier}'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (p.location.isNotEmpty || p.ticketNo.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                [
                                  if (p.location.isNotEmpty) p.location,
                                  if (p.ticketNo.isNotEmpty)
                                    'İrsaliye ${p.ticketNo}',
                                ].join(' · '),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    ConcretePour? existing,
  }) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;

    final volumeCtrl = TextEditingController(
      text: existing == null ? '' : BetonProgress.fmtM3(existing.volumeM3),
    );
    final elementCtrl =
        TextEditingController(text: existing?.elementName ?? '');
    final locationCtrl =
        TextEditingController(text: existing?.location ?? '');
    final classCtrl =
        TextEditingController(text: existing?.concreteClass ?? 'C30/37');
    final supplierCtrl =
        TextEditingController(text: existing?.supplier ?? 'Akdeniz Beton');
    final ticketCtrl = TextEditingController(text: existing?.ticketNo ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var date = existing?.date ?? AppDate.format(AppDate.today());

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.md,
          ),
          child: StatefulBuilder(
            builder: (context, setSheet) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null ? 'Yeni Döküm' : 'Dökümü Düzenle',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: volumeCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Hacim (m³)',
                      ),
                    ),
                    TextField(
                      controller: elementCtrl,
                      decoration: const InputDecoration(labelText: 'Element'),
                    ),
                    TextField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(labelText: 'Lokasyon'),
                    ),
                    TextField(
                      controller: classCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Beton sınıfı'),
                    ),
                    TextField(
                      controller: supplierCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Beton firması'),
                    ),
                    TextField(
                      controller: ticketCtrl,
                      decoration:
                          const InputDecoration(labelText: 'İrsaliye no'),
                    ),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: 'Not'),
                      maxLines: 2,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Tarih: $date'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: AppDate.today(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setSheet(() => date = AppDate.format(picked));
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: () {
                        final vol = double.tryParse(
                              volumeCtrl.text.replaceAll(',', '.'),
                            ) ??
                            0;
                        if (vol <= 0) return;
                        final draft = ConcretePour(
                          id: existing?.id ?? '',
                          projectId: project.id,
                          date: date,
                          volumeM3: vol,
                          elementName: elementCtrl.text.trim(),
                          location: locationCtrl.text.trim(),
                          concreteClass: classCtrl.text.trim(),
                          supplier: supplierCtrl.text.trim(),
                          ticketNo: ticketCtrl.text.trim(),
                          notes: notesCtrl.text.trim(),
                          pourStart: existing?.pourStart ?? DateTime.now(),
                        );
                        if (existing == null) {
                          ref.read(poursProvider.notifier).add(draft);
                        } else {
                          ref.read(poursProvider.notifier).update(draft);
                        }
                        Navigator.pop(ctx, true);
                      },
                      child: const Text('Kaydet'),
                    ),
                    if (existing != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(poursProvider.notifier)
                              .delete(existing.id);
                          Navigator.pop(ctx, true);
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
      },
    );

    volumeCtrl.dispose();
    elementCtrl.dispose();
    locationCtrl.dispose();
    classCtrl.dispose();
    supplierCtrl.dispose();
    ticketCtrl.dispose();
    notesCtrl.dispose();
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Döküm kaydedildi')),
      );
    }
  }
}
