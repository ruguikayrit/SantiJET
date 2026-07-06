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

      final groups = computeLengthMatchGroups(pieces, toleranceM: 0.10);

      expect(groups, hasLength(1));
      expect(groups.first.diameter, 16);
      expect(groups.first.totalQuantity, 18);
      expect(groups.first.members, hasLength(2));
    });

    test('length match uses min-max span not chained neighbor distance', () {
      const pieces = [
        RebarPieceLine(diameter: 12, lengthM: 4.75, quantity: 12),
        RebarPieceLine(diameter: 12, lengthM: 4.95, quantity: 6),
        RebarPieceLine(diameter: 12, lengthM: 5.05, quantity: 12),
      ];

      final groups20 = computeLengthMatchGroups(pieces, toleranceM: 0.20);
      expect(groups20, hasLength(1));
      expect(groups20.first.maxLengthM - groups20.first.minLengthM, closeTo(0.20, 1e-9));
      expect(groups20.first.members, hasLength(2));

      final groups30 = computeLengthMatchGroups(pieces, toleranceM: 0.30);
      expect(groups30, hasLength(1));
      expect(groups30.first.maxLengthM - groups30.first.minLengthM, closeTo(0.30, 1e-9));
      expect(groups30.first.members, hasLength(3));
    });

    test('suggests tahvil for different diameters with near lengths', () {
      const pieces = [
        RebarPieceLine(diameter: 16, lengthM: 2.00, quantity: 10),
        RebarPieceLine(diameter: 20, lengthM: 2.08, quantity: 6),
        RebarPieceLine(diameter: 12, lengthM: 5.00, quantity: 3),
      ];

      final tahvil = computeTahvilGroups(pieces, toleranceM: 0.10);

      expect(tahvil, hasLength(1));
      expect(tahvil.first.members, hasLength(2));
      expect(tahvil.first.diameters, {16, 20});
      expect(tahvil.first.equivalents, isNotEmpty);
      expect(
        tahvil.first.equivalents.every(
          (eq) => (eq.fromDiameter - eq.toDiameter).abs() <= 4,
        ),
        isTrue,
      );
    });

    test('does not suggest tahvil when diameter difference exceeds 4 mm', () {
      const pieces = [
        RebarPieceLine(diameter: 12, lengthM: 2.60, quantity: 2),
        RebarPieceLine(diameter: 28, lengthM: 2.70, quantity: 24),
      ];

      final tahvil = computeTahvilGroups(pieces, toleranceM: 0.20);

      expect(tahvil, isEmpty);
    });

    test('computes tahvil quantity from cross-section area ratio', () {
      expect(
        TahvilEquivalent.computeEquivalentQuantity(
          fromDiameter: 16,
          fromQuantity: 1978,
          toDiameter: 12,
        ),
        3516,
      );
      expect(
        TahvilEquivalent.computeEquivalentQuantity(
          fromDiameter: 12,
          fromQuantity: 52,
          toDiameter: 16,
        ),
        29,
      );
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

    test('buildCuttingBendingBatch includes stock cut plans', () {
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

      expect(batch.stockCutPlans, isNotEmpty);
      expect(batch.stockCutPlans.first.totalBars, 2);
    });

    test('applyLengthMatchesToPieceLines merges approved length match groups', () {
      const pieces = [
        RebarPieceLine(diameter: 16, lengthM: 2.00, quantity: 10),
        RebarPieceLine(diameter: 16, lengthM: 2.05, quantity: 8),
        RebarPieceLine(diameter: 16, lengthM: 3.50, quantity: 4),
      ];
      final groups = computeLengthMatchGroups(pieces, toleranceM: 0.10);
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

    test('stock cut plans wait for completed length matching', () {
      const pieces = [
        RebarPieceLine(diameter: 12, lengthM: 6.50, quantity: 5),
        RebarPieceLine(diameter: 12, lengthM: 6.55, quantity: 5),
      ];
      final groups = computeLengthMatchGroups(pieces, toleranceM: 0.10);
      var batch = syncBatchLengthMatchDerivatives(
        CuttingBendingBatch(
          id: 'kb-test',
          title: 'Test',
          createdAt: DateTime.now(),
          sourceMetrajRecordIds: const [],
          labelDetails: const [],
          pieceLines: pieces,
          revisedPieceLines: const [],
          lengthMatches: groups,
          tahvilGroups: const [],
          stockCutPlans: const [],
        ),
      );

      expect(batch.stockCutPlans, isEmpty);
      expect(batch.revisedPieceLines, hasLength(2));

      batch = syncBatchLengthMatchDerivatives(
        batch.copyWith(
          lengthMatches: [
            groups.first.copyWith(approved: true, selectedLengthM: 6.50),
          ],
        ),
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
      expect(rebuilt.tahvilGroups, isEmpty);
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
      });

      expect(batch.labelDetails, isEmpty);
    });
  });
}
