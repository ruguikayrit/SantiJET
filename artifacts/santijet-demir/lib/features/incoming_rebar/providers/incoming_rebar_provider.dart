import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/mock/mock_deliveries.dart';
import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';

final deliveriesProvider = Provider<List<DeliveryItem>>((ref) {
  return getMockDeliveries();
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
