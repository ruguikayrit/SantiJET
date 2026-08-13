import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';

/// Metrajı henüz girilmemiş poz uyarısı (sayfa başı).
class MetrajsizPozWarning extends StatelessWidget {
  const MetrajsizPozWarning({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final label = count == 1
        ? '1 pozun metrajı girilmemiş.'
        : '$count pozun metrajı girilmemiş.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: AppRadii.md,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '$label Metraj sayfasından cetvel satırı veya miktar girin.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
