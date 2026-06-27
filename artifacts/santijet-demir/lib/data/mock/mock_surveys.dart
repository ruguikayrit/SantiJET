import 'package:santijet_demir/domain/entities/survey.dart';

SurveyProject getMockSurveyProject() {
  return SurveyProject(
    projectName: '',
    date: DateTime.now(),
    revision: 'Rev.1',
    imalats: [],
  );
}
