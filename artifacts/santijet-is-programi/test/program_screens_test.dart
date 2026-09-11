import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:santijet_is_programi/data/daily_crew_repository.dart';
import 'package:santijet_is_programi/data/program_repository.dart';
import 'package:santijet_is_programi/data/project_repository.dart';
import 'package:santijet_is_programi/features/program/program_screen.dart';

Widget host(Widget child) => ProviderScope(
  child: MaterialApp(
    locale: const Locale('tr', 'TR'),
    supportedLocales: const [Locale('tr', 'TR')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  ),
);

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
    hiveDir = await Directory.systemTemp.createTemp('isprog_program_ui');
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

  testWidgets('Program GİRİŞ tablosu MS Project alanlarını gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(host(const ProgramScreen()));
    await tester.pump();

    expect(find.text('GİRİŞ'), findsWidgets);
    expect(find.text('İZLEME'), findsOneWidget);
    expect(find.text('Görev Adı'), findsOneWidget);
    expect(find.text('Süre'), findsOneWidget);
    expect(find.text('Başlangıç'), findsOneWidget);
    expect(find.text('Bitiş'), findsOneWidget);
    expect(find.text('Öncüller'), findsOneWidget);
    expect(find.text('Kaynak Adları'), findsOneWidget);
    expect(find.text('Hafriyat ve zemin tesviyesi'), findsOneWidget);
    expect(find.text('Liste'), findsNothing);
    expect(find.text('Geciken'), findsNothing);
  });

  testWidgets('İZLEME tablosu fiili alanları gösterir', (tester) async {
    await tester.pumpWidget(host(const ProgramScreen()));
    await tester.pump();

    await tester.tap(find.text('İZLEME'));
    await tester.pump();

    expect(find.text('% Tamamlanma'), findsOneWidget);
    expect(find.text('Fiili Başlangıç'), findsOneWidget);
    expect(find.text('Fiili Bitiş'), findsOneWidget);
    expect(find.text('Fiili Süre'), findsOneWidget);
    expect(find.text('Kalan Süre'), findsOneWidget);
    expect(find.text('Fiili İş'), findsOneWidget);
    expect(find.text('Kalan İş'), findsOneWidget);
    expect(find.text('Hafriyat ve zemin tesviyesi'), findsOneWidget);
  });
}
