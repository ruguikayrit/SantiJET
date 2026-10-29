import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';

void main() {
  group('cutting bending calculator', () {
    test('groups exact diameter and length into piece lines', () {
      const details = [
        RebarMetrajTextDetail(
          entityType: 'TEXT',
          sourceText: 'a',
          included: true,
          diameter: 16,
          lengthM: 2.0,
          quantity: 10,
        ),
        RebarMetrajTextDetail(
          entityType: 'TEXT',
          sourceText: 'b',
          included: true,
          diameter: 16,
          lengthM: 2.0,
          quantity: 5,
        ),
      ];

      final lines = extractPieceLinesFromMetrajDetails(details);

      expect(lines, hasLength(1));
      expect(lines.first.diameter, 16);
      expect(lines.first.lengthM, 2.0);
      expect(lines.first.quantity, 15);
    });

    test('matches same diameter with near lengths', () {
      const pieces = [
        RebarPieceLine(diameter: 16, lengthM: 2.00, quantity: 10),
        RebarPieceLine(diameter: 16, lengthM: 2.05, quantity: 8),
        RebarPieceLine(diameter: 16, lengthM: 3.50, quantity: 4),
      ];

      final groups = computeLengthMatchGroups(pieces);

      expect(groups, hasLength(1));
      expect(groups.first.diameter, 16);
      expect(groups.first.totalQuantity, 18);
      expect(groups.first.members, hasLength(2));
    });

    test('length match tolerance scales with shortest bar length', () {
      const pieces = [
        RebarPieceLine(diameter: 12, lengthM: 4.75, quantity: 12),
        RebarPieceLine(diameter: 12, lengthM: 4.95, quantity: 6),
        RebarPieceLine(diameter: 12, lengthM: 5.05, quantity: 12),
      ];

      final groups5 = computeLengthMatchGroups(pieces);
      expect(groups5, hasLength(1));
      expect(groups5.first.maxLengthM - groups5.first.minLengthM, closeTo(0.20, 1e-9));
      expect(groups5.first.members, hasLength(2));

      final groups7 = computeLengthMatchGroups(pieces, tolerancePercent: 0.07);
      expect(groups7, hasLength(1));
      expect(groups7.first.maxLengthM - groups7.first.minLengthM, closeTo(0.30, 1e-9));
      expect(groups7.first.members, hasLength(3));
    });

    test('length match percent follows source bar length', () {
      const pieces100 = [
        RebarPieceLine(diameter: 16, lengthM: 1.00, quantity: 10),
        RebarPieceLine(diameter: 16, lengthM: 1.05, quantity: 8),
      ];
      const pieces400 = [
        RebarPieceLine(diameter: 16, lengthM: 4.00, quantity: 10),
        RebarPieceLine(diameter: 16, lengthM: 4.20, quantity: 8),
      ];

      final group100 = computeLengthMatchGroups(pieces100);
      final group400 = computeLengthMatchGroups(pieces400);

      expect(group100, hasLength(1));
      expect(group400, hasLength(1));
      expect(group100.first.maxLengthM - group100.first.minLengthM, closeTo(0.05, 1e-9));
      expect(group400.first.maxLengthM - group400.first.minLengthM, closeTo(0.20, 1e-9));
    });

    test('plans 12m stock cuts with minimum waste for same diameter', () {
      const pieces = [
        RebarPieceLine(diameter: 12, lengthM: 6.50, quantity: 5),
        RebarPieceLine(diameter: 12, lengthM: 5.50, quantity: 5),
        RebarPieceLine(diameter: 12, lengthM: 5.00, quantity: 2),
      ];

      final plans = computeStockCutPlans(pieces);

      expect(plans, hasLength(1));
      final plan = plans.first;
      expect(plan.diameter, 12);
      expect(plan.totalBars, 6);

      final zeroWasteBars =
          plan.bars.where((bar) => bar.wasteLengthM <= 0.001).length;
      expect(zeroWasteBars, 5);

      final pairedBar = plan.bars.firstWhere(
        (bar) => bar.members.any((m) => m.lengthM == 6.5),
      );
      expect(pairedBar.members, hasLength(2));
      expect(pairedBar.usedLengthM, closeTo(12.0, 0.001));
      expect(pairedBar.wasteLengthM, closeTo(0.0, 0.001));

      final remainderBar = plan.bars.firstWhere(
        (bar) => bar.members.every((m) => m.lengthM == 5.0),
      );
      expect(remainderBar.members.fold(0, (sum, m) => sum + m.count), 2);
      expect(remainderBar.usedLengthM, closeTo(10.0, 0.001));
      expect(remainderBar.wasteLengthM, closeTo(2.0, 0.001));

      expect(plan.totalStockM, closeTo(plan.totalBars * stockBarLengthM, 0.001));
      expect(
        plan.totalStockTonnage,
        closeTo(
          RebarWeightCalculator.tonnage(
            diameterMm: 12,
            lengthM: plan.totalStockM,
          ),
          0.0001,
        ),
      );
      expect(
        plan.totalUsedTonnage,
        closeTo(
          RebarWeightCalculator.tonnage(
            diameterMm: 12,
            lengthM: plan.totalUsedM,
          ),
          0.0001,
        ),
      );
      expect(
        plan.totalWasteTonnage,
        closeTo(
          RebarWeightCalculator.tonnage(
            diameterMm: 12,
            lengthM: plan.totalWasteM,
          ),
          0.0001,
        ),
      );
    });

    test('fire drill-down counts include bars beyond preview retention', () {
      final pieces = [
        RebarPieceLine(diameter: 28, lengthM: 12.0, quantity: 2085),
        RebarPieceLine(diameter: 28, lengthM: 11.2, quantity: 200),
      ];

      final plan = computeStockCutPlans(pieces).first;

      expect(plan.totalBars, 2285);
      expect(stockBarWasteCount(plan), 200);
      expect(stockBarNoWasteCount(plan), 2085);
      expect(listStockBarsWithWaste(plan).length, 200);
      expect(listStockBarsWithoutWaste(plan).length, 2085);
      expect(listStockBarsWithoutWaste(plan), isNotEmpty);
      expect(
        computeFireWasteLengthBuckets(plan).fold<int>(
          0,
          (sum, bucket) => sum + bucket.barCount,
        ),
        200,
      );
    });

    test('groups stock cuts separately per diameter', () {
      const pieces = [
        RebarPieceLine(diameter: 12, lengthM: 6.00, quantity: 2),
        RebarPieceLine(diameter: 16, lengthM: 6.00, quantity: 2),
      ];

      final plans = computeStockCutPlans(pieces);

      expect(plans, hasLength(2));
      expect(plans.map((plan) => plan.diameter).toSet(), {12, 16});
      for (final plan in plans) {
        expect(plan.totalBars, 1);
        expect(plan.bars.first.usedLengthM, closeTo(12.0, 0.001));
      }
    });

    test('buildCuttingBendingBatch defers stock cut plans until optimization', () async {
      const details = [
        RebarMetrajTextDetail(
          entityType: 'TEXT',
          sourceText: 'a',
          included: true,
          diameter: 12,
          lengthM: 6.5,
          quantity: 2,
        ),
        RebarMetrajTextDetail(
          entityType: 'TEXT',
          sourceText: 'b',
          included: true,
          diameter: 12,
          lengthM: 5.5,
          quantity: 2,
        ),
      ];

      final batch = buildCuttingBendingBatch(
        title: 'Test',
        sourceMetrajRecordIds: const [],
        textDetails: details,
      );

      expect(batch.stockCutPlans, isEmpty);
      expect(batch.isOptimized, isFalse);

      final optimized = await runOptimumFireAnalysis(batch);

      expect(optimized.isOptimized, isTrue);
      expect(optimized.optimizationStrategy, FireReductionStrategy.lengthMatchOnly);
      expect(optimized.lengthMatches, isEmpty);
      expect(optimized.stockCutPlans, isNotEmpty);
      expect(optimized.stockCutPlans.first.totalBars, 2);
    });

    test('applyLengthMatchesToPieceLines merges approved length match groups', () {
      const pieces = [
        RebarPieceLine(diameter: 16, lengthM: 2.00, quantity: 10),
        RebarPieceLine(diameter: 16, lengthM: 2.05, quantity: 8),
        RebarPieceLine(diameter: 16, lengthM: 3.50, quantity: 4),
      ];
      final groups = computeLengthMatchGroups(pieces);
      final approved = groups.first.copyWith(
        approved: true,
        selectedLengthM: 2.00,
      );

      final revised = applyLengthMatchesToPieceLines(pieces, [approved]);

      expect(revised, hasLength(2));
      expect(revised.first.diameter, 16);
      expect(revised.first.lengthM, 2.00);
      expect(revised.first.quantity, 18);
      expect(revised.last.lengthM, 3.50);
    });

    test('stock cut plans wait for optimization and completed length matching', () {
      const pieces = [
        RebarPieceLine(diameter: 12, lengthM: 6.50, quantity: 5),
        RebarPieceLine(diameter: 12, lengthM: 6.55, quantity: 5),
      ];
      final groups = computeLengthMatchGroups(pieces);
      var batch = syncBatchLengthMatchDerivatives(
        CuttingBendingBatch(
          id: 'kb-test',
          title: 'Test',
          createdAt: DateTime.now(),
          sourceMetrajRecordIds: const [],
          labelDetails: const [],
          pieceLines: pieces,
          revisedPieceLines: const [],
          lengthMatches: [
            groups.first.copyWith(approved: true, selectedLengthM: 6.50),
          ],
          stockCutPlans: const [],
        ),
      );

      expect(batch.stockCutPlans, isEmpty);

      batch = syncBatchLengthMatchDerivatives(
        batch.copyWith(optimizationAppliedAt: DateTime.now()),
      );

      expect(batch.revisedPieceLines, hasLength(1));
      expect(batch.revisedPieceLines.first.quantity, 10);
      expect(batch.stockCutPlans, isNotEmpty);
    });

    test('rebuildCuttingBendingBatch recalculates after label removal', () {
      const details = [
        RebarMetrajTextDetail(
          entityType: 'TEXT',
          sourceText: 'a',
          included: true,
          diameter: 16,
          lengthM: 2.0,
          quantity: 10,
        ),
        RebarMetrajTextDetail(
          entityType: 'TEXT',
          sourceText: 'b',
          included: true,
          diameter: 20,
          lengthM: 2.05,
          quantity: 6,
        ),
      ];
      final batch = buildCuttingBendingBatch(
        title: 'Test',
        sourceMetrajRecordIds: const [],
        textDetails: details,
      );

      final rebuilt = rebuildCuttingBendingBatch(
        batch,
        labelDetails: [details.first],
      );

      expect(rebuilt.labelDetails, hasLength(1));
      expect(rebuilt.pieceLines, hasLength(1));
      expect(rebuilt.lengthMatches, isEmpty);
    });

    test('optimized fire percent moves with fire tonnage', () async {
      const pieces = [
        RebarPieceLine(diameter: 16, lengthM: 2.00, quantity: 10),
        RebarPieceLine(diameter: 16, lengthM: 2.05, quantity: 8),
        RebarPieceLine(diameter: 16, lengthM: 3.50, quantity: 4),
        RebarPieceLine(diameter: 20, lengthM: 2.08, quantity: 6),
      ];
      final batch = buildCuttingBendingBatch(
        title: 'Test',
        sourceMetrajRecordIds: const [],
        textDetails: const [],
      ).copyWith(pieceLines: pieces);

      final optimized = await runOptimumFireAnalysis(batch);
      final summary = computeAnalysisFireSummary(optimized);

      expect(summary.isPlannedReady, isTrue);
      expect(summary.plannedStockTonnage!, greaterThan(summary.rawMaterialTonnage * 0.9));

      if (summary.plannedWasteTonnage! < summary.rawWasteTonnage) {
        expect(summary.plannedWastePercent!, lessThan(summary.rawWastePercent));
      }
    });

    test('runOptimumFireAnalysis preserves source piece lines', () async {
      const pieces = [
        RebarPieceLine(diameter: 16, lengthM: 2.00, quantity: 10),
        RebarPieceLine(diameter: 16, lengthM: 2.05, quantity: 8),
        RebarPieceLine(diameter: 16, lengthM: 3.50, quantity: 4),
      ];
      final batch = buildCuttingBendingBatch(
        title: 'Test',
        sourceMetrajRecordIds: const [],
        textDetails: const [],
      ).copyWith(pieceLines: pieces);

      final optimized = await runOptimumFireAnalysis(batch);

      expect(optimized.pieceLines, pieces);
      expect(optimized.isOptimized, isTrue);
      expect(optimized.lengthMatches, isNotEmpty);
      expect(optimized.optimizationStrategy, FireReductionStrategy.lengthMatchOnly);
      expect(computeAnalysisFireSummary(optimized).isPlannedReady, isTrue);
    });

    test('computePieceListComparisonRows marks unchanged and changed rows', () {
      const pieces = [
        RebarPieceLine(diameter: 16, lengthM: 2.00, quantity: 10),
        RebarPieceLine(diameter: 16, lengthM: 2.05, quantity: 8),
        RebarPieceLine(diameter: 12, lengthM: 4.50, quantity: 6),
      ];
      final groups = computeLengthMatchGroups(pieces);
      final approvedGroup = groups.first.copyWith(
        approved: true,
        selectedLengthM: 2.05,
      );
      final batch = CuttingBendingBatch(
        id: 'kb-test',
        title: 'Test',
        createdAt: DateTime(2026),
        sourceMetrajRecordIds: const ['rec-1'],
        labelDetails: const [],
        pieceLines: pieces,
        revisedPieceLines:
            applyLengthMatchesToPieceLines(pieces, [approvedGroup]),
        lengthMatches: [approvedGroup],
        stockCutPlans: const [],
        optimizationAppliedAt: DateTime(2026),
        optimizationStrategy: FireReductionStrategy.lengthMatchOnly,
      );

      final rows = computePieceListComparisonRows(batch);

      expect(rows, hasLength(3));
      expect(rows.where((row) => row.isChanged), hasLength(1));
      expect(rows.where((row) => !row.isChanged), hasLength(2));
      final changed = rows.firstWhere((row) => row.beforeLengthM == 2.00);
      expect(changed.afterLengthM, 2.05);
      expect(changed.deltaCm, closeTo(5.0, 1e-9));
    });

    test('computeLengthMatchChanges lists before and after lengths', () {
      const pieces = [
        RebarPieceLine(diameter: 16, lengthM: 2.00, quantity: 10),
        RebarPieceLine(diameter: 16, lengthM: 2.05, quantity: 8),
      ];
      final groups = computeLengthMatchGroups(pieces);
      final approved = groups.first.copyWith(
        approved: true,
        selectedLengthM: 2.05,
      );

      final changes = computeLengthMatchChanges([approved]);

      expect(changes, hasLength(1));
      expect(changes.first.beforeLengthM, 2.00);
      expect(changes.first.afterLengthM, 2.05);
      expect(changes.first.quantity, 10);
    });

    test('CuttingBendingBatch.fromJson tolerates missing labelDetails', () {
      final batch = CuttingBendingBatch.fromJson({
        'id': 'kb-1',
        'title': 'Test',
        'createdAt': DateTime.now().toIso8601String(),
        'sourceMetrajRecordIds': ['rec-1'],
        'labelDetails': null,
        'pieceLines': [],
        'lengthMatches': [],
        'tahvilGroups': [],
        'stockCutPlans': [],
        'optimizationStrategy': 'tahvilOnly',
      });

      expect(batch.labelDetails, isEmpty);
      expect(batch.optimizationStrategy, FireReductionStrategy.lengthMatchOnly);
    });

    test('saveOptimizationSnapshot stores result per strategy', () async {
      const pieces = [
        RebarPieceLine(diameter: 16, lengthM: 2.00, quantity: 10),
        RebarPieceLine(diameter: 16, lengthM: 2.05, quantity: 8),
      ];
      var batch = buildCuttingBendingBatch(
        title: 'Test',
        sourceMetrajRecordIds: const ['rec-1'],
        textDetails: const [],
      ).copyWith(pieceLines: pieces);

      batch = await runOptimumFireAnalysis(batch);

      final saved = saveOptimizationSnapshot(batch);

      expect(saved.hasSavedOptimization(FireReductionStrategy.lengthMatchOnly), isTrue);
      expect(saved.isCurrentOptimizationSaved, isTrue);
      expect(saved.savedOptimizations, hasLength(1));
    });

    test('applyOptimizationSnapshot restores saved analysis', () async {
      const pieces = [
        RebarPieceLine(diameter: 16, lengthM: 2.00, quantity: 10),
        RebarPieceLine(diameter: 16, lengthM: 2.05, quantity: 8),
      ];
      var batch = buildCuttingBendingBatch(
        title: 'Test',
        sourceMetrajRecordIds: const ['rec-1'],
        textDetails: const [],
      ).copyWith(pieceLines: pieces);

      batch = await runOptimumFireAnalysis(batch);
      final withSave = saveOptimizationSnapshot(batch);
      final cleared = clearActiveOptimization(withSave);

      expect(cleared.isOptimized, isFalse);

      final restored = applyOptimizationSnapshot(
        cleared,
        withSave.savedOptimizations[FireReductionStrategy.lengthMatchOnly]!,
      );

      expect(restored.isOptimized, isTrue);
      expect(restored.optimizationStrategy, FireReductionStrategy.lengthMatchOnly);
      expect(restored.revisedPieceLines.length, batch.revisedPieceLines.length);
      expect(restored.stockCutPlans, isNotEmpty);
      expect(
        computeAnalysisFireSummary(restored).plannedWasteTonnage,
        computeAnalysisFireSummary(batch).plannedWasteTonnage,
      );
    });

    test('OptimizationSnapshot round-trips through batch json', () async {
      const pieces = [
        RebarPieceLine(diameter: 16, lengthM: 2.00, quantity: 10),
        RebarPieceLine(diameter: 16, lengthM: 2.05, quantity: 8),
      ];
      var batch = buildCuttingBendingBatch(
        title: 'Test',
        sourceMetrajRecordIds: const ['rec-1'],
        textDetails: const [],
      ).copyWith(pieceLines: pieces);

      batch = await runOptimumFireAnalysis(batch);
      batch = saveOptimizationSnapshot(batch);

      final decoded = CuttingBendingBatch.fromJson(batch.toJson());

      expect(decoded.savedOptimizations, hasLength(1));
      expect(decoded.hasSavedOptimization(FireReductionStrategy.lengthMatchOnly), isTrue);
    });

    test('computeStrategyFireComparisons lists saved and active strategies', () async {
      const pieces = [
        RebarPieceLine(diameter: 16, lengthM: 2.00, quantity: 10),
        RebarPieceLine(diameter: 16, lengthM: 2.05, quantity: 8),
      ];
      var batch = buildCuttingBendingBatch(
        title: 'Test',
        sourceMetrajRecordIds: const ['rec-1'],
        textDetails: const [],
      ).copyWith(pieceLines: pieces);

      batch = await runOptimumFireAnalysis(batch);
      batch = saveOptimizationSnapshot(batch);

      final rows = computeStrategyFireComparisons(batch);

      expect(rows, hasLength(1));
      expect(rows.where((row) => row.isAvailable), hasLength(1));
      expect(
        rows.firstWhere((row) => row.strategy == FireReductionStrategy.lengthMatchOnly).isSaved,
        isTrue,
      );
    });

    test('mergeCuttingBendingBatchesForAnalysis combines piece lines across files', () {
      final batchA = buildCuttingBendingBatch(
        title: 'TEMEL',
        sourceMetrajRecordIds: const ['a'],
        textDetails: const [
          RebarMetrajTextDetail(
            entityType: 'TEXT',
            sourceText: 'a1',
            included: true,
            diameter: 16,
            lengthM: 2.0,
            quantity: 10,
          ),
        ],
      );
      final batchB = buildCuttingBendingBatch(
        title: 'PERDE',
        sourceMetrajRecordIds: const ['b'],
        textDetails: const [
          RebarMetrajTextDetail(
            entityType: 'TEXT',
            sourceText: 'b1',
            included: true,
            diameter: 16,
            lengthM: 2.0,
            quantity: 5,
          ),
          RebarMetrajTextDetail(
            entityType: 'TEXT',
            sourceText: 'b2',
            included: true,
            diameter: 12,
            lengthM: 3.0,
            quantity: 4,
          ),
        ],
      );

      final merged = mergeCuttingBendingBatchesForAnalysis([batchA, batchB]);

      expect(merged.title, '2 dosya birleşik analiz');
      expect(merged.pieceLines, hasLength(2));
      expect(
        merged.pieceLines.firstWhere((piece) => piece.diameter == 16).quantity,
        15,
      );
      expect(merged.sourceMetrajRecordIds, containsAll(['a', 'b']));
    });

    test('keeps element identity on piece lines and stock cut members', () {
      const details = [
        RebarMetrajTextDetail(
          entityType: 'TEXT',
          sourceText: 's1',
          included: true,
          diameter: 12,
          lengthM: 4.10,
          quantity: 2,
          elementCode: 'SB12',
          elementTypeCode: 'S',
        ),
        RebarMetrajTextDetail(
          entityType: 'TEXT',
          sourceText: 'k1',
          included: true,
          diameter: 12,
          lengthM: 4.10,
          quantity: 1,
          elementCode: 'K101',
          elementTypeCode: 'K',
        ),
        RebarMetrajTextDetail(
          entityType: 'TEXT',
          sourceText: 'd1',
          included: true,
          diameter: 12,
          lengthM: 3.75,
          quantity: 1,
          elementCode: 'D3',
          elementTypeCode: 'D',
        ),
      ];

      final lines = extractPieceLinesFromMetrajDetails(details);
      expect(lines, hasLength(3));
      expect(
        lines.map((line) => line.elementDisplayLabel).toSet(),
        containsAll(['Kolon SB12', 'Kiriş K101', 'Döşeme D3']),
      );

      final plans = computeStockCutPlans(lines, useCache: false);
      expect(plans, hasLength(1));
      final members = plans.first.bars.expand((bar) => bar.members).toList();
      expect(
        members.any((m) => m.elementDisplayLabel == 'Kolon SB12'),
        isTrue,
      );
      expect(
        members.any((m) => m.elementDisplayLabel == 'Kiriş K101'),
        isTrue,
      );
      expect(
        members.any((m) => m.elementDisplayLabel == 'Döşeme D3'),
        isTrue,
      );
    });
  });
}
