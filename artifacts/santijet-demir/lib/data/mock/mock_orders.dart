import 'package:santijet_demir/domain/entities/order.dart';

const imalatOptions = <(String, double)>[];

const supplierOptions = <SupplierOption>[];

List<OrderItem> getMockOrders() => [];

List<DiameterOrderLine> calculateDiameterLines(double totalTonnage) {
  const distribution = {12: 0.15, 16: 0.35, 20: 0.30, 22: 0.20};
  const currentStock = {12: 0.0, 16: 0.0, 20: 0.0, 22: 0.0};

  return distribution.entries.map((e) {
    final orderAmount = totalTonnage * e.value;
    return DiameterOrderLine(
      diameter: e.key,
      currentStock: currentStock[e.key] ?? 0,
      orderAmount: orderAmount,
    );
  }).toList();
}
