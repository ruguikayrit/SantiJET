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
    required this.orderId,
    required this.orderNo,
    required this.irsaliyeNo,
    required this.date,
    required this.supplier,
    required this.tonnage,
    required this.fulfillmentPercent,
    required this.status,
    required this.diameterLines,
    this.plateNo = '',
  });

  final String id;
  final String orderId;
  final String orderNo;
  final String irsaliyeNo;
  final DateTime date;
  final String supplier;
  final double tonnage;
  final double fulfillmentPercent;
  final DeliveryStatus status;
  final List<DeliveryDiameterLine> diameterLines;
  final String plateNo;

  DeliveryItem copyWith({
    String? id,
    String? orderId,
    String? orderNo,
    String? irsaliyeNo,
    DateTime? date,
    String? supplier,
    double? tonnage,
    double? fulfillmentPercent,
    DeliveryStatus? status,
    List<DeliveryDiameterLine>? diameterLines,
    String? plateNo,
  }) {
    return DeliveryItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderNo: orderNo ?? this.orderNo,
      irsaliyeNo: irsaliyeNo ?? this.irsaliyeNo,
      date: date ?? this.date,
      supplier: supplier ?? this.supplier,
      tonnage: tonnage ?? this.tonnage,
      fulfillmentPercent: fulfillmentPercent ?? this.fulfillmentPercent,
      status: status ?? this.status,
      diameterLines: diameterLines ?? this.diameterLines,
      plateNo: plateNo ?? this.plateNo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'orderNo': orderNo,
        'irsaliyeNo': irsaliyeNo,
        'date': date.toIso8601String(),
        'supplier': supplier,
        'tonnage': tonnage,
        'fulfillmentPercent': fulfillmentPercent,
        'status': status.name,
        'plateNo': plateNo,
        'diameterLines': diameterLines
            .map(
              (line) => {
                'diameter': line.diameter,
                'ordered': line.ordered,
                'delivered': line.delivered,
              },
            )
            .toList(),
      };

  factory DeliveryItem.fromJson(Map<dynamic, dynamic> json) {
    final rawLines = json['diameterLines'] as List<dynamic>? ?? const [];
    return DeliveryItem(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      orderNo: json['orderNo'] as String? ?? '',
      irsaliyeNo: json['irsaliyeNo'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      supplier: json['supplier'] as String? ?? '',
      tonnage: (json['tonnage'] as num?)?.toDouble() ?? 0,
      fulfillmentPercent: (json['fulfillmentPercent'] as num?)?.toDouble() ?? 0,
      status: switch (json['status'] as String?) {
        final String? name when name != null => DeliveryStatus.values.firstWhere(
            (value) => value.name == name,
            orElse: () => DeliveryStatus.received,
          ),
        _ => DeliveryStatus.received,
      },
      plateNo: json['plateNo'] as String? ?? '',
      diameterLines: rawLines
          .whereType<Map>()
          .map(
            (line) => DeliveryDiameterLine(
              diameter: (line['diameter'] as num?)?.toInt() ?? 0,
              ordered: (line['ordered'] as num?)?.toDouble() ?? 0,
              delivered: (line['delivered'] as num?)?.toDouble() ?? 0,
            ),
          )
          .where((line) => line.diameter > 0)
          .toList(),
    );
  }
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
    this.orderId,
    this.supplier,
    this.orderNo = '',
    this.date,
    this.irsaliyeNo = '',
    this.plateNo = '',
    this.diameterEntries = const {},
    this.orderedDiameters = const {},
  });

  final String? orderId;
  final String? supplier;
  final String orderNo;
  final DateTime? date;
  final String irsaliyeNo;
  final String plateNo;
  final Map<int, double> diameterEntries;
  final Map<int, double> orderedDiameters;

  double get totalOrdered =>
      orderedDiameters.values.fold(0.0, (sum, value) => sum + value);

  double get totalDelivered =>
      diameterEntries.values.fold(0.0, (sum, value) => sum + value);

  NewDeliveryDraft copyWith({
    String? orderId,
    String? supplier,
    String? orderNo,
    DateTime? date,
    String? irsaliyeNo,
    String? plateNo,
    Map<int, double>? diameterEntries,
    Map<int, double>? orderedDiameters,
    bool clearOrder = false,
  }) {
    return NewDeliveryDraft(
      orderId: clearOrder ? null : (orderId ?? this.orderId),
      supplier: supplier ?? this.supplier,
      orderNo: orderNo ?? this.orderNo,
      date: date ?? this.date,
      irsaliyeNo: irsaliyeNo ?? this.irsaliyeNo,
      plateNo: plateNo ?? this.plateNo,
      diameterEntries: diameterEntries ?? this.diameterEntries,
      orderedDiameters: orderedDiameters ?? this.orderedDiameters,
    );
  }
}
