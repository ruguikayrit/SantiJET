import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';

class StockCutSection extends StatelessWidget {
  const StockCutSection({
    super.key,
    required this.plans,
    this.stockLengthM = CuttingBendingBatch.defaultStockBarLengthM,
  });

  final List<StockCutPlan> plans;
  final double stockLengthM;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return Text(
        'Parça listesi boş veya kesim planı oluşturulamadı.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${stockLengthM.toStringAsFixed(0)} m tam boydan minimum fire ile eşleştirme',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        ...plans.map(
          (plan) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DiameterCutPlanCard(plan: plan, stockLengthM: stockLengthM),
          ),
        ),
      ],
    );
  }
}

class _DiameterCutPlanCard extends StatelessWidget {
  const _DiameterCutPlanCard({
    required this.plan,
    required this.stockLengthM,
  });

  final StockCutPlan plan;
  final double stockLengthM;

  @override
  Widget build(BuildContext context) {
    final diameterColor = AppColors.diameterColor(plan.diameter);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ø${plan.diameter}',
            style: AppTypography.titleMedium.copyWith(color: diameterColor),
          ),
          const SizedBox(height: 4),
          Text(
            '${plan.totalBars} çubuk · fire ${plan.totalWasteM.toStringAsFixed(2)} m '
            '(%${plan.wastePercent.toStringAsFixed(1)})',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          ...plan.bars.map(
            (bar) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _StockBarCutRow(
                bar: bar,
                stockLengthM: stockLengthM,
                diameterColor: diameterColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockBarCutRow extends StatelessWidget {
  const _StockBarCutRow({
    required this.bar,
    required this.stockLengthM,
    required this.diameterColor,
  });

  final StockBarCut bar;
  final double stockLengthM;
  final Color diameterColor;

  @override
  Widget build(BuildContext context) {
    final parts = bar.members
        .expand(
          (member) => List.filled(
            member.count,
            '${member.lengthM.toStringAsFixed(2)} m',
          ),
        )
        .join(' + ');
    final isZeroWaste = bar.wasteLengthM <= 0.001;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isZeroWaste
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.canvas,
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: isZeroWaste
              ? AppColors.success.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Çubuk ${bar.barIndex}',
            style: AppTypography.labelMedium.copyWith(color: diameterColor),
          ),
          const SizedBox(height: 4),
          Text(
            '$parts = ${bar.usedLengthM.toStringAsFixed(2)} m',
            style: AppTypography.bodyMedium,
          ),
          Text(
            'Fire: ${bar.wasteLengthM.toStringAsFixed(2)} m / '
            '${stockLengthM.toStringAsFixed(0)} m',
            style: AppTypography.bodySmall.copyWith(
              color: isZeroWaste ? AppColors.success : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
