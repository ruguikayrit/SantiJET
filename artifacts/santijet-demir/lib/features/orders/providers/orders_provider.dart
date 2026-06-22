import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/mock/mock_orders.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';

final ordersProvider = Provider<List<OrderItem>>((ref) => getMockOrders());

final orderFilterProvider = StateProvider<int>((ref) => 0);

const orderFilterLabels = [
  'Tümü',
  'Taslak',
  'Onay Bek.',
  'Verildi',
  'Yolda',
  'Tamamlandı',
];

final filteredOrdersProvider = Provider<List<OrderItem>>((ref) {
  final orders = ref.watch(ordersProvider);
  final filterIndex = ref.watch(orderFilterProvider);

  if (filterIndex == 0) return orders;

  final status = OrderStatus.values[filterIndex - 1];
  return orders.where((o) => o.status == status).toList();
});

final newOrderDraftProvider =
    StateNotifierProvider<NewOrderDraftNotifier, NewOrderDraft>(
  (ref) => NewOrderDraftNotifier(),
);

class NewOrderDraftNotifier extends StateNotifier<NewOrderDraft> {
  NewOrderDraftNotifier() : super(NewOrderDraft());

  void toggleImalat(String name, double tonnage) {
    final updated = Map<String, double>.from(state.selectedImalats);
    if (updated.containsKey(name)) {
      updated.remove(name);
    } else {
      updated[name] = tonnage;
    }
    state = state.copyWith(selectedImalats: updated);
  }

  void setRatio(int ratio) {
    state = state.copyWith(ratio: ratio);
  }

  void selectSupplier(SupplierOption supplier) {
    state = state.copyWith(selectedSupplier: supplier);
  }

  void reset() {
    state = NewOrderDraft();
  }
}
