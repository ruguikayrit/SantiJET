import '../../../core/theme/app_colors.dart';
import '../../../data/services/period_site_report_builder.dart';
import '../../../data/services/production_chart_options.dart';
import '../../imalat/widgets/production_summary_charts.dart';

abstract final class PeriodProductionChartSlices {
  static List<ProductionChartSlice> imalat(
    PeriodSiteReportData report,
    ImalatChartMetric metric,
  ) {
    final rows = report.imalatRows;
    if (rows.isEmpty) return const [];

    switch (metric) {
      case ImalatChartMetric.phaseShare:
        var devam = 0;
        var tamam = 0;
        for (final r in rows) {
          if (r.progressPct >= 100) {
            tamam++;
          } else {
            devam++;
          }
        }
        return [
          if (devam > 0)
            ProductionChartSlice(
              label: 'Devam',
              value: devam.toDouble(),
              color: AppColors.info,
            ),
          if (tamam > 0)
            ProductionChartSlice(
              label: 'Tamam',
              value: tamam.toDouble(),
              color: AppColors.success,
            ),
        ];
      case ImalatChartMetric.teamProgress:
        final byTeam = <String, List<double>>{};
        for (final r in rows) {
          final t = r.teamName.trim().isEmpty ? 'Diğer' : r.teamName.trim();
          byTeam.putIfAbsent(t, () => []).add(r.progressPct);
        }
        final teams = byTeam.keys.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        final palette = [
          AppColors.electricBlue,
          AppColors.info,
          AppColors.success,
          AppColors.warning,
          AppColors.partial,
          AppColors.critical,
        ];
        return [
          for (var i = 0; i < teams.length; i++)
            ProductionChartSlice(
              label: teams[i],
              value: byTeam[teams[i]]!.reduce((a, b) => a + b) /
                  byTeam[teams[i]]!.length,
              color: palette[i % palette.length],
            ),
        ];
      case ImalatChartMetric.metrajPlanActual:
        var planned = 0.0;
        var actual = 0.0;
        for (final r in rows) {
          actual += r.periodQty;
          if (r.plannedQty > 0 && r.totalQty > 0) {
            planned += r.plannedQty * (r.periodQty / r.totalQty);
          } else if (r.plannedQty > 0) {
            planned += r.plannedQty / report.days.length;
          }
        }
        return [
          ProductionChartSlice(
            label: 'Plan',
            value: planned,
            color: AppColors.electricBlue.withValues(alpha: 0.55),
          ),
          ProductionChartSlice(
            label: 'Gerçek',
            value: actual,
            color: AppColors.success,
          ),
        ];
    }
  }

  static List<ProductionChartSlice> verim(
    PeriodSiteReportData report,
    VerimChartMetric metric,
  ) {
    final rows = report.verimRows;
    if (rows.isEmpty) return const [];

    final palette = [
      AppColors.electricBlue,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      AppColors.partial,
      AppColors.critical,
    ];

    switch (metric) {
      case VerimChartMetric.teamEfficiency:
        final byTeam = <String, List<double>>{};
        for (final r in rows) {
          if (r.unitEfficiency == null) continue;
          final t = (r.teamName ?? '').trim().isEmpty ? 'Diğer' : r.teamName!.trim();
          byTeam.putIfAbsent(t, () => []).add(r.unitEfficiency! * 100);
        }
        final teams = byTeam.keys.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        return [
          for (var i = 0; i < teams.length; i++)
            ProductionChartSlice(
              label: teams[i],
              value: byTeam[teams[i]]!.reduce((a, b) => a + b) /
                  byTeam[teams[i]]!.length,
              color: palette[i % palette.length],
            ),
        ];
      case VerimChartMetric.laborPlanActual:
        var planned = 0.0;
        var actual = 0.0;
        for (final r in rows) {
          planned += r.plannedWorkerDays;
          actual += r.periodActualWorkerDays;
        }
        return [
          ProductionChartSlice(
            label: 'Plan Adam-gün',
            value: planned,
            color: AppColors.electricBlue.withValues(alpha: 0.55),
          ),
          ProductionChartSlice(
            label: 'Gerçek Adam-gün',
            value: actual,
            color: AppColors.success,
          ),
        ];
      case VerimChartMetric.rowEfficiency:
        final sorted = [
          for (final r in rows)
            if (r.unitEfficiency != null)
              (name: r.imalatName, eff: r.unitEfficiency!),
        ]..sort((a, b) => b.eff.compareTo(a.eff));
        final top = sorted.take(8).toList();
        return [
          for (var i = 0; i < top.length; i++)
            ProductionChartSlice(
              label: top[i].name,
              value: top[i].eff * 100,
              color: palette[i % palette.length],
            ),
        ];
    }
  }
}
