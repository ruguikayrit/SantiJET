import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/mock/mock_deliveries.dart';
import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';

final deliveriesProvider = Provider<List<DeliveryItem>>((ref) {
  return getMockDeliveries();
});

class IncomingRebarDashboardSummary {
  const IncomingRebarDashboardSummary({
    required this.totalOrdered,
    required this.totalDelivered,
    required this.pending,
    required this.missing,
    required this.fulfillmentPercent,
  });

  final double totalOrdered;
  final double totalDelivered;
  final double pending;
  final double missing;
  final double fulfillmentPercent;
}

IncomingRebarDashboardSummary computeIncomingRebarSummary(
  List<DeliveryItem> deliveries,
) {
  var totalOrdered = 0.0;
  var totalDelivered = 0.0;
  var missing = 0.0;

  for (final delivery in deliveries) {
    for (final line in delivery.diameterLines) {
      totalOrdered += line.ordered;
      totalDelivered += line.delivered;
      if (line.delivered < line.ordered) {
        missing += line.ordered - line.delivered;
      }
    }
  }

  final pending = totalOrdered - totalDelivered;
  final fulfillmentPercent = totalOrdered > 0
      ? (totalDelivered / totalOrdered * 100)
      : 0.0;

  return IncomingRebarDashboardSummary(
    totalOrdered: totalOrdered,
    totalDelivered: totalDelivered,
    pending: pending,
    missing: missing,
    fulfillmentPercent: fulfillmentPercent,
  );
}

/// Gelen Demir KPI — teslimat listesinden hesaplanır; ana sayfa bu provider'ı okur.
final incomingRebarDashboardSummaryProvider =
    Provider<IncomingRebarDashboardSummary>((ref) {
  final deliveries = ref.watch(deliveriesProvider);
  return computeIncomingRebarSummary(deliveries);
});

final deliveryFilterProvider = StateProvider<int>((ref) => 0);

final filteredDeliveriesProvider = Provider<List<DeliveryItem>>((ref) {
  final deliveries = ref.watch(deliveriesProvider);
  final filterIndex = ref.watch(deliveryFilterProvider);

  if (filterIndex == 0) return deliveries;

  final status = DeliveryStatus.values[filterIndex - 1];
  return deliveries.where((d) => d.status == status).toList();
});

final supplierPerformanceProvider = Provider<List<SupplierPerformance>>((ref) {
  return getMockSupplierPerformance();
});

final newDeliveryDraftProvider =
    StateNotifierProvider<NewDeliveryDraftNotifier, NewDeliveryDraft>(
  (ref) => NewDeliveryDraftNotifier(),
);

class NewDeliveryDraftNotifier extends StateNotifier<NewDeliveryDraft> {
  NewDeliveryDraftNotifier()
      : super(NewDeliveryDraft(
          date: DateTime.now(),
          diameterEntries: {16: 28, 20: 20, 22: 0},
        ));

  void setSupplier(String supplier) {
    state = state.copyWith(supplier: supplier);
  }

  void setOrderNo(String orderNo) {
    state = state.copyWith(orderNo: orderNo);
  }

  void setIrsaliyeNo(String value) {
    state = state.copyWith(irsaliyeNo: value);
  }

  void setPlateNo(String value) {
    state = state.copyWith(plateNo: value);
  }

  void setDiameterEntry(int diameter, double value) {
    final updated = Map<int, double>.from(state.diameterEntries);
    updated[diameter] = value;
    state = state.copyWith(diameterEntries: updated);
  }

  void reset() {
    state = NewDeliveryDraft(
      date: DateTime.now(),
      diameterEntries: {16: 28, 20: 20, 22: 0},
    );
  }
}
