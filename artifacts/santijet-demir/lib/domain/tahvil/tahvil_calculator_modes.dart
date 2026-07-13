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
const _areaEpsilon = 1e-6;

/// Tahvilde hedef kesit alanı kaynak alana eşit veya büyük olmalıdır.
bool isTargetAreaAtLeastSource(double sourceAreaMm2, double targetAreaMm2) =>
    targetAreaMm2 + _areaEpsilon >= sourceAreaMm2;

/// Kaynak alanın üzerindeki fazlalık yüzdesi (hedef < kaynak ise null).
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

  /// Hedef As ≥ kaynak As (kesit yeterli).
  final bool isAdequate;

  /// Yeterli kesit + fazla kesit limiti içinde.
  final bool isOptimal;

  final double sourceAreaMm2;
  final double targetAreaMm2;
  final double? excessDeviationPercent;
  final String? rejectReason;

  bool get isAllowed => isOptimal;

  bool get hasAreaDeficit =>
      targetAreaMm2 + _areaEpsilon < sourceAreaMm2;

  bool get isAdequateButNotOptimal => isAdequate && !isOptimal;
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
          'kaynak As ${formatAreaMm2(sourceAreaMm2)} mm² değerinden küçük',
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

/// Eşdeğer As için hedef aralıkta gerekli çap (mm, en yakın tam sayı).
int? computeIdealTargetDiameterMm({
  required int sourceDiameter,
  required double sourceSpacingMm,
  required double targetSpacingMm,
}) {
  if (sourceDiameter <= 0 || sourceSpacingMm <= 0 || targetSpacingMm <= 0) {
    return null;
  }
  final ideal = sourceDiameter * math.sqrt(targetSpacingMm / sourceSpacingMm);
  final rounded = ideal.round();
  return rounded > 0 ? rounded : null;
}

enum TahvilSpacingTargetKind {
  diameter('Hedef çap'),
  spacing('Hedef aralık');

  const TahvilSpacingTargetKind(this.label);
  final String label;
}

class TahvilSpacingTargetResult {
  const TahvilSpacingTargetResult({
    required this.inputKind,
    required this.sourceDiameter,
    required this.sourceSpacingMm,
    required this.targetDiameter,
    required this.targetSpacingMm,
    required this.sourceAsPerMeterMm2,
    required this.targetAsPerMeterMm2,
    required this.isAdequate,
    required this.isOptimal,
    this.rejectReason,
  });

  final TahvilSpacingTargetKind inputKind;
  final int sourceDiameter;
  final double sourceSpacingMm;
  final int targetDiameter;
  final double targetSpacingMm;
  final double sourceAsPerMeterMm2;
  final double targetAsPerMeterMm2;
  final bool isAdequate;
  final bool isOptimal;
  final String? rejectReason;

  bool get isAdequateButNotOptimal => isAdequate && !isOptimal;
}

TahvilSpacingTargetResult? computeSpacingTahvilTarget({
  required int sourceDiameter,
  required double sourceSpacingMm,
  required TahvilSpacingTargetKind inputKind,
  int? inputTargetDiameter,
  double? inputTargetSpacingMm,
}) {
  if (sourceDiameter <= 0 || sourceSpacingMm <= 0) return null;

  final sourceAs = computeAsPerMeterMm2(sourceDiameter, sourceSpacingMm);
  late final int targetDiameter;
  late final double targetSpacingMm;

  switch (inputKind) {
    case TahvilSpacingTargetKind.diameter:
      if (inputTargetDiameter == null || inputTargetDiameter <= 0) return null;
      if (inputTargetDiameter == sourceDiameter) return null;
      targetDiameter = inputTargetDiameter;
      final spacing = computeEquivalentSpacingMm(
        sourceDiameter: sourceDiameter,
        sourceSpacingMm: sourceSpacingMm,
        targetDiameter: targetDiameter,
      );
      if (spacing == null || spacing <= 0) return null;
      targetSpacingMm = spacing;
    case TahvilSpacingTargetKind.spacing:
      if (inputTargetSpacingMm == null || inputTargetSpacingMm <= 0) return null;
      targetSpacingMm = inputTargetSpacingMm;
      final diameter = computeIdealTargetDiameterMm(
        sourceDiameter: sourceDiameter,
        sourceSpacingMm: sourceSpacingMm,
        targetSpacingMm: targetSpacingMm,
      );
      if (diameter == null || diameter <= 0 || diameter == sourceDiameter) {
        return null;
      }
      targetDiameter = diameter;
  }

  final targetAs = computeAsPerMeterMm2(targetDiameter, targetSpacingMm);
  final areaCompliance = evaluateTahvilAreaCompliance(
    sourceAreaMm2: sourceAs,
    targetAreaMm2: targetAs,
  );

  final diameterAllowed =
      isTahvilDiameterAllowed(sourceDiameter, targetDiameter);
  final spacingCm = targetSpacingMm / 10;
  final spacingAllowed = spacingCm <= tahvilMaxSpacingCm + 1e-9;
  final standardDiameter =
      RebarWeightCalculator.standardDiameters.contains(targetDiameter);

  String? rejectReason;
  if (!standardDiameter) {
    rejectReason = 'Ø$targetDiameter standart çap değil';
  } else if (!diameterAllowed) {
    rejectReason =
        '±$tahvilMaxDiameterDiffMm mm çap (fark ${(sourceDiameter - targetDiameter).abs()} mm)';
  } else if (!spacingAllowed) {
    rejectReason =
        'Aralık ${spacingCm.toStringAsFixed(1)} cm '
        '(limit ${tahvilMaxSpacingCm.toStringAsFixed(0)} cm)';
  } else if (!areaCompliance.isAdequate) {
    rejectReason = areaCompliance.rejectReason;
  } else if (!areaCompliance.isOptimal) {
    rejectReason = areaCompliance.rejectReason;
  }

  final ruleOk = diameterAllowed && spacingAllowed && standardDiameter;
  final isAdequate = ruleOk && areaCompliance.isAdequate;
  final isOptimal = isAdequate && areaCompliance.isOptimal;

  return TahvilSpacingTargetResult(
    inputKind: inputKind,
    sourceDiameter: sourceDiameter,
    sourceSpacingMm: sourceSpacingMm,
    targetDiameter: targetDiameter,
    targetSpacingMm: targetSpacingMm,
    sourceAsPerMeterMm2: sourceAs,
    targetAsPerMeterMm2: targetAs,
    isAdequate: isAdequate,
    isOptimal: isOptimal,
    rejectReason: rejectReason,
  );
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

  bool get isAdequateButNotOptimal => isAdequate && !isAllowed;
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
    final areaCompliance = evaluateTahvilAreaCompliance(
      sourceAreaMm2: sourceAreaMm2,
      targetAreaMm2: targetAreaMm2,
    );

    final diameterAllowed = isTahvilDiameterAllowed(sourceDiameter, targetDiameter);

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

class TahvilDualQuantityComparison {
  const TahvilDualQuantityComparison({
    required this.sourceAreaMm2,
    required this.targetAreaMm2,
    required this.areaDeviationPercent,
    required this.isAdequate,
    required this.isOptimal,
    required this.hasAreaDeficit,
    this.diameterRuleViolations = const [],
    this.areaRejectReason,
  });

  final double sourceAreaMm2;
  final double targetAreaMm2;
  final double areaDeviationPercent;
  final bool isAdequate;
  final bool isOptimal;
  final bool hasAreaDeficit;
  final List<String> diameterRuleViolations;
  final String? areaRejectReason;

  bool get isAllowed => isOptimal;

  bool get isAdequateButNotOptimal => isAdequate && !isOptimal;
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
    required this.comparison,
    required this.isAdequate,
    required this.isOptimal,
  });

  final String id;
  final TahvilDualConversionLeg legA;
  final TahvilDualConversionLeg legB;
  final TahvilDualQuantityComparison comparison;
  final bool isAdequate;
  final bool isOptimal;

  bool get isAllowed => isOptimal;

  bool get isAdequateButNotOptimal => isAdequate && !isOptimal;

  String get summary => '${legA.label} · ${legB.label}';
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
        rejectReason: result.rejectReason,
      ),
    );
  }

  return options;
}

class _DualLegOption {
  const _DualLegOption({
    required this.targetQuantity,
    required this.targetDiameter,
    required this.isUnchanged,
    this.isAllowed = true,
    this.rejectReason,
  });

  final int targetQuantity;
  final int targetDiameter;
  final bool isUnchanged;
  final bool isAllowed;
  final String? rejectReason;
}

List<String> _dualDiameterRuleViolations({
  required int sourceDiameterA,
  required int targetDiameterA,
  required int sourceDiameterB,
  required int targetDiameterB,
}) {
  final violations = <String>[];

  if (sourceDiameterA != targetDiameterA &&
      !isTahvilDiameterAllowed(sourceDiameterA, targetDiameterA)) {
    violations.add(
      '1. çeşit çap farkı ${(sourceDiameterA - targetDiameterA).abs()} mm '
      '(limit ±$tahvilMaxDiameterDiffMm mm)',
    );
  }
  if (sourceDiameterB != targetDiameterB &&
      !isTahvilDiameterAllowed(sourceDiameterB, targetDiameterB)) {
    violations.add(
      '2. çeşit çap farkı ${(sourceDiameterB - targetDiameterB).abs()} mm '
      '(limit ±$tahvilMaxDiameterDiffMm mm)',
    );
  }

  return violations;
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

  final areaCompliance = evaluateTahvilAreaCompliance(
    sourceAreaMm2: sourceAreaMm2,
    targetAreaMm2: targetAreaMm2,
  );
  final diameterViolations = _dualDiameterRuleViolations(
    sourceDiameterA: sourceDiameterA,
    targetDiameterA: targetDiameterA,
    sourceDiameterB: sourceDiameterB,
    targetDiameterB: targetDiameterB,
  );
  final isAdequate =
      diameterViolations.isEmpty && !areaCompliance.hasAreaDeficit;
  final isOptimal = isAdequate && areaCompliance.isOptimal;

  return TahvilDualQuantityComparison(
    sourceAreaMm2: sourceAreaMm2,
    targetAreaMm2: targetAreaMm2,
    areaDeviationPercent: areaCompliance.excessDeviationPercent ?? 0,
    hasAreaDeficit: areaCompliance.hasAreaDeficit,
    areaRejectReason: areaCompliance.rejectReason,
    isAdequate: isAdequate,
    isOptimal: isOptimal,
    diameterRuleViolations: diameterViolations,
  );
}

List<TahvilDualSuggestion> computeDualQuantityTahvilSuggestions({
  required int sourceQuantityA,
  required int sourceDiameterA,
  required int sourceQuantityB,
  required int sourceDiameterB,
  int maxSuggestions = 12,
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

  final suggestions = <TahvilDualSuggestion>[];

  for (final optA in optionsA) {
    for (final optB in optionsB) {
      if (optA.isUnchanged && optB.isUnchanged) continue;

      final comparison = computeDualQuantityComparison(
        sourceQuantityA: sourceQuantityA,
        sourceDiameterA: sourceDiameterA,
        sourceQuantityB: sourceQuantityB,
        sourceDiameterB: sourceDiameterB,
        targetQuantityA: optA.targetQuantity,
        targetDiameterA: optA.targetDiameter,
        targetQuantityB: optB.targetQuantity,
        targetDiameterB: optB.targetDiameter,
      );
      if (comparison == null) continue;

      final legRuleOk =
          (optA.isUnchanged || optA.isAllowed) && (optB.isUnchanged || optB.isAllowed);
      final isAdequate = legRuleOk && comparison.isAdequate;
      final isOptimal = legRuleOk && comparison.isOptimal;

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
          comparison: comparison,
          isAdequate: isAdequate,
          isOptimal: isOptimal,
        ),
      );
    }
  }

  suggestions.sort((a, b) {
    if (a.isOptimal != b.isOptimal) return a.isOptimal ? -1 : 1;
    if (a.isAdequate != b.isAdequate) return a.isAdequate ? -1 : 1;
    final deviation = a.comparison.areaDeviationPercent
        .compareTo(b.comparison.areaDeviationPercent);
    if (deviation != 0) return deviation;
    final changedA = a.legA.isUnchanged ? 1 : 0;
    final changedB = b.legA.isUnchanged ? 1 : 0;
    final changedCompare = changedA.compareTo(changedB);
    if (changedCompare != 0) return changedCompare;
    return a.summary.compareTo(b.summary);
  });

  if (suggestions.length <= maxSuggestions) return suggestions;
  return suggestions.sublist(0, maxSuggestions);
}

bool isStandardTahvilDiameter(int? diameter) =>
    diameter != null &&
    RebarWeightCalculator.standardDiameters.contains(diameter);


String formatAreaMm2(double areaMm2) => areaMm2.toStringAsFixed(2);

String formatSpacingMm(double spacingMm) => spacingMm.toStringAsFixed(0);

String formatDiameterSpacingLabel(int diameterMm, double spacingMm) =>
    'Ø$diameterMm / ${formatSpacingMm(spacingMm)} mm';
