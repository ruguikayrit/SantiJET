import 'package:santijet_demir/domain/entities/delivery.dart';

List<DeliveryItem> getMockDeliveries() => [];

const deliveryFilterLabels = [
  'Tümü',
  'Teslim Alındı',
  'Kısmi',
  'Eksik',
  'Fazla',
  'Beklemede',
];

List<SupplierPerformance> getMockSupplierPerformance() => const [];

const matchedOrderInfo = {
  'orderNo': '',
  'supplier': '',
  'totalOrdered': 0.0,
  'diameters': <int, double>{},
};
