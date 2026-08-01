import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../domain/entities/concrete_discovery.dart';
import '../../domain/entities/metraj_variance_note.dart';

/// Keşif metrajı, element ilerlemesi ve metraj fark açıklamaları.
class KesifScreen extends ConsumerWidget {
  const KesifScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final progress = ref.watch(projectProgressProvider);
    final elements = ref.watch(elementProgressProvider);
    final variance = ref.watch(activeVarianceProvider);
    final discovery = ref.watch(activeDiscoveryProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SantijetHeader(subtitle: 'Keşif / İlerleme', avatarInitial: 'SJ'),
            Expanded(
              child: project == null
                  ? const SJEmptyState(
                      title: 'Proje seçin',
                      message: 'Keşif metrajı için aktif bir proje gerekir.',
                      icon: Icons.apartment_outlined,
                    )
                  : discovery.isEmpty && variance.isEmpty
                      ? SJEmptyState(
                          title: 'Keşif yok',
                          message:
                              'Planlanan beton metrajını element bazında ekleyin.',
                          icon: Icons.pie_chart_outline,
                          actionLabel: 'Keşif Ekle',
                          onAction: () => _openDiscoveryEditor(context, ref),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            88,
                          ),
                          children: [
                            _OverallProgressCard(progress: progress),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Yapısal eleman ilerlemesi',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (elements.isEmpty)
                              SJCard(
                                child: Builder(
                                  builder: (context) => Text(
                                    'Henüz element keşfi yok.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.cardTextSecondary,
                                        ),
                                  ),
                                ),
                              )
                            else
                              ...[
                                for (var i = 0; i < elements.length; i++) ...[
                                  if (i > 0)
                                    const SizedBox(height: AppSpacing.sm),
                                  _ElementProgressTile(
                                    row: elements[i],
                                    onTap: () {
                                      ConcreteDiscoveryItem? match;
                                      for (final d in discovery) {
                                        if (d.elementName ==
                                            elements[i].elementName) {
                                          match = d;
                                          break;
                                        }
                                      }
                                      if (match != null) {
                                        _openDiscoveryEditor(
                                          context,
                                          ref,
                                          existing: match,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ],
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Metraj Fark Açıklamaları',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _openVarianceEditor(context, ref),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Fark Ekle'),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (variance.isEmpty)
                              SJCard(
                                child: Builder(
                                  builder: (context) => Text(
                                    'Plan ↔ gerçekleşen farkı için henüz açıklama yok.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.cardTextSecondary,
                                        ),
                                  ),
                                ),
                              )
                            else
                              ...[
                                for (var i = 0; i < variance.length; i++) ...[
                                  if (i > 0)
                                    const SizedBox(height: AppSpacing.sm),
                                  _VarianceTile(
                                    note: variance[i],
                                    onDelete: () async {
                                      final ok = await SJModal.confirm(
                                        context: context,
                                        title: 'Açıklamayı sil',
                                        message:
                                            'Bu metraj fark kaydı silinsin mi?',
                                        confirmLabel: 'Sil',
                                        destructive: true,
                                      );
                                      if (!ok) return;
                                      ref
                                          .read(varianceProvider.notifier)
                                          .delete(variance[i].id);
                                    },
                                  ),
                                ],
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
              onPressed: () => _openDiscoveryEditor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Keşif Ekle'),
            ),
    );
  }

  Future<void> _openDiscoveryEditor(
    BuildContext context,
    WidgetRef ref, {
    ConcreteDiscoveryItem? existing,
  }) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;

    final discovery = ref.read(activeDiscoveryProvider);
    final nameCtrl =
        TextEditingController(text: existing?.elementName ?? '');
    final m3Ctrl = TextEditingController(
      text: existing == null ? '' : BetonProgress.fmtM3(existing.plannedM3),
    );
    final locationCtrl =
        TextEditingController(text: existing?.location ?? '');
    var concreteClass = existing?.concreteClass ?? 'C30/37';
    final sortOrder = existing?.sortOrder ?? discovery.length;

    final saved = await SJModal.showSheet<bool>(
      context: context,
      title: existing == null ? 'Yeni keşif kalemi' : 'Keşfi düzenle',
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Yapısal eleman'),
                  textCapitalization: TextCapitalization.sentences,
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
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () {
                    final m3 = double.tryParse(
                      m3Ctrl.text.trim().replaceAll(',', '.'),
                    );
                    if (nameCtrl.text.trim().isEmpty) return;
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
                        title: 'Keşfi sil',
                        message: 'Bu keşif kalemi silinsin mi?',
                        confirmLabel: 'Sil',
                        destructive: true,
                      );
                      if (!ok || !ctx.mounted) return;
                      ref
                          .read(discoveryProvider.notifier)
                          .delete(existing.id);
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
    final draft = ConcreteDiscoveryItem(
      id: existing?.id ?? '',
      projectId: project.id,
      elementName: nameCtrl.text.trim(),
      plannedM3: m3,
      location: locationCtrl.text.trim(),
      concreteClass: concreteClass,
      sortOrder: sortOrder,
    );
    if (existing == null) {
      ref.read(discoveryProvider.notifier).add(draft);
    } else {
      ref.read(discoveryProvider.notifier).update(draft);
    }
  }

  Future<void> _openVarianceEditor(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;

    final dateCtrl = TextEditingController(
      text: AppDate.format(AppDate.today()),
    );
    final plannedCtrl = TextEditingController();
    final actualCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final elementCtrl = TextEditingController();
    final detailCtrl = TextEditingController();

    final saved = await SJModal.showSheet<bool>(
      context: context,
      title: 'Metraj fark açıklaması',
      child: Builder(
        builder: (ctx) {
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
                  controller: elementCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Yapısal eleman (opsiyonel)',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: plannedCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Planlanan m³'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: actualCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Gerçekleşen m³'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Neden'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: detailCtrl,
                  decoration: const InputDecoration(labelText: 'Detay'),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () {
                    final planned = double.tryParse(
                      plannedCtrl.text.trim().replaceAll(',', '.'),
                    );
                    final actual = double.tryParse(
                      actualCtrl.text.trim().replaceAll(',', '.'),
                    );
                    if (planned == null || actual == null) return;
                    if (reasonCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (saved != true) return;
    final planned =
        double.tryParse(plannedCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final actual =
        double.tryParse(actualCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    ref.read(varianceProvider.notifier).add(
          MetrajVarianceNote(
            id: '',
            projectId: project.id,
            date: dateCtrl.text.trim(),
            plannedM3: planned,
            actualM3: actual,
            reason: reasonCtrl.text.trim(),
            elementName: elementCtrl.text.trim(),
            detail: detailCtrl.text.trim(),
          ),
        );
  }
}

class _OverallProgressCard extends StatelessWidget {
  const _OverallProgressCard({required this.progress});

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
    final pct = progress.progressPct;
    final color = pct >= 100
        ? AppColors.success
        : pct >= 50
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
                  Icon(Icons.pie_chart_outline,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Genel İlerleme',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.cardTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '%${pct.clamp(0, 999).toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Keşif',
                      value: BetonProgress.fmtM3(progress.planned),
                      color: AppColors.electricBlue,
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
                      label: 'Kalan',
                      value: BetonProgress.fmtM3(progress.remaining),
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppRadii.xs,
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: color.withValues(alpha: 0.15),
                  color: color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ElementProgressTile extends StatelessWidget {
  const _ElementProgressTile({required this.row, this.onTap});

  final ElementProgressRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pct = row.progressPct;
    final color = pct >= 100
        ? AppColors.success
        : pct >= 50
            ? AppColors.warning
            : AppColors.critical;
    final subtitle = [
      if (row.location.isNotEmpty) row.location,
      if (row.concreteClass.isNotEmpty) row.concreteClass,
    ].join(' · ');

    return SJCard(
      onTap: onTap,
      accentColor: color,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row.elementName.isEmpty ? 'İsimsiz' : row.elementName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.cardTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '%${pct.clamp(0, 999).toStringAsFixed(0)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.cardTextMuted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Plan ${BetonProgress.fmtM3(row.plannedM3)} m³',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.cardTextSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Dökülen ${BetonProgress.fmtM3(row.pouredM3)} m³',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.cardTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Kalan ${BetonProgress.fmtM3(row.remainingM3)} m³',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.cardTextSecondary,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: AppRadii.xs,
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: color.withValues(alpha: 0.15),
                  color: color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VarianceTile extends StatelessWidget {
  const _VarianceTile({required this.note, required this.onDelete});

  final MetrajVarianceNote note;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final delta = note.deltaM3;
    final color = delta.abs() < 0.01
        ? AppColors.success
        : delta > 0
            ? AppColors.warning
            : AppColors.critical;

    return SJCard(
      accentColor: color,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.reason,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.cardTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: AppColors.critical,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Text(
                [
                  note.date,
                  if (note.elementName.isNotEmpty) note.elementName,
                ].join(' · '),
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Plan ${BetonProgress.fmtM3(note.plannedM3)} → '
                'Gerçek ${BetonProgress.fmtM3(note.actualM3)}  '
                '(${delta >= 0 ? '+' : ''}${BetonProgress.fmtM3(delta)} m³)',
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
              if (note.detail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(note.detail, style: theme.textTheme.bodySmall),
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
