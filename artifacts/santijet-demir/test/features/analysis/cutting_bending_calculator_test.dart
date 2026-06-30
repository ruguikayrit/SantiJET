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
    });
  });
}
