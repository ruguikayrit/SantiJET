import 'package:flutter/material.dart';

/// ŞantiJET Pro kabuk renkleri. Modül ekranlarının paleti burada değişmez.
abstract final class ProColors {
  static const canvas = Color(0xFF05070A);
  static const surface = Color(0xFF0D1117);
  static const border = Color(0xFF1E293B);
  static const text = Color(0xFFFFFFFF);
  static const textMuted = Color(0xB3FFFFFF);
  static const textFaint = Color(0x66FFFFFF);
  static const electricBlue = Color(0xFF0055FF);
}

abstract final class ProTheme {
  static ThemeData get dark {
    const text = TextStyle(fontFamily: 'Inter', color: ProColors.text);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ProColors.canvas,
      colorScheme: const ColorScheme.dark(
        surface: ProColors.canvas,
        primary: ProColors.electricBlue,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        bodyMedium: text,
        bodyLarge: text,
        titleMedium: text,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
