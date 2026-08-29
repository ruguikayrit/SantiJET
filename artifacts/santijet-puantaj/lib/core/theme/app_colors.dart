import 'package:flutter/material.dart';

/// Uygulama renk paleti — açık / koyu / ŞantiJET / ŞantiJET Pro (hibritler).
enum AppColorPalette { light, dark, santijet, santijetPro }

/// Figma Make Design System — açık/koyu/hibrit paletler.
///
/// ŞantiJET: açık iskelet (canvas) + koyu özet/uyarı kartları ([cardSurface]).
/// ŞantiJET Pro: ŞantiJET'in tersi — koyu iskelet + açık özet kartları.
abstract final class AppColors {
  static AppColorPalette _palette = AppColorPalette.santijetPro;

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
      'santijet_pro' || 'gecejet' => AppColorPalette.santijetPro,
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
  static bool get isSantijetPro => _palette == AppColorPalette.santijetPro;

  /// Koyu chrome (iskelet) — koyu ve ŞantiJET Pro.
  static bool get useDarkChrome => isDark || isSantijetPro;

  /// Özet / brifing / uyarı kartlarında koyu yüzey kullan.
  /// ŞantiJET Pro her zaman açık kart + koyu mürekkep (koyu chrome üzerinde).
  static bool get useDarkCards => isSantijet || (isDark && !isSantijetPro);

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

  // Chrome (iskelet) — ŞantiJET açık; ŞantiJET Pro koyu
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
  static Color get border => useDarkChrome ? darkBorder : lightBorder;
  static Color get borderSubtle =>
      useDarkChrome ? darkBorderSubtle : lightBorderSubtle;

  // —— Kart paleti (özet / brifing / uyarı) ——
  // ŞantiJET Pro: açık tema kartları (beyaz yüzey + koyu mürekkep).
  static Color get cardSurface => useDarkCards
      ? darkSurfaceElevated
      : (isSantijetPro ? lightSurface : lightSurfaceElevated);
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

  /// Hibrit özet kartı: ŞantiJET koyu / ŞantiJET Pro açık.
  static bool get useHybridCards => isSantijet || isSantijetPro;

  /// Arka plan koyuysa açık mürekkep; açıkta / parlak dolguda koyu mürekkep.
  ///
  /// Eşik 0.35 — amber (`#F59E0B`, L≈0.44) ve yarım gün (`#D97706`, L≈0.36)
  /// gibi parlak durum renklerinde beyaz yazının kaybolmasını engeller.
  static Color readableOn(Color background) {
    final luminance = background.computeLuminance();
    return luminance < 0.35 ? darkTextPrimary : lightTextPrimary;
  }

  static Color readableSecondaryOn(Color background) {
    final luminance = background.computeLuminance();
    return luminance < 0.35 ? darkTextSecondary : lightTextSecondary;
  }

  static Color readableMutedOn(Color background) {
    final luminance = background.computeLuminance();
    return luminance < 0.35 ? darkTextMuted : lightTextMuted;
  }

  /// Durum / uyarı rengini metin mürekkebi olarak kullanırken:
  /// açık yüzeylerde rengi koyulaştırır (AA kontrast), koyu yüzeyde bırakır.
  static Color statusInk(Color status, {required Color surface}) {
    if (surface.computeLuminance() < 0.45) return status;
    // Açık zemin: doygun rengi koyu mürekkebe yaklaştır.
    return Color.lerp(status, lightTextPrimary, 0.42) ?? status;
  }

  /// Kart yüzeyi üzerinde durum mürekkebi.
  static Color statusInkOnCard(Color status) =>
      statusInk(status, surface: cardSurface);

  /// Chrome / canvas üzerinde durum mürekkebi.
  static Color statusInkOnChrome(Color status) =>
      statusInk(status, surface: canvas);

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
    // Açık kartlar — ŞantiJET Pro'da koyu zeminde daha belirgin gölge
    return [
      BoxShadow(
        color: Color(isSantijetPro ? 0x59000000 : 0x140B1220),
        blurRadius: isSantijetPro ? 14 : 16,
        offset: Offset(0, isSantijetPro ? 3 : 4),
      ),
    ];
  }

  // Blueprint / overlay
  static const blueprintGrid = Color(0x0B4876DC);

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
    return brightness == Brightness.dark || isSantijetPro
        ? 'assets/images/splash_wordmark.png'
        : 'assets/images/splash_wordmark_light.png';
  }

  /// BFA ailesi modül vurguları (ürün uyumu).
  static const moduleInsaat = Color(0xFFF59E0B);
  /// Mekanik — gök mavisi yerine mor; birincil mavi ile karışmasın.
  static const moduleMekanik = Color(0xFF9333EA);
  static const moduleElektrik = Color(0xFF10B981);
  static const moduleFavori = Color(0xFFEAB308);
  static const moduleKesif = Color(0xFFA855F7);
  static const moduleKatalog = Color(0xFF10B981);
}
