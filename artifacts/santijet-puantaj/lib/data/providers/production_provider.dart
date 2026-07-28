import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/utils/id_gen.dart';
import '../../core/utils/puantaj_date.dart';
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

  void deleteForProject(String projectId) {
    state = state.where((p) => p.projectId != projectId).toList();
    _persist();
  }

  void replaceAll(List<Production> items) {
    state = List<Production>.from(items);
    _persist();
  }

  /// Yıllık verim grafiği incelemesi için örnek imalat (iş günü × ~1 yıl).
  /// Id `prd_chart_demo_year_*` — inceledikten sonra İmalat’tan silin.
  /// Bir kez oluşturulur; silindikten sonra otomatik yeniden eklenmez.
  static const demoYearPrefix = 'prd_chart_demo_year_';
  static const _demoSeededKeyPrefix = 'chart_demo_year_seeded_';

  bool hasYearlyChartDemo(String projectId) => state.any(
        (p) =>
            p.projectId == projectId && p.id.startsWith(demoYearPrefix),
      );

  void ensureYearlyChartDemo(String projectId) {
    if (projectId.isEmpty) return;
    final flagKey = '$_demoSeededKeyPrefix$projectId';
    if (_box.get(flagKey) == true) return;
    if (hasYearlyChartDemo(projectId)) {
      _box.put(flagKey, true);
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 364));
    final entries = <ProductionDayEntry>[];
    var dayIndex = 0;
    for (var d = start; !d.isAfter(today); d = d.add(const Duration(days: 1))) {
      if (d.weekday > DateTime.friday) continue; // Pzt–Cum
      // Mevsimsel eğri + hafif gürültü → mum renkleri ortalamanın üst/altında.
      final seasonal = 0.92 + 0.18 * math.sin(dayIndex / 18.0);
      final noise = ((dayIndex * 17) % 23 - 11) / 100.0;
      final ratePerAs = (seasonal + noise).clamp(0.55, 1.35);
      final usta = 2.0 + (dayIndex % 3);
      final cirak = 1.0 + (dayIndex % 2).toDouble();
      final labor = usta + cirak;
      final qty = ratePerAs * labor * 8.0;
      entries.add(
        ProductionDayEntry(
          id: '${demoYearPrefix}d$dayIndex',
          date: PuantajDate.format(d),
          ustaCount: usta,
          duzIsciCount: cirak,
          completedQty: double.parse(qty.toStringAsFixed(2)),
          note: 'demo',
        ),
      );
      dayIndex++;
    }
    if (entries.isEmpty) {
      _box.put(flagKey, true);
      return;
    }

    final completed =
        entries.fold<double>(0, (s, e) => s + e.completedQty);
    final item = Production(
      id: '$demoYearPrefix$projectId',
      projectId: projectId,
      name: 'Demo · Yıllık Verim Grafiği',
      floor: 'Zemin',
      section: 'Demo Etap',
      teamName: 'Demo Ekip',
      unit: 'm³',
      plannedQty: double.parse((completed * 1.08).toStringAsFixed(2)),
      note: '[DEMO] Yıllık grafik örneği — inceledikten sonra silin',
      dailyEntries: entries,
    );
    state = [...state, item];
    _persist();
    _box.put(flagKey, true);
  }

  void removeYearlyChartDemo(String projectId) {
    state = state
        .where(
          (p) =>
              !(p.projectId == projectId && p.id.startsWith(demoYearPrefix)),
        )
        .toList();
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
