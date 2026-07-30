import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// ŞantiJET Design System — kart.
///
/// ŞantiJET / koyu temada kart yüzeyi her zaman koyu; metin her zaman açık.
/// Kart içinde [Theme.of] kullanırken mutlaka [Builder] ile kart context'ini alın;
/// aksi halde dış (açık chrome) mürekkep renkleri TextStyle'a gömülür.
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
  /// Tüm tipografi stillerine açık mürekkep zorlanır (koyu-üzerine-koyu yok).
  static ThemeData contrastTheme(ThemeData base) {
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

    TextTheme forceOnDark(TextTheme source) {
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
      textTheme: forceOnDark(base.textTheme),
      primaryTextTheme: forceOnDark(base.primaryTextTheme),
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

    // childBuilder: kartın kontrast Theme'i altında yeniden kurulur —
    // dış açık chrome'dan gömülmüş koyu TextStyle renkleri engellenir.
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
            style: const TextStyle(
              color: AppColors.darkTextPrimary,
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
