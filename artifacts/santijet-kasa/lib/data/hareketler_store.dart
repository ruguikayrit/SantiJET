import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../domain/kasa_hareket.dart';
import '../domain/kasa_rules.dart';
import 'settings_store.dart';

final hareketlerBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('hareketlerBoxProvider override edilmeli'),
);

class HareketlerNotifier extends StateNotifier<List<KasaHareket>> {
  HareketlerNotifier(this._box) : super(_read(_box));

  final Box _box;
  static const _key = 'items';

  static List<KasaHareket> _read(Box box) {
    final raw = box.get(_key);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(KasaHareket.fromJson)
        .toList()
      ..sort((a, b) => b.tarih.compareTo(a.tarih));
  }

  Future<void> _persist() async {
    await _box.put(_key, state.map((item) => item.toJson()).toList());
  }

  Future<void> upsert(KasaHareket hareket) async {
    assertValidHareket(hareket);
    state = [
      hareket,
      ...state.where((item) => item.id != hareket.id),
    ]..sort((a, b) => b.tarih.compareTo(a.tarih));
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _persist();
  }

  Future<void> replaceAll(List<KasaHareket> items) async {
    for (final item in items) {
      assertValidHareket(item);
    }
    state = [...items]..sort((a, b) => b.tarih.compareTo(a.tarih));
    await _persist();
  }

  Future<void> clear() async {
    state = const [];
    await _persist();
  }
}

final hareketlerProvider =
    StateNotifierProvider<HareketlerNotifier, List<KasaHareket>>(
  (ref) => HareketlerNotifier(ref.watch(hareketlerBoxProvider)),
);

/// Aktif şantiyeye göre hareketler.
final santiyeScopedHareketlerProvider = Provider<List<KasaHareket>>((ref) {
  final all = ref.watch(hareketlerProvider);
  final active = ref.watch(activeSantiyeProvider).trim();
  return all.where((h) => h.santiye.trim() == active).toList();
});

final kasaOzetProvider = Provider<KasaOzet>((ref) {
  return hesaplaOzet(ref.watch(santiyeScopedHareketlerProvider));
});
