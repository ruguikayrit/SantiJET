import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Favori analiz id'leri — Hive `favorites` kutusunda kalıcıdır.
class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this._box) : super(_read(_box));

  final Box _box;
  static const _key = 'ids';

  static Set<String> _read(Box box) {
    final raw = box.get(_key);
    if (raw is List) {
      return raw.whereType<String>().toSet();
    }
    return <String>{};
  }

  void _persist() => _box.put(_key, state.toList());

  bool isFavorite(String id) => state.contains(id);

  void toggle(String id) {
    final next = Set<String>.from(state);
    if (!next.add(id)) next.remove(id);
    state = next;
    _persist();
  }
}

/// Hive `favorites` kutusu — bootstrap'ta açılır ve override edilir.
final favoritesBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('favoritesBoxProvider override edilmeli'),
);

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(ref.watch(favoritesBoxProvider)),
);
