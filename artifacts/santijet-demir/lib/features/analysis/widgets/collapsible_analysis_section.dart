import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';

/// Hesap ve Analiz sayfasında katlanabilir bölüm kartı.
/// Açık/kapalı durum [analysisSectionExpandedProvider] ile saklanır.
class CollapsibleAnalysisSection extends ConsumerWidget {
  const CollapsibleAnalysisSection({
    super.key,
    required this.sectionId,
    required this.title,
    this.subtitle,
    required this.child,
    this.headerAccentColor,
  });

  static const sectionGap = AppSpacing.sm;

  final String sectionId;
  final String title;
  final String? subtitle;
  final Widget child;
  final Color? headerAccentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(analysisSectionExpandedProvider(sectionId));
    final accent = headerAccentColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: sectionGap),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: AppRadii.md,
          border: Border.all(
            color: accent != null
                ? accent.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (accent != null)
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.9),
                      accent.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            Material(
              color: accent?.withValues(alpha: 0.08) ?? Colors.transparent,
              child: InkWell(
                onTap: () {
                  ref
                      .read(analysisSectionExpandedProvider(sectionId).notifier)
                      .state = !expanded;
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (accent != null) ...[
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            Icons.calculate_outlined,
                            size: 18,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTypography.titleMedium.copyWith(
                                color: accent,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                subtitle!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        size: 22,
                        color: accent ?? AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (expanded) ...[
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: child,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
