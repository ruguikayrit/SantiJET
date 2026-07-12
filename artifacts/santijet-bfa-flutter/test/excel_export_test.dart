import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_bfa/data/services/analiz_excel_export_service.dart';
import 'package:santijet_bfa/domain/entities/analiz_kalemi.dart';
import 'package:santijet_bfa/domain/entities/poz_analiz.dart';
import 'package:santijet_bfa/domain/enums/app_enums.dart';

void main() {
  const analiz = PozAnaliz(
    id: 'xlsx-1',
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

  test('Analiz XLSX paketi geçerli OpenXML dosyalarını içerir', () {
    final bytes = analizExcelExportService.buildBytes(analiz);
    expect(bytes.length, greaterThan(1000));

    final archive = ZipDecoder().decodeBytes(bytes);
    expect(archive.findFile('[Content_Types].xml'), isNotNull);
    expect(archive.findFile('xl/workbook.xml'), isNotNull);
    final sheet = archive.findFile('xl/worksheets/sheet1.xml');
    expect(sheet, isNotNull);

    final xml = utf8.decode(sheet!.content as List<int>);
    expect(xml, contains('ŞantiJET BFA'));
    expect(xml, contains('15.225.1009'));
    expect(xml, contains('Gazbeton duvar yapılması'));
  });
}
