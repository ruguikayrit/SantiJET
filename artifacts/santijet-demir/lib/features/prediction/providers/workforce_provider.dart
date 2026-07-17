import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/repositories/workforce_repository.dart';
import 'package:santijet_demir/domain/entities/workforce.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

final workforceRepositoryProvider = Provider<WorkforceRepository>((ref) {
  return WorkforceRepository(ref.watch(projectDataRepositoryProvider));
});

final workforceProvider =
    StateNotifierProvider<WorkforceNotifier, List<WorkforceEntry>>((ref) {
  final notifier = WorkforceNotifier(ref);
  ref.listen(activeProjectIdProvider, (previous, next) {
    if (previous != next) notifier.loadForProject(next);
  });
  return notifier;
});

class WorkforceNotifier extends StateNotifier<List<WorkforceEntry>> {
  WorkforceNotifier(this._ref) : super(const []) {
    loadForProject(_ref.read(activeProjectIdProvider));
  }

  final Ref _ref;
  String? _loadedProjectId;

  WorkforceRepository get _repo => _ref.read(workforceRepositoryProvider);

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

  WorkforceEntry? entryFor(DateTime date) {
    final key = WorkforceEntry.normalizeDate(date);
    for (final e in state) {
      if (WorkforceEntry.normalizeDate(e.date) == key) return e;
    }
    return null;
  }

  Future<void> upsert(WorkforceEntry entry) async {
    final normalized = entry.copyWith(
      date: WorkforceEntry.normalizeDate(entry.date),
    );
    final next = state.where((e) => e.dateKey != normalized.dateKey).toList();
    next.insert(0, normalized);
    next.sort((a, b) => b.date.compareTo(a.date));
    state = next;
    await _persist();
  }

  Future<void> delete(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _persist();
  }
}
