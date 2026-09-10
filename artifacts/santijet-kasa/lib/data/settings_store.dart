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

/// Ana sayfada seçili şantiye — hareket ekleme ve liste kapsamı buna bağlı.
class ActiveSantiyeNotifier extends StateNotifier<String> {
  ActiveSantiyeNotifier(this._box) : super(_read(_box));

  final Box _box;
  static const _activeKey = 'activeSantiye';
  static const _legacyKey = 'defaultSantiye';

  static String _read(Box box) {
    final active = (box.get(_activeKey) as String?)?.trim();
    if (active != null && active.isNotEmpty) return active;
    final legacy = (box.get(_legacyKey) as String?)?.trim();
    if (legacy != null && legacy.isNotEmpty) return legacy;
    return 'İZMİT/EFSANE';
  }

  Future<void> setActive(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = trimmed;
    await _box.put(_activeKey, trimmed);
    await _box.put(_legacyKey, trimmed);
  }

  /// Liste değişince aktif şantiye hâlâ geçerli mi?
  Future<void> ensureValid(List<String> santiyeler) async {
    if (santiyeler.contains(state)) return;
    final next =
        santiyeler.isNotEmpty ? santiyeler.first : 'İZMİT/EFSANE';
    await setActive(next);
  }
}

final activeSantiyeProvider =
    StateNotifierProvider<ActiveSantiyeNotifier, String>(
  (ref) => ActiveSantiyeNotifier(ref.watch(settingsBoxProvider)),
);

/// Geriye dönük — activeSantiye ile aynı.
@Deprecated('activeSantiyeProvider kullanın')
final defaultSantiyeProvider = activeSantiyeProvider;

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
