import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Aktif tema: `light` / `dark` / `santijet` / `santijet_pro`.
class ThemeModeNotifier extends StateNotifier<String> {
  ThemeModeNotifier(this._box) : super(_read(_box));

  final Box _box;
  static const _key = 'themeMode';

  static String _read(Box box) {
    final raw = box.get(_key) as String?;
    final normalized = raw == 'gecejet' ? 'santijet_pro' : raw;
    return switch (normalized) {
      'light' || 'dark' || 'santijet' || 'santijet_pro' => normalized!,
      _ => 'santijet_pro',
    };
  }

  Future<void> setThemeMode(String mode) async {
    final next = switch (mode) {
      'light' || 'dark' || 'santijet' || 'santijet_pro' => mode,
      _ => 'santijet_pro',
    };
    state = next;
    await _box.put(_key, next);
  }
}

/// ŞantiJET açık chrome; ŞantiJET Pro koyu chrome; kartlar [AppColors.cardSurface].
ThemeMode themeModeFromSettings(String mode) => switch (mode) {
      'light' || 'santijet' => ThemeMode.light,
      _ => ThemeMode.dark,
    };

String themeLabel(String mode) => switch (mode) {
      'light' => 'Açık',
      'dark' => 'Koyu',
      'santijet' => 'ŞantiJET',
      _ => 'ŞantiJET Pro',
    };

/// Hive `settings` kutusu — bootstrap'ta açılır ve override edilir.
final settingsBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('settingsBoxProvider override edilmeli'),
);

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, String>(
  (ref) => ThemeModeNotifier(ref.watch(settingsBoxProvider)),
);
