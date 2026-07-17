/// Demir Tahmin Motoru — risk, boşluk, çıktı modelleri.
enum PredictionRiskLevel {
  green,
  yellow,
  orange,
  red,
  unknown,
}

enum PredictionDataGapKind {
  survey,
  fieldCounts,
  workSchedule,
  workforce,
  stock,
}

class PredictionConfig {
  const PredictionConfig({
    this.safetyStockDays = 3,
    this.criticalDays = 3,
    this.purchaseSoonDays = 7,
    this.monitorDays = 14,
    this.deviationWarningPercent = 20,
    this.defaultWorkingDaysPerWeek = 5,
    this.historyLimit = 30,
  });

  /// Güvenlik stoğu (gün cinsinden tüketim karşılığı).
  final double safetyStockDays;

  /// Kırmızı kritik eşik (kalan gün).
  final double criticalDays;

  /// Turuncu — yakında sipariş.
  final double purchaseSoonDays;

  /// Sarı — izle.
  final double monitorDays;

  /// Plan vs gerçek sapma uyarı eşiği (%).
  final double deviationWarningPercent;

  final int defaultWorkingDaysPerWeek;
  final int historyLimit;

  PredictionConfig copyWith({
    double? safetyStockDays,
    double? criticalDays,
    double? purchaseSoonDays,
    double? monitorDays,
    double? deviationWarningPercent,
    int? defaultWorkingDaysPerWeek,
    int? historyLimit,
  }) {
    return PredictionConfig(
      safetyStockDays: safetyStockDays ?? this.safetyStockDays,
      criticalDays: criticalDays ?? this.criticalDays,
      purchaseSoonDays: purchaseSoonDays ?? this.purchaseSoonDays,
      monitorDays: monitorDays ?? this.monitorDays,
      deviationWarningPercent:
          deviationWarningPercent ?? this.deviationWarningPercent,
      defaultWorkingDaysPerWeek:
          defaultWorkingDaysPerWeek ?? this.defaultWorkingDaysPerWeek,
      historyLimit: historyLimit ?? this.historyLimit,
    );
  }

  Map<String, dynamic> toJson() => {
        'safetyStockDays': safetyStockDays,
        'criticalDays': criticalDays,
        'purchaseSoonDays': purchaseSoonDays,
        'monitorDays': monitorDays,
        'deviationWarningPercent': deviationWarningPercent,
        'defaultWorkingDaysPerWeek': defaultWorkingDaysPerWeek,
        'historyLimit': historyLimit,
      };

  factory PredictionConfig.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return const PredictionConfig();
    return PredictionConfig(
      safetyStockDays: (json['safetyStockDays'] as num?)?.toDouble() ?? 3,
      criticalDays: (json['criticalDays'] as num?)?.toDouble() ?? 3,
      purchaseSoonDays: (json['purchaseSoonDays'] as num?)?.toDouble() ?? 7,
      monitorDays: (json['monitorDays'] as num?)?.toDouble() ?? 14,
      deviationWarningPercent:
          (json['deviationWarningPercent'] as num?)?.toDouble() ?? 20,
      defaultWorkingDaysPerWeek:
          (json['defaultWorkingDaysPerWeek'] as num?)?.toInt() ?? 5,
      historyLimit: (json['historyLimit'] as num?)?.toInt() ?? 30,
    );
  }
}

class PredictionDataGap {
  const PredictionDataGap({
    required this.kind,
    required this.message,
    required this.actionLabel,
    required this.route,
  });

  final PredictionDataGapKind kind;
  final String message;
  final String actionLabel;
  final String route;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'message': message,
        'actionLabel': actionLabel,
        'route': route,
      };

  factory PredictionDataGap.fromJson(Map<dynamic, dynamic> json) {
    return PredictionDataGap(
      kind: PredictionDataGapKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => PredictionDataGapKind.survey,
      ),
      message: json['message'] as String? ?? '',
      actionLabel: json['actionLabel'] as String? ?? '',
      route: json['route'] as String? ?? '',
    );
  }
}

class DiameterPrediction {
  const DiameterPrediction({
    required this.diameter,
    required this.currentStock,
    required this.actualDailyConsumption,
    required this.plannedDailyConsumption,
    required this.daysRemaining,
    required this.remainingRequirement,
    required this.inTransit,
    required this.recommendedPurchase,
    required this.risk,
  });

  final int diameter;
  final double currentStock;
  final double actualDailyConsumption;
  final double plannedDailyConsumption;
  final double? daysRemaining;
  final double remainingRequirement;
  final double inTransit;
  final double recommendedPurchase;
  final PredictionRiskLevel risk;

  Map<String, dynamic> toJson() => {
        'diameter': diameter,
        'currentStock': currentStock,
        'actualDailyConsumption': actualDailyConsumption,
        'plannedDailyConsumption': plannedDailyConsumption,
        'daysRemaining': daysRemaining,
        'remainingRequirement': remainingRequirement,
        'inTransit': inTransit,
        'recommendedPurchase': recommendedPurchase,
        'risk': risk.name,
      };

  factory DiameterPrediction.fromJson(Map<dynamic, dynamic> json) {
    return DiameterPrediction(
      diameter: (json['diameter'] as num?)?.toInt() ?? 0,
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0,
      actualDailyConsumption:
          (json['actualDailyConsumption'] as num?)?.toDouble() ?? 0,
      plannedDailyConsumption:
          (json['plannedDailyConsumption'] as num?)?.toDouble() ?? 0,
      daysRemaining: (json['daysRemaining'] as num?)?.toDouble(),
      remainingRequirement:
          (json['remainingRequirement'] as num?)?.toDouble() ?? 0,
      inTransit: (json['inTransit'] as num?)?.toDouble() ?? 0,
      recommendedPurchase:
          (json['recommendedPurchase'] as num?)?.toDouble() ?? 0,
      risk: PredictionRiskLevel.values.firstWhere(
        (r) => r.name == json['risk'],
        orElse: () => PredictionRiskLevel.unknown,
      ),
    );
  }
}

class PurchaseRecommendation {
  const PurchaseRecommendation({
    required this.totalRequired,
    required this.byDiameter,
    required this.requiredPurchaseDate,
    required this.supplierLeadDays,
  });

  final double totalRequired;
  final Map<int, double> byDiameter;
  final DateTime? requiredPurchaseDate;
  final int supplierLeadDays;

  Map<String, dynamic> toJson() => {
        'totalRequired': totalRequired,
        'byDiameter': byDiameter.map((k, v) => MapEntry(k.toString(), v)),
        'requiredPurchaseDate': requiredPurchaseDate?.toIso8601String(),
        'supplierLeadDays': supplierLeadDays,
      };

  factory PurchaseRecommendation.fromJson(Map<dynamic, dynamic> json) {
    final raw = json['byDiameter'];
    final map = <int, double>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        final d = int.tryParse(e.key.toString());
        final t = (e.value as num?)?.toDouble();
        if (d != null && t != null) map[d] = t;
      }
    }
    return PurchaseRecommendation(
      totalRequired: (json['totalRequired'] as num?)?.toDouble() ?? 0,
      byDiameter: map,
      requiredPurchaseDate: json['requiredPurchaseDate'] != null
          ? DateTime.tryParse(json['requiredPurchaseDate'] as String)
          : null,
      supplierLeadDays: (json['supplierLeadDays'] as num?)?.toInt() ?? 7,
    );
  }
}

class PredictionWarning {
  const PredictionWarning({
    required this.code,
    required this.severity,
    required this.message,
  });

  final String code;
  final PredictionRiskLevel severity;
  final String message;

  Map<String, dynamic> toJson() => {
        'code': code,
        'severity': severity.name,
        'message': message,
      };

  factory PredictionWarning.fromJson(Map<dynamic, dynamic> json) {
    return PredictionWarning(
      code: json['code'] as String? ?? '',
      severity: PredictionRiskLevel.values.firstWhere(
        (r) => r.name == json['severity'],
        orElse: () => PredictionRiskLevel.yellow,
      ),
      message: json['message'] as String? ?? '',
    );
  }
}

class PredictionSnapshot {
  const PredictionSnapshot({
    required this.id,
    required this.projectId,
    required this.createdAt,
    required this.dataGaps,
    required this.canPredict,
    this.actualDailyConsumption,
    this.plannedDailyConsumption,
    this.predictedDepletionDate,
    this.tonsPerWorkerDay,
    this.deviationPercent,
    this.overallRisk = PredictionRiskLevel.unknown,
    this.diameters = const [],
    this.purchase,
    this.warnings = const [],
    this.narratives = const [],
  });

  final String id;
  final String projectId;
  final DateTime createdAt;
  final List<PredictionDataGap> dataGaps;
  final bool canPredict;

  final double? actualDailyConsumption;
  final double? plannedDailyConsumption;
  final DateTime? predictedDepletionDate;
  final double? tonsPerWorkerDay;
  final double? deviationPercent;
  final PredictionRiskLevel overallRisk;
  final List<DiameterPrediction> diameters;
  final PurchaseRecommendation? purchase;
  final List<PredictionWarning> warnings;
  final List<String> narratives;

  List<DiameterPrediction> get criticalDiameters => diameters
      .where(
        (d) =>
            d.risk == PredictionRiskLevel.red ||
            d.risk == PredictionRiskLevel.orange,
      )
      .toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'createdAt': createdAt.toIso8601String(),
        'dataGaps': dataGaps.map((g) => g.toJson()).toList(),
        'canPredict': canPredict,
        'actualDailyConsumption': actualDailyConsumption,
        'plannedDailyConsumption': plannedDailyConsumption,
        'predictedDepletionDate': predictedDepletionDate?.toIso8601String(),
        'tonsPerWorkerDay': tonsPerWorkerDay,
        'deviationPercent': deviationPercent,
        'overallRisk': overallRisk.name,
        'diameters': diameters.map((d) => d.toJson()).toList(),
        'purchase': purchase?.toJson(),
        'warnings': warnings.map((w) => w.toJson()).toList(),
        'narratives': narratives,
      };

  factory PredictionSnapshot.fromJson(Map<dynamic, dynamic> json) {
    return PredictionSnapshot(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      dataGaps: (json['dataGaps'] as List?)
              ?.whereType<Map>()
              .map(PredictionDataGap.fromJson)
              .toList() ??
          const [],
      canPredict: json['canPredict'] as bool? ?? false,
      actualDailyConsumption:
          (json['actualDailyConsumption'] as num?)?.toDouble(),
      plannedDailyConsumption:
          (json['plannedDailyConsumption'] as num?)?.toDouble(),
      predictedDepletionDate: json['predictedDepletionDate'] != null
          ? DateTime.tryParse(json['predictedDepletionDate'] as String)
          : null,
      tonsPerWorkerDay: (json['tonsPerWorkerDay'] as num?)?.toDouble(),
      deviationPercent: (json['deviationPercent'] as num?)?.toDouble(),
      overallRisk: PredictionRiskLevel.values.firstWhere(
        (r) => r.name == json['overallRisk'],
        orElse: () => PredictionRiskLevel.unknown,
      ),
      diameters: (json['diameters'] as List?)
              ?.whereType<Map>()
              .map(DiameterPrediction.fromJson)
              .toList() ??
          const [],
      purchase: json['purchase'] is Map
          ? PurchaseRecommendation.fromJson(json['purchase'] as Map)
          : null,
      warnings: (json['warnings'] as List?)
              ?.whereType<Map>()
              .map(PredictionWarning.fromJson)
              .toList() ??
          const [],
      narratives: (json['narratives'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
    );
  }
}

class PredictionHistoryEntry {
  const PredictionHistoryEntry({
    required this.snapshot,
    this.actualDailyConsumptionLater,
    this.resolvedAt,
  });

  final PredictionSnapshot snapshot;
  final double? actualDailyConsumptionLater;
  final DateTime? resolvedAt;

  Map<String, dynamic> toJson() => {
        'snapshot': snapshot.toJson(),
        'actualDailyConsumptionLater': actualDailyConsumptionLater,
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  factory PredictionHistoryEntry.fromJson(Map<dynamic, dynamic> json) {
    return PredictionHistoryEntry(
      snapshot: PredictionSnapshot.fromJson(
        (json['snapshot'] as Map?) ?? const {},
      ),
      actualDailyConsumptionLater:
          (json['actualDailyConsumptionLater'] as num?)?.toDouble(),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'] as String)
          : null,
    );
  }
}
