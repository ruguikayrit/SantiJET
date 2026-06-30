import 'package:flutter_test/flutter_test.dart';
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
      });

      expect(batch.labelDetails, isEmpty);
    });
  });
}
