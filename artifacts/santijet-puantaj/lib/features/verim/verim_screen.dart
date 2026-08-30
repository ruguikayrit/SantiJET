import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/production_triple_progress.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/verim_provider.dart';

/// Verim — plan + gerçekleşen tamamen İmalat sekmesinden.
class VerimScreen extends ConsumerWidget {
  const VerimScreen({super.key, this.embedded = false});

  /// Hub içindeyken üst chrome (header) gösterilmez.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final project = ref.watch(activeProjectProvider);
    final rows = ref.watch(verimRowsProvider);
    final teamSummaries = ref.watch(teamVerimSummariesProvider);

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

    final body = rows.isEmpty
        ? SJEmptyState(
            title: 'Henüz imalat yok',
            message:
                'Verim, İmalat sekmesindeki metraj · süre · adam-gün '
                'plan/gerçekleşen değerlerinden hesaplanır.',
            icon: Icons.speed_outlined,
            actionLabel: 'İmalat',
            onAction: () => context.go(AppRoutes.imalat),
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              Text(
                'İmalat bazlı verim',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Mavi çubuklar: tamamlanma (metraj · süre · AG)\n'
                'Yeşil rozet: birim verim — (gerçek metraj / gerçek AG) ÷ (plan metraj / plan AG)',
                style: theme.textTheme.bodySmall,
              ),
              if (teamSummaries.length > 1) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Ekip özeti', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                _TeamVerimSummaryStrip(summaries: teamSummaries),
              ],
              const SizedBox(height: AppSpacing.md),
              Text('İmalat satırları', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              for (final row in rows) ...[
                _VerimRowCard(row: row),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
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

class _TeamVerimSummaryStrip extends StatelessWidget {
  const _TeamVerimSummaryStrip({required this.summaries});

  final List<TeamVerimSummary> summaries;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: summaries.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final s = summaries[i];
          final efficiency = s.unitEfficiency;

          return SizedBox(
            width: 168,
            child: SJCard.builder(
              builder: (context, theme) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.planLineCount} imalat',
                      style: theme.textTheme.labelSmall,
                    ),
                    const Spacer(),
                    if (efficiency != null)
                      Row(
                        children: [
                          UnitEfficiencyBadge(
                            efficiency: efficiency,
                            compact: true,
                          ),
                          const Spacer(),
                          Text(
                            '${_fmt(s.actualQty)} / ${_fmt(s.plannedQty)}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      )
                    else
                      Text(
                        'Verim için plan + kayıt gerekli',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.statusInkOnCard(AppColors.warning),
                        ),
                      ),
                    if (efficiency != null) ...[
                      const SizedBox(height: 6),
                      UnitEfficiencyBar(efficiency: efficiency, height: 4),
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

class _VerimRowCard extends StatelessWidget {
  const _VerimRowCard({required this.row});

  final VerimRow row;

  @override
  Widget build(BuildContext context) {
    final metrics = row.metrics;
    final efficiency = row.unitEfficiency;

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
                      row.imalatName,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  UnitEfficiencyBadge(
                    efficiency: efficiency,
                    missingLabel: metrics.canComputeEfficiency
                        ? 'Kayıt bekleniyor'
                        : 'Plan eksik',
                  ),
                ],
              ),
              if (row.locationLabel.isNotEmpty ||
                  row.teamName != 'Diğer') ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if (row.teamName != 'Diğer') row.teamName,
                    if (row.locationLabel.isNotEmpty) row.locationLabel,
                  ].join(' · '),
                  style: theme.textTheme.labelSmall,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              ProductionTripleProgress(metrics: metrics),
            ],
          );
        },
      ),
    );
  }
}
