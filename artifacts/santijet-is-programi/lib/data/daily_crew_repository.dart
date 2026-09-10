import 'dart:convert';

import 'package:hive/hive.dart';

import '../domain/daily_crew_entry.dart';
import '../domain/program_item.dart';

const dailyCrewBoxName = 'isprog_daily_crew';

class DailyCrewRepository {
  DailyCrewRepository(this._box);
  final Box<String> _box;

  List<DailyCrewEntry> readAll() {
    final entries = _box.values
        .map(
          (raw) => DailyCrewEntry.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          ),
        )
        .toList();
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  Future<void> save(DailyCrewEntry entry) =>
      _box.put(entry.id, jsonEncode(entry.toJson()));

  Future<void> delete(String id) => _box.delete(id);

  Future<void> deleteForItem(String itemId) async {
    final keys = [
      for (final entry in readAll())
        if (entry.itemId == itemId) entry.id,
    ];
    await _box.deleteAll(keys);
  }

  Future<void> clear() => _box.clear();

  /// Aynı imalat + gün satırı varsa üzerine yazar; yoksa ekler.
  Future<DailyCrewEntry> upsert({
    required String itemId,
    required DateTime date,
    required int workers,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    final stamp = day.toIso8601String().substring(0, 10);
    final existing = readAll().where(
      (entry) =>
          entry.itemId == itemId &&
          entry.date.toIso8601String().substring(0, 10) == stamp,
    );
    final entry = DailyCrewEntry(
      id: existing.firstOrNull?.id ?? 'crew-$itemId-$stamp',
      itemId: itemId,
      date: day,
      workers: workers,
    );
    await save(entry);
    return entry;
  }
}

/// Demo imalatların gerçekleşen adam-gününü, ilerleme yüzdesine göre dağıtır.
List<DailyCrewEntry> demoDailyCrew(
  List<ProgramItem> items, {
  required DateTime today,
}) {
  final entries = <DailyCrewEntry>[];
  for (final item in items) {
    if (item.progress <= 0 || item.plannedManDays <= 0) continue;
    final target = (item.plannedManDays * item.progress / 100).round();
    if (target <= 0) continue;

    var remaining = target;
    final last = today.isBefore(item.endDate) ? today : item.endDate;
    final first = item.startDate;
    final span = last.difference(first).inDays;
    final days = span < 0 ? 0 : span;
    for (var offset = 0; offset <= days && remaining > 0; offset++) {
      final date = first.add(Duration(days: offset));
      final workers = remaining < item.plannedCrew ? remaining : item.plannedCrew;
      if (workers <= 0) break;
      entries.add(
        DailyCrewEntry(
          id: 'crew-${item.id}-${date.toIso8601String().substring(0, 10)}',
          itemId: item.id,
          date: DateTime(date.year, date.month, date.day),
          workers: workers,
        ),
      );
      remaining -= workers;
    }
  }
  return entries;
}
