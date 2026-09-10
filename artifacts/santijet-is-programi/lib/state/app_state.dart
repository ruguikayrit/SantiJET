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
