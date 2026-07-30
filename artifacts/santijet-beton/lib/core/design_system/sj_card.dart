import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// ŞantiJET Design System — kart.
///
/// ŞantiJET temasında koyu yüzey + açık mürekkep teması sağlar.
/// İçerikte [Theme.of] kullanırken kartın altındaki context'i alın
/// ([Builder] ile); aksi halde dış açık tema renkleri gömülür.
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

  /// ŞantiJET (ve koyu) kartlar için yüksek kontrastlı yerel tema.
  static ThemeData contrastTheme(ThemeData base) {
    const onPrimary = AppColors.darkTextPrimary;
    const onSecondary = AppColors.darkTextSecondary;
    final scheme = ColorScheme.dark(
      surface: AppColors.darkSurfaceElevated,
      primary: AppColors.electricBlueLight,
      onPrimary: onPrimary,
      secondary: AppColors.electricBlueLight,
      onSecondary: onPrimary,
      error: AppColors.critical,
      onError: onPrimary,
      onSurface: onPrimary,
      onSurfaceVariant: onSecondary,
      outline: AppColors.darkBorderSubtle,
    );

    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: scheme,
      textTheme: base.textTheme.apply(
        bodyColor: onSecondary,
        displayColor: onPrimary,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        bodyColor: onSecondary,
        displayColor: onPrimary,
      ),
      iconTheme: const IconThemeData(color: onSecondary),
      primaryIconTheme: const IconThemeData(color: AppColors.electricBlueLight),
      dividerColor: AppColors.darkBorder,
      disabledColor: AppColors.darkTextMuted,
      hintColor: AppColors.darkTextMuted,
      unselectedWidgetColor: onSecondary,
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.electricBlueLight,
          side: const BorderSide(color: AppColors.electricBlueLight),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.electricBlueLight,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: onSecondary,
        textColor: onPrimary,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: AppColors.darkSurface,
        hintStyle: base.textTheme.bodyMedium?.copyWith(
          color: AppColors.darkTextMuted,
        ),
        labelStyle: base.textTheme.bodyMedium?.copyWith(color: onSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: const BorderSide(color: AppColors.darkBorderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: const BorderSide(color: AppColors.electricBlueLight),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useContrast = AppColors.useDarkCards;
    final surface = useContrast
        ? AppColors.cardSurface
        : (theme.cardTheme.color ?? theme.colorScheme.surface);
    final borderColor = selected
        ? theme.colorScheme.primary
        : (useContrast ? AppColors.cardBorder : theme.dividerColor);

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

    if (useContrast) {
      content = Theme(
        data: contrastTheme(theme),
        child: IconTheme.merge(
          data: const IconThemeData(color: AppColors.darkTextSecondary),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: AppColors.darkTextPrimary),
            child: content,
          ),
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
