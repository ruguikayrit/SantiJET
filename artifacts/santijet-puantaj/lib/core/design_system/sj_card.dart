import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// ŞantiJET Design System — kart.
///
/// Demir kart deseni: [AppColors.cardSurface] (ŞantiJET'te koyu özet kartları).
class SJCard extends StatelessWidget {
  const SJCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.accentColor,
    this.selected = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = AppColors.isSantijet
        ? AppColors.cardSurface
        : (theme.cardTheme.color ?? theme.colorScheme.surface);
    final borderColor = selected
        ? theme.colorScheme.primary
        : (AppColors.isSantijet ? AppColors.cardBorder : theme.dividerColor);

    Widget content = Padding(
      padding: padding,
      child: accentColor == null
          ? child
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: AppRadii.xs,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: child),
                ],
              ),
            ),
    );

    if (AppColors.isSantijet) {
      content = Theme(
        data: theme.copyWith(
          textTheme: theme.textTheme.apply(
            bodyColor: AppColors.cardTextPrimary,
            displayColor: AppColors.cardTextPrimary,
          ),
          iconTheme: IconThemeData(color: AppColors.cardTextSecondary),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: AppColors.cardTextPrimary),
          child: content,
        ),
      );
    }

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadii.md,
        border: Border.all(
          color: borderColor,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: AppColors.isSantijet ? AppColors.cardElevation : null,
      ),
      child: content,
    );

    if (onTap == null) return decorated;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: decorated,
      ),
    );
  }
}
