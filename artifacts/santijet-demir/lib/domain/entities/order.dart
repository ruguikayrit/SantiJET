import 'package:santijet_demir/domain/enums/app_enums.dart';

class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderNo,
    required this.date,
    required this.imalatTypes,
    required this.tonnage,
    required this.status,
    required this.supplier,
  });

  final String id;
  final String orderNo;
  final DateTime date;
  final List<String> imalatTypes;
  final double tonnage;
  final OrderStatus status;
  final String supplier;
}

class SupplierOption {
  const SupplierOption({
    required this.name,
    required this.pricePerTon,
    required this.rating,
    required this.deliveryDays,
  });

  final String name;
  final double pricePerTon;
  final double rating;
  final int deliveryDays;
}

class DiameterOrderLine {
  const DiameterOrderLine({
    required this.diameter,
    required this.currentStock,
    required this.orderAmount,
  });

  final int diameter;
  final double currentStock;
  final double orderAmount;
}

class NewOrderDraft {
  NewOrderDraft({
    this.selectedImalats = const {},
    this.ratio = 100,
    this.selectedSupplier,
  });

  final Map<String, double> selectedImalats;
  final int ratio;
  final SupplierOption? selectedSupplier;

  double get totalTonnage =>
      selectedImalats.values.fold(0.0, (sum, v) => sum + v) * ratio / 100;

  NewOrderDraft copyWith({
    Map<String, double>? selectedImalats,
    int? ratio,
    SupplierOption? selectedSupplier,
    bool clearSupplier = false,
  }) {
    return NewOrderDraft(
      selectedImalats: selectedImalats ?? this.selectedImalats,
      ratio: ratio ?? this.ratio,
      selectedSupplier:
          clearSupplier ? null : (selectedSupplier ?? this.selectedSupplier),
    );
  }
}
