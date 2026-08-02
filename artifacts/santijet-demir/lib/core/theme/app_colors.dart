import 'package:flutter/material.dart';

/// Uygulama renk paleti — açık / koyu / ŞantiJET / GeceJET (hibritler).
enum AppColorPalette { light, dark, santijet, gecejet }

/// Figma Make Design System — açık/koyu/hibrit paletler.
///
/// Marka mavileri ve durum renkleri temadan bağımsızdır.
/// Yüzey / metin / kenarlık [applyPalette] ile temaya göre değişir.
///
/// ŞantiJET: açık iskelet (canvas) + koyu özet/uyarı kartları ([cardSurface]).
/// GeceJET: ŞantiJET'in tersi — koyu iskelet + açık özet kartları.
///
/// Önemli: Bu getter'lar [Theme.of] bağımlılığı oluşturmaz. Tema değişiminde
/// ekranın yeniden çizilmesi için [ThemeRebuildGate] / [AppColorsThemeSync]
/// veya [Theme.of] kullanılmalıdır.
abstract final class AppColors {
  static AppColorPalette _palette = AppColorPalette.dark;

  /// Geriye dönük — yalnızca brightness (system/light/dark).
  static void applyBrightness(Brightness brightness) {
    _palette = brightness == Brightness.dark
        ? AppColorPalette.dark
        : AppColorPalette.light;
  }

  /// Ayarlar tema modu + sistem brightness.
  static void applyPaletteFromMode(String mode, Brightness systemBrightness) {
    _palette = switch (mode) {
      'light' => AppColorPalette.light,
      'dark' => AppColorPalette.dark,
      'santijet' => AppColorPalette.santijet,
      'gecejet' => AppColorPalette.gecejet,
      _ => systemBrightness == Brightness.dark
          ? AppColorPalette.dark
          : AppColorPalette.light,
    };
  }

  static void applyPalette(AppColorPalette palette) {
    _palette = palette;
  }

  static AppColorPalette get palette => _palette;
  static bool get isDark => _palette == AppColorPalette.dark;
  static bool get isLight => _palette == AppColorPalette.light;
  static bool get isSantijet => _palette == AppColorPalette.santijet;
  static bool get isGecejet => _palette == AppColorPalette.gecejet;

  /// Koyu chrome (iskelet) — koyu ve GeceJET.
  static bool get useDarkChrome => isDark || isGecejet;

  /// Özet / brifing / uyarı kartlarında koyu yüzey kullan.
  static bool get useDarkCards => isDark || isSantijet;

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

  // —— Açık sabitler ——
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

  // Chrome (iskelet) — ŞantiJET açık; GeceJET koyu
  static Color get canvas => useDarkChrome ? darkCanvas : lightCanvas;
  static Color get surface => useDarkChrome ? darkSurface : lightSurface;
  static Color get surfaceElevated =>
      useDarkChrome ? darkSurfaceElevated : lightSurfaceElevated;
  static Color get surfaceHighlight =>
      useDarkChrome ? darkSurfaceHighlight : lightSurfaceHighlight;

  // Marka
  static const electricBlue = Color(0xFF0055FF);
  static const electricBlueLight = Color(0xFF3B82F6);
  static const electricBlueGlow = Color(0x334877DC);

  // Genel metin — chrome ile uyumlu
  static Color get textPrimary =>
      useDarkChrome ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      useDarkChrome ? darkTextSecondary : lightTextSecondary;
  static Color get textMuted =>
      useDarkChrome ? darkTextMuted : lightTextMuted;
  static Color get textDisabled =>
      useDarkChrome ? darkTextDisabled : lightTextDisabled;

  // Durum
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const critical = Color(0xFFEF4444);
  static const info = Color(0xFF0EA5E9);
  static const partial = Color(0xFFA855F7);

  // Çap
  static const diameter8 = Color(0xFF10B981);
  static const diameter10 = Color(0xFF06B6D4);
  static const diameter12 = Color(0xFF3B82F6);
  static const diameter14 = Color(0xFF8B5CF6);
  static const diameter16 = Color(0xFFF59E0B);
  static const diameter20 = Color(0xFFEF4444);
  static const diameter22 = Color(0xFFDC2626);
  static const diameter28 = Color(0xFFF97316);

  // Kenarlık (chrome)
  static Color get border => useDarkChrome ? darkBorder : lightBorder;
  static Color get borderSubtle =>
      useDarkChrome ? darkBorderSubtle : lightBorderSubtle;

  // —— Kart paleti (özet / brifing / uyarı / sipariş / fire) ——
  // ŞantiJET/koyu: koyu yüzey + açık metin.
  // GeceJET: açık tema kartı (beyaz yüzey + koyu mürekkep).
  static Color get cardSurface => useDarkCards
      ? darkSurfaceElevated
      : (isGecejet ? lightSurface : lightSurfaceElevated);
  static Color get cardSurfaceHighlight =>
      useDarkCards ? darkSurfaceHighlight : lightSurfaceHighlight;
  static Color get cardBorder => useDarkCards ? darkBorder : lightBorder;
  static Color get cardBorderSubtle =>
      useDarkCards ? darkBorderSubtle : lightBorderSubtle;
  static Color get cardTextPrimary =>
      useDarkCards ? darkTextPrimary : lightTextPrimary;
  static Color get cardTextSecondary =>
      useDarkCards ? darkTextSecondary : lightTextSecondary;
  static Color get cardTextMuted =>
      useDarkCards ? darkTextMuted : lightTextMuted;
  static Color get cardTextDisabled =>
      useDarkCards ? darkTextDisabled : lightTextDisabled;

  /// Hibrit özet kartı: ŞantiJET koyu / GeceJET açık.
  static bool get useHybridCards => isSantijet || isGecejet;

  static List<BoxShadow> get cardElevation {
    if (useDarkCards) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: isSantijet ? 0.22 : 0.35),
          blurRadius: isSantijet ? 12 : 8,
          offset: const Offset(0, 3),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Color(isGecejet ? 0x59000000 : 0x140B1220),
        blurRadius: isGecejet ? 14 : 16,
        offset: Offset(0, isGecejet ? 3 : 4),
      ),
    ];
  }

  // Blueprint / overlay
  static const blueprintGrid = Color(0x0B4876DC);
  static Color get rebarOverlay =>
      useDarkChrome ? const Color(0x0AFFFFFF) : const Color(0x0A0B1220);

  /// Hafif yükselti gölgesi — açık chrome'da kart/nav ayrımı.
  static List<BoxShadow> get elevationSoft => useDarkChrome
      ? const []
      : [
          const BoxShadow(
            color: Color(0x140B1220),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ];

  /// Wordmark — koyu chrome'da beyaz; açık ve ŞantiJET'te siyah harf.
  static String wordmarkAssetFor(Brightness brightness) {
    return brightness == Brightness.dark || isGecejet
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
