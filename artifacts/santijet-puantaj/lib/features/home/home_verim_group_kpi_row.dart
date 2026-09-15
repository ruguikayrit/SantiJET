import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/production_triple_progress.dart';
import '../../data/providers/production_provider.dart';
import '../../domain/catalogs/task_tags.dart';
import '../../domain/models/production_group_summary.dart';

/// Ana sayfa — İnşaat / Elektrik / Mekanik grup verim %.
class HomeVerimGroupKpiRow extends ConsumerWidget {
  const HomeVerimGroupKpiRow({super.key});

  static String _fmtVerimPct(double? ratio) {
    if (ratio == null) return '—';
    return '%${(ratio * 100).toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(homeImalatGroupSummariesProvider);
    final byKey = {for (final s in summaries) s.groupKey: s};

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.xs;
        const columns = 3;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < TaskTagCatalog.all.length; i++) ...[
              if (i > 0) const SizedBox(width: spacing),
              SizedBox(
                width: itemWidth,
                child: _VerimGroupKpiCard(
                  summary: byKey[TaskTagCatalog.all[i]],
                  groupKey: TaskTagCatalog.all[i],
                  onTap: () => context.go(AppRoutes.verim),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _VerimGroupKpiCard extends StatelessWidget {
  const _VerimGroupKpiCard({
    required this.summary,
    required this.groupKey,
    required this.onTap,
  });

  final ProductionGroupSummary? summary;
  final String groupKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = TaskTagCatalog.accentFor(groupKey);
    final ink = AppColors.statusInkOnCard(accent);
    final verim = summary?.groupScheduleLaborEfficiency;
    final verimInk = verim == null
        ? theme.colorScheme.onSurfaceVariant
        : AppColors.statusInkOnCard(efficiencyColorForRatio(verim));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: AppRadii.sm,
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                HomeVerimGroupKpiRow._fmtVerimPct(verim),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: verimInk,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                TaskTagCatalog.cardLabel(groupKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              if (summary != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${summary!.itemCount} imalat',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
              if (verim != null) ...[
                const SizedBox(height: 8),
                UnitEfficiencyBar(
                  efficiency: verim.clamp(0.0, 2.0),
                  height: 4,
                ),
              ] else if (summary == null || summary!.itemCount == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Veri yok',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Plan / kayıt eksik',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.statusInkOnCard(AppColors.warning),
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
