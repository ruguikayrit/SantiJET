import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/repositories/work_schedule_repository.dart';
import 'package:santijet_demir/domain/entities/work_schedule.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

final workScheduleRepositoryProvider = Provider<WorkScheduleRepository>((ref) {
  return WorkScheduleRepository(ref.watch(projectDataRepositoryProvider));
});

final workScheduleProvider =
    StateNotifierProvider<WorkScheduleNotifier, List<WorkScheduleDay>>((ref) {
  final notifier = WorkScheduleNotifier(ref);
  ref.listen(activeProjectIdProvider, (previous, next) {
    if (previous != next) notifier.loadForProject(next);
  });
  return notifier;
});

class WorkScheduleNotifier extends StateNotifier<List<WorkScheduleDay>> {
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

  WorkScheduleDay? dayFor(DateTime date) {
    final key = WorkScheduleDay.normalizeDate(date);
    for (final day in state) {
      if (WorkScheduleDay.normalizeDate(day.date) == key) return day;
    }
    return null;
  }

  Future<void> upsertDay(WorkScheduleDay day) async {
    final normalized = day.copyWith(
      date: WorkScheduleDay.normalizeDate(day.date),
    );
    final key = normalized.dateKey;
    final next = state.where((d) => d.dateKey != key).toList();
    if (normalized.activities.isNotEmpty) {
      next.add(normalized);
    }
    next.sort((a, b) => b.date.compareTo(a.date));
    state = next;
    await _persist();
  }

  Future<void> deleteDay(DateTime date) async {
    final key = WorkScheduleDay.normalizeDate(date);
    state = state
        .where((d) => WorkScheduleDay.normalizeDate(d.date) != key)
        .toList();
    await _persist();
  }
}
