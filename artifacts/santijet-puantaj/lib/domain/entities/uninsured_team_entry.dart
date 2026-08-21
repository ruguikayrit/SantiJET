import 'package:equatable/equatable.dart';

import '../../core/utils/text_format.dart';

/// Günlük ekip baş sayısı — katalog ekip adı + çalışan sayısı.
///
/// Personel satırı yoktur; yalnız [teamName] + [workerCount].
/// Mantıksal kapsam: `(projectId, date)`.
class UninsuredTeamEntry extends Equatable {
  const UninsuredTeamEntry._({
    required this.id,
    required this.projectId,
    required this.date,
    required this.teamName,
    required this.workerCount,
  });

  factory UninsuredTeamEntry({
    required String id,
    required String projectId,
    required String date,
    required String teamName,
    required int workerCount,
  }) {
    return UninsuredTeamEntry._(
      id: id,
      projectId: projectId,
      date: date,
      teamName: titleCaseTr(teamName),
      workerCount: workerCount < 0 ? 0 : workerCount,
    );
  }

  final String id;
  final String projectId;

  /// TR tarih: `dd.MM.yyyy`
  final String date;
  final String teamName;
  final int workerCount;

  UninsuredTeamEntry copyWith({
    String? id,
    String? projectId,
    String? date,
    String? teamName,
    int? workerCount,
  }) {
    return UninsuredTeamEntry(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      teamName: teamName ?? this.teamName,
      workerCount: workerCount ?? this.workerCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'date': date,
        'teamName': teamName,
        'workerCount': workerCount,
      };

  factory UninsuredTeamEntry.fromJson(Map<String, dynamic> json) {
    return UninsuredTeamEntry(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      date: json['date'] as String,
      teamName: json['teamName'] as String? ?? '',
      workerCount: (json['workerCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, projectId, date, teamName, workerCount];
}
