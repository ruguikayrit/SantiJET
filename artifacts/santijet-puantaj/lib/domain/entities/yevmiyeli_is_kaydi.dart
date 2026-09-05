import 'package:equatable/equatable.dart';

import '../../core/utils/text_format.dart';

/// Taşeronun parça iş için verdiği adamın günlük yevmiye kaydı.
///
/// Puantajdaki otomatik saat÷8 yevmiyesinden ayrıdır; bedel manuel yazılır.
class YevmiyeliIsKaydi extends Equatable {
  const YevmiyeliIsKaydi._({
    required this.id,
    required this.projectId,
    required this.date,
    required this.personId,
    required this.personName,
    required this.company,
    required this.profession,
    required this.team,
    required this.workDescription,
    required this.yevmiyeCount,
    this.note = '',
    this.createdAt,
    this.updatedAt,
  });

  factory YevmiyeliIsKaydi({
    required String id,
    required String projectId,
    required String date,
    required String personId,
    required String personName,
    String company = '',
    String profession = '',
    String team = '',
    required String workDescription,
    required double yevmiyeCount,
    String note = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final yv = yevmiyeCount < 0.5 ? 0.5 : yevmiyeCount;
    return YevmiyeliIsKaydi._(
      id: id,
      projectId: projectId,
      date: date,
      personId: personId,
      personName: titleCaseTr(personName),
      company: titleCaseTr(company),
      profession: titleCaseTr(profession),
      team: titleCaseTr(team),
      workDescription: workDescription.trim(),
      yevmiyeCount: yv,
      note: note.trim(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  final String id;
  final String projectId;

  /// TR tarih: `dd.MM.yyyy`
  final String date;
  final String personId;
  final String personName;

  /// Listeye yazılmayan tek seferlik isim (`ymnl_…` id).
  static bool isManualPersonId(String id) => id.startsWith('ymnl_');

  bool get isManualPerson => isManualPersonId(personId);

  /// Firma Adı / taşeron.
  final String company;
  final String profession;
  final String team;

  /// Yapılan işin tanımı.
  final String workDescription;

  /// Manuel yevmiye adedi (0,5 adım).
  final double yevmiyeCount;
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  YevmiyeliIsKaydi copyWith({
    String? id,
    String? projectId,
    String? date,
    String? personId,
    String? personName,
    String? company,
    String? profession,
    String? team,
    String? workDescription,
    double? yevmiyeCount,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return YevmiyeliIsKaydi(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      company: company ?? this.company,
      profession: profession ?? this.profession,
      team: team ?? this.team,
      workDescription: workDescription ?? this.workDescription,
      yevmiyeCount: yevmiyeCount ?? this.yevmiyeCount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'date': date,
        'personId': personId,
        'personName': personName,
        'company': company,
        'profession': profession,
        'team': team,
        'workDescription': workDescription,
        'yevmiyeCount': yevmiyeCount,
        'note': note,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory YevmiyeliIsKaydi.fromJson(Map<String, dynamic> json) {
    return YevmiyeliIsKaydi(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      date: json['date'] as String? ?? '',
      personId: json['personId'] as String? ?? '',
      personName: json['personName'] as String? ?? '',
      company: json['company'] as String? ?? '',
      profession: json['profession'] as String? ?? '',
      team: json['team'] as String? ?? '',
      workDescription: json['workDescription'] as String? ?? '',
      yevmiyeCount: (json['yevmiyeCount'] as num?)?.toDouble() ?? 1,
      note: json['note'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        date,
        personId,
        personName,
        company,
        profession,
        team,
        workDescription,
        yevmiyeCount,
        note,
        createdAt,
        updatedAt,
      ];
}
