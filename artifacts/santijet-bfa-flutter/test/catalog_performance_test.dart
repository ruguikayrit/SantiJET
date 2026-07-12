import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_bfa/data/providers/catalog_provider.dart';
import 'package:santijet_bfa/domain/entities/poz_analiz.dart';
import 'package:santijet_bfa/domain/enums/app_enums.dart';

void main() {
  List<PozAnaliz> makeItems(int count) {
    return [
      for (var i = 0; i < count; i++)
        PozAnaliz(
          id: 'a$i',
          pozNo: '15.225.${1000 + i}',
          analizAdi: i.isEven ? 'Gazbeton duvar yapılması' : 'Betonarme kalıp',
          olcuBirimi: 'm²',
          kategori: i.isEven ? 'Duvar' : 'Kalıp',
          discipline: AnalizDiscipline.insaat,
        ),
    ];
  }

  test('CatalogData searchIn limit uygular ve sıralı sonuç döndürür', () {
    final catalog = CatalogData(
      byDiscipline: {AnalizDiscipline.insaat: makeItems(1000)},
    );

    final results = catalog.searchIn(catalog.all, 'gazbeton', limit: 10);

    expect(results.length, 10);
    expect(results.every((a) => a.analizAdi.contains('Gazbeton')), isTrue);
    expect(results.first.pozNo.compareTo(results.last.pozNo) <= 0, isTrue);
  });

  test('Kategori cache disipline göre sıklık sıralar', () {
    final catalog = CatalogData(
      byDiscipline: {AnalizDiscipline.insaat: makeItems(10)},
    );

    final cats = catalog.categoriesForDiscipline(AnalizDiscipline.insaat);
    expect(cats, containsAll(['Duvar', 'Kalıp']));
  });
}
