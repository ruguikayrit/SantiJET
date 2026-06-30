class RebarPieceLine {
  const RebarPieceLine({
    required this.diameter,
    required this.lengthM,
    required this.quantity,
    this.sourceText,
  });

  final int diameter;
  final double lengthM;
  final int quantity;
  final String? sourceText;

  Map<String, dynamic> toJson() => {
        'diameter': diameter,
        'lengthM': lengthM,
        'quantity': quantity,
        'sourceText': sourceText,
      };

  factory RebarPieceLine.fromJson(Map<dynamic, dynamic> json) {
    return RebarPieceLine(
      diameter: (json['diameter'] as num?)?.toInt() ?? 0,
      lengthM: (json['lengthM'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      sourceText: json['sourceText'] as String?,
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
    this.approved = false,
  });

  final String id;
  final int diameter;
  final double representativeLengthM;
  final double minLengthM;
  final double maxLengthM;
  final int totalQuantity;
  final List<RebarPieceLine> members;
  final bool approved;

  LengthMatchGroup copyWith({bool? approved}) {
    return LengthMatchGroup(
      id: id,
      diameter: diameter,
      representativeLengthM: representativeLengthM,
      minLengthM: minLengthM,
      maxLengthM: maxLengthM,
      totalQuantity: totalQuantity,
      members: members,
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
      approved: json['approved'] as bool? ?? false,
    );
  }
}

class TahvilSuggestion {
  const TahvilSuggestion({
    required this.id,
    required this.representativeLengthM,
    required this.minLengthM,
    required this.maxLengthM,
    required this.members,
    this.approved = false,
  });

  final String id;
  final double representativeLengthM;
  final double minLengthM;
  final double maxLengthM;
  final List<RebarPieceLine> members;
  final bool approved;

  TahvilSuggestion copyWith({bool? approved}) {
    return TahvilSuggestion(
      id: id,
      representativeLengthM: representativeLengthM,
      minLengthM: minLengthM,
      maxLengthM: maxLengthM,
      members: members,
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
        'approved': approved,
      };

  factory TahvilSuggestion.fromJson(Map<dynamic, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? const [];
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
    required this.pieceLines,
    required this.lengthMatches,
    required this.tahvilGroups,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final List<String> sourceMetrajRecordIds;
  final List<RebarPieceLine> pieceLines;
  final List<LengthMatchGroup> lengthMatches;
  final List<TahvilSuggestion> tahvilGroups;

  CuttingBendingBatch copyWith({
    List<LengthMatchGroup>? lengthMatches,
    List<TahvilSuggestion>? tahvilGroups,
  }) {
    return CuttingBendingBatch(
      id: id,
      title: title,
      createdAt: createdAt,
      sourceMetrajRecordIds: sourceMetrajRecordIds,
      pieceLines: pieceLines,
      lengthMatches: lengthMatches ?? this.lengthMatches,
      tahvilGroups: tahvilGroups ?? this.tahvilGroups,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'sourceMetrajRecordIds': sourceMetrajRecordIds,
        'pieceLines': pieceLines.map((p) => p.toJson()).toList(),
        'lengthMatches': lengthMatches.map((g) => g.toJson()).toList(),
        'tahvilGroups': tahvilGroups.map((g) => g.toJson()).toList(),
      };

  factory CuttingBendingBatch.fromJson(Map<dynamic, dynamic> json) {
    List<T> parseList<T>(
      String key,
      T Function(Map<dynamic, dynamic>) fromJson,
    ) {
      final raw = json[key] as List<dynamic>? ?? const [];
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
      pieceLines: parseList('pieceLines', RebarPieceLine.fromJson),
      lengthMatches: parseList('lengthMatches', LengthMatchGroup.fromJson),
      tahvilGroups: parseList('tahvilGroups', TahvilSuggestion.fromJson),
    );
  }
}
