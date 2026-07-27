import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../../domain/catalogs/professions.dart';

/// Meslek ve ekip katalogları — varsayılanlar + kullanıcının ekledikleri (Hive).
class CatalogNotifier extends StateNotifier<List<String>> {
  CatalogNotifier(this._box, this._key, List<String> defaults)
      : super(_load(_box, _key, defaults));

  final Box _box;
  final String _key;

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
          if (list.isNotEmpty) return list;
        }
      } catch (_) {}
    }
    return List<String>.from(defaults);
  }

  void _persist() => _box.put(_key, jsonEncode(state));

  bool add(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final exists = state.any((e) => e.toLowerCase() == trimmed.toLowerCase());
    if (exists) return false;
    state = [...state, trimmed]..sort((a, b) => a.compareTo(b));
    _persist();
    return true;
  }

  void rename(String oldName, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final idx = state.indexOf(oldName);
    if (idx < 0) return;
    final exists = state.any(
      (e) => e.toLowerCase() == trimmed.toLowerCase() && e != oldName,
    );
    if (exists) return;
    final next = [...state];
    next[idx] = trimmed;
    next.sort((a, b) => a.compareTo(b));
    state = next;
    _persist();
  }

  void remove(String name) {
    state = state.where((e) => e != name).toList();
    _persist();
  }

  void resetToDefaults(List<String> defaults) {
    state = List<String>.from(defaults);
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
