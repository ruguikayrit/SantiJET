import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:santijet_is_programi/data/daily_crew_repository.dart';
import 'package:santijet_is_programi/data/program_repository.dart';
import 'package:santijet_is_programi/data/project_repository.dart';
import 'package:santijet_is_programi/features/calendar/calendar_screen.dart';

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('isprog_gantt_ui');
    Hive.init(hiveDir.path);
    await Hive.openBox<String>(programBoxName);
    await Hive.openBox<dynamic>(settingsBoxName);
    await Hive.openBox<String>(dailyCrewBoxName);
    await Hive.openBox<String>(projectBoxName);
  });

  setUp(() async {
    await Hive.box<String>(programBoxName).clear();
    await Hive.box<dynamic>(settingsBoxName).clear();
    await Hive.box<String>(dailyCrewBoxName).clear();
    await Hive.box<String>(projectBoxName).clear();
    await ProgramRepository(Hive.box<String>(programBoxName))
        .replaceWithDemo(today: DateTime(2026, 3, 10));
    final projects = await ProjectRepository(Hive.box<String>(projectBoxName))
        .migrateFromSiteNames(['Merkez Şantiyesi', 'Depo Şantiyesi']);
    final active = projects.firstWhere(
      (project) => project.name == 'Merkez Şantiyesi',
    );
    await Hive.box<dynamic>(settingsBoxName).put('activeProjectId', active.id);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  testWidgets('Gantt sayfasında yalnız grafik vardır', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CalendarScreen())),
    );
    await tester.pump();

    expect(find.text('Hafriyat ve zemin tesviyesi'), findsOneWidget);
    expect(find.text('Liste'), findsNothing);
    expect(find.text('Durum'), findsNothing);
    expect(find.text('Sorumlu'), findsNothing);
    expect(find.text('Önümüzdeki 7 gün'), findsNothing);
    expect(find.text('Filtreye uyan faaliyet yok.'), findsNothing);
  });
}
