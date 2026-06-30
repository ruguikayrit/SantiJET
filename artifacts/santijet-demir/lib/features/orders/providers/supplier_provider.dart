import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

const _suppliersKey = 'order_suppliers';

final supplierOptionsProvider =
    StateNotifierProvider<SupplierOptionsNotifier, List<SupplierOption>>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return SupplierOptionsNotifier(box);
});

class SupplierOptionsNotifier extends StateNotifier<List<SupplierOption>> {
  SupplierOptionsNotifier(this._box) : super(_loadSuppliers(_box));

  final Box _box;

  static List<SupplierOption> _loadSuppliers(Box box) {
    final raw = box.get(_suppliersKey);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map(SupplierOption.fromJson)
          .where((s) => s.name.isNotEmpty)
          .toList();
    }
    return [];
  }

  Future<void> _persist() async {
    await _box.put(_suppliersKey, state.map((s) => s.toJson()).toList());
  }

  Future<SupplierOption> addSupplier({
    required String name,
    required double pricePerTon,
    double rating = 4,
    int deliveryDays = 7,
  }) async {
    final trimmedName = name.trim();
    final supplier = SupplierOption(
      name: trimmedName,
      pricePerTon: pricePerTon,
      rating: rating,
      deliveryDays: deliveryDays,
    );

    final existingIndex = state.indexWhere(
      (item) => item.name.toLowerCase() == trimmedName.toLowerCase(),
    );

    if (existingIndex >= 0) {
      final updated = List<SupplierOption>.from(state);
      updated[existingIndex] = supplier;
      state = updated;
    } else {
      state = [...state, supplier];
    }

    await _persist();
    return supplier;
  }
}
