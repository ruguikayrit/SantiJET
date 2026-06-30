import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/tahvil/tahvil_rules.dart';
/// Boy eşleştirme — aynı çapta yakın boy toleransı (metre).
const lengthMatchToleranceM = 0.30;

/// Tahvil gruplama — farklı çapta yakın boy toleransı (metre).
const tahvilLengthToleranceM = 0.10;

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

    var cluster = <RebarPieceLine>[];
    for (final piece in sorted) {
      if (cluster.isEmpty) {
        cluster = [piece];
        continue;
      }
      final clusterMax = cluster.map((p) => p.lengthM).reduce((a, b) => a > b ? a : b);
      if (piece.lengthM - clusterMax <= toleranceM + 1e-9) {
        cluster.add(piece);
      } else {
        if (cluster.length > 1) {
          groups.add(_buildLengthMatchGroup(cluster, groupIndex++));
        }
        cluster = [piece];
      }
    }
    if (cluster.length > 1) {
      groups.add(_buildLengthMatchGroup(cluster, groupIndex++));
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

List<TahvilSuggestion> computeTahvilGroups(
  List<RebarPieceLine> pieces, {
  double toleranceM = tahvilLengthToleranceM,
}) {
  if (pieces.length < 2) return const [];

  final sorted = List<RebarPieceLine>.from(pieces)
    ..sort((a, b) => a.lengthM.compareTo(b.lengthM));

  final clusters = <List<RebarPieceLine>>[];
  var cluster = <RebarPieceLine>[];

  for (final piece in sorted) {
    if (cluster.isEmpty) {
      cluster = [piece];
      continue;
    }
    final clusterMax = cluster.map((p) => p.lengthM).reduce((a, b) => a > b ? a : b);
    if (piece.lengthM - clusterMax <= toleranceM + 1e-9) {
      cluster.add(piece);
    } else {
      clusters.add(cluster);
      cluster = [piece];
    }
  }
  if (cluster.isNotEmpty) clusters.add(cluster);

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
  return CuttingBendingBatch(
    id: 'kb-${DateTime.now().millisecondsSinceEpoch}',
    title: title,
    createdAt: DateTime.now(),
    sourceMetrajRecordIds: sourceMetrajRecordIds,
    labelDetails: labels,
    pieceLines: pieceLines,
    lengthMatches: computeLengthMatchGroups(
      pieceLines,
      toleranceM: lengthMatchTolerance,
    ),
    tahvilGroups: computeTahvilGroups(pieceLines, toleranceM: tahvilTolerance),
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
  double lengthMatchTolerance = lengthMatchToleranceM,
  double tahvilTolerance = tahvilLengthToleranceM,
}) {
  final pieceLines = extractPieceLinesFromMetrajDetails(
    labelDetails.where((detail) => detail.included),
  );
  return batch.copyWith(
    labelDetails: labelDetails,
    pieceLines: pieceLines,
    lengthMatches: computeLengthMatchGroups(
      pieceLines,
      toleranceM: lengthMatchTolerance,
    ),
    tahvilGroups: computeTahvilGroups(pieceLines, toleranceM: tahvilTolerance),
  );
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
