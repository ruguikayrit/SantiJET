import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../../core/utils/text_format.dart';
import '../../domain/catalogs/professions.dart';
import '../../domain/catalogs/task_categories.dart';

/// Meslek ve ekip katalogları — varsayılanlar + kullanıcının ekledikleri (Hive).
///
/// Kayıtlar daima başlık biçiminde tutulur (bkz. [titleCaseTr]).
class CatalogNotifier extends StateNotifier<List<String>> {
  CatalogNotifier(this._box, this._key, List<String> defaults)
      : super(_load(_box, _key, defaults));

  final Box _box;
  final String _key;

  static const _legacyAlciAsma = 'Alçı / Asma Tavan';
  static const _alciSiva = 'Alçı Sıva';
  static const _asmaTavan = 'Asma Tavan';

  static List<String> _normalizeList(Iterable<String> raw) {
    final seen = <String>{};
    final out = <String>[];
    for (final e in raw) {
      final t = titleCaseTr(e);
      if (t.isEmpty) continue;
      final key = t.toLowerCase();
      if (seen.add(key)) out.add(t);
    }
    out.sort((a, b) => a.compareTo(b));
    return out;
  }

  static List<String> _load(Box box, String key, List<String> defaults) {
    final raw = box.get(key);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final list = decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (list.isNotEmpty) {
            final migrated = key == 'catalog_teams'
                ? _migrateAlciAsmaTeams(list)
                : list;
            final normalized = _normalizeList(migrated);
            if (jsonEncode(normalized) != jsonEncode(migrated)) {
              box.put(key, jsonEncode(normalized));
            }
            return normalized;
          }
        }
      } catch (_) {}
    }
    return _normalizeList(defaults);
  }

  /// Eski birleşik ekip adını ayrı ekiple değiştirir.
  static List<String> _migrateAlciAsmaTeams(List<String> list) {
    if (!list.any((e) => e == _legacyAlciAsma)) return list;
    final next = <String>[
      for (final e in list)
        if (e != _legacyAlciAsma) e,
    ];
    if (!next.any((e) => e.toLowerCase() == _alciSiva.toLowerCase())) {
      next.add(_alciSiva);
    }
    if (!next.any((e) => e.toLowerCase() == _asmaTavan.toLowerCase())) {
      next.add(_asmaTavan);
    }
    next.sort((a, b) => a.compareTo(b));
    return next;
  }

  void _persist() => _box.put(_key, jsonEncode(state));

  bool add(String name) {
    final trimmed = titleCaseTr(name);
    if (trimmed.isEmpty) return false;
    final exists = state.any((e) => e.toLowerCase() == trimmed.toLowerCase());
    if (exists) return false;
    state = [...state, trimmed]..sort((a, b) => a.compareTo(b));
    _persist();
    return true;
  }

  bool rename(String oldName, String newName) {
    final trimmed = titleCaseTr(newName);
    if (trimmed.isEmpty) return false;
    final idx = state.indexOf(oldName);
    if (idx < 0) return false;
    final exists = state.any(
      (e) => e.toLowerCase() == trimmed.toLowerCase() && e != oldName,
    );
    if (exists) return false;
    final next = [...state];
    next[idx] = trimmed;
    next.sort((a, b) => a.compareTo(b));
    state = next;
    _persist();
    return true;
  }

  void remove(String name) {
    state = state.where((e) => e != name).toList();
    _persist();
  }

  void resetToDefaults(List<String> defaults) {
    state = _normalizeList(defaults);
    _persist();
  }

  void replaceAll(List<String> items) {
    state = _normalizeList(items);
    _persist();
  }
}

final professionsProvider =
    StateNotifierProvider<CatalogNotifier, List<String>>((ref) {
  return CatalogNotifier(
    ref.watch(settingsBoxProvider),
    'catalog_professions',
    ProfessionCatalog.defaultProfessions,
  );
});

final teamsProvider =
    StateNotifierProvider<CatalogNotifier, List<String>>((ref) {
  return CatalogNotifier(
    ref.watch(settingsBoxProvider),
    'catalog_teams',
    ProfessionCatalog.defaultTradeGroups,
  );
});

final taskCategoriesProvider =
    StateNotifierProvider<CatalogNotifier, List<String>>((ref) {
  return CatalogNotifier(
    ref.watch(settingsBoxProvider),
    'catalog_task_categories',
    TaskCategoryCatalog.defaults,
  );
});
