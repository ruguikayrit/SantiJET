import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../data/daily_crew_repository.dart';
import '../data/interop/program_interop_service.dart';
import '../data/program_repository.dart';
import '../domain/daily_crew_entry.dart';
import '../domain/man_day_progress.dart';
import '../domain/program_item.dart';

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
  }

  Future<void> clear() async {
    await _repository.clear();
    await ref.read(dailyCrewProvider.notifier).clear();
    state = const [];
  }

  /// Saha kayıtlarından ilerleme yüzdesini faaliyete işler; aktarım
  /// dosyaları da aynı sayıyı görür.
  Future<void> syncProgress(String itemId) async {
    final item = state.where((found) => found.id == itemId).firstOrNull;
    if (item == null) return;
    final row = ManDayProgress.of(item, ref.read(dailyCrewProvider));
    await _repository.save(
      item.copyWith(progress: row.progress, status: row.effectiveStatus),
    );
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
  }
}

final programInteropServiceProvider = Provider<ProgramInteropService>(
  (ref) => ProgramInteropService(),
);

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
