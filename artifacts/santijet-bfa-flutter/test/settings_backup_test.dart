import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:santijet_bfa/core/theme/theme_mode_provider.dart';
import 'package:santijet_bfa/data/services/backup_service.dart';
import 'package:santijet_bfa/domain/entities/kesif.dart';
import 'package:santijet_bfa/domain/entities/poz_analiz.dart';
import 'package:santijet_bfa/domain/enums/app_enums.dart';

late Directory _tempDir;
var _seq = 0;

void main() {
  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('bfa_settings_test');
    Hive.init(_tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await _tempDir.delete(recursive: true);
  });

  test('BfaBackup JSON round-trip', () {
    const backup = BfaBackup(
      exportedAt: '2026-06-23T00:00:00.000Z',
      userAnalizleri: [
        PozAnaliz(
          id: 'u1',
          pozNo: 'P.1',
          analizAdi: 'Özel analiz',
          olcuBirimi: 'Ad',
          kategori: 'Diğer',
          kaynakTip: KaynakTip.kullanici,
        ),
      ],
      favoriteIds: ['u1'],
      recentIds: ['u1'],
      kesifProjects: [
        KesifProject(
          id: 'k1',
          ad: 'A Blok',
          aciklama: '',
          satirlar: [],
          olusturmaTarihi: '2026',
          guncellemeTarihi: '2026',
        ),
      ],
      themeMode: 'dark',
    );

    final decoded = json.decode(json.encode(backup.toJson())) as Map;
    final parsed = BfaBackup.fromJson(decoded);

    expect(parsed.userAnalizleri.single.analizAdi, 'Özel analiz');
    expect(parsed.favoriteIds, ['u1']);
    expect(parsed.kesifProjects.single.ad, 'A Blok');
    expect(parsed.themeMode, 'dark');
  });

  test('ThemeModeNotifier Hive kalıcılığı', () async {
    final box = await Hive.openBox('settings_${_seq++}');
    final notifier = ThemeModeNotifier(box);
    expect(notifier.state, ThemeMode.system);

    notifier.set(ThemeMode.dark);
    final restored = ThemeModeNotifier(box);
    expect(restored.state, ThemeMode.dark);
  });
}
