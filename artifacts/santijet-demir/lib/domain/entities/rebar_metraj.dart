import 'package:equatable/equatable.dart';

class RebarMetrajTextDetail extends Equatable {
  const RebarMetrajTextDetail({
    required this.entityType,
    required this.sourceText,
    required this.included,
    this.diameter,
    this.lengthM,
    this.quantity = 0,
    this.weightKg = 0,
    this.spacingCm,
    this.skipReason,
  });

  final String entityType;
  final String sourceText;
  final bool included;
  final int? diameter;
  final double? lengthM;
  final int quantity;
  final double weightKg;
  final double? spacingCm;
  final String? skipReason;

  @override
  List<Object?> get props => [
        entityType,
        sourceText,
        included,
        diameter,
        lengthM,
        quantity,
        weightKg,
        spacingCm,
        skipReason,
      ];

  Map<String, dynamic> toJson() => {
        'entityType': entityType,
        'sourceText': sourceText,
        'included': included,
        'diameter': diameter,
        'lengthM': lengthM,
        'quantity': quantity,
        'weightKg': weightKg,
        if (spacingCm != null) 'spacingCm': spacingCm,
        'skipReason': skipReason,
      };

  factory RebarMetrajTextDetail.fromJson(Map<dynamic, dynamic> json) {
    return RebarMetrajTextDetail(
      entityType: json['entityType'] as String,
      sourceText: json['sourceText'] as String,
      included: json['included'] as bool? ?? false,
      diameter: (json['diameter'] as num?)?.toInt(),
      lengthM: (json['lengthM'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      spacingCm: (json['spacingCm'] as num?)?.toDouble(),
      skipReason: json['skipReason'] as String?,
    );
  }
}

class RebarMetrajLine extends Equatable {
  const RebarMetrajLine({
    required this.diameter,
    required this.totalLengthM,
    required this.weightKg,
    required this.barCount,
    required this.layerName,
  });

  final int diameter;
  final double totalLengthM;
  final double weightKg;
  final int barCount;
  final String layerName;

  double get tonnage => weightKg / 1000;

  @override
  List<Object?> get props =>
      [diameter, totalLengthM, weightKg, barCount, layerName];

  Map<String, dynamic> toJson() => {
        'diameter': diameter,
        'totalLengthM': totalLengthM,
        'weightKg': weightKg,
        'barCount': barCount,
        'layerName': layerName,
      };

  factory RebarMetrajLine.fromJson(Map<dynamic, dynamic> json) {
    return RebarMetrajLine(
      diameter: (json['diameter'] as num).toInt(),
      totalLengthM: (json['totalLengthM'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      barCount: (json['barCount'] as num).toInt(),
      layerName: json['layerName'] as String? ?? '',
    );
  }
}

class RebarMetrajResult extends Equatable {
  const RebarMetrajResult({
    required this.fileName,
    required this.sourceFormat,
    required this.parsedAt,
    required this.lines,
    required this.textDetails,
    required this.skippedEntityCount,
    required this.warnings,
  });

  final String fileName;
  final String sourceFormat;
  final DateTime parsedAt;
  final List<RebarMetrajLine> lines;
  final List<RebarMetrajTextDetail> textDetails;
  final int skippedEntityCount;
  final List<String> warnings;

  double get totalLengthM =>
      lines.fold(0, (sum, line) => sum + line.totalLengthM);

  double get totalWeightKg =>
      lines.fold(0, (sum, line) => sum + line.weightKg);

  double get totalTonnage => totalWeightKg / 1000;

  int get totalBarCount => lines.fold(0, (sum, line) => sum + line.barCount);

  int get includedTextCount =>
      textDetails.where((detail) => detail.included).length;

  @override
  List<Object?> get props => [
        fileName,
        sourceFormat,
        parsedAt,
        lines,
        textDetails,
        skippedEntityCount,
        warnings,
      ];

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'sourceFormat': sourceFormat,
        'parsedAt': parsedAt.toIso8601String(),
        'lines': lines.map((line) => line.toJson()).toList(),
        'textDetails': textDetails.map((detail) => detail.toJson()).toList(),
        'skippedEntityCount': skippedEntityCount,
        'warnings': warnings,
      };

  factory RebarMetrajResult.fromJson(Map<dynamic, dynamic> json) {
    return RebarMetrajResult(
      fileName: json['fileName'] as String,
      sourceFormat: json['sourceFormat'] as String,
      parsedAt: DateTime.parse(json['parsedAt'] as String),
      lines: (json['lines'] as List<dynamic>? ?? const [])
          .map((line) => RebarMetrajLine.fromJson(line as Map<dynamic, dynamic>))
          .toList(),
      textDetails: (json['textDetails'] as List<dynamic>? ?? const [])
          .map(
            (detail) =>
                RebarMetrajTextDetail.fromJson(detail as Map<dynamic, dynamic>),
          )
          .toList(),
      skippedEntityCount: (json['skippedEntityCount'] as num?)?.toInt() ?? 0,
      warnings: (json['warnings'] as List<dynamic>? ?? const [])
          .map((warning) => warning.toString())
          .toList(),
    );
  }
}

/// Proje bazında kaydedilmiş demir metraj sonucu.
class SavedRebarMetraj {
  const SavedRebarMetraj({
    required this.id,
    required this.savedAt,
    required this.result,
    this.title,
    this.surveyImalatId,
    this.surveyImalatName,
  });

  final String id;
  final DateTime savedAt;
  final RebarMetrajResult result;
  final String? title;
  final String? surveyImalatId;
  final String? surveyImalatName;

  String get displayTitle {
    final custom = title?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return result.fileName.replaceAll(
      RegExp(r'\.(dwg|dxf)$', caseSensitive: false),
      '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'savedAt': savedAt.toIso8601String(),
        'result': result.toJson(),
        if (title != null) 'title': title,
        'surveyImalatId': surveyImalatId,
        'surveyImalatName': surveyImalatName,
      };

  factory SavedRebarMetraj.fromJson(Map<dynamic, dynamic> json) {
    return SavedRebarMetraj(
      id: json['id'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      result: RebarMetrajResult.fromJson(json['result'] as Map<dynamic, dynamic>),
      title: json['title'] as String?,
      surveyImalatId: json['surveyImalatId'] as String?,
      surveyImalatName: json['surveyImalatName'] as String?,
    );
  }

  SavedRebarMetraj copyWith({
    String? id,
    DateTime? savedAt,
    RebarMetrajResult? result,
    String? title,
    String? surveyImalatId,
    String? surveyImalatName,
  }) {
    return SavedRebarMetraj(
      id: id ?? this.id,
      savedAt: savedAt ?? this.savedAt,
      result: result ?? this.result,
      title: title ?? this.title,
      surveyImalatId: surveyImalatId ?? this.surveyImalatId,
      surveyImalatName: surveyImalatName ?? this.surveyImalatName,
    );
  }
}

class RebarLayerRule extends Equatable {
  const RebarLayerRule({
    required this.layerPattern,
    this.defaultDiameter,
  });

  final String layerPattern;
  final int? defaultDiameter;

  @override
  List<Object?> get props => [layerPattern, defaultDiameter];
}

class RebarMetrajSettings extends Equatable {
  const RebarMetrajSettings({
    this.layerKeywords = const [
      'DONAT',
      'DONATI',
      'ARMAT',
      'ARMATUR',
      'DEMIR',
      'DEMİR',
      'REBAR',
      'CELİK',
      'CELIK',
      'STEEL',
    ],
    this.defaultDiameter = 12,
    this.unitScale = 1.0,
  });

  final List<String> layerKeywords;
  final int defaultDiameter;
  final double unitScale;

  @override
  List<Object?> get props => [layerKeywords, defaultDiameter, unitScale];
}
