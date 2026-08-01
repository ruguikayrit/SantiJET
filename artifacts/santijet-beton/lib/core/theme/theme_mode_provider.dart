import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Aktif tema: `light` / `dark` / `santijet` / `gecejet` / `system`.
class ThemeModeNotifier extends StateNotifier<String> {
  ThemeModeNotifier(this._box) : super(_read(_box));

  final Box _box;
  static const _key = 'themeMode';

  static String _read(Box box) {
    final raw = box.get(_key) as String?;
    return switch (raw) {
      'light' || 'dark' || 'santijet' || 'gecejet' || 'system' => raw!,
      _ => 'system',
    };
  }

  Future<void> setThemeMode(String mode) async {
    state = mode;
    await _box.put(_key, mode);
  }
}

/// ŞantiJET açık chrome; GeceJET koyu chrome; kartlar [AppColors.cardSurface].
ThemeMode themeModeFromSettings(String mode) => switch (mode) {
      'light' || 'santijet' => ThemeMode.light,
      'dark' || 'gecejet' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

String themeLabel(String mode) => switch (mode) {
      'light' => 'Açık',
      'dark' => 'Koyu',
      'santijet' => 'ŞantiJET',
      'gecejet' => 'GeceJET',
      _ => 'Sistem',
    };

/// Hive `settings` kutusu — bootstrap'ta açılır ve override edilir.
final settingsBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('settingsBoxProvider override edilmeli'),
);

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, String>(
  (ref) => ThemeModeNotifier(ref.watch(settingsBoxProvider)),
);
