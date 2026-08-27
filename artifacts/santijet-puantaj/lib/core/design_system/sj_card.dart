import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// ŞantiJET Design System — kart.
///
/// ŞantiJET: koyu kart + açık mürekkep.
/// ŞantiJET Pro: açık (light) kart + koyu mürekkep — koyu zemin üzerinde.
///
/// **Önemli:** Kart içinde `Theme.of` / `textTheme` kullanırken dış `build`
/// context’ini kapatmayın. Dış tema chrome mürekkebidir; kart yüzeyiyle
/// çakışır (beyaz üstüne beyaz / koyu üstüne koyu). Ya [Builder] kullanın
/// ya da [SJCard.builder] ile kart temasına bağlı kalın.
class SJCard extends StatelessWidget {
  const SJCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.accentColor,
    this.selected = false,
    super.key,
  });

  /// Kart kontrast temasını alan builder — dış Theme kapanmasını engeller.
  factory SJCard.builder({
    Key? key,
    required Widget Function(BuildContext context, ThemeData theme) builder,
    VoidCallback? onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.md),
    Color? accentColor,
    bool selected = false,
  }) {
    return SJCard(
      key: key,
      onTap: onTap,
      padding: padding,
      accentColor: accentColor,
      selected: selected,
      child: Builder(
        builder: (context) => builder(context, Theme.of(context)),
      ),
    );
  }

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;
  final bool selected;

  static TextTheme _forceInk(
    TextTheme source, {
    required Color onPrimary,
    required Color onSecondary,
    required Color onMuted,
  }) {
    TextStyle paint(TextStyle? style, Color color) =>
        (style ?? const TextStyle()).copyWith(
          color: color,
          decoration: TextDecoration.none,
        );
    return TextTheme(
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
      labelLarge: paint(source.labelLarge, onPrimary),
      labelMedium: paint(source.labelMedium, onMuted),
      labelSmall: paint(source.labelSmall, onMuted),
    );
  }

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
    final ink = _forceInk(
      base.textTheme,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
      onMuted: onMuted,
    );

    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: scheme,
      textTheme: ink,
      primaryTextTheme: _forceInk(
        base.primaryTextTheme,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
        onMuted: onMuted,
      ),
      cardColor: AppColors.darkSurfaceElevated,
      canvasColor: AppColors.darkSurfaceElevated,
      cardTheme: base.cardTheme.copyWith(
        color: AppColors.darkSurfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.md,
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      iconTheme: const IconThemeData(color: onSecondary),
      primaryIconTheme: const IconThemeData(color: AppColors.electricBlueLight),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: onSecondary),
      ),
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
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: onSecondary,
        collapsedIconColor: onSecondary,
        textColor: onPrimary,
        collapsedTextColor: onPrimary,
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

    // Koyu chrome ThemeData üzerinde brightness flip mürekkebi ezebiliyor;
    // açık kart için light seed üzerinden zorla.
    final seeded = ThemeData(
      useMaterial3: base.useMaterial3,
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: base.textTheme.bodyMedium?.fontFamily,
    );
    final ink = _forceInk(
      base.textTheme,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
      onMuted: onMuted,
    );
    return seeded.copyWith(
      textTheme: ink,
      primaryTextTheme: _forceInk(
        base.primaryTextTheme,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
        onMuted: onMuted,
      ),
      cardColor: AppColors.lightSurface,
      canvasColor: AppColors.lightSurface,
      cardTheme: base.cardTheme.copyWith(
        color: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.md,
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      iconTheme: const IconThemeData(color: onSecondary),
      primaryIconTheme: const IconThemeData(color: AppColors.electricBlue),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: onSecondary),
      ),
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
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: onSecondary,
        collapsedIconColor: onSecondary,
        textColor: onPrimary,
        collapsedTextColor: onPrimary,
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

  /// Aktif palete göre kart kontrast teması.
  static ThemeData cardContrastTheme(ThemeData base) {
    if (AppColors.isSantijetPro) return lightContrastTheme(base);
    if (AppColors.useDarkCards) return darkContrastTheme(base);
    return base;
  }

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

    // Accent şerit: IntrinsicHeight kullanma — LayoutBuilder / CustomPaint
    // gibi çocuklar intrinsik yüksekliği 0 verir; kart grafik açılınca
    // sıkışır ve taşar. Stack, içeriğin gerçek yüksekliğine göre uzar.
    Widget content = Padding(
      padding: padding,
      child: accentColor == null
          ? child
          : Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: AppRadii.xs,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4 + AppSpacing.sm),
                  child: child,
                ),
              ],
            ),
    );

    // Pro açık kart öncelikli — koyu chrome’da koyu mürekkep.
    if (useLightContrast) {
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
    } else if (useDarkContrast) {
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
