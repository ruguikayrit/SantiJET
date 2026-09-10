import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../data/program_repository.dart';
import '../domain/program_item.dart';

final programRepositoryProvider = Provider<ProgramRepository>(
  (ref) => ProgramRepository(Hive.box<String>(programBoxName)),
);

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

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = _repository.readAll();
  }

  Future<void> loadDemo() async {
    await _repository.replaceWithDemo();
    state = _repository.readAll();
  }

  Future<void> clear() async {
    await _repository.clear();
    state = const [];
  }
}

final activeSiteProvider = NotifierProvider<ActiveSiteController, String>(
  ActiveSiteController.new,
);

class ActiveSiteController extends Notifier<String> {
  Box<dynamic> get _settings => Hive.box<dynamic>(settingsBoxName);

  @override
  String build() =>
      _settings.get('defaultSite', defaultValue: 'Merkez Şantiyesi') as String;

  Future<void> select(String value) async {
    state = value;
    await _settings.put('defaultSite', value);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  Box<dynamic> get _settings => Hive.box<dynamic>(settingsBoxName);

  @override
  ThemeMode build() {
    final value = _settings.get('themeMode', defaultValue: 'system') as String;
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> select(ThemeMode mode) async {
    state = mode;
    await _settings.put('themeMode', mode.name);
  }
}
