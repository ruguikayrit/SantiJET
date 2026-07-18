import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/tahvil/tahvil_rules.dart';

/// Fire azaltma analiz stratejisi.
enum FireReductionStrategy {
  tahvilOnly,
  lengthMatchOnly,
  both;

  String get label => switch (this) {
        FireReductionStrategy.tahvilOnly => 'Sadece tahvil',
        FireReductionStrategy.lengthMatchOnly => 'Sadece uzunluk eşleştirme',
        FireReductionStrategy.both => 'Tahvil + uzunluk eşleştirme',
      };

  String get description => switch (this) {
        FireReductionStrategy.tahvilOnly => 'Farklı çaplarda yakın uzunluklar',
        FireReductionStrategy.lengthMatchOnly => 'Aynı çapta yakın uzunluklar',
        FireReductionStrategy.both => 'Tahvil + uzunluk eşleştirme',
      };

  String get toleranceDescription => 'Proje uzunluğunun max %5 toleransı';

  bool get appliesTahvil =>
      this == FireReductionStrategy.tahvilOnly ||
      this == FireReductionStrategy.both;

  bool get appliesLengthMatch =>
      this == FireReductionStrategy.lengthMatchOnly ||
      this == FireReductionStrategy.both;

  static FireReductionStrategy? fromJson(String? value) {
    if (value == null) return null;
    for (final item in FireReductionStrategy.values) {
      if (item.name == value) return item;
    }
    return null;
  }
}

class LengthMatchChange {
  const LengthMatchChange({
    required this.diameter,
    required this.beforeLengthM,
    required this.afterLengthM,
    required this.quantity,
  });

  final int diameter;
  final double beforeLengthM;
  final double afterLengthM;
  final int quantity;

  double get deltaM => afterLengthM - beforeLengthM;
}

/// Ham parça satırının revize sonrası karşılaştırma satırı.
class PieceListComparisonRow {
  const PieceListComparisonRow({
    required this.beforeDiameter,
    required this.afterDiameter,
    required this.beforeLengthM,
    required this.afterLengthM,
    required this.quantity,
  });

  final int beforeDiameter;
  final int afterDiameter;
  final double beforeLengthM;
  final double afterLengthM;
  final int quantity;

  bool get isChanged =>
      beforeDiameter != afterDiameter ||
      (beforeLengthM - afterLengthM).abs() > 1e-9;

  double get deltaCm => (afterLengthM - beforeLengthM) * 100;
}

class RebarPieceLine {
  const RebarPieceLine({
    required this.diameter,
    required this.lengthM,
    required this.quantity,
    this.sourceText,
    this.spacingCm,
    this.elementCode,
    this.elementTypeCode,
    this.elementTypeLabel,
  });

  final int diameter;
  final double lengthM;
  final int quantity;
  final String? sourceText;
  final double? spacingCm;
  /// Örn. SB12, K101 — metraj eleman kodu.
  final String? elementCode;
  /// S / P / K / D
  final String? elementTypeCode;
  /// Kolon / Perde / Kiriş / Döşeme
  final String? elementTypeLabel;

  /// UI: "Kolon SB12" — hata ayıklamada imalat kimliği.
  String get elementDisplayLabel {
    final type = elementTypeLabel?.trim() ?? '';
    final code = elementCode?.trim() ?? '';
    if (type.isEmpty && code.isEmpty) return '';
    if (type.isEmpty) return code;
    if (code.isEmpty) return type;
    return '$type $code';
  }

  RebarPieceLine copyWith({
    int? diameter,
    double? lengthM,
    int? quantity,
    String? sourceText,
    double? spacingCm,
    String? elementCode,
    String? elementTypeCode,
    String? elementTypeLabel,
  }) {
    return RebarPieceLine(
      diameter: diameter ?? this.diameter,
      lengthM: lengthM ?? this.lengthM,
      quantity: quantity ?? this.quantity,
      sourceText: sourceText ?? this.sourceText,
      spacingCm: spacingCm ?? this.spacingCm,
      elementCode: elementCode ?? this.elementCode,
      elementTypeCode: elementTypeCode ?? this.elementTypeCode,
      elementTypeLabel: elementTypeLabel ?? this.elementTypeLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'diameter': diameter,
        'lengthM': lengthM,
        'quantity': quantity,
        'sourceText': sourceText,
        if (spacingCm != null) 'spacingCm': spacingCm,
        if (elementCode != null) 'elementCode': elementCode,
        if (elementTypeCode != null) 'elementTypeCode': elementTypeCode,
        if (elementTypeLabel != null) 'elementTypeLabel': elementTypeLabel,
      };

  factory RebarPieceLine.fromJson(Map<dynamic, dynamic> json) {
    return RebarPieceLine(
      diameter: (json['diameter'] as num?)?.toInt() ?? 0,
      lengthM: (json['lengthM'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      sourceText: json['sourceText'] as String?,
      spacingCm: (json['spacingCm'] as num?)?.toDouble(),
      elementCode: json['elementCode'] as String?,
      elementTypeCode: json['elementTypeCode'] as String?,
      elementTypeLabel: json['elementTypeLabel'] as String?,
    );
  }
}

class LengthMatchGroup {
  const LengthMatchGroup({
    required this.id,
    required this.diameter,
    required this.representativeLengthM,
    required this.minLengthM,
    required this.maxLengthM,
    required this.totalQuantity,
    required this.members,
    this.selectedLengthM,
    this.approved = false,
  });

  final String id;
  final int diameter;
  final double representativeLengthM;
  final double minLengthM;
  final double maxLengthM;
  final int totalQuantity;
  final List<RebarPieceLine> members;
  final double? selectedLengthM;
  final bool approved;

  LengthMatchGroup copyWith({
    bool? approved,
    double? selectedLengthM,
    bool clearSelectedLength = false,
  }) {
    return LengthMatchGroup(
      id: id,
      diameter: diameter,
      representativeLengthM: representativeLengthM,
      minLengthM: minLengthM,
      maxLengthM: maxLengthM,
      totalQuantity: totalQuantity,
      members: members,
      selectedLengthM:
          clearSelectedLength ? null : (selectedLengthM ?? this.selectedLengthM),
      approved: approved ?? this.approved,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'diameter': diameter,
        'representativeLengthM': representativeLengthM,
        'minLengthM': minLengthM,
        'maxLengthM': maxLengthM,
        'totalQuantity': totalQuantity,
        'members': members.map((m) => m.toJson()).toList(),
        if (selectedLengthM != null) 'selectedLengthM': selectedLengthM,
        'approved': approved,
      };

  factory LengthMatchGroup.fromJson(Map<dynamic, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? const [];
    return LengthMatchGroup(
      id: json['id'] as String? ?? '',
      diameter: (json['diameter'] as num?)?.toInt() ?? 0,
      representativeLengthM:
          (json['representativeLengthM'] as num?)?.toDouble() ?? 0,
      minLengthM: (json['minLengthM'] as num?)?.toDouble() ?? 0,
      maxLengthM: (json['maxLengthM'] as num?)?.toDouble() ?? 0,
      totalQuantity: (json['totalQuantity'] as num?)?.toInt() ?? 0,
      members: rawMembers
          .whereType<Map>()
          .map(RebarPieceLine.fromJson)
          .toList(),
      selectedLengthM: (json['selectedLengthM'] as num?)?.toDouble(),
      approved: json['approved'] as bool? ?? false,
    );
  }
}

class TahvilEquivalent {
  const TahvilEquivalent({
    required this.fromDiameter,
    required this.fromQuantity,
    required this.toDiameter,
    required this.equivalentQuantity,
    this.areaDeviationPercent = 0,
    this.resultingSpacingCm,
    this.isRecommended = false,
  });

  final int fromDiameter;
  final int fromQuantity;
  final int toDiameter;
  final int equivalentQuantity;
  final double areaDeviationPercent;
  final double? resultingSpacingCm;
  final bool isRecommended;

  TahvilEquivalent copyWith({
    int? fromDiameter,
    int? fromQuantity,
    int? toDiameter,
    int? equivalentQuantity,
    double? areaDeviationPercent,
    double? resultingSpacingCm,
    bool? isRecommended,
  }) {
    return TahvilEquivalent(
      fromDiameter: fromDiameter ?? this.fromDiameter,
      fromQuantity: fromQuantity ?? this.fromQuantity,
      toDiameter: toDiameter ?? this.toDiameter,
      equivalentQuantity: equivalentQuantity ?? this.equivalentQuantity,
      areaDeviationPercent: areaDeviationPercent ?? this.areaDeviationPercent,
      resultingSpacingCm: resultingSpacingCm ?? this.resultingSpacingCm,
      isRecommended: isRecommended ?? this.isRecommended,
    );
  }

  Map<String, dynamic> toJson() => {
        'fromDiameter': fromDiameter,
        'fromQuantity': fromQuantity,
        'toDiameter': toDiameter,
        'equivalentQuantity': equivalentQuantity,
        'areaDeviationPercent': areaDeviationPercent,
        if (resultingSpacingCm != null) 'resultingSpacingCm': resultingSpacingCm,
        'isRecommended': isRecommended,
      };

  factory TahvilEquivalent.fromJson(Map<dynamic, dynamic> json) {
    return TahvilEquivalent(
      fromDiameter: (json['fromDiameter'] as num?)?.toInt() ?? 0,
      fromQuantity: (json['fromQuantity'] as num?)?.toInt() ?? 0,
      toDiameter: (json['toDiameter'] as num?)?.toInt() ?? 0,
      equivalentQuantity: (json['equivalentQuantity'] as num?)?.toInt() ?? 0,
      areaDeviationPercent:
          (json['areaDeviationPercent'] as num?)?.toDouble() ?? 0,
      resultingSpacingCm: (json['resultingSpacingCm'] as num?)?.toDouble(),
      isRecommended: json['isRecommended'] as bool? ?? false,
    );
  }

  /// Kesit alanı oranı: d₁² × adet₁ ÷ d₂² → hedef çapta tahvil adedi.
  static int computeEquivalentQuantity({
    required int fromDiameter,
    required int fromQuantity,
    required int toDiameter,
  }) {
    return computeTahvilEquivalentQuantity(
      fromDiameter: fromDiameter,
      fromQuantity: fromQuantity,
      toDiameter: toDiameter,
    );
  }

  /// Grup üyelerinden kurallara uygun tahvil eşdeğerleri üretir.
  static List<TahvilEquivalent> fromMembers(List<RebarPieceLine> members) {
    return computeTahvilEquivalents(members);
  }
}

class TahvilSuggestion {
  const TahvilSuggestion({
    required this.id,
    required this.representativeLengthM,
    required this.minLengthM,
    required this.maxLengthM,
    required this.members,
    required this.equivalents,
    this.approved = false,
  });

  final String id;
  final double representativeLengthM;
  final double minLengthM;
  final double maxLengthM;
  final List<RebarPieceLine> members;
  final List<TahvilEquivalent> equivalents;
  final bool approved;

  TahvilSuggestion copyWith({bool? approved}) {
    return TahvilSuggestion(
      id: id,
      representativeLengthM: representativeLengthM,
      minLengthM: minLengthM,
      maxLengthM: maxLengthM,
      members: members,
      equivalents: equivalents,
      approved: approved ?? this.approved,
    );
  }

  Set<int> get diameters => members.map((m) => m.diameter).toSet();

  Map<String, dynamic> toJson() => {
        'id': id,
        'representativeLengthM': representativeLengthM,
        'minLengthM': minLengthM,
        'maxLengthM': maxLengthM,
        'members': members.map((m) => m.toJson()).toList(),
        'equivalents': equivalents.map((e) => e.toJson()).toList(),
        'approved': approved,
      };

  factory TahvilSuggestion.fromJson(Map<dynamic, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? const [];
    final rawEquivalents = json['equivalents'] as List<dynamic>? ?? const [];
    return TahvilSuggestion(
      id: json['id'] as String? ?? '',
      representativeLengthM:
          (json['representativeLengthM'] as num?)?.toDouble() ?? 0,
      minLengthM: (json['minLengthM'] as num?)?.toDouble() ?? 0,
      maxLengthM: (json['maxLengthM'] as num?)?.toDouble() ?? 0,
      members: rawMembers
          .whereType<Map>()
          .map(RebarPieceLine.fromJson)
          .toList(),
      equivalents: rawEquivalents.isEmpty
          ? TahvilEquivalent.fromMembers(
              rawMembers
                  .whereType<Map>()
                  .map(RebarPieceLine.fromJson)
                  .toList(),
            )
          : rawEquivalents
              .whereType<Map>()
              .map(TahvilEquivalent.fromJson)
              .toList(),
      approved: json['approved'] as bool? ?? false,
    );
  }
}

class StockBarCutMember {
  const StockBarCutMember({
    required this.lengthM,
    required this.count,
    this.elementCode,
    this.elementTypeCode,
    this.elementTypeLabel,
  });

  final double lengthM;
  final int count;
  final String? elementCode;
  final String? elementTypeCode;
  final String? elementTypeLabel;

  /// UI: "Kolon SB12"
  String get elementDisplayLabel {
    final type = elementTypeLabel?.trim() ?? '';
    final code = elementCode?.trim() ?? '';
    if (type.isEmpty && code.isEmpty) return '';
    if (type.isEmpty) return code;
    if (code.isEmpty) return type;
    return '$type $code';
  }

  /// Kısa etiket (bar segmenti): kod varsa kod, yoksa tip.
  String get shortLabel {
    final code = elementCode?.trim() ?? '';
    if (code.isNotEmpty) return code;
    return elementTypeLabel?.trim() ?? '';
  }

  Map<String, dynamic> toJson() => {
        'lengthM': lengthM,
        'count': count,
        if (elementCode != null) 'elementCode': elementCode,
        if (elementTypeCode != null) 'elementTypeCode': elementTypeCode,
        if (elementTypeLabel != null) 'elementTypeLabel': elementTypeLabel,
      };

  factory StockBarCutMember.fromJson(Map<dynamic, dynamic> json) {
    return StockBarCutMember(
      lengthM: (json['lengthM'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      elementCode: json['elementCode'] as String?,
      elementTypeCode: json['elementTypeCode'] as String?,
      elementTypeLabel: json['elementTypeLabel'] as String?,
    );
  }
}

class StockBarCut {
  const StockBarCut({
    required this.barIndex,
    required this.diameter,
    required this.members,
    required this.usedLengthM,
    required this.wasteLengthM,
  });

  final int barIndex;
  final int diameter;
  final List<StockBarCutMember> members;
  final double usedLengthM;
  final double wasteLengthM;

  Map<String, dynamic> toJson() => {
        'barIndex': barIndex,
        'diameter': diameter,
        'members': members.map((m) => m.toJson()).toList(),
        'usedLengthM': usedLengthM,
        'wasteLengthM': wasteLengthM,
      };

  factory StockBarCut.fromJson(Map<dynamic, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? const [];
    return StockBarCut(
      barIndex: (json['barIndex'] as num?)?.toInt() ?? 0,
      diameter: (json['diameter'] as num?)?.toInt() ?? 0,
      members: rawMembers
          .whereType<Map>()
          .map(StockBarCutMember.fromJson)
          .toList(),
      usedLengthM: (json['usedLengthM'] as num?)?.toDouble() ?? 0,
      wasteLengthM: (json['wasteLengthM'] as num?)?.toDouble() ?? 0,
    );
  }
}

class StockCutPlan {
  const StockCutPlan({
    required this.diameter,
    required this.bars,
    required this.totalBars,
    required this.totalStockM,
    required this.totalWasteM,
    required this.totalUsedM,
    required this.wastePercent,
    required this.totalStockTonnage,
    required this.totalUsedTonnage,
    required this.totalWasteTonnage,
    this.wasteBarCount,
    this.noWasteBarCount,
    this.wasteLengthBucketCounts,
  });

  final int diameter;
  final List<StockBarCut> bars;
  final int totalBars;
  /// Tam plana göre fireli çubuk adedi (önizleme listesi kısıtlı olsa bile).
  final int? wasteBarCount;
  /// Tam plana göre firesiz çubuk adedi.
  final int? noWasteBarCount;
  /// Kalan boy özeti — anahtar: fire boyu (cm, yuvarlanmış), değer: çubuk adedi.
  final Map<int, int>? wasteLengthBucketCounts;
  final double totalStockM;
  final double totalWasteM;
  final double totalUsedM;
  final double wastePercent;
  final double totalStockTonnage;
  final double totalUsedTonnage;
  final double totalWasteTonnage;

  Map<String, dynamic> toJson() => {
        'diameter': diameter,
        'bars': bars.map((b) => b.toJson()).toList(),
        'totalBars': totalBars,
        'totalStockM': totalStockM,
        'totalWasteM': totalWasteM,
        'totalUsedM': totalUsedM,
        'wastePercent': wastePercent,
        'totalStockTonnage': totalStockTonnage,
        'totalUsedTonnage': totalUsedTonnage,
        'totalWasteTonnage': totalWasteTonnage,
        if (wasteBarCount != null) 'wasteBarCount': wasteBarCount,
        if (noWasteBarCount != null) 'noWasteBarCount': noWasteBarCount,
        if (wasteLengthBucketCounts != null)
          'wasteLengthBucketCounts': wasteLengthBucketCounts!
              .map((key, value) => MapEntry('$key', value)),
      };

  factory StockCutPlan.fromJson(Map<dynamic, dynamic> json) {
    final rawBars = json['bars'] as List<dynamic>? ?? const [];
    final diameter = (json['diameter'] as num?)?.toInt() ?? 0;
    final totalStockM = (json['totalStockM'] as num?)?.toDouble() ??
        ((json['totalUsedM'] as num?)?.toDouble() ?? 0) +
            ((json['totalWasteM'] as num?)?.toDouble() ?? 0);
    final totalUsedM = (json['totalUsedM'] as num?)?.toDouble() ?? 0;
    final totalWasteM = (json['totalWasteM'] as num?)?.toDouble() ?? 0;

    final rawBucketCounts = json['wasteLengthBucketCounts'];
    Map<int, int>? wasteLengthBucketCounts;
    if (rawBucketCounts is Map) {
      wasteLengthBucketCounts = rawBucketCounts.map(
        (key, value) => MapEntry(
          int.tryParse('$key') ?? 0,
          (value as num?)?.toInt() ?? 0,
        ),
      );
    }

    return StockCutPlan(
      diameter: diameter,
      bars: rawBars.whereType<Map>().map(StockBarCut.fromJson).toList(),
      totalBars: (json['totalBars'] as num?)?.toInt() ?? 0,
      wasteBarCount: (json['wasteBarCount'] as num?)?.toInt(),
      noWasteBarCount: (json['noWasteBarCount'] as num?)?.toInt(),
      wasteLengthBucketCounts: wasteLengthBucketCounts,
      totalStockM: totalStockM,
      totalWasteM: totalWasteM,
      totalUsedM: totalUsedM,
      wastePercent: (json['wastePercent'] as num?)?.toDouble() ?? 0,
      totalStockTonnage: (json['totalStockTonnage'] as num?)?.toDouble() ??
          RebarWeightCalculator.tonnage(
            diameterMm: diameter,
            lengthM: totalStockM,
          ),
      totalUsedTonnage: (json['totalUsedTonnage'] as num?)?.toDouble() ??
          RebarWeightCalculator.tonnage(
            diameterMm: diameter,
            lengthM: totalUsedM,
          ),
      totalWasteTonnage: (json['totalWasteTonnage'] as num?)?.toDouble() ??
          RebarWeightCalculator.tonnage(
            diameterMm: diameter,
            lengthM: totalWasteM,
          ),
    );
  }
}

/// Kayıtlı fire analizi sonucu — strateji başına bir anlık görüntü.
class OptimizationSnapshot {
  const OptimizationSnapshot({
    required this.strategy,
    required this.savedAt,
    required this.optimizationAppliedAt,
    required this.revisedPieceLines,
    required this.lengthMatches,
    required this.tahvilGroups,
    required this.stockCutPlans,
    required this.lengthMatchTolerancePercent,
  });

  final FireReductionStrategy strategy;
  final DateTime savedAt;
  final DateTime optimizationAppliedAt;
  final List<RebarPieceLine> revisedPieceLines;
  final List<LengthMatchGroup> lengthMatches;
  final List<TahvilSuggestion> tahvilGroups;
  final List<StockCutPlan> stockCutPlans;
  final double lengthMatchTolerancePercent;

  Map<String, dynamic> toJson() => {
        'strategy': strategy.name,
        'savedAt': savedAt.toIso8601String(),
        'optimizationAppliedAt': optimizationAppliedAt.toIso8601String(),
        'revisedPieceLines':
            revisedPieceLines.map((piece) => piece.toJson()).toList(),
        'lengthMatches': lengthMatches.map((group) => group.toJson()).toList(),
        'tahvilGroups': tahvilGroups.map((group) => group.toJson()).toList(),
        'stockCutPlans': stockCutPlans.map((plan) => plan.toJson()).toList(),
        'lengthMatchTolerancePercent': lengthMatchTolerancePercent,
      };

  factory OptimizationSnapshot.fromJson(Map<dynamic, dynamic> json) {
    List<T> parseList<T>(
      String key,
      T Function(Map<dynamic, dynamic>) fromJson,
    ) {
      final raw = json[key];
      if (raw == null || raw is! List) return [];
      return raw.whereType<Map>().map(fromJson).toList();
    }

    return OptimizationSnapshot(
      strategy: FireReductionStrategy.fromJson(json['strategy'] as String?) ??
          FireReductionStrategy.both,
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
      optimizationAppliedAt:
          DateTime.tryParse(json['optimizationAppliedAt'] as String? ?? '') ??
              DateTime.now(),
      revisedPieceLines:
          parseList('revisedPieceLines', RebarPieceLine.fromJson),
      lengthMatches: parseList('lengthMatches', LengthMatchGroup.fromJson),
      tahvilGroups: parseList('tahvilGroups', TahvilSuggestion.fromJson),
      stockCutPlans: parseList('stockCutPlans', StockCutPlan.fromJson),
      lengthMatchTolerancePercent: CuttingBendingBatch.parseLengthMatchTolerancePercent(
        json,
      ),
    );
  }
}

class CuttingBendingBatch {
  const CuttingBendingBatch({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.sourceMetrajRecordIds,
    required this.labelDetails,
    required this.pieceLines,
    required this.revisedPieceLines,
    required this.lengthMatches,
    required this.tahvilGroups,
    required this.stockCutPlans,
    this.lengthMatchTolerancePercent = defaultLengthMatchTolerancePercent,
    this.optimizationAppliedAt,
    this.optimizationStrategy,
    this.savedOptimizations = const {},
  });

  /// Kaynak demir boyunun en fazla bu oranı boy eşleştirmeye alınır (%5).
  static const defaultLengthMatchTolerancePercent = 0.05;
  static const defaultStockBarLengthM = 12.0;

  /// Örnek: 1,00 m → 5 cm, 4,00 m → 20 cm.
  static double toleranceCmForLengthM(double lengthM) =>
      lengthM * 100 * defaultLengthMatchTolerancePercent;

  static String get lengthMatchToleranceDescription =>
      'proje uzunluğunun max %${(defaultLengthMatchTolerancePercent * 100).toStringAsFixed(0)}\'i';

  static double parseLengthMatchTolerancePercent(Map<dynamic, dynamic> json) {
    final percent = json['lengthMatchTolerancePercent'];
    if (percent is num) return percent.toDouble();
    return defaultLengthMatchTolerancePercent;
  }

  final String id;
  final String title;
  final DateTime createdAt;
  final List<String> sourceMetrajRecordIds;
  final List<RebarMetrajTextDetail> labelDetails;
  final List<RebarPieceLine> pieceLines;
  final List<RebarPieceLine> revisedPieceLines;
  final List<LengthMatchGroup> lengthMatches;
  final List<TahvilSuggestion> tahvilGroups;
  final List<StockCutPlan> stockCutPlans;
  final double lengthMatchTolerancePercent;
  final DateTime? optimizationAppliedAt;
  final FireReductionStrategy? optimizationStrategy;
  final Map<FireReductionStrategy, OptimizationSnapshot> savedOptimizations;

  bool get isOptimized => optimizationAppliedAt != null;

  bool get hasAnySavedOptimization => savedOptimizations.isNotEmpty;

  bool hasSavedOptimization(FireReductionStrategy strategy) =>
      savedOptimizations.containsKey(strategy);

  bool get isCurrentOptimizationSaved {
    final strategy = optimizationStrategy;
    if (strategy == null || !isOptimized) return false;
    final saved = savedOptimizations[strategy];
    if (saved == null) return false;
    return saved.optimizationAppliedAt == optimizationAppliedAt;
  }

  OptimizationSnapshot? savedOptimizationFor(FireReductionStrategy strategy) =>
      savedOptimizations[strategy];

  double lengthMatchToleranceMForLength(double lengthM) =>
      lengthM * lengthMatchTolerancePercent;

  CuttingBendingBatch copyWith({
    List<RebarMetrajTextDetail>? labelDetails,
    List<RebarPieceLine>? pieceLines,
    List<RebarPieceLine>? revisedPieceLines,
    List<LengthMatchGroup>? lengthMatches,
    List<TahvilSuggestion>? tahvilGroups,
    List<StockCutPlan>? stockCutPlans,
    double? lengthMatchTolerancePercent,
    DateTime? optimizationAppliedAt,
    FireReductionStrategy? optimizationStrategy,
    Map<FireReductionStrategy, OptimizationSnapshot>? savedOptimizations,
    bool clearOptimizationAppliedAt = false,
    bool clearOptimizationStrategy = false,
  }) {
    return CuttingBendingBatch(
      id: id,
      title: title,
      createdAt: createdAt,
      sourceMetrajRecordIds: sourceMetrajRecordIds,
      labelDetails: labelDetails ?? this.labelDetails,
      pieceLines: pieceLines ?? this.pieceLines,
      revisedPieceLines: revisedPieceLines ?? this.revisedPieceLines,
      lengthMatches: lengthMatches ?? this.lengthMatches,
      tahvilGroups: tahvilGroups ?? this.tahvilGroups,
      stockCutPlans: stockCutPlans ?? this.stockCutPlans,
      lengthMatchTolerancePercent:
          lengthMatchTolerancePercent ?? this.lengthMatchTolerancePercent,
      optimizationAppliedAt: clearOptimizationAppliedAt
          ? null
          : (optimizationAppliedAt ?? this.optimizationAppliedAt),
      optimizationStrategy: clearOptimizationStrategy
          ? null
          : (optimizationStrategy ?? this.optimizationStrategy),
      savedOptimizations: savedOptimizations ?? this.savedOptimizations,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'sourceMetrajRecordIds': sourceMetrajRecordIds,
        'labelDetails': labelDetails.map((d) => d.toJson()).toList(),
        'pieceLines': pieceLines.map((p) => p.toJson()).toList(),
        'revisedPieceLines': revisedPieceLines.map((p) => p.toJson()).toList(),
        'lengthMatches': lengthMatches.map((g) => g.toJson()).toList(),
        'tahvilGroups': tahvilGroups.map((g) => g.toJson()).toList(),
        'stockCutPlans': stockCutPlans.map((p) => p.toJson()).toList(),
        'lengthMatchTolerancePercent': lengthMatchTolerancePercent,
        if (optimizationAppliedAt != null)
          'optimizationAppliedAt': optimizationAppliedAt!.toIso8601String(),
        if (optimizationStrategy != null)
          'optimizationStrategy': optimizationStrategy!.name,
        if (savedOptimizations.isNotEmpty)
          'savedOptimizations': {
            for (final entry in savedOptimizations.entries)
              entry.key.name: entry.value.toJson(),
          },
      };

  factory CuttingBendingBatch.fromJson(Map<dynamic, dynamic> json) {
    List<T> parseList<T>(
      String key,
      T Function(Map<dynamic, dynamic>) fromJson,
    ) {
      final raw = json[key];
      if (raw == null || raw is! List) return [];
      return raw.whereType<Map>().map(fromJson).toList();
    }

    return CuttingBendingBatch(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      sourceMetrajRecordIds: (json['sourceMetrajRecordIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      labelDetails:
          parseList('labelDetails', RebarMetrajTextDetail.fromJson),
      pieceLines: parseList('pieceLines', RebarPieceLine.fromJson),
      revisedPieceLines: parseList('revisedPieceLines', RebarPieceLine.fromJson),
      lengthMatches: parseList('lengthMatches', LengthMatchGroup.fromJson),
      tahvilGroups: parseList('tahvilGroups', TahvilSuggestion.fromJson),
      stockCutPlans: parseList('stockCutPlans', StockCutPlan.fromJson),
      lengthMatchTolerancePercent: parseLengthMatchTolerancePercent(json),
      optimizationAppliedAt: json['optimizationAppliedAt'] != null
          ? DateTime.tryParse(json['optimizationAppliedAt'] as String)
          : null,
      optimizationStrategy: FireReductionStrategy.fromJson(
        json['optimizationStrategy'] as String?,
      ),
      savedOptimizations: _parseSavedOptimizations(json['savedOptimizations']),
    );
  }

  static Map<FireReductionStrategy, OptimizationSnapshot>
      _parseSavedOptimizations(Object? raw) {
    if (raw is! Map) return const {};
    final result = <FireReductionStrategy, OptimizationSnapshot>{};
    for (final entry in raw.entries) {
      final strategy = FireReductionStrategy.fromJson(entry.key.toString());
      if (strategy == null || entry.value is! Map) continue;
      result[strategy] =
          OptimizationSnapshot.fromJson(entry.value as Map<dynamic, dynamic>);
    }
    return result;
  }
}
