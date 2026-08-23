import 'package:flutter/material.dart';

import '../design_system/sj_button.dart';
import '../design_system/sj_card.dart';
import '../design_system/sj_status_badge.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../domain/tahvil_calculator.dart';

/// Hesap özet kartı ve Kayıtlar satırı — mavi kaynak / yeşil hedef iki satır.
class TahvilHeroRow extends StatelessWidget {
  const TahvilHeroRow({
    super.key,
    required this.donatiLine,
    required this.asLabel,
    required this.color,
  });

  final String donatiLine;
  final String asLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            donatiLine,
            style: AppTypography.onCard(
              AppTypography.cardTitleMedium,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          asLabel,
          softWrap: false,
          style: AppTypography.cardBodySmall.copyWith(
            color: AppColors.cardTextSecondary,
          ),
        ),
      ],
    );
  }
}

class TahvilHeroCard extends StatelessWidget {
  const TahvilHeroCard({
    super.key,
    required this.title,
    required this.badgeLabel,
    required this.badgeColor,
    required this.sourceLine,
    required this.sourceAs,
    required this.targetLine,
    required this.targetAs,
    required this.asUnit,
    this.footer,
    this.child,
  });

  final String title;
  final String badgeLabel;
  final Color badgeColor;
  final String sourceLine;
  final double sourceAs;
  final String targetLine;
  final double targetAs;
  final String asUnit;
  final Widget? footer;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      accentColor: AppColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(title, style: AppTypography.cardLabelMedium),
              const Spacer(),
              SJStatusBadge(label: badgeLabel, color: badgeColor),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TahvilHeroRow(
            donatiLine: sourceLine,
            asLabel: 'As ${formatAreaMm2(sourceAs)} $asUnit',
            color: AppColors.statusInkOnCard(AppColors.electricBlue),
          ),
          const SizedBox(height: AppSpacing.sm),
          TahvilHeroRow(
            donatiLine: targetLine,
            asLabel: 'As ${formatAreaMm2(targetAs)} $asUnit',
            color: AppColors.statusInkOnCard(AppColors.success),
          ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.sm),
            footer!,
          ],
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// Hesap sayfası önerilen tahvil kartı + Kaydet.
class TahvilHeroSaveCard extends StatelessWidget {
  const TahvilHeroSaveCard({
    super.key,
    required this.sourceLine,
    required this.sourceAs,
    required this.targetLine,
    required this.targetAs,
    required this.asUnit,
    required this.onSave,
  });

  final String sourceLine;
  final double sourceAs;
  final String targetLine;
  final double targetAs;
  final String asUnit;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return TahvilHeroCard(
      title: 'Önerilen tahvil',
      badgeLabel: 'Optimum Uygunluk',
      badgeColor: AppColors.success,
      sourceLine: sourceLine,
      sourceAs: sourceAs,
      targetLine: targetLine,
      targetAs: targetAs,
      asUnit: asUnit,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          SJButton(
            label: 'Kaydet',
            icon: Icons.bookmark_add_outlined,
            onPressed: onSave,
            expanded: true,
          ),
        ],
      ),
    );
  }
}
