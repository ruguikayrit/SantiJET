import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/utils/id_gen.dart';
import '../../domain/entities/uninsured_team_entry.dart';

final uninsuredTeamsBoxProvider = Provider<Box>(
  (ref) =>
      throw UnimplementedError('uninsuredTeamsBoxProvider override edilmeli'),
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

class UninsuredTeamsNotifier extends StateNotifier<List<UninsuredTeamEntry>> {
  UninsuredTeamsNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<UninsuredTeamEntry> _load(Box box) =>
      _readList(box, _key).map(UninsuredTeamEntry.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  List<UninsuredTeamEntry> forDay({
    required String projectId,
    required String date,
  }) {
    return state
        .where((e) => e.projectId == projectId && e.date == date)
        .toList()
      ..sort((a, b) => a.teamName.compareTo(b.teamName));
  }

  void upsert(UninsuredTeamEntry entry) {
    final name = entry.teamName.trim();
    final count = entry.workerCount;
    if (name.isEmpty || count <= 0) return;

    final cleaned = entry.copyWith(teamName: name, workerCount: count);
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
  }

  void add({
    required String projectId,
    required String date,
    required String teamName,
    required int workerCount,
  }) {
    upsert(
      UninsuredTeamEntry(
        id: IdGen.make('sig'),
        projectId: projectId,
        date: date,
        teamName: teamName,
        workerCount: workerCount,
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
}

final uninsuredTeamsProvider =
    StateNotifierProvider<UninsuredTeamsNotifier, List<UninsuredTeamEntry>>(
  (ref) => UninsuredTeamsNotifier(ref.watch(uninsuredTeamsBoxProvider)),
);
