import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/providers/production_performance_chart_options_provider.dart';
import '../../../data/services/production_performance_chart_options.dart';
import '../../../domain/entities/production.dart';
import 'production_performance_bar_chart.dart';
import 'production_performance_line_chart.dart';

/// İmalat kartı performans grafiği — çizgi veya çubuk (kullanıcı seçimi).
class ProductionPerformanceChart extends ConsumerWidget {
  const ProductionPerformanceChart({
    required this.production,
    super.key,
    this.height = 220,
  });

  final Production production;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(productionPerformanceChartOptionsProvider);
    final style = options.style;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final s in ProductionPerformanceChartStyle.values)
              FilterChip(
                showCheckmark: false,
                label: Text(s.label),
                selected: style == s,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => ref
                    .read(productionPerformanceChartOptionsProvider.notifier)
                    .save(options.copyWith(style: s)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (style == ProductionPerformanceChartStyle.bar)
          ProductionPerformanceBarChart(
            production: production,
            height: height,
          )
        else
          ProductionPerformanceLineChart(
            production: production,
            height: height,
          ),
      ],
    );
  }
}
