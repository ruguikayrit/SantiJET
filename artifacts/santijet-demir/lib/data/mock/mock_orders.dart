import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';

const imalatOptions = [
  ('Radye Temel', 1382.0),
  ('Perde', 628.0),
  ('Kolon', 412.0),
  ('Kiriş', 384.0),
  ('Döşeme', 350.0),
  ('Merdiven', 86.0),
];

const supplierOptions = [
  SupplierOption(name: 'Çolakoğlu', pricePerTon: 24500, rating: 4.9, deliveryDays: 3),
  SupplierOption(name: 'Kardemir', pricePerTon: 23800, rating: 4.7, deliveryDays: 4),
  SupplierOption(name: 'İsdemir', pricePerTon: 24100, rating: 4.5, deliveryDays: 5),
  SupplierOption(name: 'Erdemir', pricePerTon: 23200, rating: 3.8, deliveryDays: 7),
];

List<OrderItem> getMockOrders() => [
  OrderItem(
    id: '1',
    orderNo: 'SIP-2025-0048',
    date: DateTime(2025, 5, 14),
    imalatTypes: ['Radye Temel', 'Kolon'],
    tonnage: 120,
    status: OrderStatus.completed,
    supplier: 'Çolakoğlu',
  ),
  OrderItem(
    id: '2',
    orderNo: 'SIP-2025-0047',
    date: DateTime(2025, 5, 13),
    imalatTypes: ['Perde', 'Kiriş'],
    tonnage: 86,
    status: OrderStatus.inTransit,
    supplier: 'Kardemir',
  ),
  OrderItem(
    id: '3',
    orderNo: 'SIP-2025-0046',
    date: DateTime(2025, 5, 12),
    imalatTypes: ['Döşeme'],
    tonnage: 54,
    status: OrderStatus.submitted,
    supplier: 'İsdemir',
  ),
  OrderItem(
    id: '4',
    orderNo: 'SIP-2025-0045',
    date: DateTime(2025, 5, 11),
    imalatTypes: ['Radye Temel'],
    tonnage: 210,
    status: OrderStatus.pendingApproval,
    supplier: 'Çolakoğlu',
  ),
  OrderItem(
    id: '5',
    orderNo: 'SIP-2025-0044',
    date: DateTime(2025, 5, 10),
    imalatTypes: ['Kolon', 'Kiriş', 'Döşeme'],
    tonnage: 178,
    status: OrderStatus.draft,
    supplier: 'Erdemir',
  ),
  OrderItem(
    id: '6',
    orderNo: 'SIP-2025-0043',
    date: DateTime(2025, 5, 9),
    imalatTypes: ['Merdiven'],
    tonnage: 32,
    status: OrderStatus.completed,
    supplier: 'Kardemir',
  ),
  OrderItem(
    id: '7',
    orderNo: 'SIP-2025-0042',
    date: DateTime(2025, 5, 8),
    imalatTypes: ['Perde', 'Radye Temel'],
    tonnage: 145,
    status: OrderStatus.inTransit,
    supplier: 'İsdemir',
  ),
];

List<DiameterOrderLine> calculateDiameterLines(double totalTonnage) {
  const distribution = {12: 0.15, 16: 0.35, 20: 0.30, 22: 0.20};
  const currentStock = {12: 18.0, 16: 42.0, 20: 28.0, 22: 15.0};

  return distribution.entries.map((e) {
    final orderAmount = totalTonnage * e.value;
    return DiameterOrderLine(
      diameter: e.key,
      currentStock: currentStock[e.key] ?? 0,
      orderAmount: orderAmount,
    );
  }).toList();
}
