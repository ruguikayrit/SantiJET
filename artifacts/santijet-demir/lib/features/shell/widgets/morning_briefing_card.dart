import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/prediction_models.dart';
import 'package:santijet_demir/features/auth/providers/membership_permission_provider.dart';
import 'package:santijet_demir/features/prediction/widgets/prediction_dashboard_card.dart';
import 'package:santijet_demir/features/shell/morning_briefing_provider.dart';

/// Ana sayfa — Hoş geldin yerine günlük kural tabanlı brifing.
class MorningBriefingCard extends ConsumerWidget {
  const MorningBriefingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefing = ref.watch(morningBriefingProvider);
    final canPrediction = ref.watch(canAccessPredictionProvider);
    final tone = predictionRiskColor(briefing.tone);
    final dateLabel =
        DateFormat('d MMMM yyyy · EEEE', 'tr_TR').format(briefing.forDate);
    final detailRoute =
        canPrediction ? AppRoutes.prediction : AppRoutes.subscription;
    final detailLabel = canPrediction
        ? 'Detay → Demir Tahmin Motoru'
        : 'Detay → Abonelik paketleri';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Material(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.md,
        child: InkWell(
          onTap: () => context.push(detailRoute),
          borderRadius: AppRadii.md,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: AppColors.cardElevation,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tone,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        briefing.eyebrow,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.cardTextMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Text(
                      dateLabel,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.cardTextMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  briefing.greetingLine,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.cardTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < briefing.bullets.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  _BriefingBullet(text: briefing.bullets[i]),
                ],
                if (briefing.tone != PredictionRiskLevel.unknown ||
                    !canPrediction) ...[
                  const SizedBox(height: 10),
                  Text(
                    detailLabel,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.electricBlueLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BriefingBullet extends StatelessWidget {
  const _BriefingBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.cardTextMuted,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.cardTextSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
