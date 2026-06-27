import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';

void main() {
  group('computeIncomingRebarSummary', () {
    test('aggregates ordered and delivered tonnage from diameter lines', () {
      final deliveries = [
        DeliveryItem(
          id: 'd1',
          orderNo: 'SIP-1',
          irsaliyeNo: 'IR-1',
          date: DateTime(2025, 5, 14),
          supplier: 'Test',
          tonnage: 48,
          fulfillmentPercent: 100,
          status: DeliveryStatus.received,
          diameterLines: const [
            DeliveryDiameterLine(diameter: 16, ordered: 30, delivered: 28),
            DeliveryDiameterLine(diameter: 20, ordered: 20, delivered: 20),
          ],
        ),
        DeliveryItem(
          id: 'd2',
          orderNo: 'SIP-2',
          irsaliyeNo: 'IR-2',
          date: DateTime(2025, 5, 13),
          supplier: 'Test',
          tonnage: 0,
          fulfillmentPercent: 0,
          status: DeliveryStatus.pending,
          diameterLines: const [
            DeliveryDiameterLine(diameter: 16, ordered: 10, delivered: 0),
          ],
        ),
      ];

      final summary = computeIncomingRebarSummary(deliveries);

      expect(summary.totalOrdered, 60);
      expect(summary.totalDelivered, 48);
      expect(summary.pending, 12);
      expect(summary.missing, 12);
      expect(summary.fulfillmentPercent, closeTo(80, 0.01));
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
