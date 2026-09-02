import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/repositories/cutting_bending_repository.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/features/analysis/analysis_compute_cache.dart';
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
        AnalysisComputeCache.clear();
        ref.read(selectedAnalysisBatchIdsProvider.notifier).state = {};
        ref.read(mergedAnalysisSessionProvider.notifier).state = null;
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

/// Hesap ve Analiz — analize alınacak DWG dosyaları (varsayılan: tümü).
final selectedAnalysisBatchIdsProvider = StateProvider<Set<String>>((ref) => {});

class MergedAnalysisSession {
  const MergedAnalysisSession({
    required this.scopeKey,
    required this.batch,
  });

  final String scopeKey;
  final CuttingBendingBatch batch;
}

/// Birleşik analiz oturumu — seçim değişince sıfırlanır, diske yazılmaz.
final mergedAnalysisSessionProvider =
    StateProvider<MergedAnalysisSession?>((ref) => null);

/// Seçili dosyaların birleştirilmiş analiz görünümü.
final mergedAnalysisBatchProvider = Provider<CuttingBendingBatch?>((ref) {
  final scope = ref.watch(selectedAnalysisBatchIdsProvider);
  if (scope.isEmpty) return null;

  final scopeKey = analysis_calc.analysisScopeKey(scope);
  final session = ref.watch(mergedAnalysisSessionProvider);
  if (session != null && session.scopeKey == scopeKey) {
    return session.batch;
  }

  return ref.watch(_mergedBatchByScopeProvider(scopeKey));
});

final _mergedBatchByScopeProvider =
    Provider.family<CuttingBendingBatch?, String>((ref, scopeKey) {
  final scope = ref.watch(selectedAnalysisBatchIdsProvider);
  if (analysis_calc.analysisScopeKey(scope) != scopeKey) return null;

  final state = ref.watch(cuttingBendingBatchesProvider);
  final selected =
      state.batches.where((batch) => scope.contains(batch.id)).toList();
  if (selected.isEmpty) return null;

  return analysis_calc.mergeCuttingBendingBatchesForAnalysis(selected);
});

/// Fire özeti — build içinde tekrar hesaplanmaz (analiz sırasında sekme çökmesini önler).
final analysisFireSummaryProvider = Provider<analysis_calc.AnalysisFireSummary?>((ref) {
  final batch = ref.watch(mergedAnalysisBatchProvider);
  if (batch == null) return null;
  return analysis_calc.computeAnalysisFireSummary(batch);
});

/// Karşılaştırma özeti — optimize batch için memoize.
final analysisComparisonProvider = Provider<analysis_calc.AnalysisComparison?>((ref) {
  final batch = ref.watch(mergedAnalysisBatchProvider);
  if (batch == null || !batch.isOptimized) return null;
  return analysis_calc.computeAnalysisComparison(batch);
});

/// Strateji fire karşılaştırması — build içinde tekrar hesaplanmaz.
final analysisStrategyComparisonProvider =
    Provider<List<analysis_calc.StrategyFireComparison>>((ref) {
  final batch = ref.watch(mergedAnalysisBatchProvider);
  if (batch == null) return const [];
  return analysis_calc.computeStrategyFireComparisons(batch);
});

/// Ham ↔ revize parça karşılaştırma satırları.
final analysisPieceListComparisonProvider =
    Provider<List<PieceListComparisonRow>>((ref) {
  final batch = ref.watch(mergedAnalysisBatchProvider);
  if (batch == null || !batch.isOptimized) return const [];
  return analysis_calc.computePieceListComparisonRows(batch);
});

/// Boy eşleştirme değişiklikleri.
final analysisLengthMatchChangesProvider =
    Provider<List<LengthMatchChange>>((ref) {
  final batch = ref.watch(mergedAnalysisBatchProvider);
  if (batch == null) return const [];
  return analysis_calc.computeLengthMatchChanges(batch.lengthMatches);
});

/// Malzeme özeti (çap bazında).
final analysisMaterialSummaryProvider =
    Provider<List<analysis_calc.MaterialDiameterSummary>>((ref) {
  final batch = ref.watch(mergedAnalysisBatchProvider);
  if (batch == null) return const [];
  return analysis_calc.computeMaterialSummaryByDiameter(batch.pieceLines);
});

/// Ham fire çap kırılımı.
final analysisRawFireBreakdownProvider =
    Provider<List<analysis_calc.FireDiameterBreakdown>>((ref) {
  final batch = ref.watch(mergedAnalysisBatchProvider);
  if (batch == null) return const [];
  return analysis_calc.computeRawFireBreakdown(batch);
});

/// Ham fire kesim planları (12 m stok simülasyonu).
final analysisRawStockCutPlansProvider = Provider<List<StockCutPlan>>((ref) {
  final batch = ref.watch(mergedAnalysisBatchProvider);
  if (batch == null) return const [];
  return analysis_calc.computeStockCutPlans(batch.pieceLines);
});

/// Plan fire çap kırılımı.
final analysisPlannedFireBreakdownProvider =
    Provider<List<analysis_calc.FireDiameterBreakdown>>((ref) {
  final batch = ref.watch(mergedAnalysisBatchProvider);
  if (batch == null || !batch.isOptimized) return const [];
  return analysis_calc.computePlannedFireBreakdown(batch);
});

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
  (ref) => FireReductionStrategy.lengthMatchOnly,
);

/// Proje fire'ı ile tahvil ön izlemesi (boy eşleştirme yok).
/// Optimize batch'te gerekmez; sayfa açılışında ağır hesabı atlar.
final tahvilFirePreviewProvider = Provider<analysis_calc.TahvilFirePreview?>((ref) {
  final batch = ref.watch(mergedAnalysisBatchProvider);
  if (batch == null || batch.pieceLines.isEmpty || batch.isOptimized) {
    return null;
  }
  try {
    return analysis_calc.estimateTahvilFirePreview(batch);
  } catch (_) {
    return null;
  }
});

final optimumFireAnalysisProgressProvider =
    StateProvider<OptimumFireAnalysisProgress>(
  (ref) => OptimumFireAnalysisProgress.idle,
);

final optimumFireAnalysisErrorProvider = StateProvider<String?>((ref) => null);

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
    _syncAnalysisScope();
  }

  void setAnalysisScope(Set<String> scope) {
    final previousKey =
        analysis_calc.analysisScopeKey(_ref.read(selectedAnalysisBatchIdsProvider));
    _ref.read(selectedAnalysisBatchIdsProvider.notifier).state = scope;
    final nextKey = analysis_calc.analysisScopeKey(scope);
    if (nextKey != previousKey) {
      _ref.read(mergedAnalysisSessionProvider.notifier).state = null;
      _ref.read(optimumFireAnalysisProgressProvider.notifier).state =
          OptimumFireAnalysisProgress.idle;
      _ref.read(optimumFireAnalysisErrorProvider.notifier).state = null;
    }
  }

  void _syncAnalysisScope() {
    Future.microtask(() {
      final batches = state.batches;
      final scopeNotifier = _ref.read(selectedAnalysisBatchIdsProvider.notifier);
      final current = _ref.read(selectedAnalysisBatchIdsProvider);
      final allIds = batches.map((batch) => batch.id).toSet();

      if (batches.isEmpty) {
        scopeNotifier.state = {};
        _ref.read(mergedAnalysisSessionProvider.notifier).state = null;
        return;
      }

      if (current.isEmpty) {
        scopeNotifier.state = allIds;
        return;
      }

      final pruned = current.intersection(allIds);
      final added = allIds.difference(current);
      final next = {...pruned, ...added};
      if (next != current) {
        setAnalysisScope(next);
      }
    });
  }

  CuttingBendingBatch? _mergedBatchForScope() {
    return _ref.read(mergedAnalysisBatchProvider);
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
    _syncAnalysisScope();
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
    final merged = _mergedBatchForScope();
    if (projectId == null || merged == null || merged.pieceLines.isEmpty) {
      return;
    }

    final progressNotifier =
        _ref.read(optimumFireAnalysisProgressProvider.notifier);
    final batchId = merged.id;
    final scopeKey = analysis_calc.analysisScopeKey(
      _ref.read(selectedAnalysisBatchIdsProvider),
    );

    progressNotifier.state = OptimumFireAnalysisProgress(
      batchId: batchId,
      isRunning: true,
      percent: 0,
      stepLabel: 'Analiz başlatılıyor...',
    );
    _ref.read(optimumFireAnalysisErrorProvider.notifier).state = null;

    try {
      DateTime? lastUiUpdate;
      var lastReportedPercent = -1;
      final updated = await analysis_calc.runOptimumFireAnalysis(
        merged,
        strategy: _ref.read(selectedFireReductionStrategyProvider),
        onProgress: (percent, stepLabel) async {
          final now = DateTime.now();
          if (percent < 100 &&
              lastUiUpdate != null &&
              now.difference(lastUiUpdate!) <
                  const Duration(milliseconds: 250) &&
              (percent - lastReportedPercent).abs() < 3) {
            return;
          }
          lastUiUpdate = now;
          lastReportedPercent = percent;
          progressNotifier.state = OptimumFireAnalysisProgress(
            batchId: batchId,
            isRunning: true,
            percent: percent,
            stepLabel: stepLabel,
          );
          if (kIsWeb) {
            await Future<void>.delayed(const Duration(milliseconds: 16));
          }
        },
      );

      await Future<void>.delayed(
        kIsWeb ? const Duration(milliseconds: 32) : Duration.zero,
      );

      _ref.read(mergedAnalysisSessionProvider.notifier).state =
          MergedAnalysisSession(scopeKey: scopeKey, batch: updated);

      await Future<void>.delayed(
        kIsWeb ? const Duration(milliseconds: 32) : Duration.zero,
      );

      progressNotifier.state = OptimumFireAnalysisProgress(
        batchId: batchId,
        isCompleted: true,
        percent: 100,
        stepLabel: 'Fire analizi tamamlandı',
      );

      _ref.read(selectedFireReductionStrategyProvider.notifier).state =
          FireReductionStrategy.lengthMatchOnly;

      await Future<void>.delayed(const Duration(seconds: 4));
      final current = _ref.read(optimumFireAnalysisProgressProvider);
      if (current.batchId == batchId && current.isCompleted) {
        progressNotifier.state = OptimumFireAnalysisProgress.idle;
      }
    } catch (e) {
      progressNotifier.state = OptimumFireAnalysisProgress.idle;
      _ref.read(optimumFireAnalysisErrorProvider.notifier).state =
          'Analiz tamamlanamadı. Veri çok büyük olabilir; tekrar deneyin.';
      if (kDebugMode) {
        debugPrint('runOptimumFireAnalysis failed: $e');
      }
    }
  }

  Future<void> saveAnalysisResult() async {
    final scopeKey = analysis_calc.analysisScopeKey(
      _ref.read(selectedAnalysisBatchIdsProvider),
    );
    final session = _ref.read(mergedAnalysisSessionProvider);
    if (session == null ||
        session.scopeKey != scopeKey ||
        !session.batch.isOptimized ||
        session.batch.optimizationStrategy == null) {
      return;
    }

    final saved = analysis_calc.saveOptimizationSnapshot(session.batch);
    _ref.read(mergedAnalysisSessionProvider.notifier).state =
        MergedAnalysisSession(scopeKey: scopeKey, batch: saved);
  }

  Future<void> selectAnalysisStrategy(FireReductionStrategy strategy) async {
    // Analiz yalnız minimum fire / zayiatsız kesim (boy eşleştirme).
    const effective = FireReductionStrategy.lengthMatchOnly;
    _ref.read(selectedFireReductionStrategyProvider.notifier).state = effective;

    final merged = _mergedBatchForScope();
    if (merged == null) return;

    if (merged.optimizationStrategy == effective && merged.isOptimized) {
      return;
    }

    final scopeKey = analysis_calc.analysisScopeKey(
      _ref.read(selectedAnalysisBatchIdsProvider),
    );

    if (merged.hasSavedOptimization(effective)) {
      final applied = analysis_calc.applyOptimizationSnapshot(
        merged,
        merged.savedOptimizations[effective]!,
      );
      _ref.read(mergedAnalysisSessionProvider.notifier).state =
          MergedAnalysisSession(scopeKey: scopeKey, batch: applied);
      return;
    }

    if (merged.isOptimized || merged.optimizationStrategy != null) {
      final cleared = analysis_calc.clearActiveOptimization(merged);
      _ref.read(mergedAnalysisSessionProvider.notifier).state =
          MergedAnalysisSession(scopeKey: scopeKey, batch: cleared);
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
    _ref.read(mergedAnalysisSessionProvider.notifier).state = null;
    state = CuttingBendingState(
      batches: remaining,
      activeBatchId: nextActiveId,
    );
    _syncAnalysisScope();
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
