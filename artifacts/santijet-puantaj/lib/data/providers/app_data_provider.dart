import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../../core/utils/id_gen.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/project.dart';
import '../../domain/enums/attendance_status.dart';

final projectsBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('projectsBoxProvider override edilmeli'),
);

final personnelBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('personnelBoxProvider override edilmeli'),
);

final attendanceBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('attendanceBoxProvider override edilmeli'),
);

/// Aktif proje kimliği (Hive settings kutusu üzerinden).
class ActiveProjectNotifier extends StateNotifier<String?> {
  ActiveProjectNotifier(this._settingsBox) : super(_read(_settingsBox));

  final Box _settingsBox;
  static const _key = 'activeProjectId';

  static String? _read(Box box) => box.get(_key) as String?;

  void set(String? id) {
    state = id;
    if (id == null) {
      _settingsBox.delete(_key);
    } else {
      _settingsBox.put(_key, id);
    }
  }
}

final activeProjectIdProvider =
    StateNotifierProvider<ActiveProjectNotifier, String?>((ref) {
  return ActiveProjectNotifier(ref.watch(settingsBoxProvider));
});

List<Map<String, dynamic>> _readList(Box box, String key) {
  final raw = box.get(key);
  if (raw is String && raw.isNotEmpty) {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
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

class ProjectsNotifier extends StateNotifier<List<Project>> {
  ProjectsNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<Project> _load(Box box) =>
      _readList(box, _key).map(Project.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  Project add({
    required String name,
    String code = '',
    String company = '',
    String logoBase64 = '',
    String logoMimeType = 'image/jpeg',
  }) {
    final project = Project(
      id: IdGen.make('prj'),
      name: name.trim(),
      code: code.trim(),
      company: company.trim(),
      logoBase64: logoBase64,
      logoMimeType: logoMimeType,
      createdAt: DateTime.now(),
    );
    state = [...state, project];
    _persist();
    return project;
  }

  void update(Project project) {
    state = [
      for (final p in state)
        if (p.id == project.id) project else p,
    ];
    _persist();
  }

  void delete(String id) {
    state = state.where((p) => p.id != id).toList();
    _persist();
  }

  void replaceAll(List<Project> items) {
    state = List<Project>.from(items);
    _persist();
  }
}

final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, List<Project>>((ref) {
  return ProjectsNotifier(ref.watch(projectsBoxProvider));
});

final activeProjectProvider = Provider<Project?>((ref) {
  final id = ref.watch(activeProjectIdProvider);
  final projects = ref.watch(projectsProvider);
  if (projects.isEmpty) return null;
  if (id != null) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
  }
  return projects.first;
});

class PersonnelNotifier extends StateNotifier<List<Person>> {
  PersonnelNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<Person> _load(Box box) =>
      _readList(box, _key).map(Person.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  List<Person> get active => state.where((p) => p.active).toList();

  List<Person> forProject(String projectId) =>
      state.where((p) => p.projectId == projectId).toList();

  Person add(Person draft) {
    final person = draft.copyWith(id: IdGen.make('per'));
    state = [...state, person];
    _persist();
    return person;
  }

  void addAll(List<Person> drafts) {
    if (drafts.isEmpty) return;
    state = [
      ...state,
      for (final d in drafts)
        d.id.trim().isEmpty ? d.copyWith(id: IdGen.make('per')) : d,
    ];
    _persist();
  }

  void update(Person person) {
    state = [
      for (final p in state)
        if (p.id == person.id) person else p,
    ];
    _persist();
  }

  void delete(String id) {
    state = state.where((p) => p.id != id).toList();
    _persist();
  }

  void deleteMany(Iterable<String> ids) {
    final remove = ids.toSet();
    if (remove.isEmpty) return;
    state = state.where((p) => !remove.contains(p.id)).toList();
    _persist();
  }

  void deleteForProject(String projectId) {
    state = state.where((p) => p.projectId != projectId).toList();
    _persist();
  }

  void replaceAll(List<Person> items) {
    state = List<Person>.from(items);
    _persist();
  }

  /// Eski (projectId'siz) kayıtları verilen projeye bağlar.
  int migrateOrphansToProject(String projectId) {
    if (projectId.isEmpty) return 0;
    var n = 0;
    state = [
      for (final p in state)
        if (p.projectId.isEmpty)
          () {
            n++;
            return p.copyWith(projectId: projectId);
          }()
        else
          p,
    ];
    if (n > 0) _persist();
    return n;
  }
}

final personnelProvider =
    StateNotifierProvider<PersonnelNotifier, List<Person>>((ref) {
  return PersonnelNotifier(ref.watch(personnelBoxProvider));
});

/// Aktif projedeki tüm personel (aktif + pasif) — Personel ekranı.
final projectPersonnelProvider = Provider<List<Person>>((ref) {
  final project = ref.watch(activeProjectProvider);
  final all = ref.watch(personnelProvider);
  if (project == null) return const [];
  return all.where((p) => p.projectId == project.id).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});

/// Aktif projedeki aktif personel — Puantaj / İmalat / Ana sayfa.
final activePersonnelProvider = Provider<List<Person>>((ref) {
  final project = ref.watch(activeProjectProvider);
  final all = ref.watch(personnelProvider);
  if (project == null) return const [];
  return all
      .where((p) => p.active && p.projectId == project.id)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});

class AttendanceNotifier extends StateNotifier<List<Attendance>> {
  AttendanceNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<Attendance> _load(Box box) =>
      _readList(box, _key).map(Attendance.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  Attendance? find({
    required String projectId,
    required String personId,
    required String date,
  }) {
    for (final a in state) {
      if (a.projectId == projectId &&
          a.personId == personId &&
          a.date == date) {
        return a;
      }
    }
    return null;
  }

  void setStatus({
    required String projectId,
    required Person person,
    required String date,
    required AttendanceStatus status,
  }) {
    final existing = find(
      projectId: projectId,
      personId: person.id,
      date: date,
    );
    // Çalışılmayan günde mesai sıfırlanır.
    final overtime = status.isWorkedDay ? (existing?.overtimeHours ?? 0) : 0.0;
    if (existing != null) {
      state = [
        for (final a in state)
          if (a.id == existing.id)
            a.copyWith(
              status: status,
              hours: status.hours,
              overtimeHours: overtime,
            )
          else
            a,
      ];
    } else {
      state = [
        ...state,
        Attendance(
          id: IdGen.make('att'),
          projectId: projectId,
          personId: person.id,
          personName: person.name,
          date: date,
          status: status,
          hours: status.hours,
          overtimeHours: 0,
        ),
      ];
    }
    _persist();
  }

  void setOvertime({
    required String projectId,
    required Person person,
    required String date,
    required double overtimeHours,
  }) {
    final clamped = overtimeHours.clamp(0, 12).toDouble();
    final existing = find(
      projectId: projectId,
      personId: person.id,
      date: date,
    );
    if (existing != null) {
      if (!existing.status.isWorkedDay) return;
      state = [
        for (final a in state)
          if (a.id == existing.id)
            a.copyWith(overtimeHours: clamped)
          else
            a,
      ];
    } else if (clamped > 0) {
      state = [
        ...state,
        Attendance(
          id: IdGen.make('att'),
          projectId: projectId,
          personId: person.id,
          personName: person.name,
          date: date,
          status: AttendanceStatus.present,
          hours: AttendanceStatus.present.hours,
          overtimeHours: clamped,
        ),
      ];
    }
    _persist();
  }

  void setNote({
    required String projectId,
    required Person person,
    required String date,
    required String note,
  }) {
    final existing = find(
      projectId: projectId,
      personId: person.id,
      date: date,
    );
    final trimmed = note.trim();
    if (existing != null) {
      state = [
        for (final a in state)
          if (a.id == existing.id) a.copyWith(note: trimmed) else a,
      ];
    } else if (trimmed.isNotEmpty) {
      state = [
        ...state,
        Attendance(
          id: IdGen.make('att'),
          projectId: projectId,
          personId: person.id,
          personName: person.name,
          date: date,
          status: AttendanceStatus.absent,
          hours: 0,
          note: trimmed,
        ),
      ];
    }
    _persist();
  }

  void bulkSetStatus({
    required String projectId,
    required List<Person> people,
    required String date,
    required AttendanceStatus status,
  }) {
    for (final person in people) {
      setStatus(
        projectId: projectId,
        person: person,
        date: date,
        status: status,
      );
    }
  }

  /// Önceki günden kopyala. Dönüş: kopyalanan kayıt sayısı.
  int copyFromPreviousDay({
    required String projectId,
    required List<Person> people,
    required String date,
    required String previousDate,
  }) {
    var copied = 0;
    for (final person in people) {
      final prev = find(
        projectId: projectId,
        personId: person.id,
        date: previousDate,
      );
      if (prev == null) continue;
      final existing = find(
        projectId: projectId,
        personId: person.id,
        date: date,
      );
      if (existing != null) {
        state = [
          for (final a in state)
            if (a.id == existing.id)
              a.copyWith(
                status: prev.status,
                hours: prev.hours,
                overtimeHours: prev.overtimeHours,
                note: prev.note,
              )
            else
              a,
        ];
      } else {
        state = [
          ...state,
          Attendance(
            id: IdGen.make('att'),
            projectId: projectId,
            personId: person.id,
            personName: person.name,
            date: date,
            status: prev.status,
            hours: prev.hours,
            overtimeHours: prev.overtimeHours,
            note: prev.note,
          ),
        ];
      }
      copied++;
    }
    if (copied > 0) _persist();
    return copied;
  }

  void deleteForProject(String projectId) {
    state = state.where((a) => a.projectId != projectId).toList();
    _persist();
  }

  void replaceAll(List<Attendance> items) {
    state = List<Attendance>.from(items);
    _persist();
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, List<Attendance>>((ref) {
  return AttendanceNotifier(ref.watch(attendanceBoxProvider));
});
