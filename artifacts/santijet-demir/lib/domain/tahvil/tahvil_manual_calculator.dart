import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/domain/tahvil/tahvil_rules.dart';

class TahvilManualInputRow {
  const TahvilManualInputRow({
    this.diameter,
    this.quantity,
    this.spacingCm,
  });

  final int? diameter;
  final int? quantity;
  final double? spacingCm;

  bool get isComplete =>
      diameter != null &&
      diameter! > 0 &&
      quantity != null &&
      quantity! > 0 &&
      spacingCm != null &&
      spacingCm! > 0;
}

class TahvilManualResult {
  const TahvilManualResult({
    required this.toDiameter,
    required this.equivalentQuantity,
    required this.resultingSpacingCm,
    required this.isAllowed,
    required this.areaDeviationPercent,
    this.rejectReason,
  });

  final int toDiameter;
  final int equivalentQuantity;
  final double? resultingSpacingCm;
  final bool isAllowed;
  final double areaDeviationPercent;
  final String? rejectReason;
}

List<TahvilManualResult> computeManualTahvilResults({
  required int fromDiameter,
  required int fromQuantity,
  required double? fromSpacingCm,
}) {
  final results = <TahvilManualResult>[];

  for (final toDiameter in RebarWeightCalculator.standardDiameters) {
    if (toDiameter == fromDiameter) continue;

    final diameterAllowed = isTahvilDiameterAllowed(fromDiameter, toDiameter);

    final equivalentQuantity = computeTahvilEquivalentQuantity(
      fromDiameter: fromDiameter,
      fromQuantity: fromQuantity,
      toDiameter: toDiameter,
    );
    if (equivalentQuantity <= 0) continue;

    final areaDeviationPercent = computeAreaDeviationRatio(
          fromDiameter: fromDiameter,
          fromQuantity: fromQuantity,
          toDiameter: toDiameter,
          equivalentQuantity: equivalentQuantity,
        ) *
        100;

    final resultingSpacingCm = computeResultingSpacingCm(
      fromQuantity: fromQuantity,
      equivalentQuantity: equivalentQuantity,
      spacingCm: fromSpacingCm,
    );

    String? rejectReason;
    if (!diameterAllowed) {
      rejectReason =
          '±$tahvilMaxDiameterDiffMm mm çap (fark ${(fromDiameter - toDiameter).abs()} mm)';
    } else if (areaDeviationPercent / 100 > tahvilMaxAreaDeviationRatio) {
      rejectReason =
          'Sapma %${areaDeviationPercent.toStringAsFixed(1)} '
          '(limit %${(tahvilMaxAreaDeviationRatio * 100).toStringAsFixed(0)})';
    } else if (!passesSpacingRule(
      fromQuantity: fromQuantity,
      equivalentQuantity: equivalentQuantity,
      spacingCm: fromSpacingCm,
    )) {
      rejectReason = resultingSpacingCm != null
          ? 'Aralık ${resultingSpacingCm.toStringAsFixed(1)} cm '
              '(limit ${tahvilMaxSpacingCm.toStringAsFixed(0)} cm)'
          : 'Aralık limiti aşılıyor';
    }

    results.add(
      TahvilManualResult(
        toDiameter: toDiameter,
        equivalentQuantity: equivalentQuantity,
        resultingSpacingCm: resultingSpacingCm,
        isAllowed: rejectReason == null,
        areaDeviationPercent: areaDeviationPercent,
        rejectReason: rejectReason,
      ),
    );
  }

  results.sort((a, b) {
    if (a.isAllowed != b.isAllowed) return a.isAllowed ? -1 : 1;
    if (a.isAllowed && b.isAllowed) {
      return _compareTahvilByOptimality(fromDiameter, a, b);
    }
    return (fromDiameter - a.toDiameter)
        .abs()
        .compareTo((fromDiameter - b.toDiameter).abs());
  });

  return results;
}

int _compareTahvilByOptimality(
  int fromDiameter,
  TahvilManualResult a,
  TahvilManualResult b,
) {
  final areaDiff = a.areaDeviationPercent.compareTo(b.areaDeviationPercent);
  if (areaDiff != 0) return areaDiff;
  return (fromDiameter - a.toDiameter)
      .abs()
      .compareTo((fromDiameter - b.toDiameter).abs());
}

/// Kurallara uygun hedef çapları kesit alanı sapmasına göre sıralar.
List<TahvilManualResult> computeAllowedManualTahvilResults({
  required int fromDiameter,
  required int fromQuantity,
  required double? fromSpacingCm,
}) {
  final allowed = computeManualTahvilResults(
    fromDiameter: fromDiameter,
    fromQuantity: fromQuantity,
    fromSpacingCm: fromSpacingCm,
  ).where((result) => result.isAllowed).toList();

  allowed.sort(
    (a, b) => _compareTahvilByOptimality(fromDiameter, a, b),
  );

  return allowed;
}

/// Kurallara uygun hedef çaplar arasından kesit alanı sapması en düşük olanı seçer.
TahvilManualResult? computeOptimalManualTahvilResult({
  required int fromDiameter,
  required int fromQuantity,
  required double? fromSpacingCm,
}) {
  final allowed = computeAllowedManualTahvilResults(
    fromDiameter: fromDiameter,
    fromQuantity: fromQuantity,
    fromSpacingCm: fromSpacingCm,
  );

  if (allowed.isEmpty) return null;

  return allowed.first;
}

TahvilManualInputRow? findManualInputForDiameter(
  List<TahvilManualInputRow> rows,
  int diameter,
) {
  for (final row in rows) {
    if (row.diameter == diameter && row.isComplete) return row;
  }
  return null;
}
