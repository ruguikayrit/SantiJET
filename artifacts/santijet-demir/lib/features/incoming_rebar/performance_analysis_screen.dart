import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/health_ring.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/performance_analysis_provider.dart';

class PerformanceAnalysisScreen extends ConsumerWidget {
  const PerformanceAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(analysisSummaryProvider);
    final supplierBars = ref.watch(supplierPerfBarsProvider);
    final maxVariance = summary.varianceBars
        .map((v) => v.value)
        .reduce((a, b) => a > b ? a : b);
    final maxConsumed = summary.consumedDiameters
        .map((c) => c.tonnage)
        .reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Performans Analizi')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('En Yüksek Sapmalar', style: AppTypography.headlineMedium),
          const SizedBox(height: 12),
          ...summary.varianceBars.map((item) {
            final color = switch (item.status) {
              'critical' => AppColors.critical,
              'warning' => AppColors.warning,
              _ => AppColors.success,
            };
            return HorizontalBarChart(
              label: item.label,
              value: item.value,
              maxValue: maxVariance,
              color: color,
            );
          }),
          const SizedBox(height: 20),
          Text('Tedarikçi Performansı', style: AppTypography.headlineMedium),
          const SizedBox(height: 12),
          ...supplierBars.map((s) {
            final color = s.$2 >= 98
                ? AppColors.success
                : s.$2 >= 90
                    ? AppColors.warning
                    : AppColors.critical;
            return HorizontalBarChart(
              label: s.$1,
              value: s.$2,
              maxValue: 100,
              color: color,
              suffix: '%',
            );
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'En İyi Tedarikçi',
                  name: supplierBars.first.$1,
                  value: '%${supplierBars.first.$2.toStringAsFixed(1)}',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'En Düşük',
                  name: supplierBars.last.$1,
                  value: '%${supplierBars.last.$2.toStringAsFixed(1)}',
                  color: AppColors.critical,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('En Çok Tüketilen Çaplar', style: AppTypography.headlineMedium),
          const SizedBox(height: 12),
          ...summary.consumedDiameters.map((item) {
            final color = AppColors.diameterColor(item.diameter);
            return HorizontalBarChart(
              label: 'Ø${item.diameter}${item.isTop ? ' ★' : ''}',
              value: item.tonnage,
              maxValue: maxConsumed,
              color: color,
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.name,
    required this.value,
    required this.color,
  });

  final String title;
  final String name;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadii.md,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.labelMedium),
          Text(name, style: AppTypography.titleMedium),
          Text(
            value,
            style: AppTypography.kpiValue.copyWith(fontSize: 20, color: color),
          ),
        ],
      ),
    );
  }
}
