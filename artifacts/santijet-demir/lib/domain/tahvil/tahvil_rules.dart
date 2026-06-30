import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';

/// Tahvilde izin verilen maksimum çap farkı (mm).
const tahvilMaxDiameterDiffMm = 4;

/// Donatı aralığı üst sınırı (cm).
const tahvilMaxSpacingCm = 25.0;

/// Yuvarlama sonrası kabul edilen maksimum kesit alanı sapması.
const tahvilMaxAreaDeviationRatio = 0.05;

/// π r² ile d² oranı aynı olduğundan d² kullanılır.
double crossSectionAreaUnits(int diameterMm) =>
    diameterMm * diameterMm.toDouble();

bool isTahvilDiameterAllowed(int fromDiameter, int toDiameter) {
  if (fromDiameter <= 0 || toDiameter <= 0 || fromDiameter == toDiameter) {
    return false;
  }
  if (!RebarWeightCalculator.standardDiameters.contains(fromDiameter) ||
      !RebarWeightCalculator.standardDiameters.contains(toDiameter)) {
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

/// Tahvil sonrası tahmini donatı aralığı (cm).
double? computeResultingSpacingCm({
  required int fromQuantity,
  required int equivalentQuantity,
  required double? spacingCm,
}) {
  if (spacingCm == null || spacingCm <= 0) return null;
  if (fromQuantity <= 1 || equivalentQuantity <= 1) return null;
  final distributionSpan = (fromQuantity - 1) * spacingCm;
  return distributionSpan / (equivalentQuantity - 1);
}

bool passesSpacingRule({
  required int fromQuantity,
  required int equivalentQuantity,
  required double? spacingCm,
}) {
  final resulting = computeResultingSpacingCm(
    fromQuantity: fromQuantity,
    equivalentQuantity: equivalentQuantity,
    spacingCm: spacingCm,
  );
  if (resulting == null) return true;
  return resulting <= tahvilMaxSpacingCm + 1e-9;
}

class _DiameterAggregate {
  int quantity = 0;
  double? spacingCm;

  void add({required int quantity, required double? spacingCm}) {
    if (quantity <= 0) return;
    if (spacingCm != null && spacingCm > 0) {
      final previousQty = this.quantity;
      final totalQty = previousQty + quantity;
      if (totalQty > 0) {
        this.spacingCm = previousQty == 0
            ? spacingCm
            : ((this.spacingCm ?? spacingCm) * previousQty +
                    spacingCm * quantity) /
                totalQty;
      }
    }
    this.quantity += quantity;
  }
}

List<TahvilEquivalent> computeTahvilEquivalents(List<RebarPieceLine> members) {
  if (members.length < 2) return const [];

  final aggregates = <int, _DiameterAggregate>{};
  for (final member in members) {
    aggregates
        .putIfAbsent(member.diameter, () => _DiameterAggregate())
        .add(quantity: member.quantity, spacingCm: member.spacingCm);
  }

  if (aggregates.length < 2) return const [];

  final diameters = aggregates.keys.toList()..sort();
  final candidates = <TahvilEquivalent>[];

  for (final fromDiameter in diameters) {
    final fromAggregate = aggregates[fromDiameter]!;
    for (final toDiameter in diameters) {
      if (fromDiameter == toDiameter) continue;
      if (!isTahvilDiameterAllowed(fromDiameter, toDiameter)) continue;

      final equivalentQuantity = computeTahvilEquivalentQuantity(
        fromDiameter: fromDiameter,
        fromQuantity: fromAggregate.quantity,
        toDiameter: toDiameter,
      );
      if (equivalentQuantity <= 0) continue;

      final areaDeviationPercent = computeAreaDeviationRatio(
            fromDiameter: fromDiameter,
            fromQuantity: fromAggregate.quantity,
            toDiameter: toDiameter,
            equivalentQuantity: equivalentQuantity,
          ) *
          100;
      if (areaDeviationPercent / 100 > tahvilMaxAreaDeviationRatio) continue;

      if (!passesSpacingRule(
        fromQuantity: fromAggregate.quantity,
        equivalentQuantity: equivalentQuantity,
        spacingCm: fromAggregate.spacingCm,
      )) {
        continue;
      }

      candidates.add(
        TahvilEquivalent(
          fromDiameter: fromDiameter,
          fromQuantity: fromAggregate.quantity,
          toDiameter: toDiameter,
          equivalentQuantity: equivalentQuantity,
          areaDeviationPercent: areaDeviationPercent,
          resultingSpacingCm: computeResultingSpacingCm(
            fromQuantity: fromAggregate.quantity,
            equivalentQuantity: equivalentQuantity,
            spacingCm: fromAggregate.spacingCm,
          ),
        ),
      );
    }
  }

  return _markRecommendedEquivalents(candidates);
}

List<TahvilEquivalent> _markRecommendedEquivalents(
  List<TahvilEquivalent> candidates,
) {
  if (candidates.isEmpty) return candidates;

  final bestBySource = <int, TahvilEquivalent>{};
  for (final candidate in candidates) {
    final current = bestBySource[candidate.fromDiameter];
    if (current == null || _compareTahvilPreference(candidate, current) < 0) {
      bestBySource[candidate.fromDiameter] = candidate;
    }
  }

  final recommendedKeys = bestBySource.values
      .map((item) => '${item.fromDiameter}-${item.toDiameter}')
      .toSet();

  return candidates
      .map(
        (item) => item.copyWith(
          isRecommended:
              recommendedKeys.contains('${item.fromDiameter}-${item.toDiameter}'),
        ),
      )
      .toList()
    ..sort(_compareTahvilPreference);
}

int _compareTahvilPreference(TahvilEquivalent a, TahvilEquivalent b) {
  if (a.isRecommended != b.isRecommended) {
    return a.isRecommended ? -1 : 1;
  }
  final diameterDiff = (a.fromDiameter - a.toDiameter).abs().compareTo(
        (b.fromDiameter - b.toDiameter).abs(),
      );
  if (diameterDiff != 0) return diameterDiff;

  final areaDiff = a.areaDeviationPercent.compareTo(b.areaDeviationPercent);
  if (areaDiff != 0) return areaDiff;

  return a.fromDiameter.compareTo(b.fromDiameter);
}

/// Tahvil grubunun gösterilip gösterilmeyeceğini belirler.
bool shouldIncludeTahvilCluster(List<RebarPieceLine> members) {
  return computeTahvilEquivalents(members).isNotEmpty;
}
