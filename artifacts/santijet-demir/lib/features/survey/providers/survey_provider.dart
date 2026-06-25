import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/mock/mock_surveys.dart';
import 'package:santijet_demir/domain/entities/survey.dart';

final surveyProjectProvider = Provider<SurveyProject>((ref) {
  return getMockSurveyProject();
});

final expandedImalatProvider = StateProvider<String?>((ref) => null);

final selectedImalatProvider = StateProvider<SurveyImalat?>((ref) => null);

final surveyTabIndexProvider = StateProvider<int>((ref) => 0);
