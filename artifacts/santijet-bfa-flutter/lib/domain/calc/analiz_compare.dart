import '../entities/analiz_kalemi.dart';
import '../entities/poz_analiz.dart';
import '../enums/app_enums.dart';
import 'analiz_hesap.dart';

class AnalizCompareSummary {
  const AnalizCompareSummary({
    required this.id,
    required this.pozNo,
    required this.analizAdi,
    required this.olcuBirimi,
    required this.malzemeIscilikToplami,
    required this.yukleniciKarOrani,
    required this.yukleniciKarTutari,
    required this.birimFiyati,
  });

  final String id;
  final String pozNo;
  final String analizAdi;
  final String olcuBirimi;
  final double malzemeIscilikToplami;
  final double yukleniciKarOrani;
  final double yukleniciKarTutari;
  final double birimFiyati;
}

class CompareKalemValue {
  const CompareKalemValue({
    required this.miktar,
    required this.birimFiyati,
    required this.tutar,
  });

  final double miktar;
  final double birimFiyati;
  final double tutar;
}

class CompareKalemRow {
  const CompareKalemRow({
    required this.key,
    required this.pozNo,
    required this.tanim,
    required this.tip,
    required this.olcuBirimi,
    required this.values,
  });

  final String key;
  final String pozNo;
  final String tanim;
  final AnalizKalemTip tip;
  final String olcuBirimi;
  final Map<String, CompareKalemValue?> values;
}

class AnalizCompareResult {
  const AnalizCompareResult({
    required this.analizler,
    required this.kalemRows,
    required this.minBirimFiyati,
    required this.maxBirimFiyati,
  });

  final List<AnalizCompareSummary> analizler;
  final List<CompareKalemRow> kalemRows;
  final double minBirimFiyati;
  final double maxBirimFiyati;
}

String _kalemKey(AnalizKalemi k) =>
    '${k.tip.name}|${k.pozNo.trim().toLowerCase()}|${k.tanim.trim().toLowerCase()}';

AnalizCompareResult buildAnalizCompare(List<PozAnaliz> analizler) {
  final summaries = analizler.map((a) {
    final totals = AnalizHesap.hesapla(a);
    return AnalizCompareSummary(
      id: a.id,
      pozNo: a.pozNo,
      analizAdi: a.analizAdi,
      olcuBirimi: a.olcuBirimi,
      malzemeIscilikToplami: totals.malzemeIscilikToplami,
      yukleniciKarOrani: a.yukleniciKarOrani,
      yukleniciKarTutari: totals.yukleniciKarTutari,
      birimFiyati: totals.birimFiyati,
    );
  }).toList();

  final rowMap = <String, CompareKalemRow>{};

  for (final analiz in analizler) {
    for (final k in analiz.kalemler) {
      final key = _kalemKey(k);
      final existing = rowMap[key];
      if (existing == null) {
        rowMap[key] = CompareKalemRow(
          key: key,
          pozNo: k.pozNo,
          tanim: k.tanim,
          tip: k.tip,
          olcuBirimi: k.olcuBirimi,
          values: {
            analiz.id: CompareKalemValue(
              miktar: k.miktar,
              birimFiyati: k.birimFiyati,
              tutar: k.tutar,
            ),
          },
        );
      } else {
        final nextValues = Map<String, CompareKalemValue?>.from(existing.values);
        nextValues[analiz.id] = CompareKalemValue(
          miktar: k.miktar,
          birimFiyati: k.birimFiyati,
          tutar: k.tutar,
        );
        rowMap[key] = CompareKalemRow(
          key: existing.key,
          pozNo: existing.pozNo,
          tanim: existing.tanim,
          tip: existing.tip,
          olcuBirimi: existing.olcuBirimi,
          values: nextValues,
        );
      }
    }
  }

  int tipOrder(AnalizKalemTip tip) => switch (tip) {
        AnalizKalemTip.malzeme => 0,
        AnalizKalemTip.iscilik => 1,
        AnalizKalemTip.ekipman => 2,
      };

  final kalemRows = rowMap.values.toList()
    ..sort((a, b) {
      final tipDiff = tipOrder(a.tip) - tipOrder(b.tip);
      if (tipDiff != 0) return tipDiff;
      return a.pozNo.compareTo(b.pozNo) != 0
          ? a.pozNo.compareTo(b.pozNo)
          : a.tanim.compareTo(b.tanim);
    });

  final birimFiyatlari = summaries.map((s) => s.birimFiyati).toList();
  return AnalizCompareResult(
    analizler: summaries,
    kalemRows: kalemRows,
    minBirimFiyati: birimFiyatlari.reduce((a, b) => a < b ? a : b),
    maxBirimFiyati: birimFiyatlari.reduce((a, b) => a > b ? a : b),
  );
}
