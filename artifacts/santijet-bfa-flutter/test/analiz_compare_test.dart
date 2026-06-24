import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_bfa/domain/calc/analiz_compare.dart';
import 'package:santijet_bfa/domain/entities/analiz_kalemi.dart';
import 'package:santijet_bfa/domain/entities/poz_analiz.dart';
import 'package:santijet_bfa/domain/enums/app_enums.dart';

void main() {
  test('buildAnalizCompare birim fiyat min/max hesaplar', () {
    const a1 = PozAnaliz(
      id: 'a1',
      pozNo: '15.225.1009',
      analizAdi: 'Analiz A',
      olcuBirimi: 'm²',
      kategori: 'Duvar',
      yukleniciKarOrani: 25,
      kalemler: [
        AnalizKalemi(
          id: 'k1',
          tip: AnalizKalemTip.malzeme,
          pozNo: '10.013',
          tanim: 'Malzeme',
          olcuBirimi: 'm³',
          miktar: 1,
          birimFiyati: 100,
          tutar: 100,
        ),
      ],
    );
    const a2 = PozAnaliz(
      id: 'a2',
      pozNo: '15.225.1010',
      analizAdi: 'Analiz B',
      olcuBirimi: 'm²',
      kategori: 'Duvar',
      yukleniciKarOrani: 25,
      kalemler: [
        AnalizKalemi(
          id: 'k2',
          tip: AnalizKalemTip.malzeme,
          pozNo: '10.013',
          tanim: 'Malzeme',
          olcuBirimi: 'm³',
          miktar: 1,
          birimFiyati: 200,
          tutar: 200,
        ),
      ],
    );

    final compare = buildAnalizCompare([a1, a2]);
    expect(compare.analizler.length, 2);
    expect(compare.minBirimFiyati, 125);
    expect(compare.maxBirimFiyati, 250);
    expect(compare.kalemRows.length, 1);
  });
}
