import 'package:flutter/foundation.dart';
import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/tahvil/tahvil_rules.dart';
import 'package:santijet_demir/features/analysis/analysis_compute_cache.dart';
/// Boy eşleştirme — kaynak demir boyunun en fazla bu oranı kadar tolerans.
const lengthMatchTolerancePercent = 0.05;

/// Kaynak boy (m) için boy eşleştirme / tahvil toleransı (m).
double lengthMatchToleranceMForLength(double lengthM) =>
    lengthM * lengthMatchTolerancePercent;

/// Standart stok boy (metre).
const stockBarLengthM = 12.0;

/// Safari / mobil web'de uzun senkron işlemlerde sekme çökmesini önlemek için.
const _maxTripletSearchLengths = 24;

/// Büyük envanterlerde ikili/üçlü arama yerine hızlı greedy paketleme.
const _largeInventoryPieceThreshold = 2500;

/// UI bellek tüketimini sınırlamak için plan başına saklanan çubuk sayısı.
const _maxRetainedWasteBarsPerPlan = 120;
const _maxRetainedNoWasteBarsPerPlan = 120;

/// Web'de paketleme döngüsünde event-loop'a ne sıklıkla bırakılır.
const _webYieldEveryBars = 96;

int totalPieceQuantity(Iterable<RebarPieceLine> pieces) =>
    pieces.fold(0, (sum, piece) => sum + piece.quantity);

_LengthInventory _cloneInventory(_LengthInventory inventory) =>
    Map<int, int>.from(inventory);

Future<void> _yieldToEventLoop() async {
  await Future<void>.delayed(
    kIsWeb ? const Duration(milliseconds: 16) : Duration.zero,
  );
}

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

List<int> _activeLengthKeys(_LengthInventory inventory) {
  return inventory.entries
      .where((entry) => entry.value > 0)
      .map((entry) => entry.key)
      .toList();
}

List<int> _searchableLengths(_LengthInventory inventory) {
  final entries = inventory.entries.where((entry) => entry.value > 0).toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) return byCount;
      return a.key.compareTo(b.key);
    });
  final keys = entries.map((entry) => entry.key).toList();
  if (keys.length <= _maxTripletSearchLengths) return keys;
  return keys.sublist(0, _maxTripletSearchLengths);
}

List<int>? _findBestPair(_LengthInventory inventory, int stockMm) {
  final lengths = _searchableLengths(inventory)..sort();

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
  final lengths = _searchableLengths(inventory)..sort();
  if (lengths.length < 3) return null;

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
  final lengths = _activeLengthKeys(inventory)
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
  if (_inventoryTotalCount(inventory) > _largeInventoryPieceThreshold) {
    return _greedyMultiFill(inventory, stockMm);
  }

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

class _DiameterPackResult {
  const _DiameterPackResult({
    required this.bars,
    required this.totalBars,
    required this.totalWasteM,
    required this.totalUsedM,
    required this.wasteBarCount,
    required this.noWasteBarCount,
    required this.wasteLengthBucketCounts,
  });

  final List<StockBarCut> bars;
  final int totalBars;
  final double totalWasteM;
  final double totalUsedM;
  final int wasteBarCount;
  final int noWasteBarCount;
  final Map<int, int> wasteLengthBucketCounts;
}

_DiameterPackResult _packDiameterInventory({
  required int diameter,
  required _LengthInventory inventory,
  required double stockLengthM,
  bool retainBars = true,
  int maxRetainedWasteBars = _maxRetainedWasteBarsPerPlan,
  int maxRetainedNoWasteBars = _maxRetainedNoWasteBarsPerPlan,
}) {
  final stockMm = _lengthToMm(stockLengthM);
  final retainedWasteBars = <StockBarCut>[];
  final retainedNoWasteBars = <StockBarCut>[];
  final wasteLengthBucketCounts = <int, int>{};
  var barIndex = 1;
  var totalWasteM = 0.0;
  var totalUsedM = 0.0;
  var wasteBarCount = 0;
  var noWasteBarCount = 0;

  while (_inventoryTotalCount(inventory) > 0) {
    final fill = _findBestBarFill(inventory, stockMm);
    _consumeFill(inventory, fill);

    final usedMm = _sumFillMm(fill);
    final wasteMm = stockMm - usedMm;
    final usedLengthM = _mmToLengthM(usedMm);
    final wasteLengthM = _mmToLengthM(wasteMm);
    totalUsedM += usedLengthM;
    totalWasteM += wasteLengthM;

    final hasWaste = wasteLengthM > 0.001;
    if (hasWaste) {
      wasteBarCount++;
      final key = (wasteLengthM * 100).round();
      wasteLengthBucketCounts[key] = (wasteLengthBucketCounts[key] ?? 0) + 1;
    } else {
      noWasteBarCount++;
    }

    if (retainBars) {
      final bar = StockBarCut(
        barIndex: barIndex,
        diameter: diameter,
        members: _membersFromFill(fill),
        usedLengthM: usedLengthM,
        wasteLengthM: wasteLengthM,
      );
      if (hasWaste) {
        if (retainedWasteBars.length < maxRetainedWasteBars) {
          retainedWasteBars.add(bar);
        }
      } else if (retainedNoWasteBars.length < maxRetainedNoWasteBars) {
        retainedNoWasteBars.add(bar);
      }
    }
    barIndex++;
  }

  return _DiameterPackResult(
    bars: [...retainedWasteBars, ...retainedNoWasteBars],
    totalBars: barIndex - 1,
    totalWasteM: totalWasteM,
    totalUsedM: totalUsedM,
    wasteBarCount: wasteBarCount,
    noWasteBarCount: noWasteBarCount,
    wasteLengthBucketCounts: wasteLengthBucketCounts,
  );
}

Future<_DiameterPackResult> _packDiameterInventoryAsync({
  required int diameter,
  required _LengthInventory inventory,
  required double stockLengthM,
  bool retainBars = true,
  int maxRetainedWasteBars = _maxRetainedWasteBarsPerPlan,
  int maxRetainedNoWasteBars = _maxRetainedNoWasteBarsPerPlan,
}) async {
  final stockMm = _lengthToMm(stockLengthM);
  final retainedWasteBars = <StockBarCut>[];
  final retainedNoWasteBars = <StockBarCut>[];
  final wasteLengthBucketCounts = <int, int>{};
  var barIndex = 1;
  var totalWasteM = 0.0;
  var totalUsedM = 0.0;
  var wasteBarCount = 0;
  var noWasteBarCount = 0;

  while (_inventoryTotalCount(inventory) > 0) {
    if (kIsWeb && barIndex % _webYieldEveryBars == 0) {
      await _yieldToEventLoop();
    }

    final fill = _findBestBarFill(inventory, stockMm);
    _consumeFill(inventory, fill);

    final usedMm = _sumFillMm(fill);
    final wasteMm = stockMm - usedMm;
    final usedLengthM = _mmToLengthM(usedMm);
    final wasteLengthM = _mmToLengthM(wasteMm);
    totalUsedM += usedLengthM;
    totalWasteM += wasteLengthM;

    final hasWaste = wasteLengthM > 0.001;
    if (hasWaste) {
      wasteBarCount++;
      final key = (wasteLengthM * 100).round();
      wasteLengthBucketCounts[key] = (wasteLengthBucketCounts[key] ?? 0) + 1;
    } else {
      noWasteBarCount++;
    }

    if (retainBars) {
      final bar = StockBarCut(
        barIndex: barIndex,
        diameter: diameter,
        members: _membersFromFill(fill),
        usedLengthM: usedLengthM,
        wasteLengthM: wasteLengthM,
      );
      if (hasWaste) {
        if (retainedWasteBars.length < maxRetainedWasteBars) {
          retainedWasteBars.add(bar);
        }
      } else if (retainedNoWasteBars.length < maxRetainedNoWasteBars) {
        retainedNoWasteBars.add(bar);
      }
    }
    barIndex++;
  }

  return _DiameterPackResult(
    bars: [...retainedWasteBars, ...retainedNoWasteBars],
    totalBars: barIndex - 1,
    totalWasteM: totalWasteM,
    totalUsedM: totalUsedM,
    wasteBarCount: wasteBarCount,
    noWasteBarCount: noWasteBarCount,
    wasteLengthBucketCounts: wasteLengthBucketCounts,
  );
}

/// Aynı çaptaki parçaları 12 m stok boydan minimum fire ile kesim planına dönüştürür.
List<StockCutPlan> computeStockCutPlans(
  List<RebarPieceLine> pieces, {
  double stockLengthM = stockBarLengthM,
  bool useCache = true,
}) {
  if (pieces.isEmpty) return const [];

  if (useCache && stockLengthM == stockBarLengthM) {
    final cacheKey = AnalysisComputeCache.keyForPieces(pieces);
    if (AnalysisComputeCache.hasStockCutPlans(cacheKey)) {
      return AnalysisComputeCache.readStockCutPlans(cacheKey);
    }
    final plans = _computeStockCutPlansUncached(
      pieces,
      stockLengthM: stockLengthM,
    );
    AnalysisComputeCache.storeStockCutPlans(cacheKey, plans);
    return plans;
  }

  return _computeStockCutPlansUncached(pieces, stockLengthM: stockLengthM);
}

Future<List<StockCutPlan>> computeStockCutPlansAsync(
  List<RebarPieceLine> pieces, {
  double stockLengthM = stockBarLengthM,
  bool useCache = true,
}) async {
  if (pieces.isEmpty) return const [];

  if (useCache && stockLengthM == stockBarLengthM) {
    final cacheKey = AnalysisComputeCache.keyForPieces(pieces);
    if (AnalysisComputeCache.hasStockCutPlans(cacheKey)) {
      return AnalysisComputeCache.readStockCutPlans(cacheKey);
    }
    final plans = await _computeStockCutPlansUncachedAsync(
      pieces,
      stockLengthM: stockLengthM,
    );
    AnalysisComputeCache.storeStockCutPlans(cacheKey, plans);
    return plans;
  }

  return _computeStockCutPlansUncachedAsync(
    pieces,
    stockLengthM: stockLengthM,
  );
}

List<StockCutPlan> _buildStockCutPlansFromPackResults({
  required List<RebarPieceLine> pieces,
  required double stockLengthM,
  required Map<int, _DiameterPackResult> packedByDiameter,
}) {
  final diameters = pieces.map((piece) => piece.diameter).toSet().toList()
    ..sort();
  final plans = <StockCutPlan>[];

  for (final diameter in diameters) {
    final packed = packedByDiameter[diameter];
    if (packed == null || packed.totalBars == 0) continue;

    final totalBars = packed.totalBars;
    final totalWasteM = packed.totalWasteM;
    final totalUsedM = packed.totalUsedM;
    final stockTotalM = totalBars * stockLengthM;
    final wastePercent = stockTotalM <= 0
        ? 0.0
        : (totalWasteM / stockTotalM) * 100.0;

    plans.add(
      StockCutPlan(
        diameter: diameter,
        bars: packed.bars,
        totalBars: totalBars,
        wasteBarCount: packed.wasteBarCount,
        noWasteBarCount: packed.noWasteBarCount,
        wasteLengthBucketCounts: packed.wasteLengthBucketCounts,
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

List<StockCutPlan> _computeStockCutPlansUncached(
  List<RebarPieceLine> pieces, {
  double stockLengthM = stockBarLengthM,
}) {
  if (pieces.isEmpty) return const [];

  final diameters = pieces.map((piece) => piece.diameter).toSet().toList()
    ..sort();
  final packedByDiameter = <int, _DiameterPackResult>{};

  for (final diameter in diameters) {
    final inventory = _buildDiameterInventory(pieces, diameter);
    if (_inventoryTotalCount(inventory) == 0) continue;
    packedByDiameter[diameter] = _packDiameterInventory(
      diameter: diameter,
      inventory: inventory,
      stockLengthM: stockLengthM,
    );
  }

  return _buildStockCutPlansFromPackResults(
    pieces: pieces,
    stockLengthM: stockLengthM,
    packedByDiameter: packedByDiameter,
  );
}

Future<List<StockCutPlan>> _computeStockCutPlansUncachedAsync(
  List<RebarPieceLine> pieces, {
  double stockLengthM = stockBarLengthM,
}) async {
  if (pieces.isEmpty) return const [];

  final diameters = pieces.map((piece) => piece.diameter).toSet().toList()
    ..sort();
  final packedByDiameter = <int, _DiameterPackResult>{};

  for (final diameter in diameters) {
    final inventory = _buildDiameterInventory(pieces, diameter);
    if (_inventoryTotalCount(inventory) == 0) continue;
    packedByDiameter[diameter] = await _packDiameterInventoryAsync(
      diameter: diameter,
      inventory: inventory,
      stockLengthM: stockLengthM,
    );
    if (kIsWeb) await _yieldToEventLoop();
  }

  return _buildStockCutPlansFromPackResults(
    pieces: pieces,
    stockLengthM: stockLengthM,
    packedByDiameter: packedByDiameter,
  );
}

/// Tek çap için fire tonajı — optimum boy seçiminde tüm çapları hesaplamaz.
double computeStockCutWasteForDiameter(
  List<RebarPieceLine> pieces,
  int diameter, {
  double stockLengthM = stockBarLengthM,
}) {
  final inventory = _buildDiameterInventory(pieces, diameter);
  if (_inventoryTotalCount(inventory) == 0) return 0;

  final packed = _packDiameterInventory(
    diameter: diameter,
    inventory: _cloneInventory(inventory),
    stockLengthM: stockLengthM,
    retainBars: false,
  );
  return RebarWeightCalculator.tonnage(
    diameterMm: diameter,
    lengthM: packed.totalWasteM,
  );
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
/// Boy eşleştirmede tolerans = en kısa boy × [tolerancePercent].
/// Tahvil gruplamada aynı kural uygulanır.
List<List<RebarPieceLine>> clusterPiecesByLengthSpan(
  List<RebarPieceLine> sortedPieces, {
  double tolerancePercent = lengthMatchTolerancePercent,
  double? fixedToleranceM,
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
    final toleranceM = fixedToleranceM ?? clusterMin * tolerancePercent;
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
  double tolerancePercent = lengthMatchTolerancePercent,
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

    for (final cluster in clusterPiecesByLengthSpan(
      sorted,
      tolerancePercent: tolerancePercent,
    )) {
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

/// Onaylı boy eşleştirmelerinde önce → sonra boy değişimlerini listeler.
List<LengthMatchChange> computeLengthMatchChanges(
  List<LengthMatchGroup> lengthMatches,
) {
  final changes = <LengthMatchChange>[];

  for (final group in lengthMatches) {
    if (!group.approved || group.selectedLengthM == null) continue;
    final afterLength = group.selectedLengthM!;
    for (final member in group.members) {
      if ((member.lengthM - afterLength).abs() <= 1e-9) continue;
      changes.add(
        LengthMatchChange(
          diameter: member.diameter,
          beforeLengthM: member.lengthM,
          afterLengthM: afterLength,
          quantity: member.quantity,
        ),
      );
    }
  }

  changes.sort((a, b) {
    final byDiameter = a.diameter.compareTo(b.diameter);
    if (byDiameter != 0) return byDiameter;
    return a.beforeLengthM.compareTo(b.beforeLengthM);
  });

  return changes;
}

RebarPieceLine _resolveRevisedStateForRawPiece(
  RebarPieceLine raw,
  CuttingBendingBatch batch,
) {
  var diameter = raw.diameter;
  var length = raw.lengthM;

  for (final group in batch.tahvilGroups.where((group) => group.approved)) {
    final equivalent = pickBestTahvilEquivalentForGroup(group);
    if (equivalent == null) continue;
    if (raw.diameter != equivalent.fromDiameter) continue;
    final matched = group.members.any(
      (member) => pieceLineKey(member) == pieceLineKey(raw),
    );
    if (!matched) continue;
    diameter = equivalent.toDiameter;
    length = group.representativeLengthM;
    break;
  }

  for (final group in batch.lengthMatches.where(
    (group) => group.approved && group.selectedLengthM != null,
  )) {
    if (group.diameter != diameter) continue;
    for (final member in group.members) {
      if ((member.lengthM - length).abs() > 1e-9) continue;
      length = group.selectedLengthM!;
      break;
    }
  }

  return RebarPieceLine(
    diameter: diameter,
    lengthM: length,
    quantity: raw.quantity,
  );
}

/// Ham parça listesinden revize sonuca satır satır önce/sonra karşılaştırması.
List<PieceListComparisonRow> computePieceListComparisonRows(
  CuttingBendingBatch batch,
) {
  final rows = batch.pieceLines.map((raw) {
    final after = _resolveRevisedStateForRawPiece(raw, batch);
    return PieceListComparisonRow(
      beforeDiameter: raw.diameter,
      afterDiameter: after.diameter,
      beforeLengthM: raw.lengthM,
      afterLengthM: after.lengthM,
      quantity: raw.quantity,
    );
  }).toList();

  rows.sort((a, b) {
    final byDiameter = a.beforeDiameter.compareTo(b.beforeDiameter);
    if (byDiameter != 0) return byDiameter;
    final byBefore = a.beforeLengthM.compareTo(b.beforeLengthM);
    if (byBefore != 0) return byBefore;
    return a.quantity.compareTo(b.quantity);
  });

  return rows;
}

List<RebarPieceLine> _mergePieceLines(List<RebarPieceLine> pieces) {
  final grouped = <String, RebarPieceLine>{};
  for (final piece in pieces) {
    final key = pieceLineKey(piece);
    final existing = grouped[key];
    if (existing == null) {
      grouped[key] = piece;
    } else {
      grouped[key] = RebarPieceLine(
        diameter: piece.diameter,
        lengthM: piece.lengthM,
        quantity: existing.quantity + piece.quantity,
        sourceText: existing.sourceText ?? piece.sourceText,
        spacingCm: existing.spacingCm ?? piece.spacingCm,
      );
    }
  }

  return grouped.values.toList()
    ..sort((a, b) {
      final byDiameter = a.diameter.compareTo(b.diameter);
      if (byDiameter != 0) return byDiameter;
      return a.lengthM.compareTo(b.lengthM);
    });
}

/// Parça listesinin toplam demir tonajı (stok değil, ihtiyaç metrajı).
double computeMaterialTonnage(List<RebarPieceLine> pieces) {
  var total = 0.0;
  for (final piece in pieces) {
    total += RebarWeightCalculator.tonnage(
      diameterMm: piece.diameter,
      lengthM: piece.lengthM * piece.quantity,
    );
  }
  return total;
}

/// Onaylı tahvil gruplarını parça listesine uygular; kaynak liste korunur.
List<RebarPieceLine> applyApprovedTahvilToPieceLines(
  List<RebarPieceLine> pieceLines,
  List<TahvilSuggestion> tahvilGroups,
) {
  var result = List<RebarPieceLine>.from(pieceLines);

  for (final group in tahvilGroups.where((group) => group.approved)) {
    final equivalent = pickBestTahvilEquivalentForGroup(group);
    if (equivalent == null) continue;

    final memberKeys = group.members
        .where((member) => member.diameter == equivalent.fromDiameter)
        .map(pieceLineKey)
        .toSet();
    if (memberKeys.isEmpty) continue;

    final updated = <RebarPieceLine>[];
    for (final piece in result) {
      if (memberKeys.contains(pieceLineKey(piece))) continue;
      updated.add(piece);
    }

    updated.add(
      RebarPieceLine(
        diameter: equivalent.toDiameter,
        lengthM: group.representativeLengthM,
        quantity: equivalent.equivalentQuantity,
      ),
    );
    result = updated;
  }

  return _mergePieceLines(result);
}

/// Grup başına tek tahvil yönü seçer (çift yönlü uygulama parça kaybına yol açar).
TahvilEquivalent? pickBestTahvilEquivalentForGroup(TahvilSuggestion group) {
  final candidates =
      group.equivalents.where((equivalent) => equivalent.isRecommended).toList();
  if (candidates.isEmpty) return null;
  if (candidates.length == 1) return candidates.first;

  candidates.sort((a, b) {
    final deviation =
        a.areaDeviationPercent.compareTo(b.areaDeviationPercent);
    if (deviation != 0) return deviation;
    return b.fromQuantity.compareTo(a.fromQuantity);
  });
  return candidates.first;
}

List<RebarPieceLine> _workingPieceLines(CuttingBendingBatch batch) {
  if (!batch.isOptimized) return batch.pieceLines;
  return applyApprovedTahvilToPieceLines(batch.pieceLines, batch.tahvilGroups);
}

/// Bir boy eşleştirme grubu için simüle fireyi minimize eden boyu seçer.
List<double> _lengthMatchCandidateLengths(LengthMatchGroup group) {
  final all = group.members.map((member) => member.lengthM).toSet().toList()
    ..sort();
  if (!kIsWeb || all.length <= 3) return all;
  final mid = all.length ~/ 2;
  return [all.first, all[mid], all.last].toSet().toList()..sort();
}

Future<double> pickOptimalLengthForGroup(
  LengthMatchGroup group,
  List<RebarPieceLine> pieceLines,
  List<LengthMatchGroup> allGroups,
) async {
  final candidates = _lengthMatchCandidateLengths(group);

  var bestLength = candidates.first;
  var bestWaste = double.infinity;

  for (var i = 0; i < candidates.length; i++) {
    final candidate = candidates[i];
    await _yieldToEventLoop();

    final trialGroups = allGroups
        .map(
          (item) => item.id == group.id
              ? item.copyWith(approved: true, selectedLengthM: candidate)
              : item,
        )
        .toList();
    final trialPieces = applyLengthMatchesToPieceLines(pieceLines, trialGroups);
    final waste = computeStockCutWasteForDiameter(trialPieces, group.diameter);
    if (waste < bestWaste) {
      bestWaste = waste;
      bestLength = candidate;
    }
  }

  return bestLength;
}

/// Boy eşleştirme sonrası revize parça listesi ve kesim planını günceller.
CuttingBendingBatch syncBatchLengthMatchDerivatives(CuttingBendingBatch batch) {
  final workingPieces = _workingPieceLines(batch);
  final revised = applyLengthMatchesToPieceLines(
    workingPieces,
    batch.lengthMatches,
  );
  final stockCutPlans = batch.isOptimized &&
          isLengthMatchingComplete(batch.lengthMatches)
      ? computeStockCutPlans(revised)
      : const <StockCutPlan>[];

  return batch.copyWith(
    revisedPieceLines: revised,
    stockCutPlans: stockCutPlans,
  );
}

Future<CuttingBendingBatch> syncBatchLengthMatchDerivativesAsync(
  CuttingBendingBatch batch,
) async {
  final workingPieces = _workingPieceLines(batch);
  final revised = applyLengthMatchesToPieceLines(
    workingPieces,
    batch.lengthMatches,
  );
  final stockCutPlans = batch.isOptimized &&
          isLengthMatchingComplete(batch.lengthMatches)
      ? await computeStockCutPlansAsync(revised)
      : const <StockCutPlan>[];

  return batch.copyWith(
    revisedPieceLines: revised,
    stockCutPlans: stockCutPlans,
  );
}

OptimizationSnapshot createOptimizationSnapshot(CuttingBendingBatch batch) {
  assert(batch.isOptimized && batch.optimizationStrategy != null);
  return OptimizationSnapshot(
    strategy: batch.optimizationStrategy!,
    savedAt: DateTime.now(),
    optimizationAppliedAt: batch.optimizationAppliedAt!,
    revisedPieceLines: List<RebarPieceLine>.from(batch.revisedPieceLines),
    lengthMatches: List<LengthMatchGroup>.from(batch.lengthMatches),
    tahvilGroups: List<TahvilSuggestion>.from(batch.tahvilGroups),
    stockCutPlans: List<StockCutPlan>.from(batch.stockCutPlans),
    lengthMatchTolerancePercent: batch.lengthMatchTolerancePercent,
  );
}

CuttingBendingBatch applyOptimizationSnapshot(
  CuttingBendingBatch batch,
  OptimizationSnapshot snapshot,
) {
  return syncBatchLengthMatchDerivatives(
    batch.copyWith(
      revisedPieceLines: snapshot.revisedPieceLines,
      lengthMatches: snapshot.lengthMatches,
      tahvilGroups: snapshot.tahvilGroups,
      stockCutPlans: snapshot.stockCutPlans,
      lengthMatchTolerancePercent: snapshot.lengthMatchTolerancePercent,
      optimizationStrategy: snapshot.strategy,
      optimizationAppliedAt: snapshot.optimizationAppliedAt,
    ),
  );
}

CuttingBendingBatch saveOptimizationSnapshot(CuttingBendingBatch batch) {
  if (!batch.isOptimized || batch.optimizationStrategy == null) return batch;

  final snapshot = createOptimizationSnapshot(batch);
  final updated = Map<FireReductionStrategy, OptimizationSnapshot>.from(
    batch.savedOptimizations,
  );
  updated[batch.optimizationStrategy!] = snapshot;

  return batch.copyWith(savedOptimizations: updated);
}

CuttingBendingBatch clearActiveOptimization(CuttingBendingBatch batch) {
  return syncBatchLengthMatchDerivatives(
    batch.copyWith(
      clearOptimizationAppliedAt: true,
      clearOptimizationStrategy: true,
      lengthMatches: const [],
      stockCutPlans: const [],
      tahvilGroups: computeTahvilGroups(batch.pieceLines),
    ),
  );
}

class AnalysisFireSummary {
  const AnalysisFireSummary({
    required this.rawMaterialTonnage,
    required this.rawStockTonnage,
    required this.rawWasteTonnage,
    required this.rawWastePercent,
    this.plannedStockTonnage,
    this.plannedWasteTonnage,
    this.plannedWastePercent,
  });

  final double rawMaterialTonnage;
  final double rawStockTonnage;
  final double rawWasteTonnage;
  final double rawWastePercent;
  final double? plannedStockTonnage;
  final double? plannedWasteTonnage;
  final double? plannedWastePercent;

  bool get isPlannedReady => plannedWasteTonnage != null;

  double get savedWasteTonnage => isPlannedReady
      ? (rawWasteTonnage - plannedWasteTonnage!).clamp(0, double.infinity)
      : 0;

  double get savedWastePercent => isPlannedReady
      ? (rawWastePercent - plannedWastePercent!).clamp(0, double.infinity)
      : 0;
}

/// Proje fire'ı ile tahvil sonrası fire arasındaki ön izleme (boy eşleştirme yok).
class TahvilFirePreview {
  const TahvilFirePreview({
    required this.baselineWasteTonnage,
    required this.baselineWastePercent,
    required this.tahvilWasteTonnage,
    required this.tahvilWastePercent,
    required this.savedWasteTonnage,
    required this.savedWastePercent,
    required this.applicableTahvilGroupCount,
  });

  final double baselineWasteTonnage;
  final double baselineWastePercent;
  final double tahvilWasteTonnage;
  final double tahvilWastePercent;
  final double savedWasteTonnage;
  final double savedWastePercent;
  final int applicableTahvilGroupCount;

  bool get hasSavings =>
      savedWastePercent > 0.001 && applicableTahvilGroupCount > 0;
}

/// Yalnızca toplam fire oranını düşüren tahvil gruplarını onaylar.
List<TahvilSuggestion> selectBeneficialTahvilGroups({
  required List<RebarPieceLine> pieceLines,
  required List<TahvilSuggestion> groups,
}) {
  if (groups.isEmpty || pieceLines.isEmpty) {
    return groups.map((group) => group.copyWith(approved: false)).toList();
  }

  final baseline = _aggregateStockCutFireMetrics(
    computeStockCutPlans(pieceLines),
  );

  final candidates = groups
      .where((group) => pickBestTahvilEquivalentForGroup(group) != null)
      .toList();
  if (candidates.isEmpty) {
    return groups.map((group) => group.copyWith(approved: false)).toList();
  }

  final approvedIds = <String>{};
  var currentPercent = baseline.wastePercent;

  while (true) {
    TahvilSuggestion? bestGroup;
    var bestPercent = currentPercent;

    for (final group in candidates) {
      if (approvedIds.contains(group.id)) continue;

      final trialGroups = groups
          .map(
            (item) => item.copyWith(
              approved:
                  approvedIds.contains(item.id) || item.id == group.id,
            ),
          )
          .toList();
      final trialPieces = applyApprovedTahvilToPieceLines(
        pieceLines,
        trialGroups,
      );
      final trialMetrics = _aggregateStockCutFireMetrics(
        computeStockCutPlans(trialPieces),
      );

      if (trialMetrics.wastePercent < bestPercent - 1e-9) {
        bestGroup = group;
        bestPercent = trialMetrics.wastePercent;
      }
    }

    if (bestGroup == null) break;

    approvedIds.add(bestGroup.id);
    currentPercent = bestPercent;
  }

  final beneficial = currentPercent < baseline.wastePercent - 1e-9;
  final effectiveApproved = beneficial ? approvedIds : <String>{};

  return groups
      .map(
        (group) => group.copyWith(
          approved: effectiveApproved.contains(group.id),
        ),
      )
      .toList();
}

List<TahvilSuggestion> autoApproveBestTahvilGroups(List<TahvilSuggestion> groups) {
  return groups
      .map(
        (group) => pickBestTahvilEquivalentForGroup(group) != null
            ? group.copyWith(approved: true)
            : group.copyWith(approved: false),
      )
      .toList();
}

TahvilFirePreview estimateTahvilFirePreview(CuttingBendingBatch batch) {
  final baseline = _aggregateStockCutFireMetrics(
    computeStockCutPlans(batch.pieceLines),
  );

  final tahvilGroups = selectBeneficialTahvilGroups(
    pieceLines: batch.pieceLines,
    groups: batch.tahvilGroups.isNotEmpty
        ? batch.tahvilGroups
        : computeTahvilGroups(batch.pieceLines),
  );
  final tahvilPieces = applyApprovedTahvilToPieceLines(
    batch.pieceLines,
    tahvilGroups,
  );
  final tahvilMetrics = _aggregateStockCutFireMetrics(
    computeStockCutPlans(tahvilPieces),
  );

  final savedTonnage = (baseline.wasteTonnage - tahvilMetrics.wasteTonnage)
      .clamp(0.0, double.infinity)
      .toDouble();
  final savedPercent = (baseline.wastePercent - tahvilMetrics.wastePercent)
      .clamp(0.0, double.infinity)
      .toDouble();

  return TahvilFirePreview(
    baselineWasteTonnage: baseline.wasteTonnage,
    baselineWastePercent: baseline.wastePercent,
    tahvilWasteTonnage: tahvilMetrics.wasteTonnage,
    tahvilWastePercent: tahvilMetrics.wastePercent,
    savedWasteTonnage: savedTonnage,
    savedWastePercent: savedPercent,
    applicableTahvilGroupCount:
        tahvilGroups.where((group) => group.approved).length,
  );
}

class AnalysisComparison {
  const AnalysisComparison({
    required this.rawLineCount,
    required this.rawPieceCount,
    required this.rawMaterialTonnage,
    required this.rawFireTonnage,
    required this.rawFirePercent,
    required this.revisedLineCount,
    required this.revisedPieceCount,
    required this.revisedMaterialTonnage,
    required this.plannedFireTonnage,
    required this.plannedFirePercent,
    required this.lengthMatchGroupsApplied,
    required this.tahvilGroupsApplied,
  });

  final int rawLineCount;
  final int rawPieceCount;
  final double rawMaterialTonnage;
  final double rawFireTonnage;
  final double rawFirePercent;
  final int revisedLineCount;
  final int revisedPieceCount;
  final double revisedMaterialTonnage;
  final double plannedFireTonnage;
  final double plannedFirePercent;
  final int lengthMatchGroupsApplied;
  final int tahvilGroupsApplied;

  int get savedLines => (rawLineCount - revisedLineCount).clamp(0, rawLineCount);

  double get savedFireTonnage =>
      (rawFireTonnage - plannedFireTonnage).clamp(0, double.infinity);

  double get savedFirePercent =>
      (rawFirePercent - plannedFirePercent).clamp(-100, 100);
}

class StrategyFireComparison {
  const StrategyFireComparison({
    required this.strategy,
    required this.isAvailable,
    this.plannedFireTonnage,
    this.plannedFirePercent,
    this.savedFireTonnage,
    this.savedFirePercent,
    this.isActive = false,
    this.isSaved = false,
  });

  final FireReductionStrategy strategy;
  final bool isAvailable;
  final double? plannedFireTonnage;
  final double? plannedFirePercent;
  final double? savedFireTonnage;
  final double? savedFirePercent;
  final bool isActive;
  final bool isSaved;
}

List<StrategyFireComparison> computeStrategyFireComparisons(
  CuttingBendingBatch batch,
) {
  final rawMetrics = _aggregateStockCutFireMetrics(
    computeStockCutPlans(batch.pieceLines),
  );

  return FireReductionStrategy.values.map((strategy) {
    final saved = batch.savedOptimizations[strategy];
    final isActive =
        batch.isOptimized && batch.optimizationStrategy == strategy;
    final isSaved = saved != null;

    CuttingBendingBatch? evalBatch;
    if (isSaved) {
      evalBatch = applyOptimizationSnapshot(batch, saved);
    } else if (isActive) {
      evalBatch = batch;
    } else {
      return StrategyFireComparison(strategy: strategy, isAvailable: false);
    }

    if (evalBatch.stockCutPlans.isEmpty) {
      return StrategyFireComparison(
        strategy: strategy,
        isAvailable: false,
        isActive: isActive,
        isSaved: isSaved,
      );
    }

    final plannedMetrics =
        _aggregateStockCutFireMetrics(evalBatch.stockCutPlans);
    final savedWasteTonnage =
        (rawMetrics.wasteTonnage - plannedMetrics.wasteTonnage)
            .clamp(0.0, double.infinity)
            .toDouble();
    final savedWastePercent =
        (rawMetrics.wastePercent - plannedMetrics.wastePercent)
            .clamp(0.0, double.infinity)
            .toDouble();

    return StrategyFireComparison(
      strategy: strategy,
      isAvailable: true,
      plannedFireTonnage: plannedMetrics.wasteTonnage,
      plannedFirePercent: plannedMetrics.wastePercent,
      savedFireTonnage: savedWasteTonnage,
      savedFirePercent: savedWastePercent,
      isActive: isActive,
      isSaved: isSaved,
    );
  }).toList();
}

class FireDiameterBreakdown {
  const FireDiameterBreakdown({
    required this.diameter,
    required this.stockTonnage,
    required this.usedTonnage,
    required this.wasteTonnage,
    required this.wastePercent,
    required this.totalBars,
  });

  final int diameter;
  final double stockTonnage;
  final double usedTonnage;
  final double wasteTonnage;
  final double wastePercent;
  final int totalBars;
}

class MaterialDiameterSummary {
  const MaterialDiameterSummary({
    required this.diameter,
    required this.tonnage,
    required this.pieceCount,
    required this.lineCount,
  });

  final int diameter;
  final double tonnage;
  final int pieceCount;
  final int lineCount;
}

List<MaterialDiameterSummary> computeMaterialSummaryByDiameter(
  List<RebarPieceLine> pieces,
) {
  final byDiameter = <int, ({double tonnage, int pieces, int lines})>{};
  for (final piece in pieces) {
    final tonnage = RebarWeightCalculator.tonnage(
      diameterMm: piece.diameter,
      lengthM: piece.lengthM * piece.quantity,
    );
    final current = byDiameter[piece.diameter];
    byDiameter[piece.diameter] = (
      tonnage: (current?.tonnage ?? 0) + tonnage,
      pieces: (current?.pieces ?? 0) + piece.quantity,
      lines: (current?.lines ?? 0) + 1,
    );
  }

  return byDiameter.entries
      .map(
        (entry) => MaterialDiameterSummary(
          diameter: entry.key,
          tonnage: entry.value.tonnage,
          pieceCount: entry.value.pieces,
          lineCount: entry.value.lines,
        ),
      )
      .toList()
    ..sort((a, b) => a.diameter.compareTo(b.diameter));
}

List<FireDiameterBreakdown> computeFireBreakdownByDiameter(
  List<StockCutPlan> plans,
) {
  return plans
      .map(
        (plan) => FireDiameterBreakdown(
          diameter: plan.diameter,
          stockTonnage: plan.totalStockTonnage,
          usedTonnage: plan.totalUsedTonnage,
          wasteTonnage: plan.totalWasteTonnage,
          wastePercent: plan.wastePercent,
          totalBars: plan.totalBars,
        ),
      )
      .toList()
    ..sort((a, b) => a.diameter.compareTo(b.diameter));
}

List<FireDiameterBreakdown> computeRawFireBreakdown(CuttingBendingBatch batch) {
  return computeFireBreakdownByDiameter(
    computeStockCutPlans(batch.pieceLines),
  );
}

List<FireDiameterBreakdown> computePlannedFireBreakdown(
  CuttingBendingBatch batch,
) {
  return computeFireBreakdownByDiameter(batch.stockCutPlans);
}

StockCutPlan? findStockCutPlanForDiameter(
  List<StockCutPlan> plans,
  int diameter,
) {
  for (final plan in plans) {
    if (plan.diameter == diameter) return plan;
  }
  return null;
}

class FireWasteLengthBucket {
  const FireWasteLengthBucket({
    required this.wasteLengthM,
    required this.barCount,
    required this.totalWasteM,
    required this.wasteTonnage,
  });

  final double wasteLengthM;
  final int barCount;
  final double totalWasteM;
  final double wasteTonnage;
}

List<FireWasteLengthBucket> computeFireWasteLengthBuckets(StockCutPlan plan) {
  final Map<int, int> counts;
  if (plan.wasteLengthBucketCounts != null &&
      plan.wasteLengthBucketCounts!.isNotEmpty) {
    counts = plan.wasteLengthBucketCounts!;
  } else {
    counts = <int, int>{};
    for (final bar in plan.bars) {
      if (bar.wasteLengthM <= 0.001) continue;
      final key = (bar.wasteLengthM * 100).round();
      counts[key] = (counts[key] ?? 0) + 1;
    }
  }

  return counts.entries
      .map((entry) {
        final wasteLengthM = entry.key / 100;
        final barCount = entry.value;
        final totalWasteM = wasteLengthM * barCount;
        return FireWasteLengthBucket(
          wasteLengthM: wasteLengthM,
          barCount: barCount,
          totalWasteM: totalWasteM,
          wasteTonnage: RebarWeightCalculator.tonnage(
            diameterMm: plan.diameter,
            lengthM: totalWasteM,
          ),
        );
      })
      .toList()
    ..sort((a, b) {
      final countCompare = b.barCount.compareTo(a.barCount);
      if (countCompare != 0) return countCompare;
      return b.wasteLengthM.compareTo(a.wasteLengthM);
    });
}

int stockBarWasteCount(StockCutPlan plan) {
  if (plan.wasteBarCount != null) return plan.wasteBarCount!;
  return plan.bars.where((bar) => bar.wasteLengthM > 0.001).length;
}

int stockBarNoWasteCount(StockCutPlan plan) {
  if (plan.noWasteBarCount != null) return plan.noWasteBarCount!;
  return plan.totalBars - stockBarWasteCount(plan);
}

List<StockBarCut> listStockBarsWithWaste(StockCutPlan plan) {
  return plan.bars
      .where((bar) => bar.wasteLengthM > 0.001)
      .toList()
    ..sort((a, b) => b.wasteLengthM.compareTo(a.wasteLengthM));
}

List<StockBarCut> listStockBarsWithoutWaste(StockCutPlan plan) {
  return plan.bars
      .where((bar) => bar.wasteLengthM <= 0.001)
      .toList()
    ..sort((a, b) => a.barIndex.compareTo(b.barIndex));
}

({double stockTonnage, double wasteTonnage, double wastePercent})
    _aggregateStockCutFireMetrics(List<StockCutPlan> plans) {
  var stockT = 0.0;
  var wasteT = 0.0;
  for (final plan in plans) {
    stockT += plan.totalStockTonnage;
    wasteT += plan.totalWasteTonnage;
  }
  final percent = stockT > 0 ? (wasteT / stockT) * 100 : 0.0;
  return (stockTonnage: stockT, wasteTonnage: wasteT, wastePercent: percent);
}

AnalysisFireSummary computeAnalysisFireSummary(CuttingBendingBatch batch) {
  final rawMaterialT = computeMaterialTonnage(batch.pieceLines);
  final rawMetrics = _aggregateStockCutFireMetrics(
    computeStockCutPlans(batch.pieceLines),
  );

  if (!batch.isOptimized) {
    return AnalysisFireSummary(
      rawMaterialTonnage: rawMaterialT,
      rawStockTonnage: rawMetrics.stockTonnage,
      rawWasteTonnage: rawMetrics.wasteTonnage,
      rawWastePercent: rawMetrics.wastePercent,
    );
  }

  final plannedMetrics = _aggregateStockCutFireMetrics(batch.stockCutPlans);

  return AnalysisFireSummary(
    rawMaterialTonnage: rawMaterialT,
    rawStockTonnage: rawMetrics.stockTonnage,
    rawWasteTonnage: rawMetrics.wasteTonnage,
    rawWastePercent: rawMetrics.wastePercent,
    plannedStockTonnage: plannedMetrics.stockTonnage,
    plannedWasteTonnage: plannedMetrics.wasteTonnage,
    plannedWastePercent: plannedMetrics.wastePercent,
  );
}

AnalysisComparison computeAnalysisComparison(CuttingBendingBatch batch) {
  final summary = computeAnalysisFireSummary(batch);
  final rawPieceCount =
      batch.pieceLines.fold(0, (sum, piece) => sum + piece.quantity);
  final revisedPieceCount = batch.revisedPieceLines.fold(
    0,
    (sum, piece) => sum + piece.quantity,
  );

  return AnalysisComparison(
    rawLineCount: batch.pieceLines.length,
    rawPieceCount: rawPieceCount,
    rawMaterialTonnage: summary.rawMaterialTonnage,
    rawFireTonnage: summary.rawWasteTonnage,
    rawFirePercent: summary.rawWastePercent,
    revisedLineCount: batch.revisedPieceLines.length,
    revisedPieceCount: revisedPieceCount,
    revisedMaterialTonnage: computeMaterialTonnage(batch.revisedPieceLines),
    plannedFireTonnage: summary.plannedWasteTonnage ?? 0,
    plannedFirePercent: summary.plannedWastePercent ?? 0,
    lengthMatchGroupsApplied:
        batch.lengthMatches.where((group) => group.approved).length,
    tahvilGroupsApplied: batch.tahvilGroups.where((group) => group.approved).length,
  );
}

/// Tahvil ile fire azaltma hattını çalıştırır (boy eşleştirme uygulanmaz).
class TahvilFireNotBeneficialException implements Exception {
  const TahvilFireNotBeneficialException();

  @override
  String toString() =>
      'Tahvil fire oranını azaltmıyor; tahvil uygulanmadı.';
}

Future<CuttingBendingBatch> runOptimumFireAnalysis(
  CuttingBendingBatch batch, {
  required FireReductionStrategy strategy,
  Future<void> Function(int percent, String stepLabel)? onProgress,
}) async {
  Future<void> report(int percent, String stepLabel) async {
    await onProgress?.call(percent, stepLabel);
  }

  const effectiveStrategy = FireReductionStrategy.tahvilOnly;

  await report(10, 'Proje fire özeti hazırlanıyor...');
  await _yieldToEventLoop();

  final sourceGroups = batch.tahvilGroups.isNotEmpty
      ? batch.tahvilGroups
      : computeTahvilGroups(batch.pieceLines);
  final tahvilState = selectBeneficialTahvilGroups(
    pieceLines: batch.pieceLines,
    groups: sourceGroups,
  );

  if (!tahvilState.any((group) => group.approved)) {
    throw const TahvilFireNotBeneficialException();
  }

  await report(35, 'Fire oranını düşüren tahvil grupları seçiliyor...');
  await _yieldToEventLoop();

  await report(65, 'Tahvilli kesim planı oluşturuluyor...');
  await _yieldToEventLoop();

  final result = await syncBatchLengthMatchDerivativesAsync(
    batch.copyWith(
      tahvilGroups: tahvilState,
      lengthMatches: const [],
      lengthMatchTolerancePercent:
          CuttingBendingBatch.defaultLengthMatchTolerancePercent,
      optimizationStrategy: effectiveStrategy,
      optimizationAppliedAt: DateTime.now(),
    ),
  );

  await _yieldToEventLoop();
  await report(100, 'Fire analizi tamamlandı');
  return result;
}

List<TahvilSuggestion> computeTahvilGroups(
  List<RebarPieceLine> pieces, {
  double tolerancePercent = lengthMatchTolerancePercent,
}) {
  if (pieces.length < 2) return const [];

  final sorted = List<RebarPieceLine>.from(pieces)
    ..sort((a, b) => a.lengthM.compareTo(b.lengthM));

  final clusters = clusterPiecesByLengthSpan(
    sorted,
    tolerancePercent: tolerancePercent,
  );

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
  double lengthMatchTolerancePercent = CuttingBendingBatch.defaultLengthMatchTolerancePercent,
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
        tolerancePercent: lengthMatchTolerancePercent,
      ),
      tahvilGroups: computeTahvilGroups(
        pieceLines,
        tolerancePercent: lengthMatchTolerancePercent,
      ),
      stockCutPlans: const [],
      lengthMatchTolerancePercent: lengthMatchTolerancePercent,
    ),
  );
}

CuttingBendingBatch buildCuttingBendingBatchFromResults({
  required String title,
  required List<String> sourceMetrajRecordIds,
  required Iterable<RebarMetrajResult> results,
  double lengthMatchTolerancePercent = CuttingBendingBatch.defaultLengthMatchTolerancePercent,
}) {
  final details = <RebarMetrajTextDetail>[];
  for (final result in results) {
    details.addAll(result.textDetails);
  }
  return buildCuttingBendingBatch(
    title: title,
    sourceMetrajRecordIds: sourceMetrajRecordIds,
    textDetails: details,
    lengthMatchTolerancePercent: lengthMatchTolerancePercent,
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
  double? lengthMatchTolerancePercent,
}) {
  final tolerancePercent =
      lengthMatchTolerancePercent ?? batch.lengthMatchTolerancePercent;
  final pieceLines = extractPieceLinesFromMetrajDetails(
    labelDetails.where((detail) => detail.included),
  );
  return syncBatchLengthMatchDerivatives(
    batch.copyWith(
      labelDetails: labelDetails,
      pieceLines: pieceLines,
      lengthMatches: computeLengthMatchGroups(
        pieceLines,
        tolerancePercent: tolerancePercent,
      ),
      tahvilGroups: computeTahvilGroups(
        pieceLines,
        tolerancePercent: tolerancePercent,
      ),
      lengthMatchTolerancePercent: tolerancePercent,
      clearOptimizationAppliedAt: true,
      clearOptimizationStrategy: true,
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

/// Çoklu seçim kapsamı için kararlı oturum anahtarı.
String analysisScopeKey(Set<String> batchIds) {
  final sorted = batchIds.toList()..sort();
  return sorted.join('|');
}

/// Birleşik analiz oturumu için sentetik batch kimliği.
String mergedAnalysisBatchId(Iterable<String> batchIds) {
  return 'merged:${analysisScopeKey(batchIds.toSet())}';
}

/// Seçili DWG analiz listelerini tek ham veri setinde birleştirir.
CuttingBendingBatch mergeCuttingBendingBatchesForAnalysis(
  List<CuttingBendingBatch> batches,
) {
  if (batches.isEmpty) {
    throw ArgumentError.value(batches, 'batches', 'cannot be empty');
  }

  if (batches.length == 1) {
    final batch = batches.first;
    return syncBatchLengthMatchDerivatives(
      batch.copyWith(
        revisedPieceLines: const [],
        stockCutPlans: const [],
        savedOptimizations: const {},
        clearOptimizationAppliedAt: true,
        clearOptimizationStrategy: true,
      ),
    );
  }

  final allLabels = <RebarMetrajTextDetail>[];
  final seenLabelKeys = <String>{};
  final allSourceIds = <String>[];
  final allPieces = <RebarPieceLine>[];
  var earliestCreated = batches.first.createdAt;

  for (final batch in batches) {
    for (final detail in batch.labelDetails) {
      final key =
          '${detail.sourceText}|${detail.entityType}|${detail.diameter}|${detail.lengthM}';
      if (seenLabelKeys.add(key)) {
        allLabels.add(detail);
      }
    }
    allSourceIds.addAll(batch.sourceMetrajRecordIds);
    allPieces.addAll(batch.pieceLines);
    if (batch.createdAt.isBefore(earliestCreated)) {
      earliestCreated = batch.createdAt;
    }
  }

  final mergedPieces = _mergePieceLines(allPieces);
  final tolerance = batches
      .map((batch) => batch.lengthMatchTolerancePercent)
      .reduce((a, b) => a > b ? a : b);
  final batchIds = batches.map((batch) => batch.id);
  final title = '${batches.length} dosya birleşik analiz';

  return syncBatchLengthMatchDerivatives(
    CuttingBendingBatch(
      id: mergedAnalysisBatchId(batchIds),
      title: title,
      createdAt: earliestCreated,
      sourceMetrajRecordIds: allSourceIds.toSet().toList(),
      labelDetails: allLabels,
      pieceLines: mergedPieces,
      revisedPieceLines: const [],
      lengthMatches: computeLengthMatchGroups(
        mergedPieces,
        tolerancePercent: tolerance,
      ),
      tahvilGroups: computeTahvilGroups(
        mergedPieces,
        tolerancePercent: tolerance,
      ),
      stockCutPlans: const [],
      lengthMatchTolerancePercent: tolerance,
    ),
  );
}
