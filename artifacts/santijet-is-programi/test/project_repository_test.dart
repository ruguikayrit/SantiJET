import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:santijet_is_programi/data/daily_crew_repository.dart';
import 'package:santijet_is_programi/data/program_repository.dart';
import 'package:santijet_is_programi/data/project_repository.dart';
import 'package:santijet_is_programi/domain/program_item.dart';
import 'package:santijet_is_programi/state/app_state.dart';

void main() {
  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('isprog_proj');
    Hive.init(hiveDir.path);
    await Hive.openBox<String>(programBoxName);
    await Hive.openBox<dynamic>(settingsBoxName);
    await Hive.openBox<String>(dailyCrewBoxName);
    await Hive.openBox<String>(projectBoxName);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await hiveDir.delete(recursive: true);
  });

  test('göç şantiye adlarından benzersiz iş kodu üretir', () async {
    final repo = ProjectRepository(Hive.box<String>(projectBoxName));
    final created = await repo.migrateFromSiteNames([
      'Merkez Şantiyesi',
      'Depo Şantiyesi',
      'Merkez Şantiyesi',
    ]);

    expect(created.map((project) => project.name).toSet(), {
      'Merkez Şantiyesi',
      'Depo Şantiyesi',
    });
    expect(
      created.map((project) => project.code).toSet(),
      hasLength(created.length),
    );
    expect(created.every((project) => project.code.startsWith('SJ')), isTrue);
  });

  test('aynı koda geçiş mevcut şantiyeyi seçer, yoksa boş şantiye yazar', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(projectsProvider.notifier).ensureNamed('Merkez Şantiyesi');
    final code = container.read(projectsProvider).single.code;

    await container.read(projectsProvider.notifier).joinCode(code);
    expect(container.read(activeSiteProvider), 'Merkez Şantiyesi');

    await container.read(projectsProvider.notifier).joinCode('SJTEST');
    expect(container.read(activeProjectProvider)?.code, 'SJTEST');
    expect(container.read(projectsProvider), hasLength(2));
  });

  test('şantiye adı değişince imalatlar yeni ada geçer', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(projectsProvider.notifier).ensureNamed('Eski Ad');
    final project = container.read(projectsProvider).single;
    await container
        .read(programItemsProvider.notifier)
        .save(
          ProgramItem(
            id: 'i1',
            santiyeId: 'Eski Ad',
            name: 'Kalıp',
            startDate: DateTime(2026, 3, 1),
            endDate: DateTime(2026, 3, 5),
            progress: 0,
            status: ProgramStatus.planned,
            responsible: 'Test',
          ),
        );

    await container
        .read(projectsProvider.notifier)
        .save(project.copyWith(name: 'Yeni Ad'));

    expect(
      container.read(programItemsProvider).single.santiyeId,
      'Yeni Ad',
    );
    expect(container.read(activeSiteProvider), 'Yeni Ad');
  });
}
