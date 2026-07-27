import 'package:flutter/material.dart';

/// ŞantiJET Design System renk paleti — Demir ile aynı marka değerleri.
///
/// Açık/koyu metin için [inkPrimary] / [inkFor] kullanılır; sabit koyu
/// [textPrimary] geriye dönük uyumluluk içindir.
abstract final class AppColors {
  // Arka plan (koyu varsayılan sabitler)
  static const canvas = Color(0xFF05070A);
  static const darkCanvas = Color(0xFF05070A);
  static const surface = Color(0xFF0D1117);
  static const surfaceElevated = Color(0xFF151B26);
  static const surfaceHighlight = Color(0xFF1E293B);

  // Açık tema yüzeyleri (Demir lightCanvas / surface)
  static const lightCanvas = Color(0xFFE8EDF4);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFF7F9FC);

  // Marka
  static const electricBlue = Color(0xFF0055FF);
  static const electricBlueLight = Color(0xFF3B82F6);
  static const electricBlueGlow = Color(0x334877DC);

  // Metin — koyu tema sabitleri
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xB3FFFFFF);
  static const textMuted = Color(0x66FFFFFF);
  static const textDisabled = Color(0x4DFFFFFF);

  // Metin — açık tema (Demir lightText*)
  static const lightTextPrimary = Color(0xFF0B1220);
  static const lightTextSecondary = Color(0xFF3A465A);
  static const lightTextMuted = Color(0xFF6B7A90);

  /// Tipografi varsayılanı (açık chrome mürekkebi — Demir light textPrimary).
  static const inkPrimary = lightTextPrimary;
  static const inkSecondary = lightTextSecondary;
  static const inkMuted = lightTextMuted;

  static Color inkFor(Brightness brightness) =>
      brightness == Brightness.dark ? textPrimary : lightTextPrimary;

  static Color inkSecondaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? textSecondary : lightTextSecondary;

  static Color inkMutedFor(Brightness brightness) =>
      brightness == Brightness.dark ? textMuted : lightTextMuted;

  // Durum
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const critical = Color(0xFFEF4444);
  static const info = Color(0xFF0EA5E9);
  static const partial = Color(0xFFA855F7);

  // Kenarlık & ayırıcı
  static const border = Color(0xFF1E293B);
  static const borderSubtle = Color(0xFF334155);
  static const darkBorder = Color(0xFF1E293B);
  static const lightBorder = Color(0xFFD5DEEA);

  // Blueprint arka plan
  static const blueprintGrid = Color(0x0B4876DC);

  /// Wordmark — koyuda beyaz+mavi; açıkta siyah+mavi (Demir ile aynı).
  static String wordmarkAssetFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? 'assets/images/splash_wordmark.png'
        : 'assets/images/splash_wordmark_light.png';
  }

  /// BFA'ya özgü modül vurgu renkleri (ürün ailesi uyumu için korunur).
  static const moduleInsaat = Color(0xFFF59E0B);
  static const moduleMekanik = Color(0xFF0EA5E9);
  static const moduleElektrik = Color(0xFF10B981);
  static const moduleFavori = Color(0xFFEAB308);
  static const moduleKesif = Color(0xFFA855F7);
  static const moduleKatalog = Color(0xFF10B981);
}
