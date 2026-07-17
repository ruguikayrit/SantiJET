import 'package:flutter/services.dart';

/// Telefon titreşim geri bildirimi. Ayarlardan kapatılabilir.
abstract final class AppHaptics {
  static bool enabled = true;

  static Future<void> light() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> selection() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> medium() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }
}
