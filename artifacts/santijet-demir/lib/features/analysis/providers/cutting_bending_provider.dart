import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/repositories/cutting_bending_repository.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_storage_provider.dart';

final cuttingBendingRepositoryProvider = Provider<CuttingBendingRepository>((ref) {
  return CuttingBendingRepository(ref.watch(projectDataRepositoryProvider));
});

final cuttingBendingBatchesProvider =
    StateNotifierProvider<CuttingBendingNotifier, CuttingBendingState>((ref) {
  final notifier = CuttingBendingNotifier(ref);
  ref.listen(activeProjectIdProvider, (previous, next) {
    if (previous != next) {
      notifier.loadForProject(next);
    }
  });
  return notifier;
});

class CuttingBendingState {
  const CuttingBendingState({
    this.batches = const [],
    this.activeBatchId,
  });

  final List<CuttingBendingBatch> batches;
  final String? activeBatchId;

  CuttingBendingBatch? get activeBatch {
    if (activeBatchId == null) return batches.isNotEmpty ? batches.first : null;
    for (final batch in batches) {
      if (batch.id == activeBatchId) return batch;
    }
    return batches.isNotEmpty ? batches.first : null;
  }

  CuttingBendingState copyWith({
    List<CuttingBendingBatch>? batches,
    String? activeBatchId,
  }) {
    return CuttingBendingState(
      batches: batches ?? this.batches,
      activeBatchId: activeBatchId ?? this.activeBatchId,
    );
  }
}

class CuttingBendingNotifier extends StateNotifier<CuttingBendingState> {
  CuttingBendingNotifier(this._ref) : super(const CuttingBendingState()) {
    loadForProject(_ref.read(activeProjectIdProvider));
  }

  final Ref _ref;
  String? _loadedProjectId;

  CuttingBendingRepository get _repo => _ref.read(cuttingBendingRepositoryProvider);

  void loadForProject(String? projectId) {
    _loadedProjectId = projectId;
    if (projectId == null) {
      state = const CuttingBendingState();
      return;
    }
    final metrajRecords = _ref.read(savedRebarMetrajProvider);
    final batches = _repo
        .readBatches(projectId)
        .map((batch) => hydrateCuttingBendingBatchLabels(batch, metrajRecords))
        .toList();
    state = CuttingBendingState(
      batches: batches,
      activeBatchId: _repo.readActiveBatchId(projectId) ?? batches.firstOrNull?.id,
    );
  }

  Future<CuttingBendingBatch?> addBatch(CuttingBendingBatch batch) async {
    final projectId = _loadedProjectId;
    if (projectId == null) return null;

    final hydrated = hydrateCuttingBendingBatchLabels(
      batch,
      _ref.read(savedRebarMetrajProvider),
    );
    final saved = await _repo.addBatch(projectId: projectId, batch: hydrated);
    state = CuttingBendingState(
      batches: [saved, ...state.batches.where((b) => b.id != saved.id)],
      activeBatchId: saved.id,
    );
    return saved;
  }

  Future<void> setActiveBatch(String batchId) async {
    final projectId = _loadedProjectId;
    if (projectId == null) return;

    await _repo.setActiveBatch(projectId: projectId, batchId: batchId);
    state = state.copyWith(activeBatchId: batchId);
  }

  Future<void> approveLengthMatch(
    String groupId, {
    required bool approved,
    double? selectedLengthM,
  }) async {
    await _updateBatch((batch) {
      final updated = batch.lengthMatches
          .map((group) {
            if (group.id != groupId) return group;
            if (!approved) {
              return group.copyWith(approved: false, clearSelectedLength: true);
            }
            if (selectedLengthM == null) return group;
            return group.copyWith(
              approved: true,
              selectedLengthM: selectedLengthM,
            );
          })
          .toList();
      return batch.copyWith(lengthMatches: updated);
    });
  }

  Future<void> approveTahvil(String groupId, {required bool approved}) async {
    await _updateBatch((batch) {
      final updated = batch.tahvilGroups
          .map((group) => group.id == groupId ? group.copyWith(approved: approved) : group)
          .toList();
      return batch.copyWith(tahvilGroups: updated);
    });
  }

  Future<void> deleteBatch(String batchId) async {
    final projectId = _loadedProjectId;
    if (projectId == null) return;

    await _repo.deleteBatch(projectId: projectId, batchId: batchId);
    final remaining = state.batches.where((batch) => batch.id != batchId).toList();
    final nextActiveId = state.activeBatchId == batchId
        ? (remaining.isNotEmpty ? remaining.first.id : null)
        : state.activeBatchId;

    state = CuttingBendingState(
      batches: remaining,
      activeBatchId: nextActiveId,
    );
  }

  Future<void> removeLabelDetail(RebarMetrajTextDetail detail) async {
    await _updateBatch((batch) {
      final updatedLabels = batch.labelDetails
          .where((item) => !isSameRebarMetrajTextDetail(item, detail))
          .toList();
      return rebuildCuttingBendingBatch(batch, labelDetails: updatedLabels);
    });
  }

  Future<void> _updateBatch(
    CuttingBendingBatch Function(CuttingBendingBatch batch) transform,
  ) async {
    final projectId = _loadedProjectId;
    final active = state.activeBatch;
    if (projectId == null || active == null) return;

    final updatedBatch = transform(active);
    await _repo.updateBatch(projectId: projectId, batch: updatedBatch);
    state = CuttingBendingState(
      batches: state.batches
          .map((batch) => batch.id == updatedBatch.id ? updatedBatch : batch)
          .toList(),
      activeBatchId: state.activeBatchId,
    );
  }
}
