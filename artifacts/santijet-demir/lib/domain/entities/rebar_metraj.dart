import 'package:equatable/equatable.dart';
import 'package:santijet_demir/data/services/rebar_text_parser.dart';

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
    this.elementCode,
    this.elementTypeCode,
    this.dimensionText,
    this.benzerCount = 1,
    this.unitQuantity = 0,
    this.rebarRole = RebarLabelRole.other,
  });

  final String entityType;
  final String sourceText;
  final bool included;
  final int? diameter;
  final double? lengthM;
  /// Toplam adet (birim adet × benzer).
  final int quantity;
  final double weightKg;
  final double? spacingCm;
  final String? skipReason;
  final String? elementCode;
  final String? elementTypeCode;
  final String? dimensionText;
  final int benzerCount;
  final int unitQuantity;
  final RebarLabelRole rebarRole;

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
        elementCode,
        elementTypeCode,
        dimensionText,
        benzerCount,
        unitQuantity,
        rebarRole,
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
        if (elementCode != null) 'elementCode': elementCode,
        if (elementTypeCode != null) 'elementTypeCode': elementTypeCode,
        if (dimensionText != null) 'dimensionText': dimensionText,
        'benzerCount': benzerCount,
        'unitQuantity': unitQuantity,
        'rebarRole': rebarRole.name,
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
      elementCode: json['elementCode'] as String?,
      elementTypeCode: json['elementTypeCode'] as String?,
      dimensionText: json['dimensionText'] as String?,
      benzerCount: (json['benzerCount'] as num?)?.toInt() ?? 1,
      unitQuantity: (json['unitQuantity'] as num?)?.toInt() ??
          (json['quantity'] as num?)?.toInt() ??
          0,
      rebarRole: _rebarRoleFromJson(json['rebarRole'] as String?),
    );
  }
}

RebarLabelRole _rebarRoleFromJson(String? value) {
  if (value == null) return RebarLabelRole.other;
  for (final role in RebarLabelRole.values) {
    if (role.name == value) return role;
  }
  return RebarLabelRole.other;
}

class MetrajCetvelRow extends Equatable {
  const MetrajCetvelRow({
    required this.role,
    required this.diameter,
    required this.lengthM,
    required this.unitQuantity,
    required this.totalQuantity,
    required this.unitWeightKg,
    required this.totalWeightKg,
    required this.sourceText,
  });

  final RebarLabelRole role;
  final int diameter;
  final double lengthM;
  final int unitQuantity;
  final int totalQuantity;
  final double unitWeightKg;
  final double totalWeightKg;
  final String sourceText;

  double get unitTonnage => unitWeightKg / 1000;
  double get totalTonnage => totalWeightKg / 1000;

  @override
  List<Object?> get props => [
        role,
        diameter,
        lengthM,
        unitQuantity,
        totalQuantity,
        unitWeightKg,
        totalWeightKg,
        sourceText,
      ];

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'diameter': diameter,
        'lengthM': lengthM,
        'unitQuantity': unitQuantity,
        'totalQuantity': totalQuantity,
        'unitWeightKg': unitWeightKg,
        'totalWeightKg': totalWeightKg,
        'sourceText': sourceText,
      };

  factory MetrajCetvelRow.fromJson(Map<dynamic, dynamic> json) {
    return MetrajCetvelRow(
      role: _rebarRoleFromJson(json['role'] as String?),
      diameter: (json['diameter'] as num).toInt(),
      lengthM: (json['lengthM'] as num).toDouble(),
      unitQuantity: (json['unitQuantity'] as num).toInt(),
      totalQuantity: (json['totalQuantity'] as num).toInt(),
      unitWeightKg: (json['unitWeightKg'] as num).toDouble(),
      totalWeightKg: (json['totalWeightKg'] as num).toDouble(),
      sourceText: json['sourceText'] as String? ?? '',
    );
  }
}

class MetrajCetvelEntry extends Equatable {
  const MetrajCetvelEntry({
    required this.elementCode,
    required this.elementTypeCode,
    required this.elementTypeLabel,
    required this.dimensionText,
    required this.benzerCount,
    required this.sourceText,
    required this.rows,
  });

  final String elementCode;
  final String elementTypeCode;
  final String elementTypeLabel;
  final String? dimensionText;
  final int benzerCount;
  final String sourceText;
  final List<MetrajCetvelRow> rows;

  String get title {
    final dims = dimensionText?.trim();
    if (dims != null && dims.isNotEmpty) {
      return '$elementCode - $dims';
    }
    return elementCode;
  }

  double get unitTonnage =>
      rows.fold(0.0, (sum, row) => sum + row.unitTonnage);

  double get totalTonnage =>
      rows.fold(0.0, (sum, row) => sum + row.totalTonnage);

  int get unitBarCount =>
      rows.fold(0, (sum, row) => sum + row.unitQuantity);

  int get totalBarCount =>
      rows.fold(0, (sum, row) => sum + row.totalQuantity);

  @override
  List<Object?> get props => [
        elementCode,
        elementTypeCode,
        elementTypeLabel,
        dimensionText,
        benzerCount,
        sourceText,
        rows,
      ];

  Map<String, dynamic> toJson() => {
        'elementCode': elementCode,
        'elementTypeCode': elementTypeCode,
        'elementTypeLabel': elementTypeLabel,
        'dimensionText': dimensionText,
        'benzerCount': benzerCount,
        'sourceText': sourceText,
        'rows': rows.map((row) => row.toJson()).toList(),
      };

  factory MetrajCetvelEntry.fromJson(Map<dynamic, dynamic> json) {
    return MetrajCetvelEntry(
      elementCode: json['elementCode'] as String? ?? '',
      elementTypeCode: json['elementTypeCode'] as String? ?? '',
      elementTypeLabel: json['elementTypeLabel'] as String? ?? '',
      dimensionText: json['dimensionText'] as String?,
      benzerCount: (json['benzerCount'] as num?)?.toInt() ?? 1,
      sourceText: json['sourceText'] as String? ?? '',
      rows: (json['rows'] as List<dynamic>? ?? const [])
          .map((row) => MetrajCetvelRow.fromJson(row as Map<dynamic, dynamic>))
          .toList(),
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
    this.cetvel = const [],
  });

  final String fileName;
  final String sourceFormat;
  final DateTime parsedAt;
  final List<RebarMetrajLine> lines;
  final List<RebarMetrajTextDetail> textDetails;
  final int skippedEntityCount;
  final List<String> warnings;
  final List<MetrajCetvelEntry> cetvel;

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
        cetvel,
      ];

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'sourceFormat': sourceFormat,
        'parsedAt': parsedAt.toIso8601String(),
        'lines': lines.map((line) => line.toJson()).toList(),
        'textDetails': textDetails.map((detail) => detail.toJson()).toList(),
        'skippedEntityCount': skippedEntityCount,
        'warnings': warnings,
        'cetvel': cetvel.map((entry) => entry.toJson()).toList(),
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
      cetvel: (json['cetvel'] as List<dynamic>? ?? const [])
          .map(
            (entry) => MetrajCetvelEntry.fromJson(entry as Map<dynamic, dynamic>),
          )
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
    this.analysisApprovedAt,
  });

  final String id;
  final DateTime savedAt;
  final RebarMetrajResult result;
  final String? title;
  final String? surveyImalatId;
  final String? surveyImalatName;
  final DateTime? analysisApprovedAt;

  bool get isApprovedForAnalysis => analysisApprovedAt != null;

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
        if (analysisApprovedAt != null)
          'analysisApprovedAt': analysisApprovedAt!.toIso8601String(),
      };

  factory SavedRebarMetraj.fromJson(Map<dynamic, dynamic> json) {
    return SavedRebarMetraj(
      id: json['id'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      result: RebarMetrajResult.fromJson(json['result'] as Map<dynamic, dynamic>),
      title: json['title'] as String?,
      surveyImalatId: json['surveyImalatId'] as String?,
      surveyImalatName: json['surveyImalatName'] as String?,
      analysisApprovedAt: json['analysisApprovedAt'] != null
          ? DateTime.parse(json['analysisApprovedAt'] as String)
          : null,
    );
  }

  SavedRebarMetraj copyWith({
    String? id,
    DateTime? savedAt,
    RebarMetrajResult? result,
    String? title,
    String? surveyImalatId,
    String? surveyImalatName,
    DateTime? analysisApprovedAt,
  }) {
    return SavedRebarMetraj(
      id: id ?? this.id,
      savedAt: savedAt ?? this.savedAt,
      result: result ?? this.result,
      title: title ?? this.title,
      surveyImalatId: surveyImalatId ?? this.surveyImalatId,
      surveyImalatName: surveyImalatName ?? this.surveyImalatName,
      analysisApprovedAt: analysisApprovedAt ?? this.analysisApprovedAt,
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
