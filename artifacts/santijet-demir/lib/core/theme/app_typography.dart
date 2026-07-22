import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';

/// Figma Make — 9 adımlı tipografi ölçeği.
abstract final class AppTypography {
  /// Global tipografi ölçeği (1.0 = tasarım referansı).
  static const double scale = 0.7;

  static double _s(double size) => size * scale;

  static TextStyle get displayLarge => GoogleFonts.rajdhani(
        fontSize: _s(40),
        fontWeight: FontWeight.w700,
        color: AppColors.electricBlue,
        height: 1.1,
      );

  static TextStyle get displayMedium => GoogleFonts.rajdhani(
        fontSize: _s(32),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.15,
      );

  static TextStyle get displaySmall => GoogleFonts.rajdhani(
        fontSize: _s(24),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: _s(22),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: _s(18),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: _s(16),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: _s(14),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: _s(16),
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: _s(14),
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.45,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: _s(12),
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.4,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: _s(14),
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.2,
        letterSpacing: 0.02,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: _s(12),
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        height: 1.2,
        letterSpacing: 0.04,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: _s(11),
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.2,
        letterSpacing: 0.28,
      );

  static TextStyle get kpiValue => GoogleFonts.rajdhani(
        fontSize: _s(28),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.0,
      );

  static TextStyle get tabLabel => GoogleFonts.inter(
        fontSize: _s(10),
        fontWeight: FontWeight.w600,
        height: 1.1,
        letterSpacing: 0.04,
      );
}
