import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/production_list_row_colors.dart';
import '../../../core/widgets/production_triple_progress.dart';
import '../../../data/services/period_site_report_builder.dart';
import '../../../data/services/production_performance_chart_options.dart';
import '../../../data/services/puantaj_report_builder.dart';
import '../../../domain/entities/production.dart';
import '../../../domain/models/production_metrics.dart';
import '../../../domain/models/production_team_group.dart';
import '../../imalat/widgets/production_group_summary_strip.dart';
import '../../imalat/widgets/production_performance_bar_chart.dart';
import '../../verim/widgets/verim_production_detail_sheet.dart';
import 'period_production_chart_panel.dart';

String periodSiteReportFmtNum(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}

/// Dönem verim satırları — ekip adına göre (Verim sekmesi sırası).
class PeriodVerimTeamBlock {
  const PeriodVerimTeamBlock({
    required this.teamKey,
    required this.teamName,
    required this.rows,
    this.unitEfficiency,
    this.planLineCount = 0,
  });

  final String teamKey;
  final String teamName;
  final List<PeriodVerimRow> rows;
  final double? unitEfficiency;
  final int planLineCount;

  static List<PeriodVerimTeamBlock> fromReport(
    PeriodSiteReportData report,
    Map<String, Production> productionsById,
  ) {
    final byTeam = <String, List<PeriodVerimRow>>{};
    final names = <String, String>{};

    for (final r in report.verimRows) {
      final prod = productionsById[r.productionId];
      final teamKey = prod != null
          ? ProductionTeamGroup.teamOnlyKey(prod)
          : (r.teamName?.trim().isEmpty ?? true
              ? 'Diğer'
              : r.teamName!.trim());
      final teamName = prod != null
          ? ProductionTeamGroup.teamOnlyCardTitle(
              ProductionTeamGroup.normalizeTeamName(prod),
            )
          : (r.teamName?.trim().isEmpty ?? true
              ? 'Diğer'
              : r.teamName!.trim());
      names[teamKey] = teamName;
      byTeam.putIfAbsent(teamKey, () => []).add(r);
    }

    final blocks = <PeriodVerimTeamBlock>[];
    for (final entry in byTeam.entries) {
      final rows = entry.value
        ..sort((a, b) => a.imalatName.toLowerCase().compareTo(
              b.imalatName.toLowerCase(),
            ));
      var planAg = 0.0;
      var actualAg = 0.0;
      var planQty = 0.0;
      var actualQty = 0.0;
      for (final r in rows) {
        planAg += r.plannedWorkerDays;
        actualAg += r.periodActualWorkerDays;
        if (r.plannedQty != null && r.plannedQty! > 0) {
          planQty += r.plannedQty!;
        }
        actualQty += r.periodActualQty;
      }
      blocks.add(
        PeriodVerimTeamBlock(
          teamKey: entry.key,
          teamName: names[entry.key] ?? entry.key,
          rows: rows,
          planLineCount: rows.length,
          unitEfficiency: ProductionMetrics.computeUnitEfficiency(
            plannedQty: planQty,
            plannedWorkerDays: planAg,
            actualQty: actualQty,
            actualWorkerDays: actualAg,
          ),
        ),
      );
    }

    blocks.sort((a, b) {
      final ae = a.unitEfficiency;
      final be = b.unitEfficiency;
      if (ae != null && be != null && ae != be) {
        return be.compareTo(ae);
      }
      return a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase());
    });
    return blocks;
  }
}

/// İmalat bölümü — rapor önizleme ve PDF yakalama ile aynı ağaç.
class PeriodImalatReportVisual extends ConsumerWidget {
  const PeriodImalatReportVisual({
    required this.report,
    required this.productionsById,
    this.expandAllCharts = false,
    this.wrapGroupCards = false,
    super.key,
  });

  final PeriodSiteReportData report;
  final Map<String, Production> productionsById;
  final bool expandAllCharts;
  final bool wrapGroupCards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = report.imalatRows;
    if (rows.isEmpty) {
      return SJCard.builder(
        builder: (context, theme) => Text(
          'Bu dönemde imalat kaydı yok. İmalat sekmesinden günlük giriş yapın.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final daySet = report.days.toSet();
    final perfPeriod = report.period == PuantajReportPeriod.weekly
        ? ProductionPerformancePeriod.daily
        : ProductionPerformancePeriod.weekly;
    final groups = report.imalatGroupSummaries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeriodProductionChartPanel.imalat(report: report),
        const SizedBox(height: AppSpacing.md),
        if (groups.isNotEmpty) ...[
          Text(
            'Grup özeti (dönem)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ProductionGroupSummaryStrip(
            summaries: groups,
            selectedTeamKey: null,
            onTeamTap: (_) {},
            wrapForExport: wrapGroupCards,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          'İmalat detayı',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          PeriodImalatReportCard(
            row: rows[i],
            production: productionsById[rows[i].productionId],
            perfPeriod: perfPeriod,
            daySet: daySet,
            expandCharts: expandAllCharts,
          ),
        ],
      ],
    );
  }
}

/// Verim bölümü — ekip başlıkları altında imalat satırları (Verim sekmesi düzeni).
class PeriodVerimReportVisual extends ConsumerWidget {
  const PeriodVerimReportVisual({
    required this.report,
    required this.productionsById,
    this.expandAllCharts = false,
    this.wrapGroupCards = false,
    super.key,
  });

  final PeriodSiteReportData report;
  final Map<String, Production> productionsById;
  final bool expandAllCharts;
  final bool wrapGroupCards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = report.verimRows;
    if (rows.isEmpty) {
      return SJCard.builder(
        builder: (context, theme) => Text(
          'Verim için İmalat sekmesinde planlanan değerler ve dönemde günlük kayıt gerekir.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final daySet = report.days.toSet();
    final groups = report.imalatGroupSummaries;
    final teams = PeriodVerimTeamBlock.fromReport(report, productionsById);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeriodProductionChartPanel.verim(report: report),
        const SizedBox(height: AppSpacing.md),
        if (groups.isNotEmpty) ...[
          Text(
            'Grup özeti (dönem)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ProductionGroupSummaryStrip(
            summaries: groups,
            selectedTeamKey: null,
            onTeamTap: (_) {},
            verimTitleOnly: true,
            wrapForExport: wrapGroupCards,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          'Verim detayı',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var t = 0; t < teams.length; t++) ...[
          if (t > 0) const SizedBox(height: AppSpacing.md),
          PeriodVerimTeamHeaderCard(block: teams[t]),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < teams[t].rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            PeriodVerimReportCard(
              row: teams[t].rows[i],
              production: productionsById[teams[t].rows[i].productionId],
              daySet: daySet,
              colorIndex: i,
              expandCharts: expandAllCharts,
            ),
          ],
        ],
      ],
    );
  }
}

class PeriodImalatReportCard extends StatelessWidget {
  const PeriodImalatReportCard({
    required this.row,
    required this.production,
    required this.perfPeriod,
    required this.daySet,
    this.expandCharts = true,
    super.key,
  });

  final PeriodImalatRow row;
  final Production? production;
  final ProductionPerformancePeriod perfPeriod;
  final Set<String> daySet;
  final bool expandCharts;

  @override
  Widget build(BuildContext context) {
    final pct = row.progressPct.clamp(0, 999).toDouble();
    final barColor = completionColorForPct(pct);
    final meta = [
      if (row.location.trim().isNotEmpty) row.location.trim(),
      if (row.teamName.trim().isNotEmpty) row.teamName.trim(),
      if (row.unit.trim().isNotEmpty) row.unit.trim(),
    ].join(' · ');

    return SJCard.builder(
      builder: (context, theme) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                PeriodReportPctBadge(pct: pct, color: barColor),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadii.xs,
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: barColor.withValues(alpha: 0.14),
                color: barColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: PeriodReportMetricTile(
                    label: 'Dönem',
                    value: '${periodSiteReportFmtNum(row.periodQty)} ${row.unit}'
                        .trim(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: PeriodReportMetricTile(
                    label: 'Adam-gün',
                    value: periodSiteReportFmtNum(row.periodLaborDays),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: PeriodReportMetricTile(
                    label: 'Kümülatif',
                    value:
                        '${periodSiteReportFmtNum(row.totalQty)} ${row.unit}'
                            .trim(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: PeriodReportMetricTile(
                    label: 'Plan',
                    value:
                        '${periodSiteReportFmtNum(row.plannedQty)} ${row.unit}'
                            .trim(),
                  ),
                ),
              ],
            ),
            if (production != null && expandCharts) ...[
              const SizedBox(height: AppSpacing.md),
              ProductionPerformanceBarChart(
                production: production!,
                fixedPeriod: perfPeriod,
                onlyDates: daySet,
                hidePeriodChips: true,
                height: 200,
              ),
              const SizedBox(height: AppSpacing.md),
              VerimProductionCharts(
                production: production!,
                inline: true,
                chartHeight: 130,
                onlyDates: daySet,
                stackBothChartModes: true,
              ),
            ],
          ],
        );
      },
    );
  }
}

class PeriodVerimTeamHeaderCard extends StatelessWidget {
  const PeriodVerimTeamHeaderCard({required this.block, super.key});

  final PeriodVerimTeamBlock block;

  @override
  Widget build(BuildContext context) {
    final efficiency = block.unitEfficiency;
    return SJCard.builder(
      builder: (context, theme) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              block.teamName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${block.planLineCount} imalat',
              style: theme.textTheme.labelSmall,
            ),
            if (efficiency != null) ...[
              const SizedBox(height: AppSpacing.sm),
              UnitEfficiencyBadge(efficiency: efficiency, compact: true),
              const SizedBox(height: 6),
              UnitEfficiencyBar(efficiency: efficiency, height: 4),
            ],
          ],
        );
      },
    );
  }
}

class PeriodVerimReportCard extends StatelessWidget {
  const PeriodVerimReportCard({
    required this.row,
    required this.production,
    required this.daySet,
    required this.colorIndex,
    this.expandCharts = true,
    super.key,
  });

  final PeriodVerimRow row;
  final Production? production;
  final Set<String> daySet;
  final int colorIndex;
  final bool expandCharts;

  @override
  Widget build(BuildContext context) {
    final efficiency = row.unitEfficiency;
    final hasEntries = production?.dailyEntries.isNotEmpty ?? false;
    final cardBg = ProductionListRowColors.at(colorIndex);
    final team = (row.teamName ?? '').trim().isEmpty
        ? (production != null
            ? ProductionTeamGroup.normalizeTeamName(production!)
            : 'Diğer')
        : row.teamName!.trim();

    return SJCard.builder(
      backgroundColor: cardBg,
      builder: (context, theme) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.imalatName.trim().isEmpty
                            ? 'İmalat'
                            : row.imalatName.trim(),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        team,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (efficiency != null)
                  Text(
                    '%${(efficiency * 100).toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusInk(
                        efficiencyColorForRatio(efficiency),
                        surface: cardBg,
                      ),
                    ),
                  )
                else
                  Text(
                    '—',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (production != null && expandCharts && hasEntries) ...[
              const SizedBox(height: AppSpacing.md),
              VerimProductionCharts(
                production: production!,
                inline: true,
                chartHeight: 130,
                onlyDates: daySet,
                stackBothChartModes: true,
              ),
            ],
          ],
        );
      },
    );
  }
}

class PeriodReportPctBadge extends StatelessWidget {
  const PeriodReportPctBadge({required this.pct, required this.color, super.key});

  final double pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadii.sm,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '%${pct.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.statusInkOnCard(color),
        ),
      ),
    );
  }
}

class PeriodReportMetricTile extends StatelessWidget {
  const PeriodReportMetricTile({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.electricBlue.withValues(alpha: 0.06),
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
