import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ŞantiJET tipografi ölçeği — Rajdhani (başlık/KPI) + Inter (gövde/etiket).
///
/// ŞantiJET Demir referansıyla aynı aileler ve ölçek. Fontlar uygulamada
/// paketlenmiştir (offline); Demir'den farkı yalnızca yükleme yöntemidir
/// (runtime fetch yerine bundled asset).
abstract final class AppTypography {
  static const _inter = 'Inter';
  static const _rajdhani = 'Rajdhani';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: _rajdhani,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.electricBlue,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _rajdhani,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: _rajdhani,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _inter,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _inter,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: _inter,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _inter,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _inter,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.2,
    letterSpacing: 0.02,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _inter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.2,
    letterSpacing: 0.04,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _inter,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.2,
    letterSpacing: 0.28,
  );

  static const TextStyle kpiValue = TextStyle(
    fontFamily: _rajdhani,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.0,
  );

  static const TextStyle tabLabel = TextStyle(
    fontFamily: _inter,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.1,
    letterSpacing: 0.04,
  );
}
