import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';

/// Fire analizi sürerken tüm uygulamayı kilitler; tamamlanınca onay gösterip kaldırır.
class AnalysisRunningLockOverlay extends ConsumerWidget {
  const AnalysisRunningLockOverlay({super.key});

  static const _progressRingSize = 220.0;
  static const _progressStrokeWidth = 12.0;
  static const _completedRingSize = 120.0;

  static TextStyle _plainText(TextStyle base, {Color? color}) {
    return base.copyWith(
      color: color,
      decoration: TextDecoration.none,
      decorationColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(optimumFireAnalysisProgressProvider);
    final isLocked = progress.isRunning || progress.isCompleted;

    if (!isLocked) {
      return const SizedBox.shrink();
    }

    final clampedPercent = progress.percent.clamp(0, 100);
    final progressValue = clampedPercent / 100;
    final isCompleted = progress.isCompleted;

    return Positioned.fill(
      child: PopScope(
        canPop: false,
        child: ColoredBox(
          color: AppColors.canvas,
          child: SelectionContainer.disabled(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              onPanDown: (_) {},
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: isCompleted
                            ? _CompletedPanel(
                                key: const ValueKey('completed'),
                              )
                            : _RunningPanel(
                                key: const ValueKey('running'),
                                percent: clampedPercent,
                                progressValue: progressValue,
                                stepLabel: progress.stepLabel,
                              ),
                      ),
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

class _RunningPanel extends StatelessWidget {
  const _RunningPanel({
    super.key,
    required this.percent,
    required this.progressValue,
    required this.stepLabel,
  });

  final int percent;
  final double progressValue;
  final String stepLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProgressRing(
          size: AnalysisRunningLockOverlay._progressRingSize,
          strokeWidth: AnalysisRunningLockOverlay._progressStrokeWidth,
          value: progressValue,
          center: Text(
            '$percent%',
            style: AnalysisRunningLockOverlay._plainText(
              AppTypography.kpiValue.copyWith(
                fontSize: 44,
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'FİRE ANALİZİ',
          style: AnalysisRunningLockOverlay._plainText(
            AppTypography.labelMedium.copyWith(
              color: AppColors.electricBlueLight,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Analiz devam ediyor',
          style: AnalysisRunningLockOverlay._plainText(
            AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Lütfen bekleyin',
          style: AnalysisRunningLockOverlay._plainText(
            AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: AppRadii.full,
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 5,
            backgroundColor: AppColors.border,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 24),
        _InfoCard(
          icon: Icons.lock_outline_rounded,
          iconColor: AppColors.warning,
          borderColor: AppColors.warning.withValues(alpha: 0.28),
          title:
              'Fire analizi tamamlanana kadar uygulama kullanımı geçici olarak durdurulmuştur.',
          body: 'Analiz bittiğinde ekran otomatik olarak açılacaktır.',
        ),
        if (stepLabel.isNotEmpty) ...[
          const SizedBox(height: 20),
          _StepChip(label: stepLabel),
        ],
      ],
    );
  }
}

class _CompletedPanel extends StatelessWidget {
  const _CompletedPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AnalysisRunningLockOverlay._completedRingSize,
          height: AnalysisRunningLockOverlay._completedRingSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.12),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.5),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.18),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 56,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Sonuçlar hazır !',
          style: AnalysisRunningLockOverlay._plainText(
            AppTypography.headlineMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Uygulama kullanımına devam edebilirsiniz.',
          style: AnalysisRunningLockOverlay._plainText(
            AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.size,
    required this.strokeWidth,
    required this.value,
    required this.center,
  });

  final double size;
  final double strokeWidth;
  final double value;
  final Widget center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              backgroundColor: AppColors.surfaceElevated,
              color: AppColors.success,
              strokeCap: StrokeCap.round,
            ),
          ),
          center,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.65),
        borderRadius: AppRadii.md,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AnalysisRunningLockOverlay._plainText(
                    AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: AnalysisRunningLockOverlay._plainText(
                    AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.electricBlue.withValues(alpha: 0.1),
        borderRadius: AppRadii.full,
        border: Border.all(
          color: AppColors.electricBlueLight.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: AnalysisRunningLockOverlay._plainText(
          AppTypography.labelMedium.copyWith(
            color: AppColors.electricBlueLight,
          ),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
