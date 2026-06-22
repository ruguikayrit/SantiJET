import 'package:flutter/material.dart';

/// Figma Make Design System — 14 renk paleti.
abstract final class AppColors {
  // Arka plan
  static const canvas = Color(0xFF05070A);
  static const surface = Color(0xFF0D1117);
  static const surfaceElevated = Color(0xFF151B26);
  static const surfaceHighlight = Color(0xFF1E293B);

  // Marka
  static const electricBlue = Color(0xFF0055FF);
  static const electricBlueLight = Color(0xFF3B82F6);
  static const electricBlueGlow = Color(0x334877DC);

  // Metin
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xB3FFFFFF);
  static const textMuted = Color(0x66FFFFFF);
  static const textDisabled = Color(0x4DFFFFFF);

  // Durum
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const critical = Color(0xFFEF4444);
  static const info = Color(0xFF0EA5E9);
  static const partial = Color(0xFFA855F7);

  // Çap gradyanı (Figma: Ø8 yeşil → Ø28 turuncu)
  static const diameter8 = Color(0xFF10B981);
  static const diameter10 = Color(0xFF06B6D4);
  static const diameter12 = Color(0xFF3B82F6);
  static const diameter14 = Color(0xFF8B5CF6);
  static const diameter16 = Color(0xFFF59E0B);
  static const diameter20 = Color(0xFFEF4444);
  static const diameter22 = Color(0xFFDC2626);
  static const diameter28 = Color(0xFFF97316);

  // Kenarlık & ayırıcı
  static const border = Color(0xFF1E293B);
  static const borderSubtle = Color(0xFF334155);

  // Blueprint arka plan
  static const blueprintGrid = Color(0x0B4876DC);
  static const rebarOverlay = Color(0x0AFFFFFF);

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
