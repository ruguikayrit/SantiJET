import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';

/// Fire analizi sürerken tüm uygulamayı kilitler; tamamlanınca onay gösterip kaldırır.
class AnalysisRunningLockOverlay extends ConsumerWidget {
  const AnalysisRunningLockOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(optimumFireAnalysisProgressProvider);
    final isLocked = progress.isRunning || progress.isCompleted;

    if (!isLocked) {
      return const SizedBox.shrink();
    }

    final clampedPercent = progress.percent.clamp(0, 100);
    final progressValue = clampedPercent / 100;

    return Positioned.fill(
      child: PopScope(
        canPop: false,
        child: Material(
          color: AppColors.canvas.withValues(alpha: 0.94),
          child: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              onPanDown: (_) {},
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (progress.isCompleted) ...[
                          Container(
                            width: 88,
                            height: 88,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.45),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: AppColors.success,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Analiz tamamlandı',
                            style: AppTypography.headlineMedium.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (progress.stepLabel.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              progress.stepLabel,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            'Uygulama kullanımına devam edebilirsiniz.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          SizedBox(
                            width: 88,
                            height: 88,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progressValue,
                                  strokeWidth: 5,
                                  backgroundColor: AppColors.border,
                                  color: AppColors.success,
                                ),
                                Text(
                                  '$clampedPercent%',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Analiz devam ediyor',
                            style: AppTypography.headlineMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: AppRadii.md,
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      size: 20,
                                      color: AppColors.warning.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Fire analizi tamamlanana kadar uygulama '
                                        'kullanımı geçici olarak durdurulmuştur.',
                                        style: AppTypography.bodyMedium.copyWith(
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'İşlem sürerken sayfa değiştirmeyin, sekme '
                                  'kapatmayın ve uygulamayı zorlamayın. Analiz '
                                  'bittiğinde ekran otomatik olarak açılacaktır.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    height: 1.45,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          if (progress.stepLabel.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              progress.stepLabel,
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.electricBlueLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: AppRadii.full,
                            child: LinearProgressIndicator(
                              value: progressValue,
                              minHeight: 6,
                              backgroundColor: AppColors.border,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
