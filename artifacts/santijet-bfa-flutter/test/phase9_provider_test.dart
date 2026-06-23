import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:santijet_bfa/data/providers/kesif_provider.dart';
import 'package:santijet_bfa/data/providers/user_analiz_provider.dart';
import 'package:santijet_bfa/domain/entities/analiz_kalemi.dart';
import 'package:santijet_bfa/domain/entities/poz_analiz.dart';
import 'package:santijet_bfa/domain/enums/app_enums.dart';

late Directory _tempDir;
var _seq = 0;

const _source = PozAnaliz(
  id: 'sys-1',
  pozNo: '15.225.1009',
  analizAdi: 'Gazbeton duvar yapılması',
  olcuBirimi: 'm²',
  kategori: 'Duvar',
  kaynakTip: KaynakTip.sistem,
  discipline: AnalizDiscipline.insaat,
  yukleniciKarOrani: 25,
  kalemler: [
    AnalizKalemi(
      id: 'k1',
      tip: AnalizKalemTip.malzeme,
      pozNo: '10.013',
      tanim: 'Gazbeton',
      olcuBirimi: 'm³',
      miktar: 1,
      birimFiyati: 100,
      tutar: 100,
    ),
  ],
);

Future<Box> _box(String prefix) async => Hive.openBox('$prefix${_seq++}');

void main() {
  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('bfa_phase9_test');
    Hive.init(_tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await _tempDir.delete(recursive: true);
  });

  test('UserAnalizNotifier sistem kaydını kopyaya çevirir ve saklar', () async {
    final box = await _box('user');
    final notifier = UserAnalizNotifier(box);

    final copy = notifier.clone(_source);

    expect(notifier.state.length, 1);
    expect(copy.kaynakTip, KaynakTip.kopya);
    expect(copy.id, isNot(_source.id));
    expect((box.get('items') as List).length, 1);
  });

  test('KesifNotifier proje oluşturur, satır ekler ve tutarı hesaplar',
      () async {
    final box = await _box('kesif');
    final notifier = KesifNotifier(box);

    final projectId = notifier.createProject('A Blok');
    notifier.addSatir(projectId, _source, 2);

    final project = notifier.byId(projectId)!;
    expect(project.ad, 'A Blok');
    expect(project.satirlar.length, 1);
    // Kalem toplamı 100 + %25 kâr = 125; miktar 2 => 250.
    expect(project.toplam, 250);
  });
}
