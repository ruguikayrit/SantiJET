import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_date.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/beton_progress.dart';
import '../../domain/entities/quality_sample.dart';
import '../projects/widgets/project_switcher.dart';

/// Ana sayfa — döküm, keşif ilerleme, sipariş fark özetleri.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final progress = ref.watch(projectProgressProvider);
    final todayPours = ref.watch(todayPoursProvider);
    final orders = ref.watch(activeOrdersProvider);
    final variance = ref.watch(activeVarianceProvider);
    final today = AppDate.format(AppDate.today());
    final todayOrdered = orders
        .where((o) => o.plannedDate == today)
        .fold<double>(0, (s, o) => s + o.plannedM3);
    final todayPoured =
        todayPours.fold<double>(0, (s, p) => s + p.volumeM3);

    final qualitySamples = ref.watch(activeQualityProvider);

    if (project == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SantijetHeader(showWordmark: true, avatarInitial: 'SJ'),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: ProjectSwitcher(),
              ),
              Expanded(
                child: SJEmptyState(
                  title: 'Önce proje ekleyin',
                  message: 'Beton döküm kaydı için en az bir projeniz olmalı.',
                  icon: Icons.apartment_outlined,
                  actionLabel: 'Projelere Git',
                  onAction: () => context.go(AppRoutes.projeler),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SantijetHeader(showWordmark: true, avatarInitial: 'SJ'),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: ProjectSwitcher(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SummarySection(
                    title: 'Bugünkü Döküm',
                    icon: Icons.local_shipping_outlined,
                    onTap: () => context.go(AppRoutes.dokum),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            label: 'Dökülen',
                            value: BetonProgress.fmtM3(todayPoured),
                            unit: 'm³',
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _MiniStat(
                            label: 'Planlı sipariş',
                            value: BetonProgress.fmtM3(todayOrdered),
                            unit: 'm³',
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _MiniStat(
                            label: 'Fark',
                            value: BetonProgress.fmtM3(
                              todayPoured - todayOrdered,
                            ),
                            unit: 'm³',
                            color: (todayPoured - todayOrdered).abs() < 0.01
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SummarySection(
                    title: 'Keşif İlerlemesi',
                    icon: Icons.pie_chart_outline,
                    onTap: () => context.go(AppRoutes.kesif),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                label: 'Keşif',
                                value: BetonProgress.fmtM3(progress.planned),
                                unit: 'm³',
                                color: AppColors.electricBlue,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: _MiniStat(
                                label: 'Dökülen',
                                value: BetonProgress.fmtM3(progress.poured),
                                unit: 'm³',
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: _MiniStat(
                                label: 'Kalan',
                                value: BetonProgress.fmtM3(progress.remaining),
                                unit: 'm³',
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _ProgressBar(pct: progress.progressPct),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SummarySection(
                    title: 'Sipariş · Gerçekleşen',
                    icon: Icons.calendar_month_outlined,
                    onTap: () => context.go(AppRoutes.program),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                label: 'Planlı sipariş',
                                value: BetonProgress.fmtM3(progress.ordered),
                                unit: 'm³',
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: _MiniStat(
                                label: 'Gerçekleşen',
                                value: BetonProgress.fmtM3(progress.poured),
                                unit: 'm³',
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: _MiniStat(
                                label: 'Sipariş farkı',
                                value: BetonProgress.fmtM3(progress.orderGap),
                                unit: 'm³',
                                color: progress.orderGap.abs() < 0.01
                                    ? AppColors.success
                                    : progress.orderGap > 0
                                        ? AppColors.warning
                                        : AppColors.critical,
                              ),
                            ),
                          ],
                        ),
                        if (variance.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${variance.length} metraj fark açıklaması kayıtlı',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SummarySection(
                    title: 'Beton Numune',
                    icon: Icons.science_outlined,
                    onTap: () => context.push(AppRoutes.kalite),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Laboratuvar basınç dayanım raporu özeti',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.cardTextMuted,
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        for (final group in ConcreteElementGroup.values) ...[
                          if (group != ConcreteElementGroup.values.first)
                            const SizedBox(height: 6),
                          _ElementQualityRow(
                            group: group,
                            samples: qualitySamples
                                .where((s) => s.elementGroup == group)
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.pct});

  final double pct;

  @override
  Widget build(BuildContext context) {
    final color = pct >= 100
        ? AppColors.success
        : pct >= 50
            ? AppColors.warning
            : AppColors.critical;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'İlerleme',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            Text(
              '%${pct.clamp(0, 999).toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
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
  }
}

class _ElementQualityRow extends StatelessWidget {
  const _ElementQualityRow({
    required this.group,
    required this.samples,
  });

  final ConcreteElementGroup group;
  final List<QualitySample> samples;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final withResult =
        samples.where((s) => s.strengthMpa != null).toList(growable: false);
    final avg = withResult.isEmpty
        ? null
        : withResult.fold<double>(0, (s, e) => s + e.strengthMpa!) /
            withResult.length;
    final passCount = samples.where((s) => s.isCompliant == true).length;
    final failCount = samples.where((s) => s.isCompliant == false).length;
    final pending = samples.where((s) => s.isPending).length;

    final Color accent;
    final String resultLabel;
    if (samples.isEmpty) {
      accent = AppColors.cardTextMuted;
      resultLabel = 'Kayıt yok';
    } else if (failCount > 0) {
      accent = AppColors.critical;
      resultLabel = '$failCount uygunsuz';
    } else if (passCount > 0) {
      accent = AppColors.success;
      resultLabel = '$passCount uygun';
    } else if (pending > 0) {
      accent = AppColors.partial;
      resultLabel = '$pending bekliyor';
    } else {
      accent = AppColors.info;
      resultLabel = '${samples.length} kayıt';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: AppRadii.sm,
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              group.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.cardTextPrimary,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              samples.isEmpty ? '—' : '${samples.length} rapor',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.cardTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              avg == null ? '— MPa' : 'Ort. ${avg.toStringAsFixed(1)} MPa',
              style: theme.textTheme.labelMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              resultLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.title,
    required this.icon,
    required this.child,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.cardTextPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              child,
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
    this.unit,
  });

  final String label;
  final String value;
  final Color color;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadii.sm,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.cardTextMuted,
              height: 1.15,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(
                  unit!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    height: 1.15,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
