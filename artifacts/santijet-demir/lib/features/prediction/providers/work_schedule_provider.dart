import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/repositories/work_schedule_repository.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/domain/entities/work_schedule.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

final workScheduleRepositoryProvider = Provider<WorkScheduleRepository>((ref) {
  return WorkScheduleRepository(ref.watch(projectDataRepositoryProvider));
});

final workScheduleProvider =
    StateNotifierProvider<WorkScheduleNotifier, List<WorkScheduleImalat>>((ref) {
  final notifier = WorkScheduleNotifier(ref);
  ref.listen(activeProjectIdProvider, (previous, next) {
    if (previous != next) notifier.loadForProject(next);
  });
  return notifier;
});

/// Keşif + iş programından türetilen günlük plan (tahmin / brifing).
final workScheduleDaysProvider = Provider<List<WorkScheduleDay>>((ref) {
  final items = ref.watch(workScheduleProvider);
  final survey = ref.watch(surveyProjectProvider);
  return expandWorkScheduleToDays(items: items, survey: survey);
});

class WorkScheduleNotifier extends StateNotifier<List<WorkScheduleImalat>> {
  WorkScheduleNotifier(this._ref) : super(const []) {
    loadForProject(_ref.read(activeProjectIdProvider));
  }

  final Ref _ref;
  String? _loadedProjectId;

  WorkScheduleRepository get _repo =>
      _ref.read(workScheduleRepositoryProvider);

  void loadForProject(String? projectId) {
    _loadedProjectId = projectId;
    if (projectId == null) {
      state = [];
      return;
    }
    state = _repo.read(projectId);
  }

  Future<void> _persist() async {
    final projectId = _loadedProjectId;
    if (projectId == null) return;
    await _repo.write(projectId, state);
  }

  /// Keşif imalatlarıyla satırları senkronize eder (eksik olanları ekler).
  Future<void> syncFromSurvey(SurveyProject survey) async {
    final byId = {for (final item in state) item.imalatId: item};
    final next = <WorkScheduleImalat>[];
    for (final imalat in survey.imalats) {
      final existing = byId[imalat.id];
      if (existing != null) {
        next.add(
          existing.copyWith(imalatName: imalat.name),
        );
      } else {
        next.add(
          WorkScheduleImalat(
            id: 'ws-${imalat.id}',
            imalatId: imalat.id,
            imalatName: imalat.name,
          ),
        );
      }
    }
    next.sort((a, b) => a.imalatName.compareTo(b.imalatName));
    state = next;
    await _persist();
  }

  Future<void> upsert(WorkScheduleImalat item) async {
    final next = state.where((e) => e.imalatId != item.imalatId).toList()
      ..add(item);
    next.sort((a, b) => a.imalatName.compareTo(b.imalatName));
    state = next;
    await _persist();
  }

  Future<void> replaceAll(List<WorkScheduleImalat> items) async {
    final next = [...items]
      ..sort((a, b) => a.imalatName.compareTo(b.imalatName));
    state = next;
    await _persist();
  }

  WorkScheduleDay? dayFor(DateTime date, SurveyProject survey) {
    return workScheduleDayFor(date: date, items: state, survey: survey);
  }
}
