import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';

class ProductionChartSlice {
  const ProductionChartSlice({
    required this.label,
    required this.value,
    required this.color,
    this.secondary,
  });

  final String label;
  final double value;
  final Color color;
  final double? secondary;
}

String productionChartFmt(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}

class ProductionSummaryPieChart extends StatelessWidget {
  const ProductionSummaryPieChart({required this.slices, super.key});

  final List<ProductionChartSlice> slices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return const SizedBox.shrink();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 32,
        sections: [
          for (final s in slices)
            PieChartSectionData(
              value: s.value,
              color: s.color,
              radius: 46,
              title: '${((s.value / total) * 100).round()}%',
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              badgeWidget: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 88),
                child: Text(
                  s.label.trim(),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    fontSize: 9,
                    height: 1.15,
                  ),
                ),
              ),
              badgePositionPercentageOffset: 1.35,
            ),
        ],
      ),
    );
  }
}

class ProductionSummaryHorizontalBarChart extends StatelessWidget {
  const ProductionSummaryHorizontalBarChart({
    required this.slices,
    required this.unitHint,
    super.key,
  });

  final List<ProductionChartSlice> slices;
  final String unitHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxV = slices.fold<double>(0, (m, s) => s.value > m ? s.value : m);
    final top = maxV <= 0 ? 1.0 : maxV;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: slices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final s = slices[i];
        final ratio = (s.value / top).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    s.label.trim(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    softWrap: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${productionChartFmt(s.value)} $unitHint',
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
                backgroundColor: s.color.withValues(alpha: 0.15),
                color: s.color,
              ),
            ),
          ],
        );
      },
    );
  }
}
