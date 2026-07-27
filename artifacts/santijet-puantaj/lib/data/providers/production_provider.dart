import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/utils/id_gen.dart';
import '../../domain/entities/production.dart';
import '../../domain/entities/production_day_entry.dart';
import 'app_data_provider.dart';

final productionBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('productionBoxProvider override edilmeli'),
);

List<Map<String, dynamic>> _readList(Box box, String key) {
  final raw = box.get(key);
  if (raw is String && raw.isNotEmpty) {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }
  if (raw is List) {
    return raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
  return [];
}

void _writeList(Box box, String key, List<Map<String, dynamic>> items) {
  box.put(key, jsonEncode(items));
}

class ProductionNotifier extends StateNotifier<List<Production>> {
  ProductionNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<Production> _load(Box box) =>
      _readList(box, _key).map(Production.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  Production add(Production draft) {
    final item = draft.copyWith(id: IdGen.make('prd'));
    state = [...state, item];
    _persist();
    return item;
  }

  void update(Production item) {
    state = [
      for (final p in state)
        if (p.id == item.id) item else p,
    ];
    _persist();
  }

  void delete(String id) {
    state = state.where((p) => p.id != id).toList();
    _persist();
  }

  ProductionDayEntry addDayEntry(String productionId, ProductionDayEntry draft) {
    final entry = draft.copyWith(id: IdGen.make('prd'));
    state = [
      for (final p in state)
        if (p.id == productionId)
          p.copyWith(dailyEntries: [...p.dailyEntries, entry])
        else
          p,
    ];
    _persist();
    return entry;
  }

  void updateDayEntry(String productionId, ProductionDayEntry entry) {
    state = [
      for (final p in state)
        if (p.id == productionId)
          p.copyWith(
            dailyEntries: [
              for (final e in p.dailyEntries)
                if (e.id == entry.id) entry else e,
            ],
          )
        else
          p,
    ];
    _persist();
  }

  void deleteDayEntry(String productionId, String entryId) {
    state = [
      for (final p in state)
        if (p.id == productionId)
          p.copyWith(
            dailyEntries:
                p.dailyEntries.where((e) => e.id != entryId).toList(),
          )
        else
          p,
    ];
    _persist();
  }
}

final productionProvider =
    StateNotifierProvider<ProductionNotifier, List<Production>>((ref) {
  return ProductionNotifier(ref.watch(productionBoxProvider));
});

final activeProductionProvider = Provider<List<Production>>((ref) {
  final project = ref.watch(activeProjectProvider);
  final all = ref.watch(productionProvider);
  if (project == null) return const [];
  final list = all.where((p) => p.projectId == project.id).toList()
    ..sort((a, b) {
      if (a.isComplete != b.isComplete) {
        return a.isComplete ? 1 : -1;
      }
      return b.latestDate.compareTo(a.latestDate);
    });
  return list;
});
