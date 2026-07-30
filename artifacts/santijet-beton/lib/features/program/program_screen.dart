import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_modal.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_date.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/beton_progress.dart';
import '../../domain/entities/concrete_order.dart';
import '../../domain/entities/concrete_pour.dart';
import '../../domain/entities/project.dart';

/// Sipariş programı — planlı sipariş ↔ dökülen karşılaştırma + WhatsApp paylaşım.
class ProgramScreen extends ConsumerWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final progress = ref.watch(projectProgressProvider);
    final orders = ref.watch(activeOrdersProvider);
    final pours = ref.watch(activePoursProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SantijetHeader(
              subtitle: 'Program / Sipariş',
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
                            _ProgramSummaryCard(progress: progress),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Siparişler',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            for (var i = 0; i < orders.length; i++) ...[
                              if (i > 0) const SizedBox(height: AppSpacing.sm),
                              _OrderCard(
                                order: orders[i],
                                project: project,
                                actualM3: _actualForOrder(orders[i], pours),
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
                                  actualM3:
                                      _actualForOrder(orders[i], pours),
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

  static double _actualForOrder(
    ConcreteOrder order,
    List<ConcretePour> pours,
  ) {
    return pours
        .where((p) {
          if (p.date != order.plannedDate) return false;
          if (order.elementName.trim().isEmpty) return true;
          return p.elementName.trim() == order.elementName.trim();
        })
        .fold<double>(0, (s, p) => s + p.volumeM3);
  }

  Future<void> _shareOrder(
    BuildContext context,
    WidgetRef ref, {
    required Project project,
    required ConcreteOrder order,
    required double actualM3,
  }) async {
    final gap = actualM3 - order.plannedM3;
    final lines = <String>[
      'ŞantiJET Beton — Sipariş',
      'Proje: ${project.name}',
      if (project.code.isNotEmpty) 'Kod: ${project.code}',
      'Tarih: ${order.plannedDate}',
      if (order.plannedStartHour.isNotEmpty)
        'Saat: ${order.plannedStartHour}',
      if (order.elementName.isNotEmpty) 'Element: ${order.elementName}',
      if (order.location.isNotEmpty) 'Lokasyon: ${order.location}',
      'Sınıf: ${order.concreteClass}',
      'Plan: ${BetonProgress.fmtM3(order.plannedM3)} m³',
      'Dökülen: ${BetonProgress.fmtM3(actualM3)} m³',
      'Fark: ${gap >= 0 ? '+' : ''}${BetonProgress.fmtM3(gap)} m³',
      if (order.supplier.isNotEmpty) 'Tedarikçi: ${order.supplier}',
      if (order.notes.isNotEmpty) 'Not: ${order.notes}',
    ];
    final text = lines.join('\n');

    var shared = false;
    try {
      final uri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(text)}',
      );
      if (await canLaunchUrl(uri)) {
        shared = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      shared = false;
    }

    if (!shared) {
      try {
        await Share.share(text, subject: 'ŞantiJET Beton Sipariş');
        shared = true;
      } catch (_) {
        shared = false;
      }
    }

    if (shared) {
      ref.read(ordersProvider.notifier).markShared(order.id);
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shared
              ? 'Sipariş paylaşıldı'
              : 'Paylaşım açılamadı — metni kopyalayın',
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
    final locationCtrl =
        TextEditingController(text: existing?.location ?? '');
    final supplierCtrl =
        TextEditingController(text: existing?.supplier ?? '');
    final m3Ctrl = TextEditingController(
      text: existing == null ? '' : BetonProgress.fmtM3(existing.plannedM3),
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var concreteClass = existing?.concreteClass ?? 'C30/37';

    final saved = await SJModal.showSheet<bool>(
      context: context,
      title: existing == null ? 'Yeni sipariş' : 'Siparişi düzenle',
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return SingleChildScrollView(
            child: Column(
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
                  decoration: const InputDecoration(labelText: 'Element'),
                  textCapitalization: TextCapitalization.sentences,
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
            ),
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
      location: locationCtrl.text.trim(),
      concreteClass: concreteClass,
      supplier: supplierCtrl.text.trim(),
      plannedStartHour: hourCtrl.text.trim(),
      notes: notesCtrl.text.trim(),
      sharedViaWhatsApp: existing?.sharedViaWhatsApp ?? false,
    );
    if (existing == null) {
      ref.read(ordersProvider.notifier).add(draft);
    } else {
      ref.read(ordersProvider.notifier).update(draft);
    }
  }
}

class _ProgramSummaryCard extends StatelessWidget {
  const _ProgramSummaryCard({required this.progress});

  final ({
    double planned,
    double poured,
    double ordered,
    double progressPct,
    double orderGap,
    double remaining,
  }) progress;

  @override
  Widget build(BuildContext context) {
    final gap = progress.orderGap;
    final gapColor = gap.abs() < 0.01
        ? AppColors.success
        : gap > 0
            ? AppColors.warning
            : AppColors.critical;

    return SJCard(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Planlı · Gerçekleşen',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Planlı sipariş',
                      value: BetonProgress.fmtM3(progress.ordered),
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _MiniStat(
                      label: 'Dökülen',
                      value: BetonProgress.fmtM3(progress.poured),
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _MiniStat(
                      label: 'Fark',
                      value: BetonProgress.fmtM3(gap),
                      color: gapColor,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.project,
    required this.actualM3,
    required this.onTap,
    required this.onShare,
  });

  final ConcreteOrder order;
  final Project project;
  final double actualM3;
  final VoidCallback onTap;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final gap = actualM3 - order.plannedM3;
    final gapColor = gap.abs() < 0.01
        ? AppColors.success
        : gap > 0
            ? AppColors.warning
            : AppColors.critical;

    return SJCard(
      onTap: onTap,
      accentColor: gapColor,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final title = order.elementName.isNotEmpty
              ? order.elementName
              : (order.location.isNotEmpty ? order.location : 'Sipariş');
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
                  IconButton(
                    onPressed: onShare,
                    tooltip: 'WhatsApp ile paylaş',
                    icon: const Icon(Icons.share_outlined, size: 20),
                    visualDensity: VisualDensity.compact,
                    color: AppColors.electricBlueLight,
                  ),
                ],
              ),
              Text(meta, style: theme.textTheme.labelSmall),
              if (order.location.isNotEmpty &&
                  order.elementName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(order.location, style: theme.textTheme.labelSmall),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Plan',
                      value: BetonProgress.fmtM3(order.plannedM3),
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _MiniStat(
                      label: 'Dökülen',
                      value: BetonProgress.fmtM3(actualM3),
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _MiniStat(
                      label: 'Fark',
                      value:
                          '${gap >= 0 ? '+' : ''}${BetonProgress.fmtM3(gap)}',
                      color: gapColor,
                    ),
                  ),
                ],
              ),
              if (order.notes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(order.notes, style: theme.textTheme.bodySmall),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadii.sm,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  'm³',
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
