import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../domain/tahvil_record.dart';

final recordsBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('recordsBoxProvider override edilmeli'),
);

class TahvilRecordsNotifier extends StateNotifier<List<TahvilRecord>> {
  TahvilRecordsNotifier(this._box) : super(_read(_box));

  final Box _box;
  static const _key = 'items';

  static List<TahvilRecord> _read(Box box) {
    final raw = box.get(_key);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(TahvilRecord.fromJson)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _persist() async {
    await _box.put(_key, state.map((item) => item.toJson()).toList());
  }

  Future<void> add(TahvilRecord record) async {
    state = [record, ...state.where((item) => item.id != record.id)];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _persist();
  }

  Future<void> clear() async {
    state = const [];
    await _persist();
  }
}

final tahvilRecordsProvider =
    StateNotifierProvider<TahvilRecordsNotifier, List<TahvilRecord>>(
  (ref) => TahvilRecordsNotifier(ref.watch(recordsBoxProvider)),
);
