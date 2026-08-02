import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/page_background.dart';

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
    // HTML gövde rengi = alt nav yüzeyi: mobil tarayıcıda Flutter alanının
    // altında kalan bant nav ile aynı renk olsun (nav altında ölü alan olmaz).
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
    // Hibrit temalar (ŞantiJET / GeceJET) brightness ile ezilmesin.
    if (!AppColors.isSantijet && !AppColors.isGecejet) {
      AppColors.applyBrightness(brightness);
    }
    // Alt nav yüzeyiyle aynı renk — nav altında gri bant/ölü alan görünmesin.
    syncPageBackground(AppColors.surface);
    return KeyedSubtree(
      key: ValueKey('${AppColors.palette}-$brightness'),
      child: child,
    );
  }
}
