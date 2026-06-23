import 'package:flutter/material.dart';

import 'sj_colors.dart';
import 'sj_typography.dart';

/// ŞantiJET BFA Material 3 tema fabrikası.
///
/// NOT (Faz 2): Açık/koyu temalar ve 6 BFA tema varyantı (Klasik, Turuncu
/// Enerji, Beyaz Minimal, Gece, Krem & Sıcak, Steel) ŞantiJET Demir tasarım
/// sistemine hizalanarak burada genişletilecektir.
class SJTheme {
  const SJTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: SJColors.brandOrange,
      primary: SJColors.brandOrange,
      secondary: SJColors.brandNavy,
      surface: SJColors.lightSurface,
      error: SJColors.destructive,
    );
    return _build(scheme, Brightness.light, SJColors.lightBackground);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: SJColors.brandOrange,
      brightness: Brightness.dark,
      primary: SJColors.brandOrange,
      secondary: SJColors.brandNavy,
      surface: SJColors.darkSurface,
      error: SJColors.destructive,
    );
    return _build(scheme, Brightness.dark, SJColors.darkBackground);
  }

  static ThemeData _build(
    ColorScheme scheme,
    Brightness brightness,
    Color scaffoldBackground,
  ) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
    );
    return base.copyWith(
      textTheme: SJTypography.build(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: SJColors.brandNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
