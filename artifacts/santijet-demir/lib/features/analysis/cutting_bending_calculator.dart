import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';

/// Yakın boy toleransı (metre) — aynı çapta eşleştirme ve tahvil için.
const cuttingBendingLengthToleranceM = 0.10;

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
      );
    } else {
      grouped[key] = RebarPieceLine(
        diameter: diameter,
        lengthM: lengthM,
        quantity: existing.quantity + detail.quantity,
        sourceText: existing.sourceText ?? detail.sourceText,
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
  double toleranceM = cuttingBendingLengthToleranceM,
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
  double toleranceM = cuttingBendingLengthToleranceM,
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

    final lengths = lengthCluster.map((p) => p.lengthM).toList();
    final minLength = lengths.reduce((a, b) => a < b ? a : b);
    final maxLength = lengths.reduce((a, b) => a > b ? a : b);
    final avgLength = lengths.fold(0.0, (sum, value) => sum + value) / lengths.length;

    suggestions.add(
      TahvilSuggestion(
        id: 'tahvil-$tahvilIndex',
        representativeLengthM: avgLength,
        minLengthM: minLength,
        maxLengthM: maxLength,
        members: List.unmodifiable(lengthCluster),
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
  double toleranceM = cuttingBendingLengthToleranceM,
}) {
  final pieceLines = extractPieceLinesFromMetrajDetails(textDetails);
  return CuttingBendingBatch(
    id: 'kb-${DateTime.now().millisecondsSinceEpoch}',
    title: title,
    createdAt: DateTime.now(),
    sourceMetrajRecordIds: sourceMetrajRecordIds,
    pieceLines: pieceLines,
    lengthMatches: computeLengthMatchGroups(pieceLines, toleranceM: toleranceM),
    tahvilGroups: computeTahvilGroups(pieceLines, toleranceM: toleranceM),
  );
}

CuttingBendingBatch buildCuttingBendingBatchFromResults({
  required String title,
  required List<String> sourceMetrajRecordIds,
  required Iterable<RebarMetrajResult> results,
  double toleranceM = cuttingBendingLengthToleranceM,
}) {
  final details = results.expand((result) => result.textDetails);
  return buildCuttingBendingBatch(
    title: title,
    sourceMetrajRecordIds: sourceMetrajRecordIds,
    textDetails: details,
    toleranceM: toleranceM,
  );
}
