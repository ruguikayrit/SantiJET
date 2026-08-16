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
  /// ŞantiJET'te koyu kart içinden açılan sheet'ler açık chrome temasına
  /// döner — beyaz metin + açık zemin çakışmasını önler.
  static ThemeData _sheetTheme(ThemeData parent) {
    if (!AppColors.isSantijet) return parent;
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
    final parentTheme = Theme.of(context);
    final theme = _sheetTheme(parentTheme);
    final bg = AppColors.isSantijet
        ? AppColors.lightSurface
        : (parentTheme.cardTheme.color ?? parentTheme.colorScheme.surface);

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
    final parentTheme = Theme.of(context);
    final theme = _sheetTheme(parentTheme);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Theme(
        data: theme,
        child: AlertDialog(
          backgroundColor: AppColors.isSantijet
              ? AppColors.lightSurface
              : (parentTheme.cardTheme.color ??
                  parentTheme.colorScheme.surface),
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
