import 'package:flutter/material.dart';

/// ŞantiJET Design System renk paleti.
///
/// ŞantiJET Demir referans projesinden (`artifacts/santijet-demir`) birebir
/// alınmıştır. Ürün ailesi genelinde görsel tutarlılık için renk değerleri
/// aynıdır. BFA'ya özgü modül vurgu renkleri en altta eklenmiştir.
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

  // Kenarlık & ayırıcı
  static const border = Color(0xFF1E293B);
  static const borderSubtle = Color(0xFF334155);

  // Blueprint arka plan
  static const blueprintGrid = Color(0x0B4876DC);

  // ─── BFA'ya özgü modül vurgu renkleri ───────────────────────────────
  // Disiplin ve bölüm renkleri. ŞantiJET paletine uyumlu tutulmuştur.
  static const moduleInsaat = Color(0xFFF59E0B); // turuncu/amber
  static const moduleMekanik = Color(0xFF0EA5E9); // camgöbeği
  static const moduleElektrik = Color(0xFF10B981); // yeşil
  static const moduleFavori = Color(0xFFEAB308); // sarı
  static const moduleKesif = Color(0xFFA855F7); // mor
  static const moduleKatalog = Color(0xFF10B981); // yeşil

  /// Disiplin anahtarına göre vurgu rengi.
  static Color disciplineColor(String discipline) {
    return switch (discipline) {
      'mekanik' => moduleMekanik,
      'elektrik' => moduleElektrik,
      _ => moduleInsaat,
    };
  }
}
