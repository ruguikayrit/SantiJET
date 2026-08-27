import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/verim_provider.dart';

/// Verim — plan süre (İş Programı) + plan metraj (Keşif) × gerçekleşen.
class VerimScreen extends ConsumerWidget {
  const VerimScreen({super.key, this.embedded = false});

  /// Hub içindeyken üst chrome (header) gösterilmez.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final project = ref.watch(activeProjectProvider);
    final verim = ref.watch(verimProvider);
    final rows = ref.watch(verimRowsProvider);
    final syncing = verim.status == VerimSyncStatus.syncing;

    if (project == null) {
      final empty = SJEmptyState(
        title: 'Önce proje ekleyin',
        message: 'Verim hesabı aktif projeye bağlıdır.',
        icon: Icons.apartment_outlined,
        actionLabel: 'Projelere Git',
        onAction: () => context.go(AppRoutes.projeler),
      );
      if (embedded) return empty;
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SantijetHeader(subtitle: 'Verim'),
              Expanded(child: empty),
            ],
          ),
        ),
      );
    }

    final body = RefreshIndicator(
                onRefresh: () =>
                    ref.read(verimProvider.notifier).syncFromCloud(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xxl,
                  ),
                  children: [
                    _CloudBanner(
                      projectName: project.name,
                      verim: verim,
                      syncing: syncing,
                      onSync: () =>
                          ref.read(verimProvider.notifier).syncFromCloud(),
                      onDemo: () => ref
                          .read(verimProvider.notifier)
                          .syncFromCloud(demoFallback: true),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (!verim.hasCloudPlan) ...[
                      SJCard(
                        child: Builder(
                          builder: (context) {
                            final theme = Theme.of(context);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.cloud_off_outlined,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        'Plan kaynakları eksik',
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Verim için iki bulut kaynağı gerekir:\n'
                                  '• İş Programı → planlanan süre / iş gücü\n'
                                  '• Keşif → planlanan metraj\n'
                                  'Yalnızca yerel puantaj ile verim hesaplanamaz.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                SJButton(
                                  label: 'Buluttan çek (İş Programı + Keşif)',
                                  icon: Icons.cloud_download_outlined,
                                  loading: syncing,
                                  expanded: true,
                                  onPressed: syncing
                                      ? null
                                      : () => ref
                                          .read(verimProvider.notifier)
                                          .syncFromCloud(),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                SJButton(
                                  label: 'Demo bulut verisi (önizleme)',
                                  icon: Icons.science_outlined,
                                  variant: SJButtonVariant.secondary,
                                  expanded: true,
                                  loading: syncing,
                                  onPressed: syncing
                                      ? null
                                      : () => ref
                                          .read(verimProvider.notifier)
                                          .syncFromCloud(demoFallback: true),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      Text(
                        'İmalat bazlı verim',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Süre ← İş Programı · Metraj ← Keşif\n'
                        'Birim verim = (dönem metraj / dönem AG) ÷ (plan metraj / plan AG)',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final row in rows) ...[
                        _VerimRowCard(row: row),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ],
                ),
    );

    if (embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SantijetHeader(subtitle: 'Verim'),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _CloudBanner extends StatelessWidget {
  const _CloudBanner({
    required this.projectName,
    required this.verim,
    required this.syncing,
    required this.onSync,
    required this.onDemo,
  });

  final String projectName;
  final VerimState verim;
  final bool syncing;
  final VoidCallback onSync;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = verim.hasCloudPlan;
    final accent = ready ? AppColors.success : AppColors.warning;
    final wash = Color.lerp(AppColors.canvas, accent, 0.12)!;
    final bodyInk = AppColors.readableSecondaryOn(wash);
    final mutedInk = AppColors.readableMutedOn(wash);
    final accentInk = AppColors.statusInk(accent, surface: wash);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: AppRadii.md,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ready ? Icons.cloud_done_outlined : Icons.cloud_sync_outlined,
                color: accentInk,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Plan bulut senkronu',
                  style: theme.textTheme.titleMedium?.copyWith(color: accentInk),
                ),
              ),
              if (ready)
                IconButton(
                  tooltip: 'Yeniden çek',
                  onPressed: syncing ? null : onSync,
                  icon: syncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.refresh, color: accentInk),
                ),
            ],
          ),
          Text(
            projectName,
            style: theme.textTheme.bodySmall?.copyWith(color: bodyInk),
          ),
          const SizedBox(height: AppSpacing.xs),
          _sourceLine(
            theme,
            label: 'İş Programı (süre)',
            ok: verim.hasSchedulePlan,
          ),
          _sourceLine(
            theme,
            label: 'Keşif (metraj)',
            ok: verim.hasKesifPlan,
          ),
          if (verim.message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              verim.message!,
              style: theme.textTheme.bodySmall?.copyWith(color: mutedInk),
            ),
          ],
          if (ready) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: syncing ? null : onDemo,
                icon: const Icon(Icons.science_outlined, size: 16),
                label: const Text('Demo veriyi yenile'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sourceLine(ThemeData theme, {required String label, required bool ok}) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 16,
            color: ok ? AppColors.success : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ok ? AppColors.success : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerimRowCard extends StatelessWidget {
  const _VerimRowCard({required this.row});

  final VerimRow row;

  @override
  Widget build(BuildContext context) {
    final item = row.item;
    final primary = row.unitEfficiency;
    final color = _pctColor(primary);
    final plannedQty = row.plannedQty;

    return SJCard(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.imalatName,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (primary != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: AppRadii.full,
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '%${(primary * 100).toStringAsFixed(0)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              if (item.startDate != null && item.endDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${item.startDate} → ${item.endDate}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              _metric(
                theme,
                label: 'İş gücü',
                planned: row.plannedWorkerDays.toStringAsFixed(
                  row.plannedWorkerDays == row.plannedWorkerDays.roundToDouble()
                      ? 0
                      : 1,
                ),
                actual: row.actualWorkerDays.toStringAsFixed(1),
                unit: 'adam-gün',
              ),
              if (plannedQty != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _metric(
                  theme,
                  label: 'Miktar',
                  planned: plannedQty.toStringAsFixed(1),
                  actual: row.actualQty.toStringAsFixed(1),
                  unit: row.unit ?? '',
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Keşif metraj eşleşmesi yok',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
              if (primary != null) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: primary.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.15),
                    color: color,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _metric(
    ThemeData theme, {
    required String label,
    required String planned,
    required String actual,
    required String unit,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        Expanded(
          child: Text(
            'Plan $planned  ·  Gerçek $actual ${unit.trim()}',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Color _pctColor(double? ratio) {
    if (ratio == null) return AppColors.cardTextMuted;
    final pct = ratio * 100;
    if (pct >= 80) return AppColors.success;
    if (pct >= 50) return AppColors.warning;
    return AppColors.critical;
  }
}
