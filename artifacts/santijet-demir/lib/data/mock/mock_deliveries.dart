import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';

List<DeliveryItem> getMockDeliveries() => [
  DeliveryItem(
    id: 'd1',
    orderNo: 'SIP-2025-0048',
    irsaliyeNo: 'IR-2025-1180',
    date: DateTime(2025, 5, 14),
    supplier: 'Çolakoğlu',
    tonnage: 48,
    fulfillmentPercent: 100,
    status: DeliveryStatus.received,
    diameterLines: const [
      DeliveryDiameterLine(diameter: 16, ordered: 28, delivered: 28),
      DeliveryDiameterLine(diameter: 20, ordered: 20, delivered: 20),
    ],
  ),
  DeliveryItem(
    id: 'd2',
    orderNo: 'SIP-2025-0047',
    irsaliyeNo: 'IR-2025-1175',
    date: DateTime(2025, 5, 13),
    supplier: 'Kardemir',
    tonnage: 62,
    fulfillmentPercent: 85,
    status: DeliveryStatus.partial,
    diameterLines: const [
      DeliveryDiameterLine(diameter: 16, ordered: 35, delivered: 30),
      DeliveryDiameterLine(diameter: 20, ordered: 38, delivered: 32),
    ],
  ),
  DeliveryItem(
    id: 'd3',
    orderNo: 'SIP-2025-0042',
    irsaliyeNo: 'IR-2025-1168',
    date: DateTime(2025, 5, 12),
    supplier: 'İsdemir',
    tonnage: 54,
    fulfillmentPercent: 72,
    status: DeliveryStatus.missing,
    diameterLines: const [
      DeliveryDiameterLine(diameter: 16, ordered: 40, delivered: 28),
      DeliveryDiameterLine(diameter: 22, ordered: 35, delivered: 26),
    ],
  ),
  DeliveryItem(
    id: 'd4',
    orderNo: 'SIP-2025-0040',
    irsaliyeNo: 'IR-2025-1160',
    date: DateTime(2025, 5, 11),
    supplier: 'Erdemir',
    tonnage: 58,
    fulfillmentPercent: 108,
    status: DeliveryStatus.excess,
    diameterLines: const [
      DeliveryDiameterLine(diameter: 12, ordered: 25, delivered: 28),
      DeliveryDiameterLine(diameter: 16, ordered: 30, delivered: 30),
    ],
  ),
  DeliveryItem(
    id: 'd5',
    orderNo: 'SIP-2025-0038',
    irsaliyeNo: 'IR-2025-1155',
    date: DateTime(2025, 5, 10),
    supplier: 'Çolakoğlu',
    tonnage: 72,
    fulfillmentPercent: 100,
    status: DeliveryStatus.received,
    diameterLines: const [
      DeliveryDiameterLine(diameter: 20, ordered: 40, delivered: 40),
      DeliveryDiameterLine(diameter: 22, ordered: 32, delivered: 32),
    ],
  ),
  DeliveryItem(
    id: 'd6',
    orderNo: 'SIP-2025-0035',
    irsaliyeNo: 'IR-2025-1148',
    date: DateTime(2025, 5, 9),
    supplier: 'Kardemir',
    tonnage: 0,
    fulfillmentPercent: 0,
    status: DeliveryStatus.pending,
    diameterLines: const [
      DeliveryDiameterLine(diameter: 16, ordered: 45, delivered: 0),
    ],
  ),
  DeliveryItem(
    id: 'd7',
    orderNo: 'SIP-2025-0032',
    irsaliyeNo: 'IR-2025-1140',
    date: DateTime(2025, 5, 8),
    supplier: 'İsdemir',
    tonnage: 36,
    fulfillmentPercent: 95,
    status: DeliveryStatus.received,
    diameterLines: const [
      DeliveryDiameterLine(diameter: 14, ordered: 20, delivered: 19),
      DeliveryDiameterLine(diameter: 16, ordered: 18, delivered: 17),
    ],
  ),
];

const deliveryFilterLabels = [
  'Tümü',
  'Teslim Alındı',
  'Kısmi',
  'Eksik',
  'Fazla',
  'Beklemede',
];

List<SupplierPerformance> getMockSupplierPerformance() => const [
  SupplierPerformance(
    name: 'Çolakoğlu',
    totalOrdered: 820,
    totalDelivered: 818,
    missing: 2,
    difference: -2,
    performancePercent: 99.7,
    rating: 4.9,
  ),
  SupplierPerformance(
    name: 'Kardemir',
    totalOrdered: 650,
    totalDelivered: 645,
    missing: 5,
    difference: -5,
    performancePercent: 99.2,
    rating: 4.7,
  ),
  SupplierPerformance(
    name: 'İsdemir',
    totalOrdered: 480,
    totalDelivered: 466,
    missing: 14,
    difference: -14,
    performancePercent: 97.0,
    rating: 4.5,
  ),
  SupplierPerformance(
    name: 'Erdemir',
    totalOrdered: 320,
    totalDelivered: 232,
    missing: 88,
    difference: -88,
    performancePercent: 72.7,
    rating: 3.8,
  ),
];

const matchedOrderInfo = {
  'orderNo': 'SIP-2025-0048',
  'supplier': 'Çolakoğlu',
  'totalOrdered': 120.0,
  'diameters': {16: 68.0, 20: 42.0, 22: 10.0},
};
