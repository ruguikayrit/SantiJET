import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_bfa/data/services/backup_service.dart';
import 'package:santijet_bfa/domain/entities/kesif.dart';
import 'package:santijet_bfa/domain/entities/poz_analiz.dart';
import 'package:santijet_bfa/domain/enums/app_enums.dart';

void main() {
  test('RN santijet-bfa yedeği Flutter tarafından okunur', () {
    final rnJson = {
      'version': 2,
      'app': 'santijet-bfa',
      'exportedAt': '2026-07-12T10:00:00.000Z',
      'pozAnalizleri': [
        {
          'id': 'pa_test_1',
          'pozNo': '99.999.0001',
          'analizAdi': 'Test Analizi',
          'olcuBirimi': 'm²',
          'kategori': 'Diğer',
          'kalemler': [],
          'pozTarifi': '',
          'yapimSartlari': '',
          'olcusu': '',
          'malzemeIscilikToplami': 100,
          'yukleniciKarOrani': 25,
          'yukleniciKarTutari': 25,
          'birimFiyati': 125,
          'olusturmaTarihi': '2026-01-01T00:00:00.000Z',
          'guncellemeTarihi': '2026-01-01T00:00:00.000Z',
          'kaynakTip': 'kullanici',
          'discipline': 'insaat',
        },
      ],
      'favoriteIds': ['pa_test_1'],
      'recentIds': ['pa_test_1'],
      'kesifProjects': [
        {
          'id': 'kp_test_1',
          'ad': 'Test Keşif',
          'aciklama': '',
          'satirlar': [],
          'olusturmaTarihi': '2026-01-01T00:00:00.000Z',
          'guncellemeTarihi': '2026-01-01T00:00:00.000Z',
        },
      ],
      'themeMode': 'dark',
    };

    final backup = BfaBackup.fromJson(rnJson);
    expect(backup.userAnalizleri, hasLength(1));
    expect(backup.userAnalizleri.first.pozNo, '99.999.0001');
    expect(backup.favoriteIds, ['pa_test_1']);
    expect(backup.kesifProjects, hasLength(1));
    expect(backup.themeMode, 'dark');
  });

  test('Flutter yedeği RN alan adlarıyla uyumlu JSON üretir', () {
    final backup = BfaBackup(
      exportedAt: '2026-07-12T10:00:00.000Z',
      userAnalizleri: [
        PozAnaliz(
          id: 'pa_flutter_1',
          pozNo: '88.888.0001',
          analizAdi: 'Flutter Analiz',
          olcuBirimi: 'm²',
          kategori: 'Beton ve Demir',
          kaynakTip: KaynakTip.kullanici,
          discipline: AnalizDiscipline.insaat,
        ),
      ],
      favoriteIds: ['pa_flutter_1'],
      recentIds: const [],
      kesifProjects: const [],
      themeMode: 'system',
    );

    final json = backup.toJson();
    expect(json['app'], 'santijet-bfa-flutter');
    expect(json['userAnalizleri'], isA<List>());
    final roundTrip = BfaBackup.fromJson(json);
    expect(roundTrip.userAnalizleri.first.id, 'pa_flutter_1');
  });

  test('Bozuk yedek dosyası reddedilir', () {
    expect(
      () => BfaBackup.fromJson({'app': 'other-app'}),
      throwsA(isA<FormatException>()),
    );
  });
}
