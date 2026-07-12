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
import 'package:santijet_bfa/features/home/home_screen.dart';

late Directory _tempDir;
var _seq = 0;

Future<List<Override>> _overrides() async {
  final fav = await Hive.openBox('fav_${_seq++}');
  final rec = await Hive.openBox('rec_${_seq++}');
  return [
    favoritesBoxProvider.overrideWithValue(fav),
    recentBoxProvider.overrideWithValue(rec),
    catalogProvider.overrideWith(
      (ref) => Future.value(
        CatalogData(
          byDiscipline: {
            AnalizDiscipline.insaat: const [
              PozAnaliz(
                id: 's1',
                pozNo: '15.225.1009',
                analizAdi: 'Gazbeton duvar yapılması',
                olcuBirimi: 'm²',
                kategori: 'Duvar',
                birimFiyati: 1061.58,
                discipline: AnalizDiscipline.insaat,
              ),
            ],
          },
        ),
      ),
    ),
  ];
}

void main() {
  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('bfa_test');
    Hive.init(_tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await _tempDir.delete(recursive: true);
  });

  testWidgets('Ana sayfa marka, modüller ve canlı sayıyı gösterir',
      (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: await _overrides(),
          child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ŞantiJET BFA'), findsWidgets);
    expect(find.text('Modüller'), findsOneWidget);
    expect(find.text('İnşaat B.F.A.'), findsOneWidget);
  });
}
