import 'package:equatable/equatable.dart';

/// Sipariş / irsaliye durumu.
enum OrderStatus {
  open,
  partial,
  delivered,
  cancelled;

  String get label => switch (this) {
        OrderStatus.open => 'Açık',
        OrderStatus.partial => 'Kısmi',
        OrderStatus.delivered => 'Teslim',
        OrderStatus.cancelled => 'İptal',
      };

  static OrderStatus fromStorage(String? raw) => switch (raw) {
        'partial' => OrderStatus.partial,
        'delivered' => OrderStatus.delivered,
        'cancelled' => OrderStatus.cancelled,
        _ => OrderStatus.open,
      };

  String get storage => name;
}

/// Beton siparişi ve irsaliye takibi.
class ConcreteOrder extends Equatable {
  const ConcreteOrder({
    required this.id,
    required this.projectId,
    required this.orderDate,
    required this.orderedM3,
    this.supplier = '',
    this.deliveredM3 = 0,
    this.waybillNo = '',
    this.concreteClass = 'C30/37',
    this.status = OrderStatus.open,
    this.notes = '',
  });

  final String id;
  final String projectId;

  /// gg.aa.yyyy
  final String orderDate;
  final String supplier;
  final double orderedM3;
  final double deliveredM3;
  final String waybillNo;
  final String concreteClass;
  final OrderStatus status;
  final String notes;

  ConcreteOrder copyWith({
    String? id,
    String? projectId,
    String? orderDate,
    String? supplier,
    double? orderedM3,
    double? deliveredM3,
    String? waybillNo,
    String? concreteClass,
    OrderStatus? status,
    String? notes,
  }) {
    return ConcreteOrder(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      orderDate: orderDate ?? this.orderDate,
      supplier: supplier ?? this.supplier,
      orderedM3: orderedM3 ?? this.orderedM3,
      deliveredM3: deliveredM3 ?? this.deliveredM3,
      waybillNo: waybillNo ?? this.waybillNo,
      concreteClass: concreteClass ?? this.concreteClass,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'orderDate': orderDate,
        'supplier': supplier,
        'orderedM3': orderedM3,
        'deliveredM3': deliveredM3,
        'waybillNo': waybillNo,
        'concreteClass': concreteClass,
        'status': status.storage,
        'notes': notes,
      };

  factory ConcreteOrder.fromJson(Map<String, dynamic> json) => ConcreteOrder(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        orderDate: json['orderDate'] as String? ?? '',
        supplier: json['supplier'] as String? ?? '',
        orderedM3: (json['orderedM3'] as num?)?.toDouble() ?? 0,
        deliveredM3: (json['deliveredM3'] as num?)?.toDouble() ?? 0,
        waybillNo: json['waybillNo'] as String? ?? '',
        concreteClass: json['concreteClass'] as String? ?? 'C30/37',
        status: OrderStatus.fromStorage(json['status'] as String?),
        notes: json['notes'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        orderDate,
        supplier,
        orderedM3,
        deliveredM3,
        waybillNo,
        concreteClass,
        status,
        notes,
      ];
}
