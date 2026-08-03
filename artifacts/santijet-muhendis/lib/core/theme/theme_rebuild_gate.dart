import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'page_background.dart';

/// Tema modunu [AppColors] ile senkronlar.
class AppColorsThemeSync extends StatelessWidget {
  const AppColorsThemeSync({
    super.key,
    required this.themeMode,
    required this.child,
  });

  final String themeMode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    AppColors.applyPaletteFromMode(themeMode, Theme.of(context).brightness);
    syncPageBackground(AppColors.surface);
    return KeyedSubtree(
      key: ValueKey(AppColors.palette),
      child: child,
    );
  }
}

/// [AppColors] kullanan alt ağacı tema değişince yeniden oluşturur.
class ThemeRebuildGate extends StatelessWidget {
  const ThemeRebuildGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Hibrit temalar (ŞantiJET / ŞantiJET Pro) brightness ile ezilmesin.
    if (!AppColors.isSantijet && !AppColors.isSantijetPro) {
      AppColors.applyBrightness(brightness);
    }
    syncPageBackground(AppColors.surface);
    return KeyedSubtree(
      key: ValueKey('${AppColors.palette}-$brightness'),
      child: child,
    );
  }
}
