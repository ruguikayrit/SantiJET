import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/repositories/survey_repository.dart';
import 'package:santijet_demir/data/services/rebar_survey_mapper.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

final surveyRepositoryProvider = Provider<SurveyRepository>((ref) {
  return SurveyRepository(ref.watch(projectDataRepositoryProvider));
});

final surveyProjectProvider =
    StateNotifierProvider<SurveyProjectNotifier, SurveyProject>((ref) {
  final notifier = SurveyProjectNotifier(ref);
  ref.listen(activeProjectIdProvider, (previous, next) {
    if (previous != next) {
      notifier.loadForProject(next);
    }
  });
  ref.listen(activeProjectProvider, (previous, next) {
    if (previous?.name != next?.name && next != null) {
      notifier.updateProjectName(next.name);
    }
  });
  return notifier;
});

class SurveyProjectNotifier extends StateNotifier<SurveyProject> {
  SurveyProjectNotifier(this._ref) : super(_initialProject(_ref)) {
    loadForProject(_ref.read(activeProjectIdProvider));
  }

  final Ref _ref;
  String? _loadedProjectId;

  SurveyRepository get _repo => _ref.read(surveyRepositoryProvider);

  static SurveyProject _initialProject(Ref ref) {
    final activeProject = ref.read(activeProjectProvider);
    return ref.read(surveyRepositoryProvider).defaultProject(
          projectName: activeProject?.name ?? '',
        );
  }

  void loadForProject(String? projectId) {
    if (projectId == null) {
      _loadedProjectId = null;
      state = _repo.defaultProject(
        projectName: _ref.read(activeProjectProvider)?.name ?? '',
      );
      return;
    }

    if (_loadedProjectId == projectId) return;

    final saved = _repo.read(projectId);
    final activeName = _ref.read(activeProjectProvider)?.name ?? '';
    if (saved != null) {
      state = saved.copyWith(
        projectName: activeName.isEmpty ? saved.projectName : activeName,
      );
    } else {
      state = _repo.defaultProject(projectName: activeName);
    }
    _loadedProjectId = projectId;
  }

  Future<void> _persist() async {
    final projectId = _ref.read(activeProjectIdProvider);
    if (projectId == null) return;
    await _repo.write(projectId, state);
  }

  void updateProjectName(String projectName) {
    if (projectName.isEmpty || state.projectName == projectName) return;
    state = state.copyWith(projectName: projectName);
    _persist();
  }

  Future<SurveyImalat> sendMetrajToImalat({
    required RebarMetrajResult result,
    required String imalatId,
    required bool replaceExisting,
  }) async {
    final imalat = state.imalats.firstWhere((item) => item.id == imalatId);
    final updated = RebarSurveyMapper.applyMetrajToImalat(
      imalat: imalat,
      lines: result.lines,
      replaceExisting: replaceExisting,
    );

    state = state.copyWith(
      imalats: state.imalats
          .map((item) => item.id == imalatId ? updated : item)
          .toList(),
    );
    await _persist();
    return updated;
  }

  Future<SurveyImalat> createImalatFromMetraj({
    required RebarMetrajResult result,
    required String name,
  }) async {
    final baseId = RebarSurveyMapper.slugifyImalatId(name);
    var id = baseId;
    var suffix = 1;
    while (state.imalats.any((imalat) => imalat.id == id)) {
      id = '$baseId-$suffix';
      suffix++;
    }

    final imalat = RebarSurveyMapper.createImalatFromMetraj(
      id: id,
      name: name.trim(),
      lines: result.lines,
    );

    state = state.copyWith(
      imalats: [...state.imalats, imalat],
    );
    await _persist();
    return imalat;
  }
}

final expandedImalatProvider = StateProvider<String?>((ref) => null);

final expandedMetrajRecordProvider = StateProvider<String?>((ref) => null);

final selectedMetrajRecordIdsProvider =
    StateProvider<Set<String>>((ref) => {});

final selectedImalatProvider = StateProvider<SurveyImalat?>((ref) => null);

final surveyTabIndexProvider = StateProvider<int>((ref) => 0);
