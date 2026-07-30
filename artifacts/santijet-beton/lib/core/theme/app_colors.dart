import 'package:flutter/material.dart';

/// Uygulama renk paleti — açık / koyu / ŞantiJET (hibrit). Demir ile aynı.
enum AppColorPalette { light, dark, santijet }

/// Figma Make Design System — açık/koyu/ŞantiJET uyumlu palet.
///
/// ŞantiJET: açık iskelet (canvas) + koyu özet/uyarı kartları ([cardSurface]).
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

  // Chrome (iskelet) — ŞantiJET'te açık kalır
  static Color get canvas => isDark ? darkCanvas : lightCanvas;
  static Color get surface => isDark ? darkSurface : lightSurface;
  static Color get surfaceElevated =>
      isDark ? darkSurfaceElevated : lightSurfaceElevated;
  static Color get surfaceHighlight =>
      isDark ? darkSurfaceHighlight : lightSurfaceHighlight;

  // Marka
  static const electricBlue = Color(0xFF0055FF);
  static const electricBlueLight = Color(0xFF3B82F6);
  static const electricBlueGlow = Color(0x334877DC);

  // Genel metin — chrome ile uyumlu (ŞantiJET'te koyu mürekkep)
  static Color get textPrimary => isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      isDark ? darkTextSecondary : lightTextSecondary;
  static Color get textMuted => isDark ? darkTextMuted : lightTextMuted;
  static Color get textDisabled =>
      isDark ? darkTextDisabled : lightTextDisabled;

  /// Tipografi varsayılanı (açık chrome mürekkebi).
  static const inkPrimary = lightTextPrimary;
  static const inkSecondary = lightTextSecondary;
  static const inkMuted = lightTextMuted;

  static Color inkFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;

  static Color inkSecondaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;

  static Color inkMutedFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextMuted : lightTextMuted;

  // Durum
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const critical = Color(0xFFEF4444);
  static const info = Color(0xFF0EA5E9);
  static const partial = Color(0xFFA855F7);

  // Kenarlık (chrome)
  static Color get border => isDark ? darkBorder : lightBorder;
  static Color get borderSubtle =>
      isDark ? darkBorderSubtle : lightBorderSubtle;

  // —— Kart paleti (özet / brifing / uyarı) ——
  static Color get cardSurface =>
      useDarkCards ? darkSurfaceElevated : lightSurfaceElevated;
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

  /// Arka plan koyuysa her zaman açık mürekkep; açıkta koyu mürekkep.
  /// Koyu-üzerine-koyu / açık-üzerine-açık kombinasyonunu engeller.
  static Color readableOn(Color background) {
    final luminance = background.computeLuminance();
    return luminance < 0.45 ? darkTextPrimary : lightTextPrimary;
  }

  static Color readableSecondaryOn(Color background) {
    final luminance = background.computeLuminance();
    return luminance < 0.45 ? darkTextSecondary : lightTextSecondary;
  }

  static Color readableMutedOn(Color background) {
    final luminance = background.computeLuminance();
    return luminance < 0.45 ? darkTextMuted : lightTextMuted;
  }

  static List<BoxShadow> get cardElevation => useDarkCards
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSantijet ? 0.22 : 0.35),
            blurRadius: isSantijet ? 12 : 8,
            offset: const Offset(0, 3),
          ),
        ]
      : elevationSoft;

  // Blueprint / overlay
  static const blueprintGrid = Color(0x0B4876DC);

  /// Hafif yükselti gölgesi — açık chrome'da kart/nav ayrımı.
  static List<BoxShadow> get elevationSoft => isDark
      ? const []
      : [
          const BoxShadow(
            color: Color(0x140B1220),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ];

  /// Wordmark — koyuda beyaz; açık ve ŞantiJET'te siyah harf.
  static String wordmarkAssetFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? 'assets/images/splash_wordmark.png'
        : 'assets/images/splash_wordmark_light.png';
  }

  /// BFA ailesi modül vurguları (ürün uyumu).
  static const moduleInsaat = Color(0xFFF59E0B);
  static const moduleMekanik = Color(0xFF0EA5E9);
  static const moduleElektrik = Color(0xFF10B981);
  static const moduleFavori = Color(0xFFEAB308);
  static const moduleKesif = Color(0xFFA855F7);
  static const moduleKatalog = Color(0xFF10B981);
}
