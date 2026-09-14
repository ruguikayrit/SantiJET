import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/providers/production_chart_options_provider.dart';
import 'period_production_chart_slices.dart';
import '../../../data/services/period_site_report_builder.dart';
import '../../../data/services/production_chart_options.dart';
import '../../../data/services/puantaj_report_builder.dart';
import '../../imalat/widgets/production_chart_panel.dart';
import '../../imalat/widgets/production_summary_charts.dart';

/// Haftalık / aylık rapor — İmalat / Verim sekmesindeki grafik paneli (dönem verisi).
class PeriodProductionChartPanel extends ConsumerWidget {
  const PeriodProductionChartPanel.imalat({
    required this.report,
    super.key,
  })  : _forVerim = false;

  const PeriodProductionChartPanel.verim({
    required this.report,
    super.key,
  })  : _forVerim = true;

  final PeriodSiteReportData report;
  final bool _forVerim;

  Future<void> _openSettings(BuildContext context, WidgetRef ref) async {
    final current = ref.read(productionChartOptionsProvider);
    final next = await showProductionChartSettingsSheet(
      context,
      initial: current,
      forVerim: _forVerim,
    );
    if (next == null) return;
    ref.read(productionChartOptionsProvider.notifier).save(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(productionChartOptionsProvider);
    final kind = _forVerim ? options.verimKind : options.imalatKind;
    final metricLabel = _forVerim
        ? options.verimMetric.label
        : options.imalatMetric.label;
    final slices = _forVerim
        ? PeriodProductionChartSlices.verim(report, options.verimMetric)
        : PeriodProductionChartSlices.imalat(report, options.imalatMetric);

    final unitHint = switch (_forVerim ? options.verimMetric : null) {
      VerimChartMetric.teamEfficiency ||
      VerimChartMetric.rowEfficiency =>
        '%',
      VerimChartMetric.laborPlanActual => 'adam-gün',
      null => switch (options.imalatMetric) {
          ImalatChartMetric.phaseShare => 'adet',
          ImalatChartMetric.teamProgress => '%',
          ImalatChartMetric.metrajPlanActual => 'metraj',
        },
    };

    final periodTag = report.period == PuantajReportPeriod.weekly
        ? 'Haftalık dönem'
        : 'Aylık dönem';

    return SJCard.builder(
      builder: (context, theme) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grafik',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$periodTag · $metricLabel · ${kind.label}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Grafik ayarları',
                  onPressed: () => _openSettings(context, ref),
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (slices.isEmpty || slices.every((s) => s.value <= 0))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'Grafik için yeterli dönem verisi yok.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              if (kind == ProductionChartKind.horizontalBar)
                ProductionSummaryHorizontalBarChart(
                  slices: slices,
                  unitHint: unitHint,
                )
              else
                SizedBox(
                  height: 200,
                  child: ProductionSummaryPieChart(slices: slices),
                ),
            ],
          ],
        );
      },
    );
  }
}
