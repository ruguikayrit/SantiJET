import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/features/analysis/widgets/stock_bar_cut_visual.dart';

void main() {
  group('stock bar cut grouping', () {
    StockBarCut bar({
      required int index,
      required List<StockBarCutMember> members,
      double used = 11.85,
      double waste = 0.15,
    }) {
      return StockBarCut(
        barIndex: index,
        diameter: 12,
        members: members,
        usedLengthM: used,
        wasteLengthM: waste,
      );
    }

    const members = [
      StockBarCutMember(
        lengthM: 5.05,
        count: 1,
        elementCode: 'K109',
        elementTypeCode: 'K',
        elementTypeLabel: 'Kiriş',
      ),
      StockBarCutMember(
        lengthM: 3.75,
        count: 1,
        elementCode: 'K109',
        elementTypeCode: 'K',
        elementTypeLabel: 'Kiriş',
      ),
      StockBarCutMember(
        lengthM: 3.05,
        count: 1,
        elementCode: 'K109',
        elementTypeCode: 'K',
        elementTypeLabel: 'Kiriş',
      ),
    ];

    test('groups identical cuts into index ranges', () {
      final bars = [
        for (var i = 1; i <= 5; i++) bar(index: i, members: members),
        bar(
          index: 6,
          members: const [
            StockBarCutMember(lengthM: 12.0, count: 1),
          ],
          used: 12.0,
          waste: 0.0,
        ),
      ];

      final groups = groupIdenticalStockBarCuts(bars);
      expect(groups, hasLength(2));
      expect(groups.first.titleLabel, 'Çubuk 1–5 · 5 adet');
      expect(groups.last.titleLabel, 'Çubuk 6');
    });

    test('formats non-contiguous ranges', () {
      expect(formatBarIndexRanges([1, 2, 3, 10, 12, 13]), '1–3, 10, 12–13');
    });
  });
}
