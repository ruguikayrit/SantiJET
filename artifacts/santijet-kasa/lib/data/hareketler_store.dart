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

  /// İçe aktarım — mevcut kayıtların üzerine ekle (silmez).
  Future<void> appendImported(List<KasaHareket> incoming) async {
    for (final item in incoming) {
      assertValidHareket(item);
    }
    if (incoming.isEmpty) return;
    final existingIds = incoming.map((e) => e.id).toSet();
    state = [
      ...incoming,
      ...state.where((e) => !existingIds.contains(e.id)),
    ]..sort((a, b) => b.tarih.compareTo(a.tarih));
    await _persist();
  }

  /// Seçili hareketleri hedef şantiyeye taşır (aynı id, şantiye değişir).
  Future<int> moveToSantiye({
    required Set<String> ids,
    required String targetSantiye,
  }) async {
    final target = targetSantiye.trim();
    if (ids.isEmpty || target.isEmpty) return 0;
    final stamp = DateTime.now();
    var count = 0;
    state = state.map((h) {
      if (!ids.contains(h.id) || h.santiye.trim() == target) return h;
      count++;
      return h.copyWith(santiye: target, updatedAt: stamp);
    }).toList()
      ..sort((a, b) => b.tarih.compareTo(a.tarih));
    if (count > 0) await _persist();
    return count;
  }

  /// Seçili hareketlerin kopyasını hedef şantiyeye ekler (yeni id).
  Future<int> copyToSantiye({
    required Set<String> ids,
    required String targetSantiye,
    required String Function() newId,
  }) async {
    final target = targetSantiye.trim();
    if (ids.isEmpty || target.isEmpty) return 0;
    final stamp = DateTime.now();
    final copies = <KasaHareket>[];
    for (final h in state) {
      if (!ids.contains(h.id)) continue;
      copies.add(
        h.copyWith(
          id: newId(),
          santiye: target,
          createdAt: stamp,
          updatedAt: stamp,
        ),
      );
    }
    if (copies.isEmpty) return 0;
    for (final item in copies) {
      assertValidHareket(item);
    }
    state = [...copies, ...state]..sort((a, b) => b.tarih.compareTo(a.tarih));
    await _persist();
    return copies.length;
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
