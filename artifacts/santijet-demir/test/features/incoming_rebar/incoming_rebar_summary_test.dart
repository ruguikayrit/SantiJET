import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/mock/mock_deliveries.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';

void main() {
  group('computeIncomingRebarSummary', () {
    test('mock deliveries produce consistent KPI totals', () {
      final summary = computeIncomingRebarSummary(getMockDeliveries());

      expect(summary.totalOrdered, 406);
      expect(summary.totalDelivered, 330);
      expect(summary.pending, 76);
      expect(summary.missing, 79);
      expect(summary.fulfillmentPercent, closeTo(81.28, 0.01));
    });

    test('empty list returns zero summary', () {
      final summary = computeIncomingRebarSummary([]);

      expect(summary.totalOrdered, 0);
      expect(summary.totalDelivered, 0);
      expect(summary.pending, 0);
      expect(summary.missing, 0);
      expect(summary.fulfillmentPercent, 0);
    });
  });
}
