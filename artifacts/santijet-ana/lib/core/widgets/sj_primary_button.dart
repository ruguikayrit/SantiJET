import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/theme_provider.dart';

class SjPrimaryButton extends ConsumerWidget {
  const SjPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeDefinitionProvider).colors;
    final child = ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.primaryForeground,
        disabledBackgroundColor: colors.muted,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + 2,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
      ),
      child: loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primaryForeground,
              ),
            )
          : Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: colors.primaryForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
    if (!expanded) return child;
    return SizedBox(width: double.infinity, child: child);
  }
}
