import 'package:flutter/material.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/services/period_site_report_builder.dart';

class PeriodReportBarSlice {
  const PeriodReportBarSlice({
    required this.label,
    required this.value,
    required this.color,
    this.unitHint = '',
  });

  final String label;
  final double value;
  final Color color;
  final String unitHint;
}

String _fmt(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}

/// Yatay çubuk — haftalık/aylık imalat ve verim özetleri.
class PeriodReportHorizontalBarChart extends StatelessWidget {
  const PeriodReportHorizontalBarChart({
    required this.title,
    required this.slices,
    super.key,
  });

  final String title;
  final List<PeriodReportBarSlice> slices;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) return const SizedBox.shrink();

    final maxV = slices.fold<double>(0, (m, s) => s.value > m ? s.value : m);
    final top = maxV <= 0 ? 1.0 : maxV;

    return SJCard.builder(
      builder: (context, cardTheme) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: cardTheme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < slices.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _BarRow(slice: slices[i], maxValue: top),
            ],
          ],
        );
      },
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.slice, required this.maxValue});

  final PeriodReportBarSlice slice;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = (slice.value / maxValue).clamp(0.0, 1.0);
    final unit = slice.unitHint.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                slice.label.trim(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              unit.isEmpty ? _fmt(slice.value) : '${_fmt(slice.value)} $unit',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: AppRadii.xs,
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: slice.color.withValues(alpha: 0.14),
            color: slice.color,
          ),
        ),
      ],
    );
  }
}

List<PeriodReportBarSlice> imalatPeriodMetrajSlices(
  List<PeriodImalatRow> rows, {
  int limit = 12,
}) {
  if (rows.isEmpty) return const [];
  final sorted = [...rows]..sort((a, b) => b.periodQty.compareTo(a.periodQty));
  final palette = [
    AppColors.success,
    AppColors.electricBlue,
    AppColors.info,
    AppColors.warning,
    AppColors.partial,
  ];
  return [
    for (var i = 0; i < sorted.length && i < limit; i++)
      PeriodReportBarSlice(
        label: sorted[i].name,
        value: sorted[i].periodQty,
        color: palette[i % palette.length],
        unitHint: sorted[i].unit.trim(),
      ),
  ];
}

List<PeriodReportBarSlice> verimPeriodEfficiencySlices(
  List<PeriodVerimRow> rows, {
  int limit = 12,
}) {
  final withEff = [
    for (final r in rows)
      if (r.unitEfficiency != null)
        (
          name: r.imalatName,
          pct: r.unitEfficiency! * 100,
        ),
  ]..sort((a, b) => b.pct.compareTo(a.pct));

  if (withEff.isEmpty) return const [];
  return [
    for (var i = 0; i < withEff.length && i < limit; i++)
      PeriodReportBarSlice(
        label: withEff[i].name,
        value: withEff[i].pct,
        color: AppColors.electricBlue,
        unitHint: '%',
      ),
  ];
}

List<PeriodReportBarSlice> verimPeriodAgCompareSlices(
  List<PeriodVerimRow> rows,
) {
  if (rows.isEmpty) return const [];
  var plan = 0.0;
  var actual = 0.0;
  for (final r in rows) {
    plan += r.plannedWorkerDays;
    actual += r.periodActualWorkerDays;
  }
  if (plan <= 0 && actual <= 0) return const [];
  return [
    PeriodReportBarSlice(
      label: 'Plan Adam-gün',
      value: plan,
      color: AppColors.electricBlue.withValues(alpha: 0.55),
      unitHint: 'AG',
    ),
    PeriodReportBarSlice(
      label: 'Dönem Adam-gün',
      value: actual,
      color: AppColors.warning,
      unitHint: 'AG',
    ),
  ];
}
