import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:santijet_bfa/core/theme/app_theme.dart';
import 'package:santijet_bfa/data/providers/catalog_provider.dart';
import 'package:santijet_bfa/data/providers/favorites_provider.dart';
import 'package:santijet_bfa/data/providers/recent_views_provider.dart';
import 'package:santijet_bfa/domain/entities/analiz_kalemi.dart';
import 'package:santijet_bfa/domain/entities/poz_analiz.dart';
import 'package:santijet_bfa/domain/enums/app_enums.dart';
import 'package:santijet_bfa/features/analiz_detail/analiz_detail_screen.dart';

late Directory _tempDir;
var _seq = 0;

const _analiz = PozAnaliz(
  id: 'd1',
  pozNo: '15.225.1009',
  analizAdi: 'Gazbeton duvar yapılması',
  olcuBirimi: 'm²',
  kategori: 'Duvar',
  yukleniciKarOrani: 25,
  discipline: AnalizDiscipline.insaat,
  pozTarifi: 'Duvar yapım tarifi metni.',
  kalemler: [
    AnalizKalemi(
      id: 'k1',
      tip: AnalizKalemTip.malzeme,
      pozNo: '10.013.1001',
      tanim: 'Gazbeton bloğu',
      olcuBirimi: 'm³',
      miktar: 0.19,
      birimFiyati: 2850,
      tutar: 541.5,
    ),
  ],
);

Future<List<Override>> _overrides() async {
  final fav = await Hive.openBox('dfav_${_seq++}');
  final rec = await Hive.openBox('drec_${_seq++}');
  return [
    favoritesBoxProvider.overrideWithValue(fav),
    recentBoxProvider.overrideWithValue(rec),
    catalogProvider.overrideWith(
      (ref) => Future.value(
        CatalogData(byDiscipline: {
          AnalizDiscipline.insaat: const [_analiz]
        }),
      ),
    ),
  ];
}

void main() {
  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('bfa_detail_test');
    Hive.init(_tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await _tempDir.delete(recursive: true);
  });

  testWidgets('detay başlık, tarif ve kalemleri gösterir', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: await _overrides(),
          child: const MaterialApp(home: _Host(id: 'd1')),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('15.225.1009'), findsWidgets);
    expect(find.text('Gazbeton duvar yapılması'), findsOneWidget);
    expect(find.text('Poz Tarifi'), findsOneWidget);
    expect(find.text('Malzeme Kalemleri'), findsOneWidget);
    expect(find.text('Metraj & Maliyet'), findsOneWidget);
  });

  testWidgets('bulunamayan analiz hata gösterir', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: await _overrides(),
          child: const MaterialApp(home: _Host(id: 'yok')),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Açılamadı'), findsOneWidget);
  });
}

class _Host extends StatelessWidget {
  const _Host({required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: AnalizDetailScreen(analizId: id),
    );
  }
}
