import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light {
    // Not: applyBrightness burada çağrılmaz — MaterialApp hem light hem dark
    // ThemeData'yı üretir; son çağrı AppColors'u yanlış temada kilitlerdi.
    // Senkron yalnızca MaterialApp.builder / ThemeRebuildGate içinde yapılır.

    final colorScheme = ColorScheme.light(
      surface: AppColors.lightSurfaceElevated,
      primary: AppColors.electricBlue,
      onPrimary: Colors.white,
      secondary: AppColors.electricBlueLight,
      onSecondary: Colors.white,
      error: AppColors.critical,
      onError: Colors.white,
      onSurface: AppColors.lightTextPrimary,
      outline: AppColors.lightBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightCanvas,
      colorScheme: colorScheme,
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightCanvas,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shadowColor: const Color(0x140B1220),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.md,
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightTextDisabled,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: const BorderSide(color: AppColors.lightBorder),
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
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.electricBlue,
        unselectedItemColor: AppColors.lightTextMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTypography.tabLabel,
        unselectedLabelStyle: AppTypography.tabLabel,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        backgroundColor: AppColors.lightSurface,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.electricBlue,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        headlineLarge: AppTypography.headlineLarge.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.lightTextSecondary,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightTextSecondary,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.lightTextMuted,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.lightTextSecondary,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.lightTextMuted,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.lightTextMuted,
        ),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      surface: AppColors.darkSurface,
      primary: AppColors.electricBlue,
      onPrimary: AppColors.darkTextPrimary,
      secondary: AppColors.electricBlueLight,
      onSecondary: AppColors.darkTextPrimary,
      error: AppColors.critical,
      onError: AppColors.darkTextPrimary,
      onSurface: AppColors.darkTextPrimary,
      outline: AppColors.darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkCanvas,
      colorScheme: colorScheme,
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkCanvas,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
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
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.electricBlue,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        headlineLarge: AppTypography.headlineLarge.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.darkTextMuted,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.darkTextMuted,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.darkTextMuted,
        ),
      ),
    );
  }
}
