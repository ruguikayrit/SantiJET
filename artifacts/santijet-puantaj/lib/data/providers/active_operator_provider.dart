import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../../domain/entities/person.dart';
import 'app_data_provider.dart';

/// Cihazda “ben kimim” — görev görünürlüğü bu kişiye göre filtrelenir.
class ActiveOperatorNotifier extends StateNotifier<String?> {
  ActiveOperatorNotifier(this._box) : super(_read(_box));

  final Box _box;
  static const _key = 'activeOperatorId';

  static String? _read(Box box) {
    final raw = box.get(_key);
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  void set(String? personId) {
    final id = personId?.trim();
    if (id == null || id.isEmpty) {
      state = null;
      _box.delete(_key);
      return;
    }
    state = id;
    _box.put(_key, id);
  }

  void clear() => set(null);
}

final activeOperatorIdProvider =
    StateNotifierProvider<ActiveOperatorNotifier, String?>((ref) {
  return ActiveOperatorNotifier(ref.watch(settingsBoxProvider));
});

/// Aktif projedeki seçili operatör (personel kaydı).
final activeOperatorProvider = Provider<Person?>((ref) {
  final id = ref.watch(activeOperatorIdProvider);
  final project = ref.watch(activeProjectProvider);
  final people = ref.watch(personnelProvider);
  if (id == null || project == null) return null;
  for (final p in people) {
    if (p.id == id && p.projectId == project.id && p.active) return p;
  }
  return null;
});
