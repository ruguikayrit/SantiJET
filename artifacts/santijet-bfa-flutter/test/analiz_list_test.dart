import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:santijet_bfa/core/theme/app_theme.dart';
import 'package:santijet_bfa/data/providers/catalog_provider.dart';
import 'package:santijet_bfa/data/providers/favorites_provider.dart';
import 'package:santijet_bfa/data/providers/recent_views_provider.dart';
import 'package:santijet_bfa/domain/entities/poz_analiz.dart';
import 'package:santijet_bfa/domain/enums/app_enums.dart';
import 'package:santijet_bfa/features/analiz_list/analiz_list_screen.dart';

late Directory _tempDir;
var _seq = 0;

const _sample = [
  PozAnaliz(
    id: 'a1',
    pozNo: '15.225.1009',
    analizAdi: 'Gazbeton duvar yapılması',
    olcuBirimi: 'm²',
    kategori: 'Duvar',
    birimFiyati: 1061.58,
    discipline: AnalizDiscipline.insaat,
  ),
  PozAnaliz(
    id: 'a2',
    pozNo: '15.100.1002',
    analizAdi: 'Kum çakıl taşıma',
    olcuBirimi: 'm³',
    kategori: 'Yükleme ve Taşıma',
    birimFiyati: 39.66,
    discipline: AnalizDiscipline.insaat,
  ),
];

Future<List<Override>> _overrides() async {
  final fav = await Hive.openBox('lfav_${_seq++}');
  final rec = await Hive.openBox('lrec_${_seq++}');
  return [
    favoritesBoxProvider.overrideWithValue(fav),
    recentBoxProvider.overrideWithValue(rec),
    catalogProvider.overrideWith(
      (ref) => Future.value(
        CatalogData(byDiscipline: {AnalizDiscipline.insaat: _sample}),
      ),
    ),
  ];
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await _overrides(),
        child: MaterialApp(theme: AppTheme.light, home: child),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('bfa_list_test');
    Hive.init(_tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await _tempDir.delete(recursive: true);
  });

  test('kategoriler sıklığa göre döner', () {
    final cats = CatalogData.kategoriler(_sample);
    expect(cats, containsAll(['Duvar', 'Yükleme ve Taşıma']));
  });

  testWidgets('liste analizleri ve sayıyı gösterir', (tester) async {
    await _pump(tester, const AnalizListScreen(modul: 'insaat'));
    expect(find.text('İnşaat B.F.A.'), findsOneWidget);
    expect(find.text('2 analiz'), findsOneWidget);
    expect(find.text('Gazbeton duvar yapılması'), findsOneWidget);
  });

  testWidgets('arama sonuçları filtreler', (tester) async {
    await _pump(
        tester, const AnalizListScreen(modul: 'insaat', query: 'gazbeton'));
    expect(find.text('Gazbeton duvar yapılması'), findsOneWidget);
    expect(find.text('Kum çakıl taşıma'), findsNothing);
  });

  testWidgets('boş favoriler durumu', (tester) async {
    await _pump(tester, const AnalizListScreen(modul: 'favoriler'));
    expect(find.text('Henüz favori yok'), findsOneWidget);
  });
}
