import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../data/daily_crew_repository.dart';
import '../data/interop/program_interop_service.dart';
import '../data/program_repository.dart';
import '../data/project_repository.dart';
import '../domain/daily_crew_entry.dart';
import '../domain/program_item.dart';
import '../domain/program_project.dart';
import '../domain/project_tracking.dart';

final programRepositoryProvider = Provider<ProgramRepository>(
  (ref) => ProgramRepository(Hive.box<String>(programBoxName)),
);

final dailyCrewRepositoryProvider = Provider<DailyCrewRepository>(
  (ref) => DailyCrewRepository(Hive.box<String>(dailyCrewBoxName)),
);

final dailyCrewProvider = NotifierProvider<DailyCrewController, List<DailyCrewEntry>>(
  DailyCrewController.new,
);

class DailyCrewController extends Notifier<List<DailyCrewEntry>> {
  DailyCrewRepository get _repository => ref.read(dailyCrewRepositoryProvider);

  @override
  List<DailyCrewEntry> build() => _repository.readAll();

  Future<void> upsert({
    required String itemId,
    required DateTime date,
    required int workers,
  }) async {
    await _repository.upsert(itemId: itemId, date: date, workers: workers);
    state = _repository.readAll();
    await ref.read(programItemsProvider.notifier).syncProgress(itemId);
  }

  Future<void> delete(String id) async {
    final itemId = state
        .where((entry) => entry.id == id)
        .map((entry) => entry.itemId)
        .firstOrNull;
    await _repository.delete(id);
    state = _repository.readAll();
    if (itemId != null) {
      await ref.read(programItemsProvider.notifier).syncProgress(itemId);
    }
  }

  Future<void> replaceWithDemo(List<ProgramItem> items, {DateTime? today}) async {
    await _repository.clear();
    for (final entry in demoDailyCrew(items, today: today ?? DateTime.now())) {
      await _repository.save(entry);
    }
    state = _repository.readAll();
  }

  Future<void> clear() async {
    await _repository.clear();
    state = const [];
  }

  Future<void> replaceAll(List<DailyCrewEntry> entries) async {
    await _repository.clear();
    for (final entry in entries) {
      await _repository.save(entry);
    }
    state = _repository.readAll();
  }
}

final programItemsProvider =
    NotifierProvider<ProgramController, List<ProgramItem>>(
      ProgramController.new,
    );

class ProgramController extends Notifier<List<ProgramItem>> {
  ProgramRepository get _repository => ref.read(programRepositoryProvider);

  @override
  List<ProgramItem> build() => _repository.readAll();

  Future<void> save(ProgramItem item) async {
    await _repository.save(item);
    state = _repository.readAll();
  }

  Future<void> renameSite(String from, String to) async {
    if (from == to) return;
    for (final item in state.where((found) => found.santiyeId == from)) {
      await _repository.save(item.copyWith(santiyeId: to));
    }
    state = _repository.readAll();
  }

  Future<void> replaceItems(List<ProgramItem> items) async {
    await _repository.replaceAll(items);
    state = _repository.readAll();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await ref.read(dailyCrewRepositoryProvider).deleteForItem(id);
    ref.invalidate(dailyCrewProvider);
    state = _repository.readAll();
  }

  Future<void> loadDemo() async {
    await _repository.replaceWithDemo();
    state = _repository.readAll();
    await ref.read(dailyCrewProvider.notifier).replaceWithDemo(state);
    await ref.read(projectsProvider.notifier).syncFromItems(state);
    await ref.read(projectsProvider.notifier).selectByName('Merkez Şantiyesi');
  }

  Future<void> clear() async {
    await _repository.clear();
    await ref.read(dailyCrewProvider.notifier).clear();
    state = const [];
  }

  /// İzleme alanlarını Project hesabına göre doldurur; aktarım aynı sayıyı görür.
  Future<void> syncProgress(String itemId) async {
    final item = state.where((found) => found.id == itemId).firstOrNull;
    if (item == null) return;
    final tracking = ProjectTracking.fromItem(
      item,
      logs: ref.read(dailyCrewProvider),
    );
    await _repository.save(tracking.applyTo(item));
    state = _repository.readAll();
  }

  /// İçe aktarılan faaliyetleri yazar. [replace] doğruysa mevcut program
  /// silinir; değilse aynı kimlikli satırlar güncellenir, yenileri eklenir.
  Future<void> importItems(
    List<ProgramItem> items, {
    required bool replace,
  }) async {
    if (replace) {
      await _repository.replaceAll(items);
      await ref.read(dailyCrewProvider.notifier).clear();
    } else {
      await _repository.saveAll(items);
    }
    state = _repository.readAll();
    await ref.read(projectsProvider.notifier).syncFromItems(state);
  }
}

final programInteropServiceProvider = Provider<ProgramInteropService>(
  (ref) => ProgramInteropService(),
);

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepository(Hive.box<String>(projectBoxName)),
);

final projectsProvider = NotifierProvider<ProjectsController, List<ProgramProject>>(
  ProjectsController.new,
);

class ProjectsController extends Notifier<List<ProgramProject>> {
  ProjectRepository get _repository => ref.read(projectRepositoryProvider);
  Box<dynamic> get _settings => Hive.box<dynamic>(settingsBoxName);

  @override
  List<ProgramProject> build() => _repository.readAll();

  String? get activeId =>
      _settings.get('activeProjectId') as String? ?? state.firstOrNull?.id;

  ProgramProject? get active =>
      state.where((project) => project.id == activeId).firstOrNull ??
      state.firstOrNull;

  Future<void> select(String id) async {
    await _settings.put('activeProjectId', id);
    final name = state.where((project) => project.id == id).firstOrNull?.name;
    if (name != null) await _settings.put('defaultSite', name);
    await ref.read(activeProjectIdProvider.notifier).setId(id);
  }

  Future<void> selectByName(String name) async {
    final match = state.where((project) => project.name == name).firstOrNull;
    if (match != null) {
      await select(match.id);
      return;
    }
    await ensureNamed(name);
  }

  Future<ProgramProject> ensureNamed(String name) async {
    final trimmed = name.trim();
    final existing = state.where((project) => project.name == trimmed).firstOrNull;
    if (existing != null) {
      await select(existing.id);
      return existing;
    }
    final project = ProgramProject(
      id: 'proj-${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed.isEmpty ? 'Yeni Şantiye' : trimmed,
      code: _uniqueCode(),
    );
    await _repository.save(project);
    state = _repository.readAll();
    await select(project.id);
    return project;
  }

  Future<void> save(ProgramProject project) async {
    final previous = state.where((found) => found.id == project.id).firstOrNull;
    await _repository.save(project);
    if (previous != null && previous.name != project.name) {
      await ref
          .read(programItemsProvider.notifier)
          .renameSite(previous.name, project.name);
    }
    state = _repository.readAll();
    if (activeId == project.id) {
      await _settings.put('defaultSite', project.name);
      await ref.read(activeProjectIdProvider.notifier).setId(project.id);
    }
  }

  Future<void> delete(String id) async {
    final project = state.where((found) => found.id == id).firstOrNull;
    if (project == null) return;
    final items = ref
        .read(programItemsProvider)
        .where((item) => item.santiyeId == project.name)
        .toList();
    for (final item in items) {
      await ref.read(programItemsProvider.notifier).delete(item.id);
    }
    await _repository.delete(id);
    state = _repository.readAll();
    if (state.isEmpty) {
      await ensureNamed('Merkez Şantiyesi');
    } else if (activeId == id) {
      await select(state.first.id);
    }
  }

  Future<void> joinCode(String raw) async {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) return;
    final match = state.where((project) => project.code == code).firstOrNull;
    if (match != null) {
      await select(match.id);
      return;
    }
    final project = ProgramProject(
      id: 'proj-${DateTime.now().microsecondsSinceEpoch}',
      name: 'Şantiye $code',
      code: code,
    );
    await _repository.save(project);
    state = _repository.readAll();
    await select(project.id);
  }

  Future<void> syncFromItems(List<ProgramItem> items) async {
    for (final name in items.map((item) => item.santiyeId).toSet()) {
      if (state.every((project) => project.name != name)) {
        await _repository.save(
          ProgramProject(
            id: 'proj-${name.hashCode.abs()}',
            name: name,
            code: _uniqueCode(seed: name.hashCode),
          ),
        );
      }
    }
    state = _repository.readAll();
    if (active == null && state.isNotEmpty) await select(state.first.id);
  }

  Future<void> resetToDefault() async {
    await _repository.clear();
    state = const [];
    await ensureNamed('Merkez Şantiyesi');
  }

  Future<void> replaceAll(
    List<ProgramProject> projects, {
    String? activeProjectId,
  }) async {
    await _repository.clear();
    await _repository.saveAll(projects);
    state = _repository.readAll();
    if (activeProjectId != null &&
        state.any((project) => project.id == activeProjectId)) {
      await select(activeProjectId);
    } else if (state.isNotEmpty) {
      await select(state.first.id);
    } else {
      await ensureNamed('Merkez Şantiyesi');
    }
  }

  String _uniqueCode({int seed = 0}) {
    var code = generateWorkCode(seed: seed);
    final used = state.map((project) => project.code).toSet();
    var attempt = 1;
    while (used.contains(code)) {
      code = generateWorkCode(seed: seed + attempt);
      attempt++;
    }
    return code;
  }
}

final activeProjectIdProvider =
    NotifierProvider<ActiveProjectIdController, String?>(
      ActiveProjectIdController.new,
    );

class ActiveProjectIdController extends Notifier<String?> {
  @override
  String? build() =>
      Hive.box<dynamic>(settingsBoxName).get('activeProjectId') as String?;

  Future<void> setId(String id) async {
    await Hive.box<dynamic>(settingsBoxName).put('activeProjectId', id);
    state = id;
  }
}

final activeProjectProvider = Provider<ProgramProject?>((ref) {
  final projects = ref.watch(projectsProvider);
  final id = ref.watch(activeProjectIdProvider);
  return projects.where((project) => project.id == id).firstOrNull ??
      projects.firstOrNull;
});

final activeSiteProvider = Provider<String>((ref) {
  return ref.watch(activeProjectProvider)?.name ?? 'Merkez Şantiyesi';
});

final profileProvider = NotifierProvider<ProfileController, LocalProfile>(
  ProfileController.new,
);

class ProfileController extends Notifier<LocalProfile> {
  @override
  LocalProfile build() =>
      ProfileRepository(Hive.box<dynamic>(settingsBoxName)).read();

  Future<void> save(LocalProfile profile) async {
    await ProfileRepository(Hive.box<dynamic>(settingsBoxName)).save(profile);
    state = profile;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, String>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<String> {
  Box<dynamic> get _settings => Hive.box<dynamic>(settingsBoxName);

  @override
  String build() {
    final raw = _settings.get('themeMode', defaultValue: 'santijet_pro');
    final value = raw == 'gecejet' ? 'santijet_pro' : raw as String;
    return switch (value) {
      'light' || 'dark' || 'santijet' || 'santijet_pro' => value,
      _ => 'santijet_pro',
    };
  }

  Future<void> select(String mode) async {
    final next = switch (mode) {
      'light' || 'dark' || 'santijet' || 'santijet_pro' => mode,
      _ => 'santijet_pro',
    };
    state = next;
    await _settings.put('themeMode', next);
  }
}

ThemeMode themeModeFromSettings(String mode) => switch (mode) {
  'light' || 'santijet' => ThemeMode.light,
  _ => ThemeMode.dark,
};

String themeLabel(String mode) => switch (mode) {
  'light' => 'Açık',
  'dark' => 'Koyu',
  'santijet' => 'ŞantiJET',
  _ => 'ŞantiJET Pro',
};
