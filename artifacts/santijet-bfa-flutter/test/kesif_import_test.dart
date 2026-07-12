import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_bfa/domain/entities/poz_analiz.dart';
import 'package:santijet_bfa/domain/enums/app_enums.dart';
import 'package:santijet_bfa/domain/kesif/kesif_import.dart';

const _catalog = [
  PozAnaliz(
    id: 'sys-1',
    pozNo: '15.225.1009',
    analizAdi: 'Gazbeton duvar yapılması',
    olcuBirimi: 'm²',
    kategori: 'Duvar',
    discipline: AnalizDiscipline.insaat,
  ),
];

void main() {
  test('validateImportRows poz typo önerir', () {
    const row = KesifImportRow(
      pozNo: '15.225.9999',
      analizAdi: 'Gazbeton duvar yapılması',
      olcuBirimi: 'm²',
      miktar: 2,
    );
    final result = validateImportRows([row], _catalog);
    expect(result.matched, isEmpty);
    expect(result.pozTypo.length, 1);
    expect(result.pozTypo.first.suggestedAnaliz?.pozNo, '15.225.1009');
  });

  test('parseCsvMatrix ve mapMatrixToRows keşif satırları üretir', () {
    const csv = '''
Proje: Test Keşif
#;Poz No;Tanım;Birim;Miktar
1;15.225.1009;Gazbeton duvar yapılması;m²;3
''';
    final matrix = parseCsvMatrix(csv);
    final parsed = mapMatrixToRows(matrix, 'test.csv');
    expect(parsed.rows.length, 1);
    expect(parsed.rows.first.pozNo, '15.225.1009');
    expect(parsed.rows.first.miktar, 3);
  });

  test('normalizeImportPozNo rakamları biçimlendirir', () {
    expect(normalizeImportPozNo('152251009'), '15.225.1009');
  });
}
