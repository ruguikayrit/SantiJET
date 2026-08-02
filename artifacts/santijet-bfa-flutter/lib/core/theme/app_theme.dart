import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

/// ŞantiJET Material 3 teması (açık + koyu).
///
/// ŞantiJET Demir referans projesinden birebir alınmıştır; BFA ile Demir'in
/// görsel dili tamamen aynıdır.
abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      surface: Color(0xFFF8FAFC),
      primary: AppColors.electricBlue,
      onPrimary: Colors.white,
      secondary: AppColors.electricBlueLight,
      onSecondary: Colors.white,
      error: AppColors.critical,
      onError: Colors.white,
      onSurface: Color(0xFF0F172A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF1F5F9),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium
            .copyWith(color: const Color(0xFF0F172A)),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.md,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle:
            AppTypography.bodyMedium.copyWith(color: const Color(0xFF94A3B8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: const BorderSide(color: AppColors.electricBlue),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.electricBlue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.electricBlue,
        unselectedItemColor: const Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTypography.tabLabel,
        unselectedLabelStyle: AppTypography.tabLabel,
      ),
      textTheme: TextTheme(
        displayLarge:
            AppTypography.displayLarge.copyWith(color: const Color(0xFF0F172A)),
        displayMedium: AppTypography.displayMedium
            .copyWith(color: const Color(0xFF0F172A)),
        displaySmall:
            AppTypography.displaySmall.copyWith(color: const Color(0xFF0F172A)),
        headlineLarge: AppTypography.headlineLarge
            .copyWith(color: const Color(0xFF0F172A)),
        headlineMedium: AppTypography.headlineMedium
            .copyWith(color: const Color(0xFF0F172A)),
        titleLarge:
            AppTypography.titleLarge.copyWith(color: const Color(0xFF0F172A)),
        titleMedium:
            AppTypography.titleMedium.copyWith(color: const Color(0xFF0F172A)),
        bodyLarge:
            AppTypography.bodyLarge.copyWith(color: const Color(0xFF334155)),
        bodyMedium:
            AppTypography.bodyMedium.copyWith(color: const Color(0xFF334155)),
        bodySmall:
            AppTypography.bodySmall.copyWith(color: const Color(0xFF64748B)),
        labelLarge:
            AppTypography.labelLarge.copyWith(color: const Color(0xFF64748B)),
        labelMedium:
            AppTypography.labelMedium.copyWith(color: const Color(0xFF64748B)),
        labelSmall:
            AppTypography.labelSmall.copyWith(color: const Color(0xFF64748B)),
      ),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      surface: AppColors.darkSurface,
      primary: AppColors.electricBlue,
      onPrimary: AppColors.darkTextPrimary,
      secondary: AppColors.electricBlueLight,
      onSecondary: AppColors.darkTextPrimary,
      error: AppColors.critical,
      onError: AppColors.darkTextPrimary,
      onSurface: AppColors.darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkCanvas,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkCanvas,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.md,
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextMuted,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: const BorderSide(color: AppColors.electricBlue),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.electricBlue,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.electricBlueLight,
        unselectedItemColor: AppColors.darkTextMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTypography.tabLabel,
        unselectedLabelStyle: AppTypography.tabLabel,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),
    );
  }
}
