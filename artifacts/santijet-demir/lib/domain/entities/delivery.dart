import 'package:santijet_demir/domain/enums/app_enums.dart';

class DeliveryDiameterLine {
  const DeliveryDiameterLine({
    required this.diameter,
    required this.ordered,
    required this.delivered,
  });

  final int diameter;
  final double ordered;
  final double delivered;

  double get difference => delivered - ordered;
  bool get isMatch => difference.abs() < 0.1;
  bool get isExcess => difference > 0.1;
  bool get isMissing => difference < -0.1;
}

class DeliveryItem {
  const DeliveryItem({
    required this.id,
    required this.orderNo,
    required this.irsaliyeNo,
    required this.date,
    required this.supplier,
    required this.tonnage,
    required this.fulfillmentPercent,
    required this.status,
    required this.diameterLines,
  });

  final String id;
  final String orderNo;
  final String irsaliyeNo;
  final DateTime date;
  final String supplier;
  final double tonnage;
  final double fulfillmentPercent;
  final DeliveryStatus status;
  final List<DeliveryDiameterLine> diameterLines;
}

class SupplierPerformance {
  const SupplierPerformance({
    required this.name,
    required this.totalOrdered,
    required this.totalDelivered,
    required this.missing,
    required this.difference,
    required this.performancePercent,
    required this.rating,
  });

  final String name;
  final double totalOrdered;
  final double totalDelivered;
  final double missing;
  final double difference;
  final double performancePercent;
  final double rating;
}

class NewDeliveryDraft {
  NewDeliveryDraft({
    this.supplier,
    this.orderNo = '',
    this.date,
    this.irsaliyeNo = '',
    this.plateNo = '',
    this.diameterEntries = const {},
  });

  final String? supplier;
  final String orderNo;
  final DateTime? date;
  final String irsaliyeNo;
  final String plateNo;
  final Map<int, double> diameterEntries;

  double get totalDelivered =>
      diameterEntries.values.fold(0.0, (s, v) => s + v);

  NewDeliveryDraft copyWith({
    String? supplier,
    String? orderNo,
    DateTime? date,
    String? irsaliyeNo,
    String? plateNo,
    Map<int, double>? diameterEntries,
  }) {
    return NewDeliveryDraft(
      supplier: supplier ?? this.supplier,
      orderNo: orderNo ?? this.orderNo,
      date: date ?? this.date,
      irsaliyeNo: irsaliyeNo ?? this.irsaliyeNo,
      plateNo: plateNo ?? this.plateNo,
      diameterEntries: diameterEntries ?? this.diameterEntries,
    );
  }
}
