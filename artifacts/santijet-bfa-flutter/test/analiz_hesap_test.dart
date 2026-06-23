import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_bfa/core/utils/app_format.dart';
import 'package:santijet_bfa/domain/calc/analiz_hesap.dart';
import 'package:santijet_bfa/domain/entities/analiz_kalemi.dart';
import 'package:santijet_bfa/domain/entities/poz_analiz.dart';
import 'package:santijet_bfa/domain/enums/app_enums.dart';

void main() {
  group('AppFormat', () {
    test('TR ondalık biçim', () {
      expect(AppFormat.decimal(1061.58), '1.061,58');
      expect(AppFormat.decimal(1234567.5), '1.234.567,50');
      expect(AppFormat.decimal(0), '0,00');
    });

    test('para birimi', () {
      expect(AppFormat.currency(1061.58), '1.061,58 ₺');
    });

    test('tam sayı binlik', () {
      expect(AppFormat.integer(5911), '5.911');
    });
  });

  group('AnalizHesap', () {
    test('kalem toplamı + %25 kâr', () {
      const analiz = PozAnaliz(
        id: 'x',
        pozNo: '1',
        analizAdi: 'test',
        olcuBirimi: 'm²',
        kategori: 'Duvar',
        yukleniciKarOrani: 25,
        kalemler: [
          AnalizKalemi(
            id: 'a',
            tip: AnalizKalemTip.malzeme,
            pozNo: 'm',
            tanim: 'malzeme',
            olcuBirimi: 'm³',
            miktar: 1,
            birimFiyati: 100,
            tutar: 100,
          ),
          AnalizKalemi(
            id: 'b',
            tip: AnalizKalemTip.iscilik,
            pozNo: 'i',
            tanim: 'iscilik',
            olcuBirimi: 'sa',
            miktar: 1,
            birimFiyati: 300,
            tutar: 300,
          ),
        ],
      );

      final h = AnalizHesap.hesapla(analiz);
      expect(h.malzemeIscilikToplami, 400);
      expect(h.yukleniciKarTutari, 100);
      expect(h.birimFiyati, 500);
    });

    test('satır tutarı = miktar × birim fiyat (kuruş)', () {
      expect(AnalizHesap.satirTutar(100, 1061.58), 106158);
      expect(AnalizHesap.satirTutar(2.5, 39.66), 99.15);
    });
  });
}
