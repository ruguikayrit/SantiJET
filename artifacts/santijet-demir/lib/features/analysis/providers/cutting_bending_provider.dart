import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/repositories/cutting_bending_repository.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart'
    as analysis_calc;
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_storage_provider.dart';

final cuttingBendingRepositoryProvider = Provider<CuttingBendingRepository>((ref) {
  return CuttingBendingRepository(ref.watch(projectDataRepositoryProvider));
});

final cuttingBendingBatchesProvider =
    StateNotifierProvider<CuttingBendingNotifier, CuttingBendingState>((ref) {
  final notifier = CuttingBendingNotifier(ref);
  ref.listen(activeProjectIdProvider, (previous, next) {
    if (previous == next) return;
    if (previous != null) {
      Future.microtask(() {
        ref.read(selectedAnalysisBatchIdsProvider.notifier).state = {};
      });
      notifier.loadForProject(next);
    }
  });
  return notifier;
});

/// Hesap ve Analiz katlanabilir bölüm kimlikleri.
abstract final class AnalysisSectionIds {
  static const dataSource = 'analysis-data-source';
  static const optimizationPipeline = 'analysis-optimization-pipeline';
  static const plannedCutting = 'analysis-planned-cutting';
  static const comparison = 'analysis-comparison';
  static const tahvilCalculator = 'analysis-tahvil-calculator';

  // Geriye dönük — eski oturum durumları için.
  static const labels = 'analysis-labels';
  static const pieceList = 'analysis-piece-list';
  static const lengthMatch = 'analysis-length-match';
  static const revisedPieceList = 'analysis-revised-piece-list';
  static const stockCutList = 'analysis-stock-cut-list';
  static const tahvilSuggestions = 'analysis-tahvil-suggestions';

  static String stockCutDiameter(String batchId, int diameter) =>
      'analysis-stock-cut-$batchId-d$diameter';
}

/// Bölüm açık/kapalı durumu — yeniden çizimlerde korunur, varsayılan kapalı.
final analysisSectionExpandedProvider =
    StateProvider.family<bool, String>((ref, sectionId) => false);

/// Hesap ve Analiz — çoklu silme için seçili DWG analiz listeleri.
final selectedAnalysisBatchIdsProvider = StateProvider<Set<String>>((ref) => {});

class OptimumFireAnalysisProgress {
  const OptimumFireAnalysisProgress({
    this.batchId,
    this.isRunning = false,
    this.isCompleted = false,
    this.percent = 0,
    this.stepLabel = '',
  });

  final String? batchId;
  final bool isRunning;
  final bool isCompleted;
  final int percent;
  final String stepLabel;

  static const idle = OptimumFireAnalysisProgress();

  bool appliesTo(String batchId) => this.batchId == batchId;
}

final selectedFireReductionStrategyProvider =
    StateProvider<FireReductionStrategy>(
  (ref) => FireReductionStrategy.both,
);

final optimumFireAnalysisProgressProvider =
    StateProvider<OptimumFireAnalysisProgress>(
  (ref) => OptimumFireAnalysisProgress.idle,
);

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
        .map((batch) => analysis_calc.hydrateCuttingBendingBatchLabels(batch, metrajRecords))
        .map(analysis_calc.hydrateStockCutPlans)
        .toList();
    state = CuttingBendingState(
      batches: batches,
      activeBatchId: _repo.readActiveBatchId(projectId) ?? batches.firstOrNull?.id,
    );
  }

  Future<CuttingBendingBatch?> addBatch(CuttingBendingBatch batch) async {
    final projectId = _loadedProjectId;
    if (projectId == null) return null;

    final hydrated = analysis_calc.hydrateCuttingBendingBatchLabels(
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

    final nextBatch =
        state.batches.where((batch) => batch.id == batchId).firstOrNull;
    if (nextBatch?.optimizationStrategy != null) {
      _ref.read(selectedFireReductionStrategyProvider.notifier).state =
          nextBatch!.optimizationStrategy!;
    }
  }

  Future<void> refreshLengthMatchGroups() async {
    await _updateBatch((batch) {
      return analysis_calc.syncBatchLengthMatchDerivatives(
        batch.copyWith(
          lengthMatches: analysis_calc.computeLengthMatchGroups(batch.pieceLines),
          clearOptimizationAppliedAt: true,
        ),
      );
    });
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
      return analysis_calc.syncBatchLengthMatchDerivatives(
        batch.copyWith(
          lengthMatches: updated,
          clearOptimizationAppliedAt: true,
        ),
      );
    });
  }

  Future<void> approveTahvil(String groupId, {required bool approved}) async {
    await _updateBatch((batch) {
      final updated = batch.tahvilGroups
          .map((group) => group.id == groupId ? group.copyWith(approved: approved) : group)
          .toList();
      return analysis_calc.syncBatchLengthMatchDerivatives(
        batch.copyWith(
          tahvilGroups: updated,
          clearOptimizationAppliedAt: true,
        ),
      );
    });
  }

  Future<void> runOptimumFireAnalysis() async {
    final projectId = _loadedProjectId;
    final active = state.activeBatch;
    if (projectId == null || active == null || active.pieceLines.isEmpty) {
      return;
    }

    final progressNotifier =
        _ref.read(optimumFireAnalysisProgressProvider.notifier);
    final batchId = active.id;

    progressNotifier.state = OptimumFireAnalysisProgress(
      batchId: batchId,
      isRunning: true,
      percent: 0,
      stepLabel: 'Analiz başlatılıyor...',
    );

    try {
      final updated = await analysis_calc.runOptimumFireAnalysis(
        active,
        strategy: _ref.read(selectedFireReductionStrategyProvider),
        onProgress: (percent, stepLabel) async {
          progressNotifier.state = OptimumFireAnalysisProgress(
            batchId: batchId,
            isRunning: true,
            percent: percent,
            stepLabel: stepLabel,
          );
          await Future<void>.delayed(const Duration(milliseconds: 120));
        },
      );

      await _repo.updateBatch(projectId: projectId, batch: updated);
      state = CuttingBendingState(
        batches: state.batches
            .map((batch) => batch.id == updated.id ? updated : batch)
            .toList(),
        activeBatchId: state.activeBatchId,
      );

      progressNotifier.state = OptimumFireAnalysisProgress(
        batchId: batchId,
        isCompleted: true,
        percent: 100,
        stepLabel: 'Analiz tamamlandı',
      );

      _ref.read(selectedFireReductionStrategyProvider.notifier).state =
          updated.optimizationStrategy ?? _ref.read(selectedFireReductionStrategyProvider);

      await Future<void>.delayed(const Duration(seconds: 4));
      final current = _ref.read(optimumFireAnalysisProgressProvider);
      if (current.batchId == batchId && current.isCompleted) {
        progressNotifier.state = OptimumFireAnalysisProgress.idle;
      }
    } catch (_) {
      progressNotifier.state = OptimumFireAnalysisProgress.idle;
      rethrow;
    }
  }

  Future<void> saveAnalysisResult() async {
    final active = state.activeBatch;
    if (active == null || !active.isOptimized || active.optimizationStrategy == null) {
      return;
    }

    await _updateBatch(analysis_calc.saveOptimizationSnapshot);
  }

  Future<void> selectAnalysisStrategy(FireReductionStrategy strategy) async {
    _ref.read(selectedFireReductionStrategyProvider.notifier).state = strategy;

    final active = state.activeBatch;
    if (active == null) return;

    if (active.optimizationStrategy == strategy && active.isOptimized) {
      return;
    }

    if (active.hasSavedOptimization(strategy)) {
      await _updateBatch(
        (batch) => analysis_calc.applyOptimizationSnapshot(
          batch,
          batch.savedOptimizations[strategy]!,
        ),
      );
      return;
    }

    if (active.isOptimized || active.optimizationStrategy != null) {
      await _updateBatch(analysis_calc.clearActiveOptimization);
    }
  }

  Future<void> deleteBatch(String batchId) async {
    await deleteBatches({batchId});
  }

  Future<void> deleteBatches(Set<String> batchIds) async {
    if (batchIds.isEmpty) return;

    final projectId = _loadedProjectId;
    if (projectId == null) return;

    await _repo.deleteBatches(projectId: projectId, batchIds: batchIds);
    final remaining =
        state.batches.where((batch) => !batchIds.contains(batch.id)).toList();
    final nextActiveId = state.activeBatchId != null &&
            batchIds.contains(state.activeBatchId!)
        ? remaining.firstOrNull?.id
        : (remaining.any((batch) => batch.id == state.activeBatchId)
            ? state.activeBatchId
            : remaining.firstOrNull?.id);

    _ref.read(selectedAnalysisBatchIdsProvider.notifier).state = {};
    state = CuttingBendingState(
      batches: remaining,
      activeBatchId: nextActiveId,
    );
  }

  Future<void> removeLabelDetail(RebarMetrajTextDetail detail) async {
    await _updateBatch((batch) {
      final updatedLabels = batch.labelDetails
          .where((item) => !analysis_calc.isSameRebarMetrajTextDetail(item, detail))
          .toList();
      return analysis_calc.rebuildCuttingBendingBatch(batch, labelDetails: updatedLabels);
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
