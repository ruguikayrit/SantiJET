import 'package:equatable/equatable.dart';

import '../../core/utils/text_format.dart';

/// Günlük ekip baş sayısı — firma + katalog ekip adı + çalışan sayısı.
///
/// Personel satırı yoktur; yalnız [company] + [teamName] + [workerCount].
/// Mantıksal kapsam: `(projectId, date)`.
class UninsuredTeamEntry extends Equatable {
  const UninsuredTeamEntry._({
    required this.id,
    required this.projectId,
    required this.date,
    required this.teamName,
    required this.workerCount,
    this.company = '',
  });

  factory UninsuredTeamEntry({
    required String id,
    required String projectId,
    required String date,
    required String teamName,
    required int workerCount,
    String company = '',
  }) {
    return UninsuredTeamEntry._(
      id: id,
      projectId: projectId,
      date: date,
      teamName: titleCaseTr(teamName),
      workerCount: workerCount < 0 ? 0 : workerCount,
      company: titleCaseTr(company),
    );
  }

  final String id;
  final String projectId;

  /// TR tarih: `dd.MM.yyyy`
  final String date;

  /// Sigorta ettiren / taşeron firma adı.
  final String company;
  final String teamName;
  final int workerCount;

  UninsuredTeamEntry copyWith({
    String? id,
    String? projectId,
    String? date,
    String? teamName,
    int? workerCount,
    String? company,
  }) {
    return UninsuredTeamEntry(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      teamName: teamName ?? this.teamName,
      workerCount: workerCount ?? this.workerCount,
      company: company ?? this.company,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'date': date,
        'teamName': teamName,
        'workerCount': workerCount,
        'company': company,
      };

  factory UninsuredTeamEntry.fromJson(Map<String, dynamic> json) {
    return UninsuredTeamEntry(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      date: json['date'] as String,
      teamName: json['teamName'] as String? ?? '',
      workerCount: (json['workerCount'] as num?)?.toInt() ?? 0,
      company: json['company'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [id, projectId, date, company, teamName, workerCount];
}
