import 'package:equatable/equatable.dart';

/// Numune / basınç dayanımı kaydı (cüruf notu opsiyonel).
class QualitySample extends Equatable {
  const QualitySample({
    required this.id,
    required this.projectId,
    required this.sampleDate,
    required this.sampleCode,
    this.pourRecordId,
    this.ageDays = 28,
    this.strengthMpa,
    this.slagNote = '',
    this.notes = '',
  });

  final String id;
  final String projectId;
  final String? pourRecordId;

  /// gg.aa.yyyy
  final String sampleDate;
  final String sampleCode;
  final int ageDays;
  final double? strengthMpa;
  final String slagNote;
  final String notes;

  bool get isPending => strengthMpa == null;

  QualitySample copyWith({
    String? id,
    String? projectId,
    String? pourRecordId,
    String? sampleDate,
    String? sampleCode,
    int? ageDays,
    double? strengthMpa,
    String? slagNote,
    String? notes,
    bool clearStrength = false,
  }) {
    return QualitySample(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      pourRecordId: pourRecordId ?? this.pourRecordId,
      sampleDate: sampleDate ?? this.sampleDate,
      sampleCode: sampleCode ?? this.sampleCode,
      ageDays: ageDays ?? this.ageDays,
      strengthMpa: clearStrength ? null : (strengthMpa ?? this.strengthMpa),
      slagNote: slagNote ?? this.slagNote,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'pourRecordId': pourRecordId,
        'sampleDate': sampleDate,
        'sampleCode': sampleCode,
        'ageDays': ageDays,
        'strengthMpa': strengthMpa,
        'slagNote': slagNote,
        'notes': notes,
      };

  factory QualitySample.fromJson(Map<String, dynamic> json) => QualitySample(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        pourRecordId: json['pourRecordId'] as String?,
        sampleDate: json['sampleDate'] as String? ?? '',
        sampleCode: json['sampleCode'] as String? ?? '',
        ageDays: (json['ageDays'] as num?)?.toInt() ?? 28,
        strengthMpa: (json['strengthMpa'] as num?)?.toDouble(),
        slagNote: json['slagNote'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        pourRecordId,
        sampleDate,
        sampleCode,
        ageDays,
        strengthMpa,
        slagNote,
        notes,
      ];
}
