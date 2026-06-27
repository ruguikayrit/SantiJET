import 'package:santijet_demir/data/repositories/project_data_repository.dart';
import 'package:santijet_demir/domain/entities/survey.dart';

class SurveyRepository {
  SurveyRepository(this._projectDataRepository);

  final ProjectDataRepository _projectDataRepository;
  static const _domain = 'survey';

  SurveyProject? read(String projectId) {
    final raw = _projectDataRepository.readDomain(projectId, _domain);
    if (raw == null) return null;
    return SurveyProject.fromJson(raw);
  }

  Future<void> write(String projectId, SurveyProject project) async {
    await _projectDataRepository.writeDomain(projectId, _domain, project.toJson());
  }

  SurveyProject defaultProject({required String projectName}) {
    return SurveyProject(
      projectName: projectName,
      date: DateTime.now(),
      revision: 'Rev.1',
      imalats: [],
    );
  }
}
