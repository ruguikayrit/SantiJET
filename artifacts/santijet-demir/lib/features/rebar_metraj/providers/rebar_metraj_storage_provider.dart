import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/repositories/rebar_metraj_repository.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

final rebarMetrajRepositoryProvider = Provider<RebarMetrajRepository>((ref) {
  return RebarMetrajRepository(ref.watch(projectDataRepositoryProvider));
});

final savedRebarMetrajProvider =
    StateNotifierProvider<SavedRebarMetrajNotifier, List<SavedRebarMetraj>>((ref) {
  final notifier = SavedRebarMetrajNotifier(ref);
  ref.listen(activeProjectIdProvider, (previous, next) {
    if (previous != next) {
      notifier.loadForProject(next);
    }
  });
  return notifier;
});

class SavedRebarMetrajNotifier extends StateNotifier<List<SavedRebarMetraj>> {
  SavedRebarMetrajNotifier(this._ref) : super(const []) {
    loadForProject(_ref.read(activeProjectIdProvider));
  }

  final Ref _ref;

  RebarMetrajRepository get _repo => _ref.read(rebarMetrajRepositoryProvider);

  void loadForProject(String? projectId) {
    if (projectId == null) {
      state = const [];
      return;
    }
    state = _repo.readSaved(projectId);
  }

  Future<SavedRebarMetraj?> saveCurrentResult(RebarMetrajResult result) async {
    final projectId = _ref.read(activeProjectIdProvider);
    if (projectId == null) return null;

    final saved = await _repo.saveResult(
      projectId: projectId,
      result: result,
    );
    state = [saved, ...state.where((record) => record.id != saved.id)];
    return saved;
  }

  Future<void> markSentToSurvey({
    required String recordId,
    required String imalatId,
    required String imalatName,
  }) async {
    final projectId = _ref.read(activeProjectIdProvider);
    if (projectId == null) return;

    await _repo.markSentToSurvey(
      projectId: projectId,
      recordId: recordId,
      imalatId: imalatId,
      imalatName: imalatName,
    );
    loadForProject(projectId);
  }

  bool isResultSaved(RebarMetrajResult result) {
    return state.any(
      (record) =>
          record.result.fileName == result.fileName &&
          record.result.parsedAt == result.parsedAt &&
          record.result.totalTonnage == result.totalTonnage,
    );
  }
}
