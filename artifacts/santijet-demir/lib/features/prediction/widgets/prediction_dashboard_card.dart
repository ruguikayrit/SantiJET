import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/haptics/app_haptics.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/prediction_models.dart';
import 'package:santijet_demir/features/prediction/providers/prediction_provider.dart';

Color predictionRiskColor(PredictionRiskLevel risk) {
  return switch (risk) {
    PredictionRiskLevel.green => AppColors.success,
    PredictionRiskLevel.yellow => AppColors.warning,
    PredictionRiskLevel.orange => const Color(0xFFEA580C),
    PredictionRiskLevel.red => AppColors.critical,
    PredictionRiskLevel.unknown => AppColors.textMuted,
  };
}

String predictionRiskLabel(PredictionRiskLevel risk) {
  return switch (risk) {
    PredictionRiskLevel.green => 'Stok Güvenli',
    PredictionRiskLevel.yellow => 'İzle',
    PredictionRiskLevel.orange => 'Yakında Sipariş',
    PredictionRiskLevel.red => 'Kritik',
    PredictionRiskLevel.unknown => 'Veri Eksik',
  };
}

class PredictionDashboardCard extends ConsumerWidget {
  const PredictionDashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(predictionSnapshotProvider);
    if (snapshot == null) return const SizedBox.shrink();

    final risk = snapshot.canPredict
        ? snapshot.overallRisk
        : PredictionRiskLevel.unknown;
    final color = predictionRiskColor(risk);
    final dateFmt = DateFormat('d MMM', 'tr_TR');

    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: AppRadii.md,
      child: InkWell(
        borderRadius: AppRadii.md,
        onTap: () {
          AppHaptics.light();
          context.push(AppRoutes.prediction);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Demir Tahmin Motoru',
                      style: AppTypography.titleLarge,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: AppRadii.full,
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      predictionRiskLabel(risk),
                      style: AppTypography.labelMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!snapshot.canPredict) ...[
                Text(
                  'Tahmin için eksik veri var. Eksikleri tamamlayın.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final gap in snapshot.dataGaps.where(
                      (g) => g.kind != PredictionDataGapKind.workforce,
                    ))
                      ActionChip(
                        label: Text(gap.actionLabel),
                        onPressed: () => context.push(gap.route),
                      ),
                  ],
                ),
              ] else ...[
                _MetricRow(
                  label: 'Günlük tüketim',
                  value: snapshot.actualDailyConsumption != null
                      ? '${AppFormat.tonnage(snapshot.actualDailyConsumption!)} t/gün'
                      : '—',
                ),
                _MetricRow(
                  label: 'Tahmini tükenme',
                  value: snapshot.predictedDepletionDate != null
                      ? dateFmt.format(snapshot.predictedDepletionDate!)
                      : '—',
                ),
                _MetricRow(
                  label: 'Kritik çaplar',
                  value: snapshot.criticalDiameters.isEmpty
                      ? 'Yok'
                      : snapshot.criticalDiameters
                          .map((d) => 'Ø${d.diameter}')
                          .join(', '),
                ),
                _MetricRow(
                  label: 'Gerekli sipariş',
                  value: snapshot.purchase != null
                      ? '${AppFormat.tonnage(snapshot.purchase!.totalRequired)} t'
                      : '—',
                ),
                if (snapshot.narratives.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    snapshot.narratives.first,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Detay →',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.electricBlueLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodySmall)),
          Text(value, style: AppTypography.titleMedium),
        ],
      ),
    );
  }
}
