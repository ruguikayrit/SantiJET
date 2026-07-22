import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';

/// [Theme] parlaklığını [AppColors] ile senkronlar (ağacı yeniden oluşturmaz).
class AppColorsThemeSync extends StatelessWidget {
  const AppColorsThemeSync({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    AppColors.applyBrightness(Theme.of(context).brightness);
    return child;
  }
}

/// [AppColors] kullanan alt ağacı tema değişince yeniden oluşturur.
///
/// `AppColors.*` getter'ları [Theme.of] bağımlılığı oluşturmaz; StatefulShell
/// / Navigator sayfaları bu yüzden eski renklerde kalabilir. [KeyedSubtree]
/// ile zorunlu yenileme yapılır.
class ThemeRebuildGate extends StatelessWidget {
  const ThemeRebuildGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    AppColors.applyBrightness(brightness);
    return KeyedSubtree(
      key: ValueKey(brightness),
      child: child,
    );
  }
}
