import 'package:equatable/equatable.dart';

/// Basınç dayanım raporunda yapısal eleman grubu.
enum ConcreteElementGroup {
  temel('Temel'),
  kolonPerde('Kolon & Perde'),
  doseme('Döşeme');

  const ConcreteElementGroup(this.label);
  final String label;

  static ConcreteElementGroup? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final v = raw.trim().toLowerCase();
    return switch (v) {
      'temel' => ConcreteElementGroup.temel,
      'kolon_perde' || 'kolon&perde' || 'kolonperde' =>
        ConcreteElementGroup.kolonPerde,
      'doseme' || 'döşeme' => ConcreteElementGroup.doseme,
      _ => null,
    };
  }

  String get storageValue => switch (this) {
        ConcreteElementGroup.temel => 'temel',
        ConcreteElementGroup.kolonPerde => 'kolon_perde',
        ConcreteElementGroup.doseme => 'doseme',
      };
}

/// Laboratuvar beton basınç dayanım raporu kaydı.
class QualitySample extends Equatable {
  const QualitySample({
    required this.id,
    required this.projectId,
    required this.sampleDate,
    required this.sampleCode,
    this.elementGroup = ConcreteElementGroup.temel,
    this.pourRecordId,
    this.labReportNo = '',
    this.concreteClass = 'C30/37',
    this.ageDays = 28,
    this.strengthMpa,
    this.minStrengthMpa,
    this.isCompliant,
    this.slagNote = '',
    this.notes = '',
  });

  final String id;
  final String projectId;
  final String? pourRecordId;

  /// Temel / Kolon & Perde / Döşeme.
  final ConcreteElementGroup elementGroup;

  /// Laboratuvar rapor numarası.
  final String labReportNo;

  final String sampleDate;
  final String sampleCode;
  final String concreteClass;
  final int ageDays;

  /// Rapor ortalama / esas basınç dayanımı (MPa).
  final double? strengthMpa;

  /// Rapordaki en düşük deney sonucu (MPa).
  final double? minStrengthMpa;

  /// Uygun / uygunsuz (null = henüz karar yok).
  final bool? isCompliant;

  final String slagNote;
  final String notes;

  bool get isPending => strengthMpa == null;

  QualitySample copyWith({
    String? id,
    String? projectId,
    String? pourRecordId,
    ConcreteElementGroup? elementGroup,
    String? labReportNo,
    String? sampleDate,
    String? sampleCode,
    String? concreteClass,
    int? ageDays,
    double? strengthMpa,
    double? minStrengthMpa,
    bool? isCompliant,
    String? slagNote,
    String? notes,
    bool clearStrength = false,
    bool clearMinStrength = false,
    bool clearCompliance = false,
  }) {
    return QualitySample(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      pourRecordId: pourRecordId ?? this.pourRecordId,
      elementGroup: elementGroup ?? this.elementGroup,
      labReportNo: labReportNo ?? this.labReportNo,
      sampleDate: sampleDate ?? this.sampleDate,
      sampleCode: sampleCode ?? this.sampleCode,
      concreteClass: concreteClass ?? this.concreteClass,
      ageDays: ageDays ?? this.ageDays,
      strengthMpa: clearStrength ? null : (strengthMpa ?? this.strengthMpa),
      minStrengthMpa:
          clearMinStrength ? null : (minStrengthMpa ?? this.minStrengthMpa),
      isCompliant: clearCompliance ? null : (isCompliant ?? this.isCompliant),
      slagNote: slagNote ?? this.slagNote,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'pourRecordId': pourRecordId,
        'elementGroup': elementGroup.storageValue,
        'labReportNo': labReportNo,
        'sampleDate': sampleDate,
        'sampleCode': sampleCode,
        'concreteClass': concreteClass,
        'ageDays': ageDays,
        'strengthMpa': strengthMpa,
        'minStrengthMpa': minStrengthMpa,
        'isCompliant': isCompliant,
        'slagNote': slagNote,
        'notes': notes,
      };

  factory QualitySample.fromJson(Map<String, dynamic> json) => QualitySample(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        pourRecordId: json['pourRecordId'] as String?,
        elementGroup: ConcreteElementGroup.tryParse(
              json['elementGroup'] as String?,
            ) ??
            ConcreteElementGroup.temel,
        labReportNo: json['labReportNo'] as String? ?? '',
        sampleDate: json['sampleDate'] as String? ?? '',
        sampleCode: json['sampleCode'] as String? ?? '',
        concreteClass: json['concreteClass'] as String? ?? 'C30/37',
        ageDays: (json['ageDays'] as num?)?.toInt() ?? 28,
        strengthMpa: (json['strengthMpa'] as num?)?.toDouble(),
        minStrengthMpa: (json['minStrengthMpa'] as num?)?.toDouble(),
        isCompliant: json['isCompliant'] as bool?,
        slagNote: json['slagNote'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        pourRecordId,
        elementGroup,
        labReportNo,
        sampleDate,
        sampleCode,
        concreteClass,
        ageDays,
        strengthMpa,
        minStrengthMpa,
        isCompliant,
        slagNote,
        notes,
      ];
}
