import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../bootstrap.dart';
import 'app_themes.dart';
import 'theme_colors.dart';

const _themeStorageKey = 'santiye_theme_id_v1';

class ThemeNotifier extends StateNotifier<String> {
  ThemeNotifier(this._box) : super(AppThemes.defaultThemeId) {
    final stored = _box.get(_themeStorageKey) as String?;
    if (stored != null && AppThemes.themes.any((t) => t.id == stored)) {
      state = stored;
    }
  }

  final Box _box;

  ThemeDefinition get theme => AppThemes.getTheme(state);

  void setThemeId(String id) {
    if (!AppThemes.themes.any((t) => t.id == id)) return;
    state = id;
    _box.put(_themeStorageKey, id);
  }
}

final themeIdProvider =
    StateNotifierProvider<ThemeNotifier, String>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return ThemeNotifier(box);
});

final themeDefinitionProvider = Provider<ThemeDefinition>((ref) {
  final id = ref.watch(themeIdProvider);
  return AppThemes.getTheme(id);
});

/// Alias — bazı ekranlar `themeProvider` adını kullanır.
final themeProvider = themeDefinitionProvider;
