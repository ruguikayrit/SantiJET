import 'package:flutter/material.dart';

/// ŞantiJET marka renk token'ları.
///
/// NOT (Faz 2): Bu token'lar React Native BFA'nın `klasik` temasından
/// türetilmiş başlangıç değerleridir. ŞantiJET Demir Flutter referans projesi
/// erişime açıldığında, `SJColors` ve `SJTheme` Demir tasarım sistemiyle
/// birebir hizalanacaktır.
class SJColors {
  const SJColors._();

  // Marka çekirdeği
  static const Color brandOrange = Color(0xFFE85D04);
  static const Color brandNavy = Color(0xFF16213E);
  static const Color brandDarkNavy = Color(0xFF0F3460);

  // Disiplin renkleri (BFA modülleri)
  static const Color insaat = Color(0xFFD97706);
  static const Color mekanik = Color(0xFF0891B2);
  static const Color elektrik = Color(0xFF16A34A);
  static const Color favori = Color(0xFFEAB308);
  static const Color kesif = Color(0xFF7C3AED);
  static const Color katalog = Color(0xFF16A34A);

  // Durum renkleri
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color destructive = Color(0xFFDC2626);

  // Açık tema yüzeyleri
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightForeground = Color(0xFF1A1A2E);
  static const Color lightMuted = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E7EB);

  // Koyu tema yüzeyleri
  static const Color darkBackground = Color(0xFF0B1428);
  static const Color darkSurface = Color(0xFF142042);
  static const Color darkForeground = Color(0xFFE8ECF5);
  static const Color darkMuted = Color(0xFF9AA6C2);
  static const Color darkBorder = Color(0xFF22305A);
}
