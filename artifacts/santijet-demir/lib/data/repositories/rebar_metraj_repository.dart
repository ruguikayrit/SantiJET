import 'package:santijet_demir/data/repositories/project_data_repository.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';

class RebarMetrajRepository {
  RebarMetrajRepository(this._projectDataRepository);

  final ProjectDataRepository _projectDataRepository;
  static const _domain = 'rebar_metraj';

  List<SavedRebarMetraj> readSaved(String projectId) {
    final raw = _projectDataRepository.readDomain(projectId, _domain);
    if (raw == null) return [];

    final records = raw['records'];
    if (records is! List) return [];

    return records
        .map((record) => SavedRebarMetraj.fromJson(record as Map<dynamic, dynamic>))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<SavedRebarMetraj> saveResult({
    required String projectId,
    required RebarMetrajResult result,
    String? surveyImalatId,
    String? surveyImalatName,
  }) async {
    final existing = readSaved(projectId);
    final saved = SavedRebarMetraj(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      savedAt: DateTime.now(),
      result: result,
      surveyImalatId: surveyImalatId,
      surveyImalatName: surveyImalatName,
    );

    await _projectDataRepository.writeDomain(projectId, _domain, {
      'records': [saved.toJson(), ...existing.map((record) => record.toJson())],
    });

    return saved;
  }

  Future<void> markSentToSurvey({
    required String projectId,
    required String recordId,
    required String imalatId,
    required String imalatName,
  }) async {
    final records = readSaved(projectId);
    final updated = records
        .map(
          (record) => record.id == recordId
              ? record.copyWith(
                  surveyImalatId: imalatId,
                  surveyImalatName: imalatName,
                )
              : record,
        )
        .toList();

    await _projectDataRepository.writeDomain(projectId, _domain, {
      'records': updated.map((record) => record.toJson()).toList(),
    });
  }
}
