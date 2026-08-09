import 'package:equatable/equatable.dart';

/// Hive typeId plan: 12
/// Opsiyonel teknik karar kaydı (örn. seçilen yapıştırıcı + gerekçe).
class MaterialDecision extends Equatable {
  const MaterialDecision({
    required this.id,
    required this.projectId,
    required this.title,
    this.requestLineId,
    this.techSheetId,
    this.productName = '',
    this.rationale = '',
    this.createdAt,
  });

  final String id;
  final String projectId;
  final String title;
  final String? requestLineId;
  final String? techSheetId;
  final String productName;
  final String rationale;
  final DateTime? createdAt;

  MaterialDecision copyWith({
    String? id,
    String? projectId,
    String? title,
    String? requestLineId,
    String? techSheetId,
    String? productName,
    String? rationale,
    DateTime? createdAt,
  }) {
    return MaterialDecision(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      requestLineId: requestLineId ?? this.requestLineId,
      techSheetId: techSheetId ?? this.techSheetId,
      productName: productName ?? this.productName,
      rationale: rationale ?? this.rationale,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'requestLineId': requestLineId,
        'techSheetId': techSheetId,
        'productName': productName,
        'rationale': rationale,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory MaterialDecision.fromJson(Map<String, dynamic> json) =>
      MaterialDecision(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        requestLineId: json['requestLineId'] as String?,
        techSheetId: json['techSheetId'] as String?,
        productName: json['productName'] as String? ?? '',
        rationale: json['rationale'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        title,
        requestLineId,
        techSheetId,
        productName,
        rationale,
        createdAt,
      ];
}
