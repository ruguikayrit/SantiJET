import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/tahvil/tahvil_rules.dart';

class RebarPieceLine {
  const RebarPieceLine({
    required this.diameter,
    required this.lengthM,
    required this.quantity,
    this.sourceText,
    this.spacingCm,
  });

  final int diameter;
  final double lengthM;
  final int quantity;
  final String? sourceText;
  final double? spacingCm;

  Map<String, dynamic> toJson() => {
        'diameter': diameter,
        'lengthM': lengthM,
        'quantity': quantity,
        'sourceText': sourceText,
        if (spacingCm != null) 'spacingCm': spacingCm,
      };

  factory RebarPieceLine.fromJson(Map<dynamic, dynamic> json) {
    return RebarPieceLine(
      diameter: (json['diameter'] as num?)?.toInt() ?? 0,
      lengthM: (json['lengthM'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      sourceText: json['sourceText'] as String?,
      spacingCm: (json['spacingCm'] as num?)?.toDouble(),
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

class CuttingBendingBatch {
  const CuttingBendingBatch({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.sourceMetrajRecordIds,
    required this.labelDetails,
    required this.pieceLines,
    required this.lengthMatches,
    required this.tahvilGroups,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final List<String> sourceMetrajRecordIds;
  final List<RebarMetrajTextDetail> labelDetails;
  final List<RebarPieceLine> pieceLines;
  final List<LengthMatchGroup> lengthMatches;
  final List<TahvilSuggestion> tahvilGroups;

  CuttingBendingBatch copyWith({
    List<RebarMetrajTextDetail>? labelDetails,
    List<RebarPieceLine>? pieceLines,
    List<LengthMatchGroup>? lengthMatches,
    List<TahvilSuggestion>? tahvilGroups,
  }) {
    return CuttingBendingBatch(
      id: id,
      title: title,
      createdAt: createdAt,
      sourceMetrajRecordIds: sourceMetrajRecordIds,
      labelDetails: labelDetails ?? this.labelDetails,
      pieceLines: pieceLines ?? this.pieceLines,
      lengthMatches: lengthMatches ?? this.lengthMatches,
      tahvilGroups: tahvilGroups ?? this.tahvilGroups,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'sourceMetrajRecordIds': sourceMetrajRecordIds,
        'labelDetails': labelDetails.map((d) => d.toJson()).toList(),
        'pieceLines': pieceLines.map((p) => p.toJson()).toList(),
        'lengthMatches': lengthMatches.map((g) => g.toJson()).toList(),
        'tahvilGroups': tahvilGroups.map((g) => g.toJson()).toList(),
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
      lengthMatches: parseList('lengthMatches', LengthMatchGroup.fromJson),
      tahvilGroups: parseList('tahvilGroups', TahvilSuggestion.fromJson),
    );
  }
}
