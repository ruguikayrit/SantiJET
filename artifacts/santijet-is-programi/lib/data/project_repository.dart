import 'dart:convert';

import 'package:hive/hive.dart';

import '../domain/program_project.dart';

const projectBoxName = 'isprog_projects';

class ProjectRepository {
  ProjectRepository(this._box);
  final Box<String> _box;

  List<ProgramProject> readAll() {
    final projects = _box.values
        .map(
          (raw) => ProgramProject.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          ),
        )
        .toList();
    projects.sort((a, b) => a.name.compareTo(b.name));
    return projects;
  }

  Future<void> save(ProgramProject project) =>
      _box.put(project.id, jsonEncode(project.toJson()));

  Future<void> saveAll(List<ProgramProject> projects) => _box.putAll({
    for (final project in projects) project.id: jsonEncode(project.toJson()),
  });

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() => _box.clear();

  /// Kayıtlı şantiye adlarından proje üretir. Kod yoksa yenisini yazar.
  Future<List<ProgramProject>> migrateFromSiteNames(Iterable<String> names) async {
    if (_box.isNotEmpty) return readAll();
    final unique = names.map((name) => name.trim()).where((name) => name.isNotEmpty).toSet();
    if (unique.isEmpty) unique.add('Merkez Şantiyesi');
    final existingCodes = <String>{};
    var index = 0;
    for (final name in unique) {
      var code = generateWorkCode(seed: name.hashCode + index);
      while (existingCodes.contains(code)) {
        index++;
        code = generateWorkCode(seed: name.hashCode + index);
      }
      existingCodes.add(code);
      await save(
        ProgramProject(
          id: 'proj-${name.hashCode.abs()}',
          name: name,
          code: code,
        ),
      );
      index++;
    }
    return readAll();
  }
}

class ProfileRepository {
  ProfileRepository(this._settings);
  final Box<dynamic> _settings;

  LocalProfile read() {
    final raw = _settings.get('localProfile');
    if (raw is Map) {
      return LocalProfile.fromJson(Map<String, dynamic>.from(raw));
    }
    return const LocalProfile();
  }

  Future<void> save(LocalProfile profile) =>
      _settings.put('localProfile', profile.toJson());
}
