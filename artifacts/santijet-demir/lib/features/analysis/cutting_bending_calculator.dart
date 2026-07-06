import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/tahvil/tahvil_rules.dart';
/// Boy eşleştirme — aynı çapta yakın boy toleransı (metre).
const lengthMatchToleranceM = 0.30;

/// Tahvil gruplama — farklı çapta yakın boy toleransı (metre).
const tahvilLengthToleranceM = 0.10;

/// Standart stok boy (metre).
const stockBarLengthM = 12.0;

int _lengthToMm(double lengthM) => (lengthM * 1000).round();

double _mmToLengthM(int lengthMm) => lengthMm / 1000.0;

typedef _LengthInventory = Map<int, int>;

int _inventoryTotalCount(_LengthInventory inventory) {
  return inventory.values.fold(0, (sum, count) => sum + count);
}

_LengthInventory _buildDiameterInventory(
  List<RebarPieceLine> pieces,
  int diameter,
) {
  final inventory = <int, int>{};
  for (final piece in pieces) {
    if (piece.diameter != diameter) continue;
    final key = _lengthToMm(piece.lengthM);
    inventory[key] = (inventory[key] ?? 0) + piece.quantity;
  }
  return inventory;
}

int _sumFillMm(List<int> fill) => fill.fold(0, (sum, value) => sum + value);

List<StockBarCutMember> _membersFromFill(List<int> fill) {
  final counts = <int, int>{};
  for (final lengthMm in fill) {
    counts[lengthMm] = (counts[lengthMm] ?? 0) + 1;
  }
  final members = counts.entries
      .map(
        (entry) => StockBarCutMember(
          lengthM: _mmToLengthM(entry.key),
          count: entry.value,
        ),
      )
      .toList()
    ..sort((a, b) => b.lengthM.compareTo(a.lengthM));
  return members;
}

void _consumeFill(_LengthInventory inventory, List<int> fill) {
  for (final lengthMm in fill) {
    final remaining = (inventory[lengthMm] ?? 0) - 1;
    if (remaining <= 0) {
      inventory.remove(lengthMm);
    } else {
      inventory[lengthMm] = remaining;
    }
  }
}

List<int>? _findBestPair(_LengthInventory inventory, int stockMm) {
  final lengths = inventory.entries
      .where((entry) => entry.value > 0)
      .map((entry) => entry.key)
      .toList()
    ..sort();

  List<int>? best;
  var bestWaste = stockMm + 1;
  var bestUsed = -1;

  for (var i = 0; i < lengths.length; i++) {
    for (var j = i; j < lengths.length; j++) {
      final first = lengths[i];
      final second = lengths[j];
      if (i == j && inventory[first]! < 2) continue;

      final used = first + second;
      if (used > stockMm) continue;

      final waste = stockMm - used;
      if (waste < bestWaste || (waste == bestWaste && used > bestUsed)) {
        bestWaste = waste;
        bestUsed = used;
        best = [first, second];
      }
    }
  }

  return best;
}

List<int>? _findBestTriplet(_LengthInventory inventory, int stockMm) {
  final lengths = inventory.entries
      .where((entry) => entry.value > 0)
      .map((entry) => entry.key)
      .toList()
    ..sort();

  List<int>? best;
  var bestWaste = stockMm + 1;
  var bestUsed = -1;

  for (var i = 0; i < lengths.length; i++) {
    for (var j = i; j < lengths.length; j++) {
      for (var k = j; k < lengths.length; k++) {
        final first = lengths[i];
        final second = lengths[j];
        final third = lengths[k];

        final required = <int, int>{};
        for (final lengthMm in [first, second, third]) {
          required[lengthMm] = (required[lengthMm] ?? 0) + 1;
        }
        if (required.entries.any((e) => (inventory[e.key] ?? 0) < e.value)) {
          continue;
        }

        final used = first + second + third;
        if (used > stockMm) continue;

        final waste = stockMm - used;
        if (waste < bestWaste || (waste == bestWaste && used > bestUsed)) {
          bestWaste = waste;
          bestUsed = used;
          best = [first, second, third];
        }
      }
    }
  }

  return best;
}

List<int> _greedyMultiFill(_LengthInventory inventory, int stockMm) {
  final lengths = inventory.entries
      .where((entry) => entry.value > 0)
      .map((entry) => entry.key)
      .toList()
    ..sort((a, b) => b.compareTo(a));

  if (lengths.isEmpty) return const [];

  final fill = <int>[];
  var remaining = stockMm;
  var progress = true;

  while (progress) {
    progress = false;
    for (final lengthMm in lengths) {
      while ((inventory[lengthMm] ?? 0) > 0 && lengthMm <= remaining) {
        fill.add(lengthMm);
        remaining -= lengthMm;
        progress = true;
      }
    }
  }

  if (fill.isEmpty) {
    fill.add(lengths.first);
  }

  return fill;
}

List<int> _findBestBarFill(_LengthInventory inventory, int stockMm) {
  final candidates = <List<int>>[];

  final pair = _findBestPair(inventory, stockMm);
  if (pair != null) candidates.add(pair);

  final triplet = _findBestTriplet(inventory, stockMm);
  if (triplet != null) candidates.add(triplet);

  candidates.add(_greedyMultiFill(inventory, stockMm));

  candidates.sort((a, b) {
    final wasteA = stockMm - _sumFillMm(a);
    final wasteB = stockMm - _sumFillMm(b);
    final wasteCompare = wasteA.compareTo(wasteB);
    if (wasteCompare != 0) return wasteCompare;
    return _sumFillMm(b).compareTo(_sumFillMm(a));
  });

  return candidates.first;
}

List<StockBarCut> _packDiameterInventory({
  required int diameter,
  required _LengthInventory inventory,
  required double stockLengthM,
}) {
  final stockMm = _lengthToMm(stockLengthM);
  final bars = <StockBarCut>[];
  var barIndex = 1;

  while (_inventoryTotalCount(inventory) > 0) {
    final fill = _findBestBarFill(inventory, stockMm);
    _consumeFill(inventory, fill);

    final usedMm = _sumFillMm(fill);
    bars.add(
      StockBarCut(
        barIndex: barIndex++,
        diameter: diameter,
        members: _membersFromFill(fill),
        usedLengthM: _mmToLengthM(usedMm),
        wasteLengthM: _mmToLengthM(stockMm - usedMm),
      ),
    );
  }

  return bars;
}

/// Aynı çaptaki parçaları 12 m stok boydan minimum fire ile kesim planına dönüştürür.
List<StockCutPlan> computeStockCutPlans(
  List<RebarPieceLine> pieces, {
  double stockLengthM = stockBarLengthM,
}) {
  if (pieces.isEmpty) return const [];

  final diameters = pieces.map((piece) => piece.diameter).toSet().toList()
    ..sort();

  final plans = <StockCutPlan>[];

  for (final diameter in diameters) {
    final inventory = _buildDiameterInventory(pieces, diameter);
    if (_inventoryTotalCount(inventory) == 0) continue;

    final bars = _packDiameterInventory(
      diameter: diameter,
      inventory: inventory,
      stockLengthM: stockLengthM,
    );

    final totalBars = bars.length;
    final totalWasteM =
        bars.fold(0.0, (sum, bar) => sum + bar.wasteLengthM);
    final totalUsedM =
        bars.fold(0.0, (sum, bar) => sum + bar.usedLengthM);
    final stockTotalM = totalBars * stockLengthM;
    final wastePercent = stockTotalM <= 0
        ? 0.0
        : (totalWasteM / stockTotalM) * 100.0;

    plans.add(
      StockCutPlan(
        diameter: diameter,
        bars: bars,
        totalBars: totalBars,
        totalStockM: stockTotalM,
        totalWasteM: totalWasteM,
        totalUsedM: totalUsedM,
        wastePercent: wastePercent,
        totalStockTonnage: RebarWeightCalculator.tonnage(
          diameterMm: diameter,
          lengthM: stockTotalM,
        ),
        totalUsedTonnage: RebarWeightCalculator.tonnage(
          diameterMm: diameter,
          lengthM: totalUsedM,
        ),
        totalWasteTonnage: RebarWeightCalculator.tonnage(
          diameterMm: diameter,
          lengthM: totalWasteM,
        ),
      ),
    );
  }

  return plans;
}

List<RebarPieceLine> extractPieceLinesFromMetrajDetails(
  Iterable<RebarMetrajTextDetail> details,
) {
  final grouped = <String, RebarPieceLine>{};

  for (final detail in details) {
    if (!detail.included) continue;
    final diameter = detail.diameter;
    final lengthM = detail.lengthM;
    if (diameter == null || lengthM == null || lengthM <= 0) continue;
    if (detail.quantity <= 0) continue;

    final key = '$diameter:${lengthM.toStringAsFixed(3)}';
    final existing = grouped[key];
    if (existing == null) {
      grouped[key] = RebarPieceLine(
        diameter: diameter,
        lengthM: lengthM,
        quantity: detail.quantity,
        sourceText: detail.sourceText,
        spacingCm: detail.spacingCm,
      );
    } else {
      final totalQty = existing.quantity + detail.quantity;
      double? mergedSpacing;
      if (detail.spacingCm != null && detail.spacingCm! > 0) {
        final baseSpacing = existing.spacingCm ?? detail.spacingCm!;
        mergedSpacing = existing.quantity == 0
            ? detail.spacingCm
            : (baseSpacing * existing.quantity +
                    detail.spacingCm! * detail.quantity) /
                totalQty;
      } else {
        mergedSpacing = existing.spacingCm;
      }
      grouped[key] = RebarPieceLine(
        diameter: diameter,
        lengthM: lengthM,
        quantity: totalQty,
        sourceText: existing.sourceText ?? detail.sourceText,
        spacingCm: mergedSpacing,
      );
    }
  }

  final lines = grouped.values.toList()
    ..sort((a, b) {
      final byDiameter = a.diameter.compareTo(b.diameter);
      if (byDiameter != 0) return byDiameter;
      return a.lengthM.compareTo(b.lengthM);
    });
  return lines;
}

/// Sıralı parçaları boy aralığı toleransına göre gruplar.
/// Tolerans = gruptaki en kısa ile en uzun boy arasındaki fark (max − min).
List<List<RebarPieceLine>> clusterPiecesByLengthSpan(
  List<RebarPieceLine> sortedPieces, {
  required double toleranceM,
}) {
  if (sortedPieces.isEmpty) return const [];

  final clusters = <List<RebarPieceLine>>[];
  var cluster = <RebarPieceLine>[];

  for (final piece in sortedPieces) {
    if (cluster.isEmpty) {
      cluster = [piece];
      continue;
    }
    final clusterMin = cluster.first.lengthM;
    if (piece.lengthM - clusterMin <= toleranceM + 1e-9) {
      cluster.add(piece);
    } else {
      clusters.add(cluster);
      cluster = [piece];
    }
  }
  if (cluster.isNotEmpty) clusters.add(cluster);
  return clusters;
}

List<LengthMatchGroup> computeLengthMatchGroups(
  List<RebarPieceLine> pieces, {
  double toleranceM = lengthMatchToleranceM,
}) {
  final byDiameter = <int, List<RebarPieceLine>>{};
  for (final piece in pieces) {
    byDiameter.putIfAbsent(piece.diameter, () => []).add(piece);
  }

  final groups = <LengthMatchGroup>[];
  var groupIndex = 0;

  for (final entry in byDiameter.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
    final sorted = List<RebarPieceLine>.from(entry.value)
      ..sort((a, b) => a.lengthM.compareTo(b.lengthM));

    for (final cluster in clusterPiecesByLengthSpan(sorted, toleranceM: toleranceM)) {
      if (cluster.length > 1) {
        groups.add(_buildLengthMatchGroup(cluster, groupIndex++));
      }
    }
  }

  return groups;
}

LengthMatchGroup _buildLengthMatchGroup(List<RebarPieceLine> cluster, int index) {
  final lengths = cluster.map((p) => p.lengthM).toList();
  final minLength = lengths.reduce((a, b) => a < b ? a : b);
  final maxLength = lengths.reduce((a, b) => a > b ? a : b);
  final avgLength = lengths.fold(0.0, (sum, value) => sum + value) / lengths.length;
  final totalQty = cluster.fold(0, (sum, p) => sum + p.quantity);

  return LengthMatchGroup(
    id: 'match-$index',
    diameter: cluster.first.diameter,
    representativeLengthM: avgLength,
    minLengthM: minLength,
    maxLengthM: maxLength,
    totalQuantity: totalQty,
    members: List.unmodifiable(cluster),
  );
}

String pieceLineKey(RebarPieceLine piece) =>
    '${piece.diameter}|${piece.lengthM.toStringAsFixed(4)}';

/// Boy eşleştirme onaylarına göre revize parça listesi üretir.
List<RebarPieceLine> applyLengthMatchesToPieceLines(
  List<RebarPieceLine> pieceLines,
  List<LengthMatchGroup> lengthMatches,
) {
  if (lengthMatches.isEmpty) {
    return List<RebarPieceLine>.from(pieceLines);
  }

  final keysInGroups = <String>{};
  for (final group in lengthMatches) {
    for (final member in group.members) {
      keysInGroups.add(pieceLineKey(member));
    }
  }

  final revised = <RebarPieceLine>[];

  for (final group in lengthMatches) {
    if (group.approved && group.selectedLengthM != null) {
      revised.add(
        RebarPieceLine(
          diameter: group.diameter,
          lengthM: group.selectedLengthM!,
          quantity: group.totalQuantity,
        ),
      );
    } else {
      revised.addAll(group.members);
    }
  }

  for (final piece in pieceLines) {
    if (!keysInGroups.contains(pieceLineKey(piece))) {
      revised.add(piece);
    }
  }

  revised.sort((a, b) {
    final byDiameter = a.diameter.compareTo(b.diameter);
    if (byDiameter != 0) return byDiameter;
    return a.lengthM.compareTo(b.lengthM);
  });

  return revised;
}

bool isLengthMatchingComplete(List<LengthMatchGroup> lengthMatches) {
  if (lengthMatches.isEmpty) return true;
  return lengthMatches.every(
    (group) => group.approved && group.selectedLengthM != null,
  );
}

/// Boy eşleştirme sonrası revize parça listesi ve kesim planını günceller.
CuttingBendingBatch syncBatchLengthMatchDerivatives(CuttingBendingBatch batch) {
  final revised = applyLengthMatchesToPieceLines(
    batch.pieceLines,
    batch.lengthMatches,
  );
  final stockCutPlans = isLengthMatchingComplete(batch.lengthMatches)
      ? computeStockCutPlans(revised)
      : const <StockCutPlan>[];

  return batch.copyWith(
    revisedPieceLines: revised,
    stockCutPlans: stockCutPlans,
  );
}

List<TahvilSuggestion> computeTahvilGroups(
  List<RebarPieceLine> pieces, {
  double toleranceM = tahvilLengthToleranceM,
}) {
  if (pieces.length < 2) return const [];

  final sorted = List<RebarPieceLine>.from(pieces)
    ..sort((a, b) => a.lengthM.compareTo(b.lengthM));

  final clusters = clusterPiecesByLengthSpan(sorted, toleranceM: toleranceM);

  final suggestions = <TahvilSuggestion>[];
  var tahvilIndex = 0;

  for (final lengthCluster in clusters) {
    final diameters = lengthCluster.map((p) => p.diameter).toSet();
    if (diameters.length < 2) continue;
    if (!shouldIncludeTahvilCluster(lengthCluster)) continue;

    final lengths = lengthCluster.map((p) => p.lengthM).toList();
    final minLength = lengths.reduce((a, b) => a < b ? a : b);
    final maxLength = lengths.reduce((a, b) => a > b ? a : b);
    final avgLength = lengths.fold(0.0, (sum, value) => sum + value) / lengths.length;

    final equivalents = computeTahvilEquivalents(lengthCluster);
    if (equivalents.isEmpty) continue;

    suggestions.add(
      TahvilSuggestion(
        id: 'tahvil-$tahvilIndex',
        representativeLengthM: avgLength,
        minLengthM: minLength,
        maxLengthM: maxLength,
        members: List.unmodifiable(lengthCluster),
        equivalents: equivalents,
      ),
    );
    tahvilIndex++;
  }

  return suggestions;
}

CuttingBendingBatch buildCuttingBendingBatch({
  required String title,
  required List<String> sourceMetrajRecordIds,
  required Iterable<RebarMetrajTextDetail> textDetails,
  double lengthMatchTolerance = lengthMatchToleranceM,
  double tahvilTolerance = tahvilLengthToleranceM,
}) {
  final pieceLines = extractPieceLinesFromMetrajDetails(textDetails);
  final labels = textDetails.toList();
  return syncBatchLengthMatchDerivatives(
    CuttingBendingBatch(
      id: 'kb-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      createdAt: DateTime.now(),
      sourceMetrajRecordIds: sourceMetrajRecordIds,
      labelDetails: labels,
      pieceLines: pieceLines,
      revisedPieceLines: const [],
      lengthMatches: computeLengthMatchGroups(
        pieceLines,
        toleranceM: lengthMatchTolerance,
      ),
      tahvilGroups: computeTahvilGroups(pieceLines, toleranceM: tahvilTolerance),
      stockCutPlans: const [],
      lengthMatchToleranceCm: lengthMatchTolerance * 100,
    ),
  );
}

CuttingBendingBatch buildCuttingBendingBatchFromResults({
  required String title,
  required List<String> sourceMetrajRecordIds,
  required Iterable<RebarMetrajResult> results,
  double lengthMatchTolerance = lengthMatchToleranceM,
  double tahvilTolerance = tahvilLengthToleranceM,
}) {
  final details = <RebarMetrajTextDetail>[];
  for (final result in results) {
    details.addAll(result.textDetails);
  }
  return buildCuttingBendingBatch(
    title: title,
    sourceMetrajRecordIds: sourceMetrajRecordIds,
    textDetails: details,
    lengthMatchTolerance: lengthMatchTolerance,
    tahvilTolerance: tahvilTolerance,
  );
}

/// Eski batch kayıtlarında boş kalan etiket listesini ön imalat kaynaklarından doldurur.
CuttingBendingBatch hydrateCuttingBendingBatchLabels(
  CuttingBendingBatch batch,
  Iterable<SavedRebarMetraj> metrajRecords,
) {
  if (batch.labelDetails.isNotEmpty) return batch;
  if (batch.sourceMetrajRecordIds.isEmpty) return batch;

  final byId = {for (final record in metrajRecords) record.id: record};
  final details = <RebarMetrajTextDetail>[];
  for (final id in batch.sourceMetrajRecordIds) {
    final record = byId[id];
    if (record != null) {
      details.addAll(record.result.textDetails);
    }
  }
  if (details.isEmpty) return batch;
  return batch.copyWith(labelDetails: details);
}

/// Etiket listesi değişince parça, boy eşleştirme ve tahvil gruplarını yeniden hesaplar.
CuttingBendingBatch rebuildCuttingBendingBatch(
  CuttingBendingBatch batch, {
  required List<RebarMetrajTextDetail> labelDetails,
  double? lengthMatchTolerance,
  double tahvilTolerance = tahvilLengthToleranceM,
}) {
  final toleranceM = lengthMatchTolerance ?? batch.lengthMatchToleranceM;
  final pieceLines = extractPieceLinesFromMetrajDetails(
    labelDetails.where((detail) => detail.included),
  );
  return syncBatchLengthMatchDerivatives(
    batch.copyWith(
      labelDetails: labelDetails,
      pieceLines: pieceLines,
      lengthMatches: computeLengthMatchGroups(
        pieceLines,
        toleranceM: toleranceM,
      ),
      tahvilGroups: computeTahvilGroups(pieceLines, toleranceM: tahvilTolerance),
      lengthMatchToleranceCm: toleranceM * 100,
    ),
  );
}

/// Eski kayıtlarda revize parça listesi ve kesim planını boy eşleştirmesine göre üretir.
CuttingBendingBatch hydrateStockCutPlans(CuttingBendingBatch batch) {
  return syncBatchLengthMatchDerivatives(batch);
}

bool isSameRebarMetrajTextDetail(
  RebarMetrajTextDetail a,
  RebarMetrajTextDetail b,
) {
  return a.sourceText == b.sourceText &&
      a.entityType == b.entityType &&
      a.diameter == b.diameter &&
      a.lengthM == b.lengthM;
}
