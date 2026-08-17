import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_modal.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/whatsapp_phone.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/beton_progress.dart';
import '../../domain/entities/concrete_order.dart';
import '../../domain/entities/project.dart';
import '../../domain/structural_element_kind.dart';

/// Sipariş programı — planlı sipariş ↔ dökülen karşılaştırma + WhatsApp paylaşım.
class ProgramScreen extends ConsumerWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final orders = ref.watch(activeOrdersProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SantijetHeader(
              subtitle: 'Sipariş',
              avatarInitial: 'SJ',
            ),
            Expanded(
              child: project == null
                  ? const SJEmptyState(
                      title: 'Proje seçin',
                      message: 'Sipariş programı için aktif bir proje gerekir.',
                      icon: Icons.apartment_outlined,
                    )
                  : orders.isEmpty
                      ? SJEmptyState(
                          title: 'Sipariş yok',
                          message:
                              'Günlük beton sipariş planını ekleyin ve paylaşın.',
                          icon: Icons.calendar_month_outlined,
                          actionLabel: 'Sipariş Ekle',
                          onAction: () => _openOrderEditor(context, ref),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            88,
                          ),
                          children: [
                            for (var i = 0; i < orders.length; i++) ...[
                              if (i > 0) const SizedBox(height: AppSpacing.sm),
                              _OrderCard(
                                order: orders[i],
                                project: project,
                                onTap: () => _openOrderEditor(
                                  context,
                                  ref,
                                  existing: orders[i],
                                ),
                                onShare: () => _shareOrder(
                                  context,
                                  ref,
                                  project: project,
                                  order: orders[i],
                                ),
                              ),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: project == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openOrderEditor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Sipariş Ekle'),
            ),
    );
  }

  Future<void> _shareOrder(
    BuildContext context,
    WidgetRef ref, {
    required Project project,
    required ConcreteOrder order,
  }) async {
    final lines = <String>[
      'ŞantiJET Beton — Sipariş',
      'Proje: ${project.name}',
      'Tarih: ${order.plannedDate}',
      if (order.plannedStartHour.isNotEmpty)
        'Saat: ${order.plannedStartHour}',
      if (order.elementName.isNotEmpty)
        'Yapısal eleman: ${order.elementName}',
      if (order.block.isNotEmpty) 'Blok: ${order.block}',
      if (order.floor.isNotEmpty) 'Kat: ${order.floor}',
      'Sınıf: ${order.concreteClass}',
      'Plan: ${BetonProgress.fmtM3(order.plannedM3)} m³',
      if (order.slumpCm != null)
        'Slump: ${BetonProgress.fmtM3(order.slumpCm!)}',
      if (order.pumpRequestSummary.isNotEmpty)
        'Pompa talebi: ${order.pumpRequestSummary}',
      if (order.supplier.isNotEmpty) 'Tedarikçi: ${order.supplier}',
      if (order.notes.isNotEmpty) 'Not: ${order.notes}',
    ];
    final text = lines.join('\n');
    final recipients = WhatsAppPhone.uniqueRecipients(
      project.whatsappRecipients.map(
        (e) => (name: e.name, number: e.number),
      ),
    );
    if (recipients.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Önce projeye sipariş WhatsApp alıcısı ekleyin '
            '(Ayarlar → Projelerim → düzenle).',
          ),
        ),
      );
      return;
    }

    var opened = 0;
    for (var i = 0; i < recipients.length; i++) {
      try {
        final uri = WhatsAppPhone.chatUri(
          digits: recipients[i].number,
          text: text,
        );
        if (await canLaunchUrl(uri)) {
          final ok =
              await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (ok) opened++;
        }
      } catch (_) {}

      if (i < recipients.length - 1) {
        if (!context.mounted) break;
        final next = recipients[i + 1];
        final go = await SJModal.confirm(
          context: context,
          title: 'Sonraki alıcı (${i + 2}/${recipients.length})',
          message: next.name.isEmpty
              ? 'WhatsApp’ta Gönder’e basın. Devam edince aynı sipariş '
                  'sıradaki numaraya açılır.'
              : 'WhatsApp’ta Gönder’e basın. Devam edince aynı sipariş '
                  '${next.name} kişisine açılır.',
          confirmLabel: 'Sonrakini aç',
          cancelLabel: 'Durdur',
        );
        if (!go) break;
      }
    }

    if (opened > 0) {
      ref.read(ordersProvider.notifier).markShared(order.id);
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened == 0
              ? 'WhatsApp açılamadı'
              : opened == 1
                  ? 'Sipariş WhatsApp sohbetine gönderildi — Gönder’e basın'
                  : '$opened WhatsApp sohbeti açıldı — her birinde Gönder’e basın',
        ),
      ),
    );
  }

  Future<void> _openOrderEditor(
    BuildContext context,
    WidgetRef ref, {
    ConcreteOrder? existing,
  }) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;

    final dateCtrl = TextEditingController(
      text: existing?.plannedDate ?? AppDate.format(AppDate.today()),
    );
    final hourCtrl =
        TextEditingController(text: existing?.plannedStartHour ?? '');
    final elementCtrl =
        TextEditingController(text: existing?.elementName ?? '');
    final blockCtrl = TextEditingController(text: existing?.block ?? '');
    final floorCtrl = TextEditingController(text: existing?.floor ?? '');
    final supplierCtrl =
        TextEditingController(text: existing?.supplier ?? '');
    final m3Ctrl = TextEditingController(
      text: existing == null ? '' : BetonProgress.fmtM3(existing.plannedM3),
    );
    final slumpCtrl = TextEditingController(
      text: existing?.slumpCm == null
          ? ''
          : BetonProgress.fmtM3(existing!.slumpCm!),
    );
    final pumpCountCtrl = TextEditingController(
      text: existing?.pumpCount?.toString() ?? '',
    );
    final pumpTypeCtrl =
        TextEditingController(text: existing?.pumpType ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final excessPourNoteCtrl =
        TextEditingController(text: existing?.excessPourNote ?? '');
    var concreteClass = existing?.concreteClass ?? 'C30/37';

    final saved = await SJModal.showSheet<bool>(
      context: context,
      title: existing == null ? 'Yeni sipariş' : 'Siparişi düzenle',
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Plan tarihi (gg.aa.yyyy)',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: hourCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Plan saat (örn. 07:30)',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: elementCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Yapısal eleman'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: blockCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Blok',
                    hintText: 'örn. A Blok',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: floorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kat',
                    hintText: 'örn. Bodrum Kat',
                  ),
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
                  decoration:
                      const InputDecoration(labelText: 'Planlanan m³'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: supplierCtrl,
                  decoration: const InputDecoration(labelText: 'Tedarikçi'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: slumpCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Beton slump değeri (cm)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: pumpCountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Pompa talebi — sayı',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: pumpTypeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Pompa talebi — tip',
                    hintText: 'örn. Sabit / Mobil',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Not'),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: excessPourNoteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Fazla dökülen beton açıklaması',
                    hintText: 'Sipariş üstü döküm nedeni',
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: SJButton(
                        label: 'İptal',
                        variant: SJButtonVariant.secondary,
                        expanded: true,
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SJButton(
                        label: 'Kaydet',
                        expanded: true,
                        onPressed: () {
                          final m3 = double.tryParse(
                            m3Ctrl.text.trim().replaceAll(',', '.'),
                          );
                          if (m3 == null || m3 <= 0) return;
                          Navigator.pop(ctx, true);
                        },
                      ),
                    ),
                  ],
                ),
                if (existing != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () async {
                      final ok = await SJModal.confirm(
                        context: ctx,
                        title: 'Siparişi sil',
                        message: 'Bu sipariş kaydı silinsin mi?',
                        confirmLabel: 'Sil',
                        destructive: true,
                      );
                      if (!ok || !ctx.mounted) return;
                      ref.read(ordersProvider.notifier).delete(existing.id);
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
    final m3 =
        double.tryParse(m3Ctrl.text.trim().replaceAll(',', '.')) ?? 0;
    final draft = ConcreteOrder(
      id: existing?.id ?? '',
      projectId: project.id,
      plannedDate: dateCtrl.text.trim(),
      plannedM3: m3,
      elementName: elementCtrl.text.trim(),
      block: blockCtrl.text.trim(),
      floor: floorCtrl.text.trim(),
      concreteClass: concreteClass,
      supplier: supplierCtrl.text.trim(),
      plannedStartHour: hourCtrl.text.trim(),
      slumpCm: double.tryParse(slumpCtrl.text.trim().replaceAll(',', '.')),
      pumpCount: int.tryParse(pumpCountCtrl.text.trim()),
      pumpType: pumpTypeCtrl.text.trim(),
      notes: notesCtrl.text.trim(),
      excessPourNote: excessPourNoteCtrl.text.trim(),
      sharedViaWhatsApp: existing?.sharedViaWhatsApp ?? false,
    );
    if (existing == null) {
      ref.read(ordersProvider.notifier).add(draft);
    } else {
      ref.read(ordersProvider.notifier).update(draft);
    }
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.project,
    required this.onTap,
    required this.onShare,
  });

  final ConcreteOrder order;
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    // Döküm kartlarıyla aynı yapısal eleman renk şeridi.
    final accent = StructuralElementKind.fromElementName(order.elementName)
        .accentColor;

    return SJCard(
      onTap: onTap,
      accentColor: accent,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final title = order.elementName.isNotEmpty
              ? order.elementName
              : (order.locationSummary.isNotEmpty
                  ? order.locationSummary
                  : 'Sipariş');
          final meta = [
            order.plannedDate,
            if (order.plannedStartHour.isNotEmpty) order.plannedStartHour,
            order.concreteClass,
            if (order.supplier.isNotEmpty) order.supplier,
          ].join(' · ');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.cardTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (order.sharedViaWhatsApp)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.success,
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: AppRadii.sm,
                    ),
                    child: Text(
                      '${BetonProgress.fmtM3(order.plannedM3)} m³',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onShare,
                    tooltip: 'WhatsApp ile paylaş',
                    icon: const Icon(Icons.share_outlined, size: 20),
                    visualDensity: VisualDensity.compact,
                    color: AppColors.electricBlueLight,
                  ),
                ],
              ),
              Text(
                meta,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.cardTextMuted,
                ),
              ),
              if (order.locationSummary.isNotEmpty &&
                  order.elementName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  order.locationSummary,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.cardTextMuted,
                  ),
                ),
              ],
              if (order.slumpCm != null ||
                  order.pumpRequestSummary.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  [
                    if (order.slumpCm != null)
                      'Slump ${BetonProgress.fmtM3(order.slumpCm!)} cm',
                    if (order.pumpRequestSummary.isNotEmpty)
                      'Pompa ${order.pumpRequestSummary}',
                  ].join(' · '),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.cardTextMuted,
                  ),
                ),
              ],
              if (order.notes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  order.notes,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.cardTextSecondary,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
