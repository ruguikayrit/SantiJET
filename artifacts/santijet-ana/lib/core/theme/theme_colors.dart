import 'package:flutter/material.dart';

/// Marka splash sabitleri — Demir / Puantaj ile aynı.
abstract final class BrandSplash {
  static const Color darkCanvas = Color(0xFF05070A);
  static const Color electricBlue = Color(0xFF0055FF);
  static const Color electricBlueLight = Color(0xFF3377FF);
  static const Color electricBlueGlow = Color(0x660055FF);
  static const Color darkBorder = Color(0xFF1A2332);
  static const Color blueprintGrid = Color(0x14FFFFFF);
}

/// RN `ThemeColors` — birebir alanlar.
class ThemeColors {
  const ThemeColors({
    required this.text,
    required this.tint,
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.success,
    required this.successForeground,
    required this.warning,
    required this.warningForeground,
    required this.border,
    required this.input,
    required this.orange,
    required this.navy,
    required this.darkNavy,
  });

  final Color text;
  final Color tint;
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color success;
  final Color successForeground;
  final Color warning;
  final Color warningForeground;
  final Color border;
  final Color input;
  final Color orange;
  final Color navy;
  final Color darkNavy;

  factory ThemeColors.fromHex({
    required String text,
    required String tint,
    required String background,
    required String foreground,
    required String card,
    required String cardForeground,
    required String primary,
    required String primaryForeground,
    required String secondary,
    required String secondaryForeground,
    required String muted,
    required String mutedForeground,
    required String accent,
    required String accentForeground,
    required String destructive,
    required String destructiveForeground,
    required String success,
    required String successForeground,
    required String warning,
    required String warningForeground,
    required String border,
    required String input,
    required String orange,
    required String navy,
    required String darkNavy,
  }) {
    return ThemeColors(
      text: _hex(text),
      tint: _hex(tint),
      background: _hex(background),
      foreground: _hex(foreground),
      card: _hex(card),
      cardForeground: _hex(cardForeground),
      primary: _hex(primary),
      primaryForeground: _hex(primaryForeground),
      secondary: _hex(secondary),
      secondaryForeground: _hex(secondaryForeground),
      muted: _hex(muted),
      mutedForeground: _hex(mutedForeground),
      accent: _hex(accent),
      accentForeground: _hex(accentForeground),
      destructive: _hex(destructive),
      destructiveForeground: _hex(destructiveForeground),
      success: _hex(success),
      successForeground: _hex(successForeground),
      warning: _hex(warning),
      warningForeground: _hex(warningForeground),
      border: _hex(border),
      input: _hex(input),
      orange: _hex(orange),
      navy: _hex(navy),
      darkNavy: _hex(darkNavy),
    );
  }

  static Color _hex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

/// Ana sayfa kart düzeni — RN `ThemeLayout`.
enum ThemeLayout { defaultLayout, hivis, steel }

class ThemePreview {
  const ThemePreview({
    required this.bg,
    required this.primary,
    required this.secondary,
  });

  final Color bg;
  final Color primary;
  final Color secondary;
}

/// RN `ThemeDefinition`.
class ThemeDefinition {
  const ThemeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.isDark,
    required this.preview,
    required this.colors,
    this.layout = ThemeLayout.defaultLayout,
  });

  final String id;
  final String name;
  final String description;
  final bool isDark;
  final ThemeLayout layout;
  final ThemePreview preview;
  final ThemeColors colors;
}
