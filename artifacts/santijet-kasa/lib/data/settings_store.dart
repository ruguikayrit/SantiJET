import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../core/theme/theme_mode_provider.dart';

final santiyelerBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('santiyelerBoxProvider override edilmeli'),
);

class SantiyelerNotifier extends StateNotifier<List<String>> {
  SantiyelerNotifier(this._box) : super(_read(_box));

  final Box _box;
  static const _key = 'items';

  static List<String> _read(Box box) {
    final raw = box.get(_key);
    if (raw is! List) return const ['İZMİT/EFSANE'];
    final list = raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    return list.isEmpty ? const ['İZMİT/EFSANE'] : list;
  }

  Future<void> _persist() async {
    await _box.put(_key, state);
  }

  Future<void> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (state.any((s) => s.toLowerCase() == trimmed.toLowerCase())) return;
    state = [...state, trimmed];
    await _persist();
  }

  Future<void> remove(String name) async {
    state = state.where((s) => s != name).toList();
    if (state.isEmpty) state = const ['İZMİT/EFSANE'];
    await _persist();
  }

  Future<void> replaceAll(List<String> names) async {
    final cleaned = names
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    state = cleaned.isEmpty ? const ['İZMİT/EFSANE'] : cleaned;
    await _persist();
  }
}

final santiyelerProvider =
    StateNotifierProvider<SantiyelerNotifier, List<String>>(
  (ref) => SantiyelerNotifier(ref.watch(santiyelerBoxProvider)),
);

class DefaultSantiyeNotifier extends StateNotifier<String> {
  DefaultSantiyeNotifier(this._box) : super(_read(_box));

  final Box _box;
  static const _key = 'defaultSantiye';

  static String _read(Box box) =>
      (box.get(_key) as String?)?.trim().isNotEmpty == true
          ? box.get(_key) as String
          : 'İZMİT/EFSANE';

  Future<void> setDefault(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = trimmed;
    await _box.put(_key, trimmed);
  }
}

final defaultSantiyeProvider =
    StateNotifierProvider<DefaultSantiyeNotifier, String>(
  (ref) => DefaultSantiyeNotifier(ref.watch(settingsBoxProvider)),
);

/// Tek seferlik lisans iskeleti — store bağlama sonra.
class LicenseNotifier extends StateNotifier<bool> {
  LicenseNotifier(this._box) : super(_read(_box));

  final Box _box;
  static const _key = 'oneTimeLicenseUnlocked';

  static bool _read(Box box) => box.get(_key) == true;

  Future<void> setUnlocked(bool value) async {
    state = value;
    await _box.put(_key, value);
  }
}

final licenseUnlockedProvider =
    StateNotifierProvider<LicenseNotifier, bool>(
  (ref) => LicenseNotifier(ref.watch(settingsBoxProvider)),
);
