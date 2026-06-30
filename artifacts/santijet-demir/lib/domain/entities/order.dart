import 'package:santijet_demir/domain/enums/app_enums.dart';

enum OrderApproverRole {
  projectManager,
  purchasing,
  employer;

  String get label => switch (this) {
        OrderApproverRole.projectManager => 'Proje Müdürü',
        OrderApproverRole.purchasing => 'Satın Alma',
        OrderApproverRole.employer => 'İşveren',
      };
}

class OrderApprovals {
  const OrderApprovals({
    this.projectManager = false,
    this.purchasing = false,
    this.employer = false,
    this.projectManagerAt,
    this.purchasingAt,
    this.employerAt,
  });

  final bool projectManager;
  final bool purchasing;
  final bool employer;
  final DateTime? projectManagerAt;
  final DateTime? purchasingAt;
  final DateTime? employerAt;

  /// Satın Alma + (Proje Müdürü veya İşveren) onayı gerekir.
  bool get isComplete => purchasing && (projectManager || employer);

  bool isApproved(OrderApproverRole role) => switch (role) {
        OrderApproverRole.projectManager => projectManager,
        OrderApproverRole.purchasing => purchasing,
        OrderApproverRole.employer => employer,
      };

  OrderApprovals approve(OrderApproverRole role) {
    final now = DateTime.now();
    return switch (role) {
      OrderApproverRole.projectManager => copyWith(
          projectManager: true,
          projectManagerAt: now,
        ),
      OrderApproverRole.purchasing => copyWith(
          purchasing: true,
          purchasingAt: now,
        ),
      OrderApproverRole.employer => copyWith(
          employer: true,
          employerAt: now,
        ),
    };
  }

  OrderApprovals copyWith({
    bool? projectManager,
    bool? purchasing,
    bool? employer,
    DateTime? projectManagerAt,
    DateTime? purchasingAt,
    DateTime? employerAt,
  }) {
    return OrderApprovals(
      projectManager: projectManager ?? this.projectManager,
      purchasing: purchasing ?? this.purchasing,
      employer: employer ?? this.employer,
      projectManagerAt: projectManagerAt ?? this.projectManagerAt,
      purchasingAt: purchasingAt ?? this.purchasingAt,
      employerAt: employerAt ?? this.employerAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'projectManager': projectManager,
        'purchasing': purchasing,
        'employer': employer,
        'projectManagerAt': projectManagerAt?.toIso8601String(),
        'purchasingAt': purchasingAt?.toIso8601String(),
        'employerAt': employerAt?.toIso8601String(),
      };

  factory OrderApprovals.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return const OrderApprovals();
    return OrderApprovals(
      projectManager: json['projectManager'] as bool? ?? false,
      purchasing: json['purchasing'] as bool? ?? false,
      employer: json['employer'] as bool? ?? false,
      projectManagerAt: _parseDate(json['projectManagerAt']),
      purchasingAt: _parseDate(json['purchasingAt']),
      employerAt: _parseDate(json['employerAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class OrderCancellation {
  const OrderCancellation({
    required this.cancelledByName,
    required this.cancellationReason,
    required this.cancelledAt,
  });

  final String cancelledByName;
  final String cancellationReason;
  final DateTime cancelledAt;

  OrderCancellation copyWith({
    String? cancelledByName,
    String? cancellationReason,
    DateTime? cancelledAt,
  }) {
    return OrderCancellation(
      cancelledByName: cancelledByName ?? this.cancelledByName,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'cancelledByName': cancelledByName,
        'cancellationReason': cancellationReason,
        'cancelledAt': cancelledAt.toIso8601String(),
      };

  factory OrderCancellation.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) {
      return OrderCancellation(
        cancelledByName: '',
        cancellationReason: '',
        cancelledAt: DateTime.now(),
      );
    }
    return OrderCancellation(
      cancelledByName: json['cancelledByName'] as String? ?? '',
      cancellationReason: json['cancellationReason'] as String? ?? '',
      cancelledAt:
          DateTime.tryParse(json['cancelledAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderNo,
    required this.date,
    required this.imalatTypes,
    required this.tonnage,
    required this.status,
    required this.supplier,
    this.approvals = const OrderApprovals(),
    this.imalatTonnages = const {},
    this.cancellation,
  });

  final String id;
  final String orderNo;
  final DateTime date;
  final List<String> imalatTypes;
  final double tonnage;
  final OrderStatus status;
  final String supplier;
  final OrderApprovals approvals;
  final Map<String, double> imalatTonnages;
  final OrderCancellation? cancellation;

  OrderItem copyWith({
    String? id,
    String? orderNo,
    DateTime? date,
    List<String>? imalatTypes,
    double? tonnage,
    OrderStatus? status,
    String? supplier,
    OrderApprovals? approvals,
    Map<String, double>? imalatTonnages,
    OrderCancellation? cancellation,
    bool clearCancellation = false,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderNo: orderNo ?? this.orderNo,
      date: date ?? this.date,
      imalatTypes: imalatTypes ?? this.imalatTypes,
      tonnage: tonnage ?? this.tonnage,
      status: status ?? this.status,
      supplier: supplier ?? this.supplier,
      approvals: approvals ?? this.approvals,
      imalatTonnages: imalatTonnages ?? this.imalatTonnages,
      cancellation:
          clearCancellation ? null : (cancellation ?? this.cancellation),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNo': orderNo,
        'date': date.toIso8601String(),
        'imalatTypes': imalatTypes,
        'tonnage': tonnage,
        'status': status.name,
        'supplier': supplier,
        'approvals': approvals.toJson(),
        'imalatTonnages': imalatTonnages,
        if (cancellation != null) 'cancellation': cancellation!.toJson(),
      };

  factory OrderItem.fromJson(Map<dynamic, dynamic> json) {
    return OrderItem(
      id: json['id'] as String? ?? '',
      orderNo: json['orderNo'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      imalatTypes: (json['imalatTypes'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      tonnage: (json['tonnage'] as num?)?.toDouble() ?? 0,
      status: switch (json['status'] as String?) {
        'draft' => OrderStatus.pendingApproval,
        final String? name when name != null => OrderStatus.values.firstWhere(
            (value) => value.name == name,
            orElse: () => OrderStatus.pendingApproval,
          ),
        _ => OrderStatus.pendingApproval,
      },
      supplier: json['supplier'] as String? ?? '',
      approvals: OrderApprovals.fromJson(
        json['approvals'] is Map ? json['approvals'] as Map : null,
      ),
      imalatTonnages: _parseImalatTonnages(json['imalatTonnages']),
      cancellation: json['cancellation'] is Map
          ? OrderCancellation.fromJson(json['cancellation'] as Map)
          : null,
    );
  }

  static Map<String, double> _parseImalatTonnages(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map(
      (key, value) => MapEntry(
        key.toString(),
        (value as num?)?.toDouble() ?? 0,
      ),
    );
  }
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'pricePerTon': pricePerTon,
        'rating': rating,
        'deliveryDays': deliveryDays,
      };

  factory SupplierOption.fromJson(Map<dynamic, dynamic> json) {
    return SupplierOption(
      name: json['name'] as String? ?? '',
      pricePerTon: (json['pricePerTon'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 4,
      deliveryDays: (json['deliveryDays'] as num?)?.toInt() ?? 7,
    );
  }
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
    this.imalatRatios = const {},
    this.diameterOrderAmounts = const {},
    this.surveyPlannedByDiameter = const {},
    this.selectedSupplier,
  });

  final Map<String, double> selectedImalats;
  final Map<String, int> imalatRatios;
  final Map<int, double> diameterOrderAmounts;

  /// Seçili imalatların keşif çap dağılımı — sipariş hesabının kaynağı.
  final Map<int, double> surveyPlannedByDiameter;
  final SupplierOption? selectedSupplier;

  double imalatOrderTonnage(String name) {
    final base = selectedImalats[name] ?? 0;
    final ratio = imalatRatios[name] ?? 100;
    return base * ratio / 100;
  }

  double get totalTonnage => selectedImalats.keys.fold(
        0.0,
        (sum, name) => sum + imalatOrderTonnage(name),
      );

  List<DiameterOrderLine> get diameterLines {
    final defaults = calculateDiameterLinesFromSurvey(
      totalTonnage: totalTonnage,
      surveyPlannedByDiameter: surveyPlannedByDiameter,
    );
    if (diameterOrderAmounts.isEmpty) return defaults;

    return defaults.map((line) {
      final adjusted = diameterOrderAmounts[line.diameter];
      if (adjusted == null) return line;
      return DiameterOrderLine(
        diameter: line.diameter,
        currentStock: line.currentStock,
        orderAmount: adjusted,
      );
    }).toList();
  }

  double get finalOrderTonnage =>
      diameterLines.fold(0.0, (sum, line) => sum + line.orderAmount);

  NewOrderDraft copyWith({
    Map<String, double>? selectedImalats,
    Map<String, int>? imalatRatios,
    Map<int, double>? diameterOrderAmounts,
    Map<int, double>? surveyPlannedByDiameter,
    SupplierOption? selectedSupplier,
    bool clearSupplier = false,
    bool clearDiameterAmounts = false,
  }) {
    return NewOrderDraft(
      selectedImalats: selectedImalats ?? this.selectedImalats,
      imalatRatios: imalatRatios ?? this.imalatRatios,
      diameterOrderAmounts: clearDiameterAmounts
          ? const {}
          : (diameterOrderAmounts ?? this.diameterOrderAmounts),
      surveyPlannedByDiameter: clearDiameterAmounts
          ? const {}
          : (surveyPlannedByDiameter ?? this.surveyPlannedByDiameter),
      selectedSupplier:
          clearSupplier ? null : (selectedSupplier ?? this.selectedSupplier),
    );
  }
}

/// Keşif çap oranlarına göre sipariş dağılımı.
List<DiameterOrderLine> calculateDiameterLinesFromSurvey({
  required double totalTonnage,
  required Map<int, double> surveyPlannedByDiameter,
}) {
  if (totalTonnage <= 0 || surveyPlannedByDiameter.isEmpty) {
    return const [];
  }

  final totalSurvey =
      surveyPlannedByDiameter.values.fold(0.0, (sum, value) => sum + value);
  if (totalSurvey <= 0) return const [];

  return surveyPlannedByDiameter.entries
      .where((entry) => entry.value > 0)
      .map(
        (entry) => DiameterOrderLine(
          diameter: entry.key,
          currentStock: 0,
          orderAmount: totalTonnage * entry.value / totalSurvey,
        ),
      )
      .toList()
    ..sort((a, b) => a.diameter.compareTo(b.diameter));
}

@Deprecated('Keşif dışı sabit çap dağılımı kullanılıyordu; survey tabanlı hesap kullanın.')
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
