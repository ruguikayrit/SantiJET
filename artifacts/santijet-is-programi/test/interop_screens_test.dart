import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:santijet_is_programi/data/daily_crew_repository.dart';
import 'package:santijet_is_programi/data/interop/msproject_xml_codec.dart';
import 'package:santijet_is_programi/data/program_repository.dart';
import 'package:santijet_is_programi/features/interop/import_preview_screen.dart';
import 'package:santijet_is_programi/features/interop/transfer_screen.dart';

Widget host(Widget child) => ProviderScope(child: MaterialApp(home: child));

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('isprog_ui');
    Hive.init(hiveDir.path);
    await Hive.openBox<String>(programBoxName);
    await Hive.openBox<dynamic>(settingsBoxName);
    await Hive.openBox<String>(dailyCrewBoxName);
  });

  setUp(() async {
    await Hive.box<String>(programBoxName).clear();
    await Hive.box<dynamic>(settingsBoxName).clear();
    await Hive.box<String>(dailyCrewBoxName).clear();
    await ProgramRepository(
      Hive.box<String>(programBoxName),
    ).replaceWithDemo(today: DateTime(2026, 3, 10));
    await Hive.box<dynamic>(
      settingsBoxName,
    ).put('defaultSite', 'Merkez Şantiyesi');
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  testWidgets(
    'Aktar sayfası üç dışa aktarım biçimini ve içe aktarımı gösterir',
    (tester) async {
      await tester.pumpWidget(host(const TransferScreen()));
      await tester.pump();

      expect(find.text('Aktar'), findsOneWidget);
      expect(find.text('MS PROJECT’E AKTAR'), findsOneWidget);
      expect(find.text('MS Project XML'), findsOneWidget);
      expect(find.text('Excel (.xlsx)'), findsOneWidget);
      expect(find.text('PDF raporu'), findsOneWidget);
      expect(find.text('MS PROJECT’TEN AL'), findsOneWidget);
      expect(find.text('Dosya seç ve önizle'), findsOneWidget);
    },
  );

  testWidgets('kapsam anahtarı tüm şantiyelere geçer', (tester) async {
    await tester.pumpWidget(host(const TransferScreen()));
    await tester.pump();

    expect(find.text('Merkez Şantiyesi'), findsOneWidget);
    expect(find.textContaining('7 faaliyet aktarılacak'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(find.text('Tüm şantiyeler'), findsOneWidget);
    expect(find.textContaining('10 faaliyet aktarılacak'), findsOneWidget);
  });

  testWidgets(
    'içe aktarım önizlemesi okunan faaliyetleri ve seçenekleri gösterir',
    (tester) async {
      final result = const MsProjectXmlCodec().decode(
        const MsProjectXmlCodec().encode(
          demoProgramItems(DateTime(2026, 3, 10)),
          projectName: 'Konut Projesi',
          now: DateTime(2026, 3, 10),
        ),
        fallbackSite: 'Merkez Şantiyesi',
        today: DateTime(2026, 3, 10),
      );

      await tester.pumpWidget(host(ImportPreviewScreen(result: result)));
      await tester.pump();

      expect(find.text('Konut Projesi'), findsOneWidget);
      expect(find.text('10 faaliyet · 2 şantiye'), findsOneWidget);
      expect(find.text('Birleştir'), findsOneWidget);
      expect(find.text('Programı değiştir'), findsOneWidget);
      expect(find.text('Programa ekle (10)'), findsOneWidget);

      await tester.ensureVisible(find.text('Programı değiştir'));
      await tester.tap(find.text('Programı değiştir'));
      await tester.pump();
      expect(find.text('Programı değiştir (10)'), findsOneWidget);
    },
  );

  test('birleştirme aynı kimlikli satırı çoğaltmaz', () async {
    final repository = ProgramRepository(Hive.box<String>(programBoxName));
    final result = const MsProjectXmlCodec().decode(
      const MsProjectXmlCodec().encode(
        demoProgramItems(DateTime(2026, 3, 10)),
        projectName: 'Konut Projesi',
        now: DateTime(2026, 3, 10),
      ),
      fallbackSite: 'Merkez Şantiyesi',
      today: DateTime(2026, 3, 10),
    );

    await repository.replaceAll(result.items);
    await repository.saveAll(result.items);

    final stored = repository.readAll();
    expect(stored, hasLength(10));
    expect(stored.map((item) => item.id).toSet(), hasLength(10));
    expect(stored.map((item) => item.santiyeId).toSet(), {
      'Merkez Şantiyesi',
      'Depo Şantiyesi',
    });
  });
}
