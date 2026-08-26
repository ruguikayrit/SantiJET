import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/utils/id_gen.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/yevmiyeli_is_kaydi.dart';

final yevmiyeliIsBoxProvider = Provider<Box>(
  (ref) =>
      throw UnimplementedError('yevmiyeliIsBoxProvider override edilmeli'),
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
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
}

void _writeList(Box box, String key, List<Map<String, dynamic>> items) {
  box.put(key, jsonEncode(items));
}

class YevmiyeliIsNotifier extends StateNotifier<List<YevmiyeliIsKaydi>> {
  YevmiyeliIsNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<YevmiyeliIsKaydi> _load(Box box) =>
      _readList(box, _key).map(YevmiyeliIsKaydi.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  List<YevmiyeliIsKaydi> forDay({
    required String projectId,
    required String date,
  }) {
    return state
        .where((e) => e.projectId == projectId && e.date == date)
        .toList()
      ..sort((a, b) {
        final byCompany = a.company.compareTo(b.company);
        if (byCompany != 0) return byCompany;
        return a.personName.compareTo(b.personName);
      });
  }

  List<YevmiyeliIsKaydi> forPeriod({
    required String projectId,
    required List<String> dates,
  }) {
    final set = dates.toSet();
    return state
        .where((e) => e.projectId == projectId && set.contains(e.date))
        .toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.personName.compareTo(b.personName);
      });
  }

  double totalForPersonDay({
    required String projectId,
    required String date,
    required String personId,
  }) {
    return state
        .where(
          (e) =>
              e.projectId == projectId &&
              e.date == date &&
              e.personId == personId,
        )
        .fold<double>(0, (sum, e) => sum + e.yevmiyeCount);
  }

  YevmiyeliIsKaydi upsert(YevmiyeliIsKaydi entry) {
    final desc = entry.workDescription.trim();
    if (desc.isEmpty || entry.personId.isEmpty) {
      throw StateError('Personel ve iş tanımı zorunlu.');
    }
    final now = DateTime.now();
    final cleaned = entry.copyWith(
      workDescription: desc,
      updatedAt: now,
      createdAt: entry.createdAt ?? now,
    );
    final i = state.indexWhere((e) => e.id == cleaned.id);
    if (i >= 0) {
      state = [
        for (var j = 0; j < state.length; j++)
          if (j == i) cleaned else state[j],
      ];
    } else {
      state = [...state, cleaned];
    }
    _persist();
    return cleaned;
  }

  YevmiyeliIsKaydi addFromPerson({
    required String projectId,
    required String date,
    required Person person,
    required String workDescription,
    required double yevmiyeCount,
    String note = '',
    String? companyOverride,
  }) {
    final company = (companyOverride ?? person.company).trim();
    if (company.isEmpty) {
      throw StateError('Taşeron firma zorunlu.');
    }
    final now = DateTime.now();
    return upsert(
      YevmiyeliIsKaydi(
        id: IdGen.make('yis'),
        projectId: projectId,
        date: date,
        personId: person.id,
        personName: person.name,
        company: company,
        profession: person.profession,
        team: person.team,
        workDescription: workDescription,
        yevmiyeCount: yevmiyeCount,
        note: note,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _persist();
  }

  void deleteForProject(String projectId) {
    state = state.where((e) => e.projectId != projectId).toList();
    _persist();
  }

  void replaceAll(List<YevmiyeliIsKaydi> items) {
    state = List<YevmiyeliIsKaydi>.from(items);
    _persist();
  }

  /// Katalog ekip adı değişince yevmiyeli kayıtlarını günceller.
  int reassignTeam(String from, String to) {
    final oldName = from.trim();
    final newName = to.trim();
    if (oldName.isEmpty || newName.isEmpty) return 0;
    final oldKey = oldName.toLowerCase();
    var count = 0;
    state = [
      for (final e in state)
        if (e.team.trim().toLowerCase() == oldKey)
          () {
            count++;
            return e.copyWith(team: newName);
          }()
        else
          e,
    ];
    if (count > 0) _persist();
    return count;
  }
}

final yevmiyeliIsProvider =
    StateNotifierProvider<YevmiyeliIsNotifier, List<YevmiyeliIsKaydi>>(
  (ref) => YevmiyeliIsNotifier(ref.watch(yevmiyeliIsBoxProvider)),
);
