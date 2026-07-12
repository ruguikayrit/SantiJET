import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_bfa/data/services/analiz_pdf_export_service.dart';
import 'package:santijet_bfa/domain/entities/analiz_kalemi.dart';
import 'package:santijet_bfa/domain/entities/poz_analiz.dart';
import 'package:santijet_bfa/domain/enums/app_enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const analiz = PozAnaliz(
    id: 'pdf-1',
    pozNo: '15.225.1009',
    analizAdi: 'Gazbeton duvar yapılması',
    olcuBirimi: 'm²',
    kategori: 'Duvar',
    discipline: AnalizDiscipline.insaat,
    yukleniciKarOrani: 25,
    pozTarifi: 'Poz tarifi metni.',
    kalemler: [
      AnalizKalemi(
        id: 'k1',
        tip: AnalizKalemTip.malzeme,
        pozNo: '10.013',
        tanim: 'Gazbeton bloğu',
        olcuBirimi: 'm³',
        miktar: 1,
        birimFiyati: 100,
        tutar: 100,
      ),
    ],
  );

  test('Analiz PDF bytes üretir', () async {
    final bytes = await analizPdfExportService.buildBytes(analiz);
    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });
}
