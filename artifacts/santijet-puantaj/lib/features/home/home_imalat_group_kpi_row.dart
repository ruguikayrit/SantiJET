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
import '../../domain/models/home_imalat_group_progress.dart';

/// Ana sayfa — Proje genel + İnşaat / Elektrik / Mekanik: Süre · Metraj · Adam-gün %.
class HomeImalatGroupKpiRow extends ConsumerWidget {
  const HomeImalatGroupKpiRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(homeImalatGroupProgressProvider);
    final project = ref.watch(homeImalatProjectProgressProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectOverallCard(
          data: project,
          onTap: () => context.go(AppRoutes.imalat),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = AppSpacing.xs;
            const columns = 3;
            final itemWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < progress.length; i++) ...[
                  if (i > 0) const SizedBox(width: spacing),
                  SizedBox(
                    width: itemWidth,
                    child: _GroupKpiCard(
                      data: progress[i],
                      onTap: () => context.go(AppRoutes.imalat),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProjectOverallCard extends StatelessWidget {
  const _ProjectOverallCard({
    required this.data,
    required this.onTap,
  });

  final HomeImalatGroupProgress data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = AppColors.electricBlue;
    final ink = AppColors.statusInkOnCard(accent);
    final hasAny = data.includedCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: AppRadii.sm,
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'PROJE GENEL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (data.totalImalatCount > 0)
                    Text(
                      '${data.includedCount}/${data.totalImalatCount} imalat',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (hasAny)
                Row(
                  children: [
                    Expanded(
                      child: _OverallAxis(
                        label: 'Süre',
                        pct: data.sureDisplayPct,
                        barColor: axisFillAccentColor('Süre'),
                        ink: ink,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _OverallAxis(
                        label: 'Metraj',
                        pct: data.metrajDisplayPct,
                        barColor: axisFillAccentColor('Metraj'),
                        ink: ink,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _OverallAxis(
                        label: 'Adam-gün',
                        pct: data.laborDisplayPct,
                        barColor: axisFillAccentColor('Adam-gün'),
                        ink: ink,
                      ),
                    ),
                  ],
                )
              else if (data.totalImalatCount == 0)
                Text(
                  'İmalat yok',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Text(
                  'Plan verisi tam değil',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.statusInkOnCard(AppColors.warning),
                  ),
                ),
              if (data.hasExcludedImalats) ...[
                const SizedBox(height: 8),
                Text(
                  'Veriler tam değil; ${data.excludedCount} imalat hesaba alınmamıştır.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.statusInkOnCard(AppColors.warning),
                    fontSize: 10,
                    height: 1.25,
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

class _OverallAxis extends StatelessWidget {
  const _OverallAxis({
    required this.label,
    required this.pct,
    required this.barColor,
    required this.ink,
  });

  final String label;
  final double? pct;
  final Color barColor;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = pct;
    final fill = display != null ? (display / 100).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: display != null ? fill : null,
            minHeight: 5,
            backgroundColor: barColor.withValues(alpha: 0.14),
            color: barColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          display != null ? '%${display.toStringAsFixed(0)}' : '—',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: ink,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _GroupKpiCard extends StatelessWidget {
  const _GroupKpiCard({
    required this.data,
    required this.onTap,
  });

  final HomeImalatGroupProgress data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = TaskTagCatalog.accentFor(data.groupKey);
    final ink = AppColors.statusInkOnCard(accent);
    final hasAny = data.includedCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
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
                TaskTagCatalog.cardLabel(data.groupKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              if (data.totalImalatCount > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${data.includedCount}/${data.totalImalatCount} imalat',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (hasAny) ...[
                _ProgressLine(
                  label: 'Süre',
                  pct: data.sureDisplayPct,
                  ink: ink,
                  barColor: axisFillAccentColor('Süre'),
                ),
                const SizedBox(height: 6),
                _ProgressLine(
                  label: 'Metraj',
                  pct: data.metrajDisplayPct,
                  ink: ink,
                  barColor: axisFillAccentColor('Metraj'),
                ),
                const SizedBox(height: 6),
                _ProgressLine(
                  label: 'Adam-gün',
                  pct: data.laborDisplayPct,
                  ink: ink,
                  barColor: axisFillAccentColor('Adam-gün'),
                ),
              ] else if (data.totalImalatCount == 0)
                Text(
                  'İmalat yok',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Text(
                  'Plan verisi tam değil',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.statusInkOnCard(AppColors.warning),
                  ),
                ),
              if (data.hasExcludedImalats) ...[
                const SizedBox(height: 8),
                Text(
                  'Veriler tam değil; ${
                      data.excludedCount} imalat hesaba alınmamıştır.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.statusInkOnCard(AppColors.warning),
                    fontSize: 10,
                    height: 1.25,
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

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.pct,
    required this.ink,
    required this.barColor,
  });

  final String label;
  final double? pct;
  final Color ink;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = pct;
    final fill = display != null
        ? (display / 100).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 58,
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: display != null ? fill : null,
                  minHeight: 4,
                  backgroundColor: barColor.withValues(alpha: 0.14),
                  color: barColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              display != null ? '%${display.toStringAsFixed(0)}' : '—',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: ink,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
