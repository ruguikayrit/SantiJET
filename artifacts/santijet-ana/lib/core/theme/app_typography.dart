import 'package:flutter/material.dart';

import 'theme_colors.dart';

/// Inter body + Rajdhani display.
abstract final class AppTypography {
  static const inter = 'Inter';
  static const rajdhani = 'Rajdhani';

  static const double scale = 0.92;

  static double _s(double size) => size * scale;

  static TextStyle get displayLarge => TextStyle(
        fontFamily: rajdhani,
        fontSize: _s(40),
        fontWeight: FontWeight.w700,
        color: BrandSplash.electricBlue,
        height: 1.1,
      );

  static TextStyle get displayMedium => TextStyle(
        fontFamily: rajdhani,
        fontSize: _s(32),
        fontWeight: FontWeight.w700,
        height: 1.15,
      );

  static TextStyle get displaySmall => TextStyle(
        fontFamily: rajdhani,
        fontSize: _s(24),
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get headlineLarge => TextStyle(
        fontFamily: inter,
        fontSize: _s(22),
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get headlineMedium => TextStyle(
        fontFamily: inter,
        fontSize: _s(18),
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get headlineSmall => TextStyle(
        fontFamily: inter,
        fontSize: _s(16),
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get titleLarge => TextStyle(
        fontFamily: inter,
        fontSize: _s(16),
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get titleMedium => TextStyle(
        fontFamily: inter,
        fontSize: _s(14),
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get titleSmall => TextStyle(
        fontFamily: inter,
        fontSize: _s(13),
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get bodyLarge => TextStyle(
        fontFamily: inter,
        fontSize: _s(16),
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: inter,
        fontSize: _s(14),
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: inter,
        fontSize: _s(12),
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get labelLarge => TextStyle(
        fontFamily: inter,
        fontSize: _s(14),
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0.02,
      );

  static TextStyle get labelMedium => TextStyle(
        fontFamily: inter,
        fontSize: _s(12),
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0.04,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: inter,
        fontSize: _s(11),
        fontWeight: FontWeight.w400,
        height: 1.2,
        letterSpacing: 0.28,
      );
}
