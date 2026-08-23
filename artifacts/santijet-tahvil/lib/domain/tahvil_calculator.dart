import 'dart:math' as math;

import '../data/rebar_weight.dart';
import 'tahvil_rules.dart';

enum TahvilBarKind {
  one('1 çeşit'),
  two('2 çeşit');

  const TahvilBarKind(this.label);
  final String label;
}

enum TahvilMeasure {
  spacing('Aralık'),
  quantity('Adet');

  const TahvilMeasure(this.label);
  final String label;
}

const _piQuarter = math.pi / 4;
const _areaEpsilon = 1e-6;

double crossSectionAreaMm2(int diameterMm) =>
    _piQuarter * diameterMm * diameterMm;

double computeAsPerMeterMm2(int diameterMm, double spacingMm) {
  if (diameterMm <= 0 || spacingMm <= 0) return 0;
  return crossSectionAreaMm2(diameterMm) * (1000 / spacingMm);
}

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

bool isTargetAreaAtLeastSource(double sourceAreaMm2, double targetAreaMm2) =>
    targetAreaMm2 + _areaEpsilon >= sourceAreaMm2;

double? computeExcessAreaDeviationPercent(
  double sourceAreaMm2,
  double targetAreaMm2,
) {
  if (sourceAreaMm2 <= 0) return null;
  if (targetAreaMm2 + _areaEpsilon < sourceAreaMm2) return null;
  return ((targetAreaMm2 - sourceAreaMm2) / sourceAreaMm2) * 100;
}

class TahvilAreaCompliance {
  const TahvilAreaCompliance({
    required this.isAdequate,
    required this.isOptimal,
    required this.sourceAreaMm2,
    required this.targetAreaMm2,
    this.excessDeviationPercent,
    this.rejectReason,
  });

  final bool isAdequate;
  final bool isOptimal;
  final double sourceAreaMm2;
  final double targetAreaMm2;
  final double? excessDeviationPercent;
  final String? rejectReason;

  bool get isAllowed => isOptimal;
}

TahvilAreaCompliance evaluateTahvilAreaCompliance({
  required double sourceAreaMm2,
  required double targetAreaMm2,
}) {
  if (sourceAreaMm2 <= 0 || targetAreaMm2 <= 0) {
    return TahvilAreaCompliance(
      isAdequate: false,
      isOptimal: false,
      sourceAreaMm2: sourceAreaMm2,
      targetAreaMm2: targetAreaMm2,
      rejectReason: 'Geçersiz kesit alanı',
    );
  }

  if (!isTargetAreaAtLeastSource(sourceAreaMm2, targetAreaMm2)) {
    return TahvilAreaCompliance(
      isAdequate: false,
      isOptimal: false,
      sourceAreaMm2: sourceAreaMm2,
      targetAreaMm2: targetAreaMm2,
      rejectReason:
          'Hedef As ${formatAreaMm2(targetAreaMm2)} mm², '
          'proje As ${formatAreaMm2(sourceAreaMm2)} mm² değerinden küçük',
    );
  }

  final excess = computeExcessAreaDeviationPercent(
    sourceAreaMm2,
    targetAreaMm2,
  )!;
  if (excess / 100 > tahvilMaxAreaDeviationRatio + 1e-9) {
    return TahvilAreaCompliance(
      isAdequate: true,
      isOptimal: false,
      sourceAreaMm2: sourceAreaMm2,
      targetAreaMm2: targetAreaMm2,
      excessDeviationPercent: excess,
      rejectReason:
          'Fazla kesit %${excess.toStringAsFixed(1)} '
          '(limit %${(tahvilMaxAreaDeviationRatio * 100).toStringAsFixed(0)})',
    );
  }

  return TahvilAreaCompliance(
    isAdequate: true,
    isOptimal: true,
    sourceAreaMm2: sourceAreaMm2,
    targetAreaMm2: targetAreaMm2,
    excessDeviationPercent: excess,
  );
}

class TahvilSpacingResult {
  const TahvilSpacingResult({
    required this.targetDiameter,
    required this.resultingSpacingMm,
    required this.sourceAsPerMeterMm2,
    required this.targetAsPerMeterMm2,
    required this.isAllowed,
    required this.isAdequate,
    this.rejectReason,
  });

  final int targetDiameter;
  final double resultingSpacingMm;
  final double sourceAsPerMeterMm2;
  final double targetAsPerMeterMm2;
  final bool isAllowed;
  final bool isAdequate;
  final String? rejectReason;

  double get resultingSpacingCm => resultingSpacingMm / 10;
}

List<TahvilSpacingResult> computeSpacingTahvilResults({
  required int sourceDiameter,
  required double sourceSpacingMm,
}) {
  if (sourceDiameter <= 0 || sourceSpacingMm <= 0) return const [];

  final sourceAs = computeAsPerMeterMm2(sourceDiameter, sourceSpacingMm);
  final results = <TahvilSpacingResult>[];

  for (final targetDiameter in RebarWeight.standardDiameters) {
    if (targetDiameter == sourceDiameter) continue;

    final resultingSpacingMm = computeEquivalentSpacingMm(
      sourceDiameter: sourceDiameter,
      sourceSpacingMm: sourceSpacingMm,
      targetDiameter: targetDiameter,
    );
    if (resultingSpacingMm == null || resultingSpacingMm <= 0) continue;

    final targetAs = computeAsPerMeterMm2(targetDiameter, resultingSpacingMm);
    final areaCompliance = evaluateTahvilAreaCompliance(
      sourceAreaMm2: sourceAs,
      targetAreaMm2: targetAs,
    );
    final diameterAllowed =
        isTahvilDiameterAllowed(sourceDiameter, targetDiameter);
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
    } else if (!areaCompliance.isOptimal) {
      rejectReason = areaCompliance.rejectReason;
    }

    results.add(
      TahvilSpacingResult(
        targetDiameter: targetDiameter,
        resultingSpacingMm: resultingSpacingMm,
        sourceAsPerMeterMm2: sourceAs,
        targetAsPerMeterMm2: targetAs,
        isAllowed: rejectReason == null,
        isAdequate: diameterAllowed && spacingAllowed && areaCompliance.isAdequate,
        rejectReason: rejectReason,
      ),
    );
  }

  results.sort((a, b) {
    if (a.isAllowed != b.isAllowed) return a.isAllowed ? -1 : 1;
    if (a.isAdequate != b.isAdequate) return a.isAdequate ? -1 : 1;
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
    required this.isAdequate,
    required this.areaDeviationPercent,
    this.rejectReason,
  });

  final int targetDiameter;
  final int equivalentQuantity;
  final double sourceAreaMm2;
  final double targetAreaMm2;
  final bool isAllowed;
  final bool isAdequate;
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

  for (final targetDiameter in RebarWeight.standardDiameters) {
    if (targetDiameter == sourceDiameter) continue;

    final equivalentQuantity = computeTahvilEquivalentQuantity(
      fromDiameter: sourceDiameter,
      fromQuantity: sourceQuantity,
      toDiameter: targetDiameter,
    );
    if (equivalentQuantity <= 0) continue;

    final targetAreaMm2 =
        crossSectionAreaMm2(targetDiameter) * equivalentQuantity;
    final areaCompliance = evaluateTahvilAreaCompliance(
      sourceAreaMm2: sourceAreaMm2,
      targetAreaMm2: targetAreaMm2,
    );

    final diameterAllowed =
        isTahvilDiameterAllowed(sourceDiameter, targetDiameter);

    String? rejectReason;
    if (!diameterAllowed) {
      rejectReason =
          '±$tahvilMaxDiameterDiffMm mm çap (fark ${(sourceDiameter - targetDiameter).abs()} mm)';
    } else if (!areaCompliance.isOptimal) {
      rejectReason = areaCompliance.rejectReason;
    }

    results.add(
      TahvilSingleQuantityResult(
        targetDiameter: targetDiameter,
        equivalentQuantity: equivalentQuantity,
        sourceAreaMm2: sourceAreaMm2,
        targetAreaMm2: targetAreaMm2,
        isAllowed: rejectReason == null,
        isAdequate: diameterAllowed && areaCompliance.isAdequate,
        areaDeviationPercent: areaCompliance.excessDeviationPercent ?? 0,
        rejectReason: rejectReason,
      ),
    );
  }

  results.sort((a, b) {
    if (a.isAllowed != b.isAllowed) return a.isAllowed ? -1 : 1;
    if (a.isAdequate != b.isAdequate) return a.isAdequate ? -1 : 1;
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

class TahvilDualConversionLeg {
  const TahvilDualConversionLeg({
    required this.sourceQuantity,
    required this.sourceDiameter,
    required this.targetQuantity,
    required this.targetDiameter,
  });

  final int sourceQuantity;
  final int sourceDiameter;
  final int targetQuantity;
  final int targetDiameter;

  bool get isUnchanged =>
      sourceQuantity == targetQuantity && sourceDiameter == targetDiameter;

  String get label => isUnchanged
      ? '$sourceQuantity×Ø$sourceDiameter (aynı)'
      : '$sourceQuantity×Ø$sourceDiameter → $targetQuantity×Ø$targetDiameter';
}

class TahvilDualSuggestion {
  const TahvilDualSuggestion({
    required this.id,
    required this.legA,
    required this.legB,
    required this.sourceAreaMm2,
    required this.targetAreaMm2,
    required this.areaDeviationPercent,
    required this.isAdequate,
    required this.isOptimal,
  });

  final String id;
  final TahvilDualConversionLeg legA;
  final TahvilDualConversionLeg legB;
  final double sourceAreaMm2;
  final double targetAreaMm2;
  final double areaDeviationPercent;
  final bool isAdequate;
  final bool isOptimal;

  bool get isAllowed => isOptimal;

  String get summary => '${legA.label} · ${legB.label}';
}

class _DualLegOption {
  const _DualLegOption({
    required this.targetQuantity,
    required this.targetDiameter,
    required this.isUnchanged,
    this.isAllowed = true,
  });

  final int targetQuantity;
  final int targetDiameter;
  final bool isUnchanged;
  final bool isAllowed;
}

List<_DualLegOption> _dualLegOptions({
  required int sourceQuantity,
  required int sourceDiameter,
}) {
  final options = <_DualLegOption>[
    _DualLegOption(
      targetQuantity: sourceQuantity,
      targetDiameter: sourceDiameter,
      isUnchanged: true,
    ),
  ];

  for (final result in computeSingleQuantityTahvilResults(
    sourceDiameter: sourceDiameter,
    sourceQuantity: sourceQuantity,
  )) {
    options.add(
      _DualLegOption(
        targetQuantity: result.equivalentQuantity,
        targetDiameter: result.targetDiameter,
        isUnchanged: false,
        isAllowed: result.isAllowed,
      ),
    );
  }

  return options;
}

List<TahvilDualSuggestion> computeDualQuantityTahvilSuggestions({
  required int sourceQuantityA,
  required int sourceDiameterA,
  required int sourceQuantityB,
  required int sourceDiameterB,
  int maxSuggestions = 8,
}) {
  if ([
    sourceQuantityA,
    sourceDiameterA,
    sourceQuantityB,
    sourceDiameterB,
  ].any((value) => value <= 0)) {
    return const [];
  }

  final optionsA = _dualLegOptions(
    sourceQuantity: sourceQuantityA,
    sourceDiameter: sourceDiameterA,
  );
  final optionsB = _dualLegOptions(
    sourceQuantity: sourceQuantityB,
    sourceDiameter: sourceDiameterB,
  );

  final sourceAreaMm2 = crossSectionAreaMm2(sourceDiameterA) * sourceQuantityA +
      crossSectionAreaMm2(sourceDiameterB) * sourceQuantityB;
  final suggestions = <TahvilDualSuggestion>[];

  for (final optA in optionsA) {
    for (final optB in optionsB) {
      if (optA.isUnchanged && optB.isUnchanged) continue;

      final targetAreaMm2 =
          crossSectionAreaMm2(optA.targetDiameter) * optA.targetQuantity +
              crossSectionAreaMm2(optB.targetDiameter) * optB.targetQuantity;
      final areaCompliance = evaluateTahvilAreaCompliance(
        sourceAreaMm2: sourceAreaMm2,
        targetAreaMm2: targetAreaMm2,
      );
      final legRuleOk =
          (optA.isUnchanged || optA.isAllowed) &&
          (optB.isUnchanged || optB.isAllowed);
      final isAdequate = legRuleOk && areaCompliance.isAdequate;
      final isOptimal = legRuleOk && areaCompliance.isOptimal;

      suggestions.add(
        TahvilDualSuggestion(
          id: '${optA.targetDiameter}-${optA.targetQuantity}_'
              '${optB.targetDiameter}-${optB.targetQuantity}',
          legA: TahvilDualConversionLeg(
            sourceQuantity: sourceQuantityA,
            sourceDiameter: sourceDiameterA,
            targetQuantity: optA.targetQuantity,
            targetDiameter: optA.targetDiameter,
          ),
          legB: TahvilDualConversionLeg(
            sourceQuantity: sourceQuantityB,
            sourceDiameter: sourceDiameterB,
            targetQuantity: optB.targetQuantity,
            targetDiameter: optB.targetDiameter,
          ),
          sourceAreaMm2: sourceAreaMm2,
          targetAreaMm2: targetAreaMm2,
          areaDeviationPercent: areaCompliance.excessDeviationPercent ?? 0,
          isAdequate: isAdequate,
          isOptimal: isOptimal,
        ),
      );
    }
  }

  suggestions.sort((a, b) {
    if (a.isOptimal != b.isOptimal) return a.isOptimal ? -1 : 1;
    if (a.isAdequate != b.isAdequate) return a.isAdequate ? -1 : 1;
    return a.areaDeviationPercent.compareTo(b.areaDeviationPercent);
  });

  if (suggestions.length <= maxSuggestions) return suggestions;
  return suggestions.sublist(0, maxSuggestions);
}

class TahvilDualSpacingLeg {
  const TahvilDualSpacingLeg({
    required this.sourceDiameter,
    required this.sourceSpacingMm,
    required this.targetDiameter,
    required this.targetSpacingMm,
  });

  final int sourceDiameter;
  final double sourceSpacingMm;
  final int targetDiameter;
  final double targetSpacingMm;

  bool get isUnchanged =>
      sourceDiameter == targetDiameter &&
      (sourceSpacingMm - targetSpacingMm).abs() < 1e-6;

  String get label => isUnchanged
      ? 'Ø$sourceDiameter / ${formatCm(sourceSpacingMm / 10)} cm (aynı)'
      : 'Ø$sourceDiameter / ${formatCm(sourceSpacingMm / 10)} cm → '
          'Ø$targetDiameter / ${formatCm(displayTargetSpacingCm(targetSpacingMm))} cm';
}

class TahvilDualSpacingSuggestion {
  const TahvilDualSpacingSuggestion({
    required this.id,
    required this.legA,
    required this.legB,
    required this.sourceAsPerMeterMm2,
    required this.targetAsPerMeterMm2,
    required this.areaDeviationPercent,
    required this.isAdequate,
    required this.isOptimal,
  });

  final String id;
  final TahvilDualSpacingLeg legA;
  final TahvilDualSpacingLeg legB;
  final double sourceAsPerMeterMm2;
  final double targetAsPerMeterMm2;
  final double areaDeviationPercent;
  final bool isAdequate;
  final bool isOptimal;

  bool get isAllowed => isOptimal;

  String get summary => '${legA.label} · ${legB.label}';
}

class _DualSpacingLegOption {
  const _DualSpacingLegOption({
    required this.targetDiameter,
    required this.targetSpacingMm,
    required this.isUnchanged,
    this.isAllowed = true,
  });

  final int targetDiameter;
  final double targetSpacingMm;
  final bool isUnchanged;
  final bool isAllowed;
}

List<_DualSpacingLegOption> _dualSpacingLegOptions({
  required int sourceDiameter,
  required double sourceSpacingMm,
}) {
  final options = <_DualSpacingLegOption>[
    _DualSpacingLegOption(
      targetDiameter: sourceDiameter,
      targetSpacingMm: sourceSpacingMm,
      isUnchanged: true,
    ),
  ];

  for (final result in computeSpacingTahvilResults(
    sourceDiameter: sourceDiameter,
    sourceSpacingMm: sourceSpacingMm,
  )) {
    options.add(
      _DualSpacingLegOption(
        targetDiameter: result.targetDiameter,
        targetSpacingMm: result.resultingSpacingMm,
        isUnchanged: false,
        isAllowed: result.isAllowed,
      ),
    );
  }

  return options;
}

List<TahvilDualSpacingSuggestion> computeDualSpacingTahvilSuggestions({
  required int sourceDiameterA,
  required double sourceSpacingMmA,
  required int sourceDiameterB,
  required double sourceSpacingMmB,
  int maxSuggestions = 8,
}) {
  if (sourceDiameterA <= 0 ||
      sourceDiameterB <= 0 ||
      sourceSpacingMmA <= 0 ||
      sourceSpacingMmB <= 0) {
    return const [];
  }

  final optionsA = _dualSpacingLegOptions(
    sourceDiameter: sourceDiameterA,
    sourceSpacingMm: sourceSpacingMmA,
  );
  final optionsB = _dualSpacingLegOptions(
    sourceDiameter: sourceDiameterB,
    sourceSpacingMm: sourceSpacingMmB,
  );

  final sourceAs = computeAsPerMeterMm2(sourceDiameterA, sourceSpacingMmA) +
      computeAsPerMeterMm2(sourceDiameterB, sourceSpacingMmB);
  final suggestions = <TahvilDualSpacingSuggestion>[];

  for (final optA in optionsA) {
    for (final optB in optionsB) {
      if (optA.isUnchanged && optB.isUnchanged) continue;

      final targetAs =
          computeAsPerMeterMm2(optA.targetDiameter, optA.targetSpacingMm) +
              computeAsPerMeterMm2(optB.targetDiameter, optB.targetSpacingMm);
      final areaCompliance = evaluateTahvilAreaCompliance(
        sourceAreaMm2: sourceAs,
        targetAreaMm2: targetAs,
      );
      final legRuleOk =
          (optA.isUnchanged || optA.isAllowed) &&
          (optB.isUnchanged || optB.isAllowed);
      final isAdequate = legRuleOk && areaCompliance.isAdequate;
      final isOptimal = legRuleOk && areaCompliance.isOptimal;

      suggestions.add(
        TahvilDualSpacingSuggestion(
          id: '${optA.targetDiameter}-${optA.targetSpacingMm}_'
              '${optB.targetDiameter}-${optB.targetSpacingMm}',
          legA: TahvilDualSpacingLeg(
            sourceDiameter: sourceDiameterA,
            sourceSpacingMm: sourceSpacingMmA,
            targetDiameter: optA.targetDiameter,
            targetSpacingMm: optA.targetSpacingMm,
          ),
          legB: TahvilDualSpacingLeg(
            sourceDiameter: sourceDiameterB,
            sourceSpacingMm: sourceSpacingMmB,
            targetDiameter: optB.targetDiameter,
            targetSpacingMm: optB.targetSpacingMm,
          ),
          sourceAsPerMeterMm2: sourceAs,
          targetAsPerMeterMm2: targetAs,
          areaDeviationPercent: areaCompliance.excessDeviationPercent ?? 0,
          isAdequate: isAdequate,
          isOptimal: isOptimal,
        ),
      );
    }
  }

  suggestions.sort((a, b) {
    if (a.isOptimal != b.isOptimal) return a.isOptimal ? -1 : 1;
    if (a.isAdequate != b.isAdequate) return a.isAdequate ? -1 : 1;
    return a.areaDeviationPercent.compareTo(b.areaDeviationPercent);
  });

  if (suggestions.length <= maxSuggestions) return suggestions;
  return suggestions.sublist(0, maxSuggestions);
}

String formatAreaMm2(double areaMm2) => areaMm2.toStringAsFixed(1);

/// Tahvil öneri aralığını 0,5 cm adımla aşağı yuvarlar (8,9 cm → 8,5 cm).
double floorSpacingCmToHalfStep(double spacingCm) {
  if (spacingCm <= 0) return spacingCm;
  return (spacingCm * 2).floor() / 2;
}

/// Görüntüleme için yuvarlanmış hedef aralık (cm).
double displayTargetSpacingCm(double spacingMm) =>
    floorSpacingCmToHalfStep(spacingMm / 10);

/// Yuvarlanmış aralıkla yeniden hesaplanan hedef As (mm²/m).
double displayTargetAsPerMeterMm2({
  required int diameterMm,
  required double spacingMm,
}) =>
    computeAsPerMeterMm2(
      diameterMm,
      displayTargetSpacingCm(spacingMm) * 10,
    );

double displayDualSpacingTargetAsPerMeterMm2({
  required TahvilDualSpacingLeg legA,
  required TahvilDualSpacingLeg legB,
}) =>
    displayTargetAsPerMeterMm2(
      diameterMm: legA.targetDiameter,
      spacingMm: legA.targetSpacingMm,
    ) +
    displayTargetAsPerMeterMm2(
      diameterMm: legB.targetDiameter,
      spacingMm: legB.targetSpacingMm,
    );

String formatCm(double cm) {
  if ((cm - cm.roundToDouble()).abs() < 0.05) return '${cm.round()}';
  return cm.toStringAsFixed(1);
}
