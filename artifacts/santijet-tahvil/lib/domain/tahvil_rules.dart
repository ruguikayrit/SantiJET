import '../data/rebar_weight.dart';

/// Tahvilde izin verilen maksimum çap farkı (mm).
const tahvilMaxDiameterDiffMm = 4;

/// Donatı aralığı üst sınırı (cm).
const tahvilMaxSpacingCm = 25.0;

/// Adet girilmediğinde aralık hesabı için referans mesafe (cm).
const tahvilReferenceSpanCm = 100.0;

/// Yuvarlama sonrası kabul edilen maksimum kesit sapması.
const tahvilMaxAreaDeviationRatio = 0.05;

/// π r² ile d² oranı aynı olduğundan d² kullanılır.
double crossSectionAreaUnits(int diameterMm) =>
    diameterMm * diameterMm.toDouble();

bool isTahvilDiameterAllowed(int fromDiameter, int toDiameter) {
  if (fromDiameter <= 0 || toDiameter <= 0 || fromDiameter == toDiameter) {
    return false;
  }
  if (!RebarWeight.isStandard(fromDiameter) ||
      !RebarWeight.isStandard(toDiameter)) {
    return false;
  }
  return (fromDiameter - toDiameter).abs() <= tahvilMaxDiameterDiffMm;
}

int computeTahvilEquivalentQuantity({
  required int fromDiameter,
  required int fromQuantity,
  required int toDiameter,
}) {
  if (fromDiameter <= 0 || toDiameter <= 0 || fromQuantity <= 0) return 0;
  return ((crossSectionAreaUnits(fromDiameter) * fromQuantity) /
          crossSectionAreaUnits(toDiameter))
      .round();
}

double computeAreaDeviationRatio({
  required int fromDiameter,
  required int fromQuantity,
  required int toDiameter,
  required int equivalentQuantity,
}) {
  final fromArea = crossSectionAreaUnits(fromDiameter) * fromQuantity;
  if (fromArea <= 0) return 1;
  final toArea = crossSectionAreaUnits(toDiameter) * equivalentQuantity;
  return (fromArea - toArea).abs() / fromArea;
}

int deriveReferenceQuantity({required double spacingCm}) {
  if (spacingCm <= 0) return 0;
  return (tahvilReferenceSpanCm / spacingCm).round();
}

double? computeResultingSpacingCm({
  required int fromQuantity,
  required int equivalentQuantity,
  required double? spacingCm,
  bool useReferenceSpan = false,
}) {
  if (spacingCm == null || spacingCm <= 0) return null;
  if (equivalentQuantity <= 0) return null;

  if (useReferenceSpan) {
    return tahvilReferenceSpanCm / equivalentQuantity;
  }

  if (fromQuantity <= 1 || equivalentQuantity <= 1) return null;
  final distributionSpan = (fromQuantity - 1) * spacingCm;
  return distributionSpan / (equivalentQuantity - 1);
}

bool passesSpacingRule({
  required int fromQuantity,
  required int equivalentQuantity,
  required double? spacingCm,
  bool useReferenceSpan = false,
}) {
  final resulting = computeResultingSpacingCm(
    fromQuantity: fromQuantity,
    equivalentQuantity: equivalentQuantity,
    spacingCm: spacingCm,
    useReferenceSpan: useReferenceSpan,
  );
  if (resulting == null) return true;
  return resulting <= tahvilMaxSpacingCm + 1e-9;
}

double? computeBarWeightKg({
  required int diameterMm,
  required double? lengthCm,
}) {
  if (lengthCm == null || lengthCm <= 0) return null;
  return RebarWeight.weightKg(
    diameterMm: diameterMm,
    lengthM: lengthCm / 100,
  );
}

double? computeTotalTonnage({
  required int diameterMm,
  required int quantity,
  required double? lengthCm,
}) {
  final barKg = computeBarWeightKg(diameterMm: diameterMm, lengthCm: lengthCm);
  if (barKg == null) return null;
  return barKg * quantity / 1000;
}

String formatCrossSectionComparison({
  required int fromDiameter,
  required int fromQuantity,
  required int toDiameter,
  required int toQuantity,
}) {
  final fromUnits = crossSectionAreaUnits(fromDiameter).round();
  final toUnits = crossSectionAreaUnits(toDiameter).round();
  final fromArea = fromUnits * fromQuantity;
  final toArea = toUnits * toQuantity;
  final symbol = fromArea > toArea
      ? '>'
      : fromArea < toArea
          ? '<'
          : '=';
  return '$fromUnits mm² × $fromQuantity ad '
      '$symbol $toUnits mm² × $toQuantity ad';
}
