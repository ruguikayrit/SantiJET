import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// ŞantiJET Design System — kart.
///
/// ŞantiJET: koyu kart + açık mürekkep.
/// ŞantiJET Pro: açık (light) kart + koyu mürekkep — koyu zemin üzerinde.
///
/// Kart içinde **chrome** mürekkep kullanmayın (`AppColors.textPrimary` /
/// `AppTypography.titleMedium` varsayılan rengi). Bunun yerine:
/// - [AppTypography.cardTitleMedium] / [AppTypography.onCard]
/// - [AppColors.cardTextPrimary] / [AppColors.statusInkOnCard]
/// - kart içi inset yüzey: [AppColors.cardInsetSurface] (chrome
///   `surfaceElevated` değil)
///
/// [Theme.of] kullanırken mutlaka [Builder] ile kart context'ini alın.
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

  /// Koyu kart (ŞantiJET / koyu) — açık mürekkep zorlanır.
  static ThemeData darkContrastTheme(ThemeData base) {
    const onPrimary = AppColors.darkTextPrimary;
    const onSecondary = AppColors.darkTextSecondary;
    const onMuted = AppColors.darkTextMuted;
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

    TextTheme forceInk(TextTheme source) {
      TextStyle? paint(TextStyle? style, Color color) =>
          style?.copyWith(color: color);
      return source.copyWith(
        displayLarge: paint(source.displayLarge, onPrimary),
        displayMedium: paint(source.displayMedium, onPrimary),
        displaySmall: paint(source.displaySmall, onPrimary),
        headlineLarge: paint(source.headlineLarge, onPrimary),
        headlineMedium: paint(source.headlineMedium, onPrimary),
        headlineSmall: paint(source.headlineSmall, onPrimary),
        titleLarge: paint(source.titleLarge, onPrimary),
        titleMedium: paint(source.titleMedium, onPrimary),
        titleSmall: paint(source.titleSmall, onPrimary),
        bodyLarge: paint(source.bodyLarge, onSecondary),
        bodyMedium: paint(source.bodyMedium, onSecondary),
        bodySmall: paint(source.bodySmall, onMuted),
        labelLarge: paint(source.labelLarge, onMuted),
        labelMedium: paint(source.labelMedium, onMuted),
        labelSmall: paint(source.labelSmall, onMuted),
      );
    }

    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: scheme,
      textTheme: forceInk(base.textTheme),
      primaryTextTheme: forceInk(base.primaryTextTheme),
      iconTheme: const IconThemeData(color: onSecondary),
      primaryIconTheme: const IconThemeData(color: AppColors.electricBlueLight),
      dividerColor: AppColors.darkBorder,
      disabledColor: onMuted,
      hintColor: onMuted,
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
        hintStyle: base.textTheme.bodyMedium?.copyWith(color: onMuted),
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

  /// Açık kart (ŞantiJET Pro) — koyu mürekkep zorlanır.
  static ThemeData lightContrastTheme(ThemeData base) {
    const onPrimary = AppColors.lightTextPrimary;
    const onSecondary = AppColors.lightTextSecondary;
    const onMuted = AppColors.lightTextMuted;
    final scheme = ColorScheme.light(
      surface: AppColors.lightSurface,
      primary: AppColors.electricBlue,
      onPrimary: Colors.white,
      secondary: AppColors.electricBlueLight,
      onSecondary: Colors.white,
      error: AppColors.critical,
      onError: Colors.white,
      onSurface: onPrimary,
      onSurfaceVariant: onSecondary,
      outline: AppColors.lightBorder,
    );

    TextTheme forceInk(TextTheme source) {
      TextStyle? paint(TextStyle? style, Color color) =>
          style?.copyWith(color: color);
      return source.copyWith(
        displayLarge: paint(source.displayLarge, onPrimary),
        displayMedium: paint(source.displayMedium, onPrimary),
        displaySmall: paint(source.displaySmall, onPrimary),
        headlineLarge: paint(source.headlineLarge, onPrimary),
        headlineMedium: paint(source.headlineMedium, onPrimary),
        headlineSmall: paint(source.headlineSmall, onPrimary),
        titleLarge: paint(source.titleLarge, onPrimary),
        titleMedium: paint(source.titleMedium, onPrimary),
        titleSmall: paint(source.titleSmall, onPrimary),
        bodyLarge: paint(source.bodyLarge, onSecondary),
        bodyMedium: paint(source.bodyMedium, onSecondary),
        bodySmall: paint(source.bodySmall, onMuted),
        labelLarge: paint(source.labelLarge, onMuted),
        labelMedium: paint(source.labelMedium, onMuted),
        labelSmall: paint(source.labelSmall, onMuted),
      );
    }

    return base.copyWith(
      brightness: Brightness.light,
      colorScheme: scheme,
      textTheme: forceInk(base.textTheme),
      primaryTextTheme: forceInk(base.primaryTextTheme),
      iconTheme: const IconThemeData(color: onSecondary),
      primaryIconTheme: const IconThemeData(color: AppColors.electricBlue),
      dividerColor: AppColors.lightBorder,
      disabledColor: onMuted,
      hintColor: onMuted,
      unselectedWidgetColor: onSecondary,
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.electricBlue,
          side: const BorderSide(color: AppColors.electricBlue),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.electricBlue,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: onSecondary,
        textColor: onPrimary,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: AppColors.lightSurfaceElevated,
        hintStyle: base.textTheme.bodyMedium?.copyWith(color: onMuted),
        labelStyle: base.textTheme.bodyMedium?.copyWith(color: onSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: const BorderSide(color: AppColors.electricBlue),
        ),
      ),
    );
  }

  /// Geriye dönük: koyu kontrast teması.
  static ThemeData contrastTheme(ThemeData base) => darkContrastTheme(base);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useDarkContrast = AppColors.useDarkCards;
    final useLightContrast = AppColors.isSantijetPro;
    final useContrast = useDarkContrast || useLightContrast;
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

    if (useDarkContrast) {
      content = Theme(
        data: darkContrastTheme(theme),
        child: IconTheme.merge(
          data: const IconThemeData(color: AppColors.darkTextSecondary),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: AppColors.darkTextPrimary,
              decoration: TextDecoration.none,
            ),
            child: content,
          ),
        ),
      );
    } else if (useLightContrast) {
      content = Theme(
        data: lightContrastTheme(theme),
        child: IconTheme.merge(
          data: const IconThemeData(color: AppColors.lightTextSecondary),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: AppColors.lightTextPrimary,
              decoration: TextDecoration.none,
            ),
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
        boxShadow: AppColors.useHybridCards ? AppColors.cardElevation : null,
      ),
      child: content,
    );

    if (onTap == null) {
      return SizedBox(width: double.infinity, child: decorated);
    }

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.md,
          child: decorated,
        ),
      ),
    );
  }
}
