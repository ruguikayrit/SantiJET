import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';

class SupplierPerformanceScreen extends ConsumerWidget {
  const SupplierPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliers = ref.watch(supplierPerformanceProvider);
    final sorted = [...suppliers]..sort((a, b) => b.performancePercent.compareTo(a.performancePercent));

    final totalOrdered = suppliers.fold(0.0, (s, v) => s + v.totalOrdered);
    final totalDelivered = suppliers.fold(0.0, (s, v) => s + v.totalDelivered);
    final overallPerf = totalOrdered > 0 ? totalDelivered / totalOrdered * 100 : 0;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Tedarikçi Performansı')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _OverallMetric(label: 'Sipariş', value: '${totalOrdered.toStringAsFixed(0)}t'),
                _OverallMetric(label: 'Teslim', value: '${totalDelivered.toStringAsFixed(0)}t'),
                _OverallMetric(
                  label: 'Performans',
                  value: '%${overallPerf.toStringAsFixed(1)}',
                  color: AppColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...sorted.map((s) => _SupplierScoreCard(supplier: s)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BestWorstCard(
                  title: 'En İyi',
                  name: sorted.first.name,
                  value: '%${sorted.first.performancePercent.toStringAsFixed(1)}',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BestWorstCard(
                  title: 'En Düşük',
                  name: sorted.last.name,
                  value: '%${sorted.last.performancePercent.toStringAsFixed(1)}',
                  color: AppColors.critical,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverallMetric extends StatelessWidget {
  const _OverallMetric({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTypography.labelMedium),
          Text(
            value,
            style: AppTypography.kpiValue.copyWith(fontSize: 20, color: color),
          ),
        ],
      ),
    );
  }
}

class _SupplierScoreCard extends StatelessWidget {
  const _SupplierScoreCard({required this.supplier});

  final SupplierPerformance supplier;

  Color get _perfColor {
    if (supplier.performancePercent >= 98) return AppColors.success;
    if (supplier.performancePercent >= 90) return AppColors.warning;
    return AppColors.critical;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(supplier.name, style: AppTypography.titleLarge),
              Row(
                children: [
                  Text(
                    '%${supplier.performancePercent.toStringAsFixed(1)}',
                    style: AppTypography.kpiValue.copyWith(fontSize: 22, color: _perfColor),
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(5, (i) {
                    return Icon(
                      i < supplier.rating.floor() ? Icons.star : Icons.star_border,
                      size: 14,
                      color: AppColors.warning,
                    );
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: AppRadii.full,
            child: LinearProgressIndicator(
              value: supplier.performancePercent / 100,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: _perfColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Metric(label: 'Sipariş', value: '${supplier.totalOrdered.toStringAsFixed(0)}t'),
              _Metric(label: 'Teslim', value: '${supplier.totalDelivered.toStringAsFixed(0)}t'),
              _Metric(label: 'Eksik', value: '${supplier.missing.toStringAsFixed(0)}t'),
              _Metric(label: 'Fark', value: '${supplier.difference.toStringAsFixed(0)}t'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelMedium),
          Text(value, style: AppTypography.titleMedium),
        ],
      ),
    );
  }
}

class _BestWorstCard extends StatelessWidget {
  const _BestWorstCard({
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
          Text(value, style: AppTypography.kpiValue.copyWith(fontSize: 20, color: color)),
        ],
      ),
    );
  }
}
