import 'dart:math' as math;

import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/domain/tahvil/tahvil_rules.dart';

/// Tahvil hesaplayıcı giriş modu.
enum TahvilCalculatorBasis {
  spacing('Aralığa göre'),
  quantity('Adede göre');

  const TahvilCalculatorBasis(this.label);
  final String label;
}

/// Adet modunda tek veya iki çeşit donatı.
enum TahvilQuantityKind {
  single('Tek çeşit donatı'),
  dual('2 çeşit donatı');

  const TahvilQuantityKind(this.label);
  final String label;
}

const _piQuarter = math.pi / 4;

/// mm²/m — Excel tahvil tablosu ile uyumlu kesit alanı.
double crossSectionAreaMm2(int diameterMm) =>
    _piQuarter * diameterMm * diameterMm;

double computeAsPerMeterMm2(int diameterMm, double spacingMm) {
  if (diameterMm <= 0 || spacingMm <= 0) return 0;
  return crossSectionAreaMm2(diameterMm) * (1000 / spacingMm);
}

/// Eşdeğer As için hedef çapta gerekli aralık (mm).
double? computeEquivalentSpacingMm({
  required int sourceDiameter,
  required double sourceSpacingMm,
  required int targetDiameter,
}) {
  if (sourceDiameter <= 0 || targetDiameter <= 0 || sourceSpacingMm <= 0) {
    return null;
  }
  return sourceSpacingMm *
      crossSectionAreaUnits(targetDiameter) /
      crossSectionAreaUnits(sourceDiameter);
}

class TahvilSpacingResult {
  const TahvilSpacingResult({
    required this.targetDiameter,
    required this.resultingSpacingMm,
    required this.asPerMeterMm2,
    required this.isAllowed,
    this.rejectReason,
  });

  final int targetDiameter;
  final double resultingSpacingMm;
  final double asPerMeterMm2;
  final bool isAllowed;
  final String? rejectReason;
}

List<TahvilSpacingResult> computeSpacingTahvilResults({
  required int sourceDiameter,
  required double sourceSpacingMm,
}) {
  if (sourceDiameter <= 0 || sourceSpacingMm <= 0) return const [];

  final sourceAs = computeAsPerMeterMm2(sourceDiameter, sourceSpacingMm);
  final results = <TahvilSpacingResult>[];

  for (final targetDiameter in RebarWeightCalculator.standardDiameters) {
    if (targetDiameter == sourceDiameter) continue;

    final resultingSpacingMm = computeEquivalentSpacingMm(
      sourceDiameter: sourceDiameter,
      sourceSpacingMm: sourceSpacingMm,
      targetDiameter: targetDiameter,
    );
    if (resultingSpacingMm == null || resultingSpacingMm <= 0) continue;

    final diameterAllowed = isTahvilDiameterAllowed(sourceDiameter, targetDiameter);
    final spacingCm = resultingSpacingMm / 10;
    final spacingAllowed = spacingCm <= tahvilMaxSpacingCm + 1e-9;

    String? rejectReason;
    if (!diameterAllowed) {
      rejectReason =
          '±$tahvilMaxDiameterDiffMm mm çap (fark ${(sourceDiameter - targetDiameter).abs()} mm)';
    } else if (!spacingAllowed) {
      rejectReason =
          'Aralık ${spacingCm.toStringAsFixed(1)} cm '
          '(limit ${tahvilMaxSpacingCm.toStringAsFixed(0)} cm)';
    }

    results.add(
      TahvilSpacingResult(
        targetDiameter: targetDiameter,
        resultingSpacingMm: resultingSpacingMm,
        asPerMeterMm2: sourceAs,
        isAllowed: rejectReason == null,
        rejectReason: rejectReason,
      ),
    );
  }

  results.sort((a, b) {
    if (a.isAllowed != b.isAllowed) return a.isAllowed ? -1 : 1;
    return (sourceDiameter - a.targetDiameter)
        .abs()
        .compareTo((sourceDiameter - b.targetDiameter).abs());
  });

  return results;
}

class TahvilSingleQuantityResult {
  const TahvilSingleQuantityResult({
    required this.targetDiameter,
    required this.equivalentQuantity,
    required this.sourceAreaMm2,
    required this.targetAreaMm2,
    required this.isAllowed,
    required this.areaDeviationPercent,
    this.rejectReason,
  });

  final int targetDiameter;
  final int equivalentQuantity;
  final double sourceAreaMm2;
  final double targetAreaMm2;
  final bool isAllowed;
  final double areaDeviationPercent;
  final String? rejectReason;
}

List<TahvilSingleQuantityResult> computeSingleQuantityTahvilResults({
  required int sourceDiameter,
  required int sourceQuantity,
}) {
  if (sourceDiameter <= 0 || sourceQuantity <= 0) return const [];

  final sourceAreaMm2 = crossSectionAreaMm2(sourceDiameter) * sourceQuantity;
  final results = <TahvilSingleQuantityResult>[];

  for (final targetDiameter in RebarWeightCalculator.standardDiameters) {
    if (targetDiameter == sourceDiameter) continue;

    final equivalentQuantity = computeTahvilEquivalentQuantity(
      fromDiameter: sourceDiameter,
      fromQuantity: sourceQuantity,
      toDiameter: targetDiameter,
    );
    if (equivalentQuantity <= 0) continue;

    final targetAreaMm2 =
        crossSectionAreaMm2(targetDiameter) * equivalentQuantity;
    final areaDeviationPercent = computeAreaDeviationRatio(
          fromDiameter: sourceDiameter,
          fromQuantity: sourceQuantity,
          toDiameter: targetDiameter,
          equivalentQuantity: equivalentQuantity,
        ) *
        100;

    final diameterAllowed = isTahvilDiameterAllowed(sourceDiameter, targetDiameter);

    String? rejectReason;
    if (!diameterAllowed) {
      rejectReason =
          '±$tahvilMaxDiameterDiffMm mm çap (fark ${(sourceDiameter - targetDiameter).abs()} mm)';
    } else if (areaDeviationPercent / 100 > tahvilMaxAreaDeviationRatio) {
      rejectReason =
          'Sapma %${areaDeviationPercent.toStringAsFixed(1)} '
          '(limit %${(tahvilMaxAreaDeviationRatio * 100).toStringAsFixed(0)})';
    }

    results.add(
      TahvilSingleQuantityResult(
        targetDiameter: targetDiameter,
        equivalentQuantity: equivalentQuantity,
        sourceAreaMm2: sourceAreaMm2,
        targetAreaMm2: targetAreaMm2,
        isAllowed: rejectReason == null,
        areaDeviationPercent: areaDeviationPercent,
        rejectReason: rejectReason,
      ),
    );
  }

  results.sort((a, b) {
    if (a.isAllowed != b.isAllowed) return a.isAllowed ? -1 : 1;
    if (a.isAllowed && b.isAllowed) {
      final areaDiff =
          a.areaDeviationPercent.compareTo(b.areaDeviationPercent);
      if (areaDiff != 0) return areaDiff;
    }
    return (sourceDiameter - a.targetDiameter)
        .abs()
        .compareTo((sourceDiameter - b.targetDiameter).abs());
  });

  return results;
}

class TahvilDualQuantityComparison {
  const TahvilDualQuantityComparison({
    required this.sourceAreaMm2,
    required this.targetAreaMm2,
    required this.areaDeviationPercent,
    required this.isAllowed,
  });

  final double sourceAreaMm2;
  final double targetAreaMm2;
  final double areaDeviationPercent;
  final bool isAllowed;
}

TahvilDualQuantityComparison? computeDualQuantityComparison({
  required int sourceQuantityA,
  required int sourceDiameterA,
  required int sourceQuantityB,
  required int sourceDiameterB,
  required int targetQuantityA,
  required int targetDiameterA,
  required int targetQuantityB,
  required int targetDiameterB,
}) {
  final inputs = [
    sourceQuantityA,
    sourceDiameterA,
    sourceQuantityB,
    sourceDiameterB,
    targetQuantityA,
    targetDiameterA,
    targetQuantityB,
    targetDiameterB,
  ];
  if (inputs.any((value) => value <= 0)) return null;

  final sourceAreaMm2 = crossSectionAreaMm2(sourceDiameterA) * sourceQuantityA +
      crossSectionAreaMm2(sourceDiameterB) * sourceQuantityB;
  final targetAreaMm2 = crossSectionAreaMm2(targetDiameterA) * targetQuantityA +
      crossSectionAreaMm2(targetDiameterB) * targetQuantityB;

  if (sourceAreaMm2 <= 0 || targetAreaMm2 <= 0) return null;

  final areaDeviationPercent =
      ((sourceAreaMm2 - targetAreaMm2).abs() / sourceAreaMm2) * 100;

  return TahvilDualQuantityComparison(
    sourceAreaMm2: sourceAreaMm2,
    targetAreaMm2: targetAreaMm2,
    areaDeviationPercent: areaDeviationPercent,
    isAllowed: areaDeviationPercent / 100 <= tahvilMaxAreaDeviationRatio + 1e-9,
  );
}

String formatAreaMm2(double areaMm2) => areaMm2.toStringAsFixed(2);

String formatSpacingMm(double spacingMm) => spacingMm.toStringAsFixed(0);
