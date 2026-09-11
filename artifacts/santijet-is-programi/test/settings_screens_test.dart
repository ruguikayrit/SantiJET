import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:santijet_is_programi/data/daily_crew_repository.dart';
import 'package:santijet_is_programi/data/program_repository.dart';
import 'package:santijet_is_programi/data/project_repository.dart';
import 'package:santijet_is_programi/features/settings/about_screen.dart';
import 'package:santijet_is_programi/features/settings/app_intro_screen.dart';
import 'package:santijet_is_programi/features/settings/projects_screen.dart';
import 'package:santijet_is_programi/features/settings/settings_screen.dart';
import 'package:santijet_is_programi/features/settings/work_code_screen.dart';

Widget host(Widget child) => ProviderScope(child: MaterialApp(home: child));

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('isprog_settings');
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
    await ProjectRepository(
      Hive.box<String>(projectBoxName),
    ).migrateFromSiteNames(['Merkez Şantiyesi']);
    final project = ProjectRepository(
      Hive.box<String>(projectBoxName),
    ).readAll().single;
    await Hive.box<dynamic>(settingsBoxName).put('activeProjectId', project.id);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  testWidgets('Ayarlar saha düzenindeki kutuları listeler', (tester) async {
    await tester.pumpWidget(host(const SettingsScreen()));
    await tester.pump();

    expect(find.text('Hesap'), findsOneWidget);
    expect(find.text('İş kodu'), findsOneWidget);
    expect(find.text('Projelerim'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Yedekleme'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Hakkında'), 400);
    expect(find.text('Geri yükleme'), findsOneWidget);
    expect(find.text('Demo veriyi yükle'), findsOneWidget);
    expect(find.text('Uygulama tanıtımı'), findsOneWidget);
    expect(find.text('Hakkında'), findsOneWidget);
  });

  testWidgets('Projelerim aktif şantiyeyi gösterir', (tester) async {
    await tester.pumpWidget(host(const ProjectsScreen()));
    await tester.pump();

    expect(find.text('Merkez Şantiyesi'), findsOneWidget);
    expect(find.text('Yeni şantiye'), findsOneWidget);
  });

  testWidgets('iş kodu ekranı yerel kodu gösterir', (tester) async {
    await tester.pumpWidget(host(const WorkCodeScreen()));
    await tester.pump();

    expect(find.text('Koda geç'), findsWidgets);
    expect(find.textContaining('SJ'), findsWidgets);
  });

  testWidgets('tanıtım adam-gün anlatır', (tester) async {
    await tester.pumpWidget(host(const AppIntroScreen()));
    await tester.pump();

    expect(find.text('Giriş tablosu'), findsOneWidget);
    expect(find.text('Gantt'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cihazda kalır'), 400);
    expect(find.text('Cihazda kalır'), findsOneWidget);
  });

  testWidgets('hakkında ürün adını gösterir', (tester) async {
    await tester.pumpWidget(host(const AboutScreen()));
    await tester.pump();

    expect(find.text('ŞantiJET İş Programı'), findsOneWidget);
  });
}
