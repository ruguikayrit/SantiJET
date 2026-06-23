import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Son görüntülenen analiz id'leri (en yeni başta, en fazla 20) — Hive `recent`
/// kutusunda kalıcıdır. React Native `recentViews.ts` davranışıyla aynı.
class RecentViewsNotifier extends StateNotifier<List<String>> {
  RecentViewsNotifier(this._box) : super(_read(_box));

  final Box _box;
  static const _key = 'ids';
  static const _max = 20;

  static List<String> _read(Box box) {
    final raw = box.get(_key);
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    return <String>[];
  }

  void record(String id) {
    final next = [id, ...state.where((e) => e != id)];
    state = next.length > _max ? next.sublist(0, _max) : next;
    _box.put(_key, state);
  }

  void clear() {
    state = const [];
    _box.delete(_key);
  }

  void replaceAll(Iterable<String> ids) {
    state = ids.where((id) => id.isNotEmpty).take(_max).toList();
    _box.put(_key, state);
  }

  void merge(Iterable<String> ids) {
    final next = [
      ...ids.where((id) => id.isNotEmpty),
      ...state,
    ];
    final seen = <String>{};
    state = [
      for (final id in next)
        if (seen.add(id)) id,
    ].take(_max).toList();
    _box.put(_key, state);
  }
}

/// Hive `recent` kutusu — bootstrap'ta açılır ve override edilir.
final recentBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('recentBoxProvider override edilmeli'),
);

final recentViewsProvider =
    StateNotifierProvider<RecentViewsNotifier, List<String>>(
  (ref) => RecentViewsNotifier(ref.watch(recentBoxProvider)),
);
