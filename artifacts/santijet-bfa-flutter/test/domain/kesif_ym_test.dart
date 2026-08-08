import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_bfa/domain/entities/kesif.dart';

void main() {
  group('KesifSatiri', () {
    test('fromJson eski kayıtları okur (fiyatKaynagi/metrajNotu yok)', () {
      final s = KesifSatiri.fromJson({
        'id': 'ks1',
        'analizId': 'a1',
        'pozNo': '10.001',
        'analizAdi': 'Test',
        'olcuBirimi': 'm2',
        'birimFiyati': 100,
        'miktar': 2,
      });
      expect(s.tutar, 200);
      expect(s.fiyatKaynagi, KesifFiyatKaynagi.katalog);
      expect(s.metrajNotu, '');
    });
  });

  group('KesifProject YM', () {
    test('toplamByOlcuBirimi birimleri gruplar', () {
      final p = KesifProject(
        id: 'kp1',
        ad: 'Test',
        aciklama: '',
        satirlar: const [
          KesifSatiri(
            id: '1',
            analizId: 'a',
            pozNo: '1',
            analizAdi: 'A',
            olcuBirimi: 'm2',
            birimFiyati: 10,
            miktar: 2,
            tutar: 20,
          ),
          KesifSatiri(
            id: '2',
            analizId: 'b',
            pozNo: '2',
            analizAdi: 'B',
            olcuBirimi: 'm2',
            birimFiyati: 5,
            miktar: 4,
            tutar: 20,
          ),
          KesifSatiri(
            id: '3',
            analizId: 'c',
            pozNo: '3',
            analizAdi: 'C',
            olcuBirimi: 'm3',
            birimFiyati: 100,
            miktar: 1,
            tutar: 100,
          ),
        ],
        olusturmaTarihi: '',
        guncellemeTarihi: '',
      );
      expect(p.toplam, 140);
      expect(p.toplamByOlcuBirimi['m2'], 40);
      expect(p.toplamByOlcuBirimi['m3'], 100);
    });
  });
}
