import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ŞantiJET tipografi — Demir ile aynı ölçek / aile / renkler.
///
/// Fontlar uygulamada paketlenmiştir (Inter + Rajdhani).
abstract final class AppTypography {
  static const _inter = 'Inter';
  static const _rajdhani = 'Rajdhani';

  /// Global tipografi ölçeği (1.0 = tasarım referansı) — Demir ile aynı.
  static const double scale = 0.92;

  /// Marka wordmark ölçü kilidi — global ölçekten bağımsız.
  static const double brandScale = 0.7;

  static double _s(double size) => size * scale;

  static TextStyle get displayLarge => TextStyle(
        fontFamily: _rajdhani,
        fontSize: _s(40),
        fontWeight: FontWeight.w700,
        color: AppColors.electricBlue,
        height: 1.1,
      );

  static TextStyle get displayMedium => TextStyle(
        fontFamily: _rajdhani,
        fontSize: _s(32),
        fontWeight: FontWeight.w700,
        color: AppColors.inkPrimary,
        height: 1.15,
      );

  static TextStyle get displaySmall => TextStyle(
        fontFamily: _rajdhani,
        fontSize: _s(24),
        fontWeight: FontWeight.w600,
        color: AppColors.inkPrimary,
        height: 1.2,
      );

  static TextStyle get headlineLarge => TextStyle(
        fontFamily: _inter,
        fontSize: _s(22),
        fontWeight: FontWeight.w700,
        color: AppColors.inkPrimary,
        height: 1.25,
      );

  static TextStyle get headlineMedium => TextStyle(
        fontFamily: _inter,
        fontSize: _s(18),
        fontWeight: FontWeight.w600,
        color: AppColors.inkPrimary,
        height: 1.3,
      );

  static TextStyle get titleLarge => TextStyle(
        fontFamily: _inter,
        fontSize: _s(16),
        fontWeight: FontWeight.w600,
        color: AppColors.inkPrimary,
        height: 1.35,
      );

  static TextStyle get titleMedium => TextStyle(
        fontFamily: _inter,
        fontSize: _s(14),
        fontWeight: FontWeight.w600,
        color: AppColors.inkPrimary,
        height: 1.4,
      );

  static TextStyle get bodyLarge => TextStyle(
        fontFamily: _inter,
        fontSize: _s(16),
        fontWeight: FontWeight.w400,
        color: AppColors.inkSecondary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: _inter,
        fontSize: _s(14),
        fontWeight: FontWeight.w400,
        color: AppColors.inkSecondary,
        height: 1.45,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: _inter,
        fontSize: _s(12),
        fontWeight: FontWeight.w400,
        color: AppColors.inkMuted,
        height: 1.4,
      );

  static TextStyle get labelLarge => TextStyle(
        fontFamily: _inter,
        fontSize: _s(14),
        fontWeight: FontWeight.w500,
        color: AppColors.inkSecondary,
        height: 1.2,
        letterSpacing: 0.02,
      );

  static TextStyle get labelMedium => TextStyle(
        fontFamily: _inter,
        fontSize: _s(12),
        fontWeight: FontWeight.w500,
        color: AppColors.inkMuted,
        height: 1.2,
        letterSpacing: 0.04,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: _inter,
        fontSize: _s(11),
        fontWeight: FontWeight.w400,
        color: AppColors.inkMuted,
        height: 1.2,
        letterSpacing: 0.28,
      );

  static TextStyle get kpiValue => TextStyle(
        fontFamily: _rajdhani,
        fontSize: _s(28),
        fontWeight: FontWeight.w700,
        color: AppColors.inkPrimary,
        height: 1.0,
      );

  static TextStyle get tabLabel => TextStyle(
        fontFamily: _inter,
        fontSize: _s(10),
        fontWeight: FontWeight.w600,
        height: 1.1,
        letterSpacing: 0.04,
      );

  static TextStyle get cardTitleMedium =>
      titleMedium.copyWith(color: AppColors.cardTextPrimary);

  static TextStyle get cardBodyMedium =>
      bodyMedium.copyWith(color: AppColors.cardTextPrimary);

  static TextStyle get cardBodySmall =>
      bodySmall.copyWith(color: AppColors.cardTextSecondary);

  static TextStyle get cardLabelLarge =>
      labelLarge.copyWith(color: AppColors.cardTextPrimary);

  static TextStyle get cardLabelMedium =>
      labelMedium.copyWith(color: AppColors.cardTextMuted);

  static TextStyle get cardLabelSmall =>
      labelSmall.copyWith(color: AppColors.cardTextMuted);

  static TextStyle onCard(TextStyle style, {Color? color}) =>
      style.copyWith(color: color ?? AppColors.cardTextPrimary);

  static TextStyle inkless(TextStyle style) => TextStyle(
        fontFamily: style.fontFamily,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        fontStyle: style.fontStyle,
        height: style.height,
        letterSpacing: style.letterSpacing,
        decoration: style.decoration,
      );
}
