import 'package:flutter/material.dart';

/// Figma Make Design System — açık/koyu uyumlu palet.
///
/// Marka mavileri ve durum renkleri temadan bağımsızdır.
/// Yüzey / metin / kenarlık [applyBrightness] ile temaya göre değişir.
///
/// Önemli: Bu getter'lar [Theme.of] bağımlılığı oluşturmaz. Tema değişiminde
/// ekranın yeniden çizilmesi için [ThemeRebuildGate] / [AppColorsThemeSync]
/// veya [Theme.of] kullanılmalıdır.
abstract final class AppColors {
  static Brightness _brightness = Brightness.dark;

  /// MaterialApp builder içinde her karede çağrılır.
  static void applyBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  static bool get isDark => _brightness == Brightness.dark;
  static bool get isLight => _brightness == Brightness.light;

  // —— Koyu sabitler ——
  static const darkCanvas = Color(0xFF05070A);
  static const darkSurface = Color(0xFF0D1117);
  static const darkSurfaceElevated = Color(0xFF151B26);
  static const darkSurfaceHighlight = Color(0xFF1E293B);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xB3FFFFFF);
  static const darkTextMuted = Color(0x66FFFFFF);
  static const darkTextDisabled = Color(0x4DFFFFFF);
  static const darkBorder = Color(0xFF1E293B);
  static const darkBorderSubtle = Color(0xFF334155);

  // —— Açık sabitler (logo: siyah ŞANTİ + mavi JET; saydam zemin) ——
  // Soğuk çelik / beton: logo mürekkebine yakın ink, mavi marka vurgusu.
  static const lightCanvas = Color(0xFFE8EDF4);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFF7F9FC);
  static const lightSurfaceHighlight = Color(0xFFDDE5F0);
  static const lightTextPrimary = Color(0xFF0B1220);
  static const lightTextSecondary = Color(0xFF3A465A);
  static const lightTextMuted = Color(0xFF6B7A90);
  static const lightTextDisabled = Color(0xFF9AA8BC);
  static const lightBorder = Color(0xFFD5DEEA);
  static const lightBorderSubtle = Color(0xFFB8C5D6);

  // Arka plan (tema duyarlı)
  static Color get canvas => isDark ? darkCanvas : lightCanvas;
  static Color get surface => isDark ? darkSurface : lightSurface;
  static Color get surfaceElevated =>
      isDark ? darkSurfaceElevated : lightSurfaceElevated;
  static Color get surfaceHighlight =>
      isDark ? darkSurfaceHighlight : lightSurfaceHighlight;

  // Marka — temadan bağımsız
  static const electricBlue = Color(0xFF0055FF);
  static const electricBlueLight = Color(0xFF3B82F6);
  static const electricBlueGlow = Color(0x334877DC);

  // Metin (tema duyarlı)
  static Color get textPrimary => isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      isDark ? darkTextSecondary : lightTextSecondary;
  static Color get textMuted => isDark ? darkTextMuted : lightTextMuted;
  static Color get textDisabled =>
      isDark ? darkTextDisabled : lightTextDisabled;

  // Durum — temadan bağımsız
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const critical = Color(0xFFEF4444);
  static const info = Color(0xFF0EA5E9);
  static const partial = Color(0xFFA855F7);

  // Çap gradyanı
  static const diameter8 = Color(0xFF10B981);
  static const diameter10 = Color(0xFF06B6D4);
  static const diameter12 = Color(0xFF3B82F6);
  static const diameter14 = Color(0xFF8B5CF6);
  static const diameter16 = Color(0xFFF59E0B);
  static const diameter20 = Color(0xFFEF4444);
  static const diameter22 = Color(0xFFDC2626);
  static const diameter28 = Color(0xFFF97316);

  // Kenarlık
  static Color get border => isDark ? darkBorder : lightBorder;
  static Color get borderSubtle =>
      isDark ? darkBorderSubtle : lightBorderSubtle;

  // Blueprint / overlay
  static const blueprintGrid = Color(0x0B4876DC);
  static Color get rebarOverlay =>
      isDark ? const Color(0x0AFFFFFF) : const Color(0x0A0B1220);

  /// Hafif yükselti gölgesi — açık temada kart/nav ayrımı.
  static List<BoxShadow> get elevationSoft => isDark
      ? const []
      : [
          BoxShadow(
            color: Color(0x140B1220),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ];

  /// Wordmark asset — koyuda beyaz harf, açıkta siyah harf; mavi aynı.
  static String wordmarkAssetFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? 'assets/images/splash_wordmark.png'
        : 'assets/images/splash_wordmark_light.png';
  }

  static Color diameterColor(int diameter) {
    return switch (diameter) {
      8 => diameter8,
      10 => diameter10,
      12 => diameter12,
      14 => diameter14,
      16 => diameter16,
      20 => diameter20,
      22 => diameter22,
      28 => diameter28,
      _ => electricBlueLight,
    };
  }
}
