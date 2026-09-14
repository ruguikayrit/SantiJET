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
import '../../domain/models/production_metrics.dart';

/// Ana sayfa — İnşaat / Elektrik / Mekanik adam-gün ilerleme (%), üçlü sıra.
class HomeImalatGroupKpiRow extends ConsumerWidget {
  const HomeImalatGroupKpiRow({super.key});

  static ProductionProgressAxis? _laborAxis(ProductionGroupSummary? summary) {
    if (summary == null) return null;
    for (final a in summary.axes) {
      if (a.label == 'Adam-gün') return a;
    }
    return null;
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
          children: [
            for (var i = 0; i < TaskTagCatalog.all.length; i++) ...[
              if (i > 0) const SizedBox(width: spacing),
              SizedBox(
                width: itemWidth,
                child: _GroupKpiCard(
                  tag: TaskTagCatalog.all[i],
                  summary: byKey[TaskTagCatalog.all[i]],
                  labor: _laborAxis(byKey[TaskTagCatalog.all[i]]),
                  onTap: () => context.go(AppRoutes.imalat),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GroupKpiCard extends StatelessWidget {
  const _GroupKpiCard({
    required this.tag,
    required this.summary,
    required this.labor,
    required this.onTap,
  });

  final String tag;
  final ProductionGroupSummary? summary;
  final ProductionProgressAxis? labor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = TaskTagCatalog.accentFor(tag);
    final ink = AppColors.statusInkOnCard(accent);
    final hasPlan = labor?.hasPlan ?? false;
    final displayPct = labor?.displayProgressPct ?? 0;
    final fill = hasPlan ? (labor!.progressPct / 100).clamp(0.0, 1.0) : 0.0;
    final imalatCount = summary?.itemCount ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
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
                TaskTagCatalog.cardLabel(tag),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasPlan ? '%${displayPct.toStringAsFixed(0)}' : '—',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                imalatCount > 0 ? '$imalatCount imalat · AG' : 'Adam-gün',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              if (hasPlan) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fill,
                    minHeight: 5,
                    backgroundColor: accent.withValues(alpha: 0.14),
                    color: axisFillAccentColor('Adam-gün'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
