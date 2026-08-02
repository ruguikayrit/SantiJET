import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_bfa/core/constants/poz_constants.dart';
import 'package:santijet_bfa/data/services/bulk_export_service.dart';
import 'package:santijet_bfa/data/services/compare_export_service.dart';
import 'package:santijet_bfa/data/services/kesif_export_service.dart';
import 'package:santijet_bfa/domain/calc/analiz_compare.dart';
import 'package:santijet_bfa/domain/calc/analiz_draft_helpers.dart';
import 'package:santijet_bfa/domain/entities/analiz_kalemi.dart';
import 'package:santijet_bfa/domain/entities/kesif.dart';
import 'package:santijet_bfa/domain/entities/poz_analiz.dart';
import 'package:santijet_bfa/domain/enums/app_enums.dart';

void main() {
  test('AnalizDraftHelpers toplam ve kalem tutarını hesaplar', () {
    const analiz = PozAnaliz(
      id: 'draft-1',
      pozNo: '99.001',
      analizAdi: 'Test',
      olcuBirimi: 'm²',
      kategori: 'Diğer',
      yukleniciKarOrani: 25,
      kalemler: [
        AnalizKalemi(
          id: 'k1',
          tip: AnalizKalemTip.malzeme,
          pozNo: '10',
          tanim: 'Malzeme',
          olcuBirimi: 'kg',
          miktar: 2,
          birimFiyati: 50,
          tutar: 0,
        ),
      ],
    );

    final result = AnalizDraftHelpers.applyTotals(analiz);
    expect(result.malzemeIscilikToplami, 100);
    expect(result.yukleniciKarTutari, 25);
    expect(result.birimFiyati, 125);
  });

  test('emptyTemplate varsayılan değerlerle oluşturulur', () {
    final template =
        AnalizDraftHelpers.emptyTemplate(AnalizDiscipline.mekanik);
    expect(template.discipline, AnalizDiscipline.mekanik);
    expect(template.kaynakTip, KaynakTip.kullanici);
    expect(template.yukleniciKarOrani, PozConstants.defaultYukleniciKarOrani);
  });

  test('CompareExportService XLSX üretir', () {
    const a1 = PozAnaliz(
      id: 'c1',
      pozNo: '15.225.1009',
      analizAdi: 'A',
      olcuBirimi: 'm²',
      kategori: 'Duvar',
      yukleniciKarOrani: 25,
      kalemler: [
        AnalizKalemi(
          id: 'k1',
          tip: AnalizKalemTip.malzeme,
          pozNo: '10',
          tanim: 'M',
          olcuBirimi: 'kg',
          miktar: 1,
          birimFiyati: 100,
          tutar: 100,
        ),
      ],
    );
    const a2 = PozAnaliz(
      id: 'c2',
      pozNo: '15.225.1010',
      analizAdi: 'B',
      olcuBirimi: 'm²',
      kategori: 'Duvar',
      yukleniciKarOrani: 25,
      kalemler: [
        AnalizKalemi(
          id: 'k2',
          tip: AnalizKalemTip.malzeme,
          pozNo: '10',
          tanim: 'M',
          olcuBirimi: 'kg',
          miktar: 1,
          birimFiyati: 200,
          tutar: 200,
        ),
      ],
    );
    final compare = buildAnalizCompare([a1, a2]);
    final bytes = compareExportService.buildExcelBytes(compare);
    final archive = ZipDecoder().decodeBytes(bytes);
    expect(archive.findFile('xl/worksheets/sheet1.xml'), isNotNull);
    final xml = utf8.decode(
      archive.findFile('xl/worksheets/sheet1.xml')!.content as List<int>,
    );
    expect(xml, contains('Birim Fiyat'));
    expect(xml, contains('15.225.1009'));
  });

  test('CompareExportService renkli ve mono PDF üretir', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const a1 = PozAnaliz(
      id: 'c1',
      pozNo: '15.225.1009',
      analizAdi: 'A',
      olcuBirimi: 'm²',
      kategori: 'Duvar',
      yukleniciKarOrani: 25,
      kalemler: [
        AnalizKalemi(
          id: 'k1',
          tip: AnalizKalemTip.malzeme,
          pozNo: '10',
          tanim: 'M',
          olcuBirimi: 'kg',
          miktar: 1,
          birimFiyati: 100,
          tutar: 100,
        ),
      ],
    );
    const a2 = PozAnaliz(
      id: 'c2',
      pozNo: '15.225.1010',
      analizAdi: 'B',
      olcuBirimi: 'm²',
      kategori: 'Duvar',
      yukleniciKarOrani: 25,
      kalemler: [
        AnalizKalemi(
          id: 'k2',
          tip: AnalizKalemTip.malzeme,
          pozNo: '10',
          tanim: 'M',
          olcuBirimi: 'kg',
          miktar: 1,
          birimFiyati: 200,
          tutar: 200,
        ),
      ],
    );
    final compare = buildAnalizCompare([a1, a2]);
    final colorBytes = await compareExportService.buildPdfBytes(
      compare,
      style: ComparePdfStyle.colorFilled,
    );
    final monoBytes = await compareExportService.buildPdfBytes(
      compare,
      style: ComparePdfStyle.monoPlain,
    );
    expect(colorBytes.length, greaterThan(1000));
    expect(monoBytes.length, greaterThan(1000));
    expect(colorBytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]); // %PDF
    expect(monoBytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
  });

  test('KesifExportService XLSX üretir', () {
    const project = KesifProject(
      id: 'kp1',
      ad: 'Test Keşif',
      aciklama: 'Açıklama',
      satirlar: [
        KesifSatiri(
          id: 's1',
          analizId: 'a1',
          pozNo: '15.225.1009',
          analizAdi: 'Duvar',
          olcuBirimi: 'm²',
          birimFiyati: 125,
          miktar: 10,
          tutar: 1250,
        ),
      ],
      olusturmaTarihi: '2026-01-01T00:00:00.000Z',
      guncellemeTarihi: '2026-01-01T00:00:00.000Z',
    );

    final bytes = kesifExportService.buildExcelBytes(project);
    final archive = ZipDecoder().decodeBytes(bytes);
    final xml = utf8.decode(
      archive.findFile('xl/worksheets/sheet1.xml')!.content as List<int>,
    );
    expect(xml, contains('Test Ke'));
    expect(xml, contains('15.225.1009'));
  });

  test('BulkExportService ZIP üretir', () async {
    const analiz = PozAnaliz(
      id: 'bulk-1',
      pozNo: '15.225.1009',
      analizAdi: 'Toplu Test',
      olcuBirimi: 'm²',
      kategori: 'Duvar',
      discipline: AnalizDiscipline.insaat,
      yukleniciKarOrani: 25,
    );
    final zipBytes = await bulkExportService.buildZipBytes(
      analizler: [analiz],
      asPdf: false,
    );
    final archive = ZipDecoder().decodeBytes(zipBytes);
    expect(archive.files.length, greaterThan(0));
    expect(
      archive.files.any((f) => f.name.endsWith('.xlsx')),
      isTrue,
    );
  });
}
