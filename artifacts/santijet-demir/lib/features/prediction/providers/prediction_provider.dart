import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/repositories/prediction_repository.dart';
import 'package:santijet_demir/domain/entities/prediction_models.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/orders/providers/supplier_provider.dart';
import 'package:santijet_demir/features/prediction/prediction_engine.dart';
import 'package:santijet_demir/features/prediction/providers/work_schedule_provider.dart';
import 'package:santijet_demir/features/prediction/providers/workforce_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  return PredictionRepository(ref.watch(projectDataRepositoryProvider));
});

final predictionConfigProvider =
    StateNotifierProvider<PredictionConfigNotifier, PredictionConfig>((ref) {
  final notifier = PredictionConfigNotifier(ref);
  ref.listen(activeProjectIdProvider, (previous, next) {
    if (previous != next) notifier.loadForProject(next);
  });
  return notifier;
});

class PredictionConfigNotifier extends StateNotifier<PredictionConfig> {
  PredictionConfigNotifier(this._ref) : super(const PredictionConfig()) {
    loadForProject(_ref.read(activeProjectIdProvider));
  }

  final Ref _ref;
  String? _projectId;

  PredictionRepository get _repo => _ref.read(predictionRepositoryProvider);

  void loadForProject(String? projectId) {
    _projectId = projectId;
    if (projectId == null) {
      state = const PredictionConfig();
      return;
    }
    state = _repo.readConfig(projectId);
  }

  Future<void> update(PredictionConfig config) async {
    state = config;
    final id = _projectId;
    if (id != null) await _repo.writeConfig(id, config);
  }
}

final predictionHistoryProvider = Provider<List<PredictionHistoryEntry>>((ref) {
  final projectId = ref.watch(activeProjectIdProvider);
  if (projectId == null) return const [];
  ref.watch(predictionHistoryTickProvider);
  return ref.read(predictionRepositoryProvider).readHistory(projectId);
});

/// History yenileme tetikleyicisi.
final predictionHistoryTickProvider = StateProvider<int>((ref) => 0);

final predictionEngineProvider = Provider<PredictionEngine>((ref) {
  return const PredictionEngine();
});

/// Canlı tahmin — kaynaklar değişince yeniden hesaplanır.
final predictionSnapshotProvider = Provider<PredictionSnapshot?>((ref) {
  final projectId = ref.watch(activeProjectIdProvider);
  if (projectId == null) return null;

  final config = ref.watch(predictionConfigProvider);
  final survey = ref.watch(surveyProjectProvider);
  final counts = ref.watch(fieldCountsProvider);
  final schedule = ref.watch(workScheduleDaysProvider);
  final workforce = ref.watch(workforceProvider);
  final orders = ref.watch(ordersProvider);
  final deliveries = ref.watch(deliveriesProvider);
  final suppliers = ref.watch(supplierOptionsProvider);

  final leadDays = suppliers.isEmpty
      ? 7
      : (suppliers.map((s) => s.deliveryDays).fold<int>(0, (a, b) => a + b) /
              suppliers.length)
          .round()
          .clamp(1, 60);

  return ref.read(predictionEngineProvider).run(
        projectId: projectId,
        config: config,
        survey: survey,
        fieldCounts: counts,
        scheduleDays: schedule,
        workforce: workforce,
        orders: orders,
        deliveries: deliveries,
        supplierLeadDays: leadDays,
      );
});

Future<void> persistPredictionSnapshot(WidgetRef ref) async {
  final projectId = ref.read(activeProjectIdProvider);
  final snapshot = ref.read(predictionSnapshotProvider);
  if (projectId == null || snapshot == null || !snapshot.canPredict) return;

  final config = ref.read(predictionConfigProvider);
  final repo = ref.read(predictionRepositoryProvider);
  await repo.appendHistory(
    projectId,
    PredictionHistoryEntry(snapshot: snapshot),
    limit: config.historyLimit,
  );
  ref.read(predictionHistoryTickProvider.notifier).state++;
}
