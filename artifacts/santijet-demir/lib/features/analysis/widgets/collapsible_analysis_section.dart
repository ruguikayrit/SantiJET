import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';

/// Kesme-Bükme sayfasında katlanabilir bölüm kartı.
/// Açık/kapalı durum [analysisSectionExpandedProvider] ile saklanır.
class CollapsibleAnalysisSection extends ConsumerWidget {
  const CollapsibleAnalysisSection({
    super.key,
    required this.sectionId,
    required this.title,
    this.subtitle,
    required this.child,
  });

  static const sectionGap = AppSpacing.sm;

  final String sectionId;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(analysisSectionExpandedProvider(sectionId));

    return Padding(
      padding: const EdgeInsets.only(bottom: sectionGap),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: AppRadii.md,
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: AppTypography.titleMedium),
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
                        color: AppColors.textMuted,
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
