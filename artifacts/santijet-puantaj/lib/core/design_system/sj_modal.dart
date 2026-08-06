import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import 'sj_button.dart';

/// ŞantiJET Design System — modal yardımcıları.
///
/// Tutarlı başlık + içerik + aksiyon düzeniyle alt sayfa (bottom sheet) ve
/// diyalog gösterir. Tüm ekranlar aynı modal dilini kullanır.
abstract final class SJModal {
  /// Sheet/dialog yüzeyi — her zaman chrome paletini izler.
  ///
  /// Kart içinden açılan modallarda [Theme.of] kart kontrast temasını verir;
  /// bu tema zemin ile mürekkebi eşleştirerek koyu-üzerine-koyu ve
  /// açık-üzerine-açık çakışmasını tüm paletlerde engeller.
  static Color get _surface =>
      AppColors.useDarkChrome ? AppColors.darkSurfaceElevated : AppColors.lightSurface;

  static ThemeData _sheetTheme(ThemeData parent) =>
      AppColors.useDarkChrome ? _darkSheetTheme(parent) : _lightSheetTheme(parent);

  /// Ham `showModalBottomSheet` / `showDialog` çağrıları için yüzey rengi.
  static Color get sheetSurface => _surface;

  /// Ham modal çağrılarında içeriği sarmalamak için tema.
  static ThemeData sheetThemeOf(BuildContext context) =>
      _sheetTheme(Theme.of(context));

  static ThemeData _darkSheetTheme(ThemeData parent) {
    return parent.copyWith(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.electricBlueLight,
        onPrimary: AppColors.darkTextPrimary,
        secondary: AppColors.electricBlueLight,
        onSecondary: AppColors.darkTextPrimary,
        surface: AppColors.darkSurfaceElevated,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextSecondary,
        outline: AppColors.darkBorder,
        error: AppColors.critical,
        onError: AppColors.darkTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.darkSurfaceElevated,
      canvasColor: AppColors.darkSurfaceElevated,
      cardColor: AppColors.darkSurfaceElevated,
      dividerColor: AppColors.darkBorder,
      textTheme: parent.textTheme.apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      primaryTextTheme: parent.primaryTextTheme.apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
      unselectedWidgetColor: AppColors.darkTextMuted,
    );
  }

  static ThemeData _lightSheetTheme(ThemeData parent) {
    return parent.copyWith(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.electricBlue,
        onPrimary: Colors.white,
        secondary: AppColors.electricBlueLight,
        onSecondary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        onSurfaceVariant: AppColors.lightTextSecondary,
        outline: AppColors.lightBorder,
        error: AppColors.critical,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.lightSurface,
      canvasColor: AppColors.lightSurface,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightBorder,
      textTheme: parent.textTheme.apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      primaryTextTheme: parent.primaryTextTheme.apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.lightTextSecondary),
      unselectedWidgetColor: AppColors.lightTextMuted,
    );
  }

  /// Alt sayfa (bottom sheet) gösterir.
  static Future<T?> showSheet<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    bool isScrollControlled = true,
  }) {
    final theme = _sheetTheme(Theme.of(context));
    final bg = _surface;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Theme(
        data: theme,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.sm,
              bottom: AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: AppRadii.full,
                    ),
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Onay diyaloğu gösterir; kullanıcı onaylarsa `true` döner.
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Onayla',
    String cancelLabel = 'İptal',
    bool destructive = false,
  }) async {
    final theme = _sheetTheme(Theme.of(context));
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Theme(
        data: theme,
        child: AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.lg),
          title: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            SJButton(
              label: cancelLabel,
              variant: SJButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            SJButton(
              label: confirmLabel,
              variant: destructive
                  ? SJButtonVariant.destructive
                  : SJButtonVariant.primary,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }
}
