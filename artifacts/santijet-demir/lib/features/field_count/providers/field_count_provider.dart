import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/repositories/field_count_repository.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/features/field_count/field_count_calculator.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/shell/project_progress_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

final fieldCountRepositoryProvider = Provider<FieldCountRepository>((ref) {
  return FieldCountRepository(ref.watch(projectDataRepositoryProvider));
});

final fieldCountsProvider =
    StateNotifierProvider<FieldCountsNotifier, List<FieldCountRecord>>((ref) {
  final notifier = FieldCountsNotifier(ref);
  ref.listen(activeProjectIdProvider, (previous, next) {
    if (previous != next) {
      notifier.loadForProject(next);
    }
  });
  return notifier;
});

class FieldCountsNotifier extends StateNotifier<List<FieldCountRecord>> {
  FieldCountsNotifier(this._ref) : super(const []) {
    loadForProject(_ref.read(activeProjectIdProvider));
  }

  final Ref _ref;
  String? _loadedProjectId;

  FieldCountRepository get _repo => _ref.read(fieldCountRepositoryProvider);

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

  Future<FieldCountRecord?> addRecord({
    required NewCountDraft draft,
    required List<CountDiameterLine> lines,
  }) async {
    if (lines.isEmpty) return null;

    final hasAnyCount = lines.any((line) => line.actual > 0);
    if (!hasAnyCount) return null;

    final lineRecords =
        lines.map(FieldCountLineRecord.fromCountLine).toList();
    final expected =
        lines.fold(0.0, (sum, line) => sum + line.expectedStock);
    final actual = lines.fold(0.0, (sum, line) => sum + line.actual);
    final region = draft.region.trim();
    final personnel = draft.personnel.trim();

    final record = FieldCountRecord(
      id: 'count-${DateTime.now().millisecondsSinceEpoch}',
      title: region.isNotEmpty ? region : 'Saha Sayımı',
      date: draft.date ?? DateTime.now(),
      personnel: personnel,
      region: region,
      expected: expected,
      actual: actual,
      status: computeFieldCountStatus(lineRecords),
      lines: lineRecords,
    );

    state = [record, ...state];
    await _persist();
    return record;
  }
}

final reconciliationFilterProvider = StateProvider<int>((ref) => 0);

/// Ana sayfa ilerleme satırlarından türetilen çap bazında planlanan kullanım.
/// Sayım ekranı BEKLENEN = teslim − bu değer.
final plannedUsageByDiameterProvider = Provider<Map<int, double>>((ref) {
  final rows = buildProjectProgressRows(ref.watch(surveyProjectProvider).imalats);
  return aggregatePlannedUsageByDiameter(rows);
});

/// Gelen demir teslimatlarından çap bazında toplam teslim miktarları.
final deliveredDiametersForCountProvider = Provider<Map<int, double>>((ref) {
  final deliveries = ref.watch(deliveriesProvider);
  final surveyDiameters = surveyDiametersFromImalats(
    ref.watch(surveyProjectProvider).imalats,
  );
  final totals = <int, double>{};

  for (final delivery in deliveries) {
    for (final line in delivery.diameterLines) {
      if (!surveyDiameters.contains(line.diameter)) continue;
      if (line.delivered <= 0) continue;
      totals[line.diameter] = (totals[line.diameter] ?? 0) + line.delivered;
    }
  }

  return Map.fromEntries(
    totals.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
});

/// Planlanan kullanıma göre çap bazında beklenen stok.
final expectedStockByDiameterProvider = Provider<Map<int, double>>((ref) {
  final delivered = ref.watch(deliveredDiametersForCountProvider);
  final plannedUsage = ref.watch(plannedUsageByDiameterProvider);

  return computeExpectedStockByDiameter(
    deliveredByDiameter: delivered,
    plannedUsageByDiameter: plannedUsage,
  );
});

class FieldCountDashboardSummary {
  const FieldCountDashboardSummary({
    required this.survey,
    required this.ordered,
    required this.delivered,
    required this.plannedUsage,
    required this.plannedStock,
    required this.fieldCount,
    required this.actualUsage,
    required this.fire,
  });

  final double survey;
  final double ordered;
  final double delivered;
  final double plannedUsage;
  final double plannedStock;
  final double fieldCount;
  final double actualUsage;
  final double fire;

  factory FieldCountDashboardSummary.fromRows(List<ReconciliationRow> rows) {
    final totals = computeReconciliationTotals(rows);
    return FieldCountDashboardSummary(
      survey: totals.survey,
      ordered: totals.ordered,
      delivered: totals.delivered,
      plannedUsage: totals.plannedUsage,
      plannedStock: totals.plannedStock,
      fieldCount: totals.fieldCount,
      actualUsage: totals.actualUsage,
      fire: totals.fire,
    );
  }
}

final fieldCountDashboardSummaryProvider =
    Provider<FieldCountDashboardSummary>((ref) {
  final rows = ref.watch(reconciliationRowsProvider);
  return FieldCountDashboardSummary.fromRows(rows);
});

final reconciliationRowsProvider = Provider<List<ReconciliationRow>>((ref) {
  final imalats = ref.watch(surveyProjectProvider).imalats;
  final deliveries = ref.watch(deliveriesProvider);
  final orders = ref.watch(ordersProvider);
  final plannedUsage = ref.watch(plannedUsageByDiameterProvider);
  final surveyDiameters = surveyDiametersFromImalats(imalats);
  final delivered = computeDeliveredByDiameterFromDeliveries(
    deliveries,
    limitToDiameters: surveyDiameters.isEmpty ? null : surveyDiameters,
  );
  final expectedStock = computeExpectedStockByDiameter(
    deliveredByDiameter: delivered,
    plannedUsageByDiameter: plannedUsage,
  );
  final deliveryOrdered = computeOrderedByDiameterFromDeliveries(
    deliveries,
    limitToDiameters: surveyDiameters.isEmpty ? null : surveyDiameters,
  );
  final orderOrdered = computeOrderedByDiameterFromOrders(orders, imalats);
  final latestCount = ref.watch(fieldCountsProvider).firstOrNull;
  final countedByDiameter = {
    for (final line in latestCount?.lines ?? const <FieldCountLineRecord>[])
      line.diameter: line.actual,
  };
  final usedByDiameter = {
    for (final line in latestCount?.lines ?? const <FieldCountLineRecord>[])
      line.diameter: line.actualUsed,
  };

  return buildReconciliationRows(
    imalats: imalats,
    deliveredByDiameter: delivered,
    plannedUsageByDiameter: plannedUsage,
    expectedStockByDiameter: expectedStock,
    countedByDiameter: countedByDiameter,
    usedByDiameter: usedByDiameter,
    orderedByDiameterFromDeliveries: deliveryOrdered,
    orderedByDiameterFromOrders: orderOrdered,
  );
});

final filteredReconciliationProvider = Provider<List<ReconciliationRow>>((ref) {
  final rows = ref.watch(reconciliationRowsProvider);
  final filterIndex = ref.watch(reconciliationFilterProvider);

  if (filterIndex == 0) return rows;

  const statusMap = ['', 'normal', 'warning', 'critical'];
  if (filterIndex < 0 || filterIndex >= statusMap.length) return rows;

  final status = statusMap[filterIndex];
  return rows.where((r) => r.status == status).toList();
});

final countDiameterLinesProvider = Provider<List<CountDiameterLine>>((ref) {
  final draft = ref.watch(newCountDraftProvider);
  final delivered = ref.watch(deliveredDiametersForCountProvider);
  final plannedUsage = ref.watch(plannedUsageByDiameterProvider);
  final expectedStock = ref.watch(expectedStockByDiameterProvider);

  return delivered.entries
      .map(
        (entry) => CountDiameterLine(
          diameter: entry.key,
          delivered: entry.value,
          plannedUsage: plannedUsage[entry.key] ?? 0,
          expectedStock: expectedStock[entry.key] ?? entry.value,
          actual: draft.diameterEntries[entry.key] ?? 0,
        ),
      )
      .toList();
});

final newCountDraftProvider =
    StateNotifierProvider<NewCountDraftNotifier, NewCountDraft>(
  (ref) => NewCountDraftNotifier(ref),
);

class NewCountDraftNotifier extends StateNotifier<NewCountDraft> {
  NewCountDraftNotifier(this._ref) : super(NewCountDraft(date: DateTime.now()));

  final Ref _ref;

  void syncFromSources() {
    final delivered = _ref.read(deliveredDiametersForCountProvider);
    final expectedStock = _ref.read(expectedStockByDiameterProvider);
    final previousActual = state.diameterEntries;

    state = state.copyWith(
      expectedByDiameter: {
        for (final entry in delivered.entries)
          entry.key: expectedStock[entry.key] ?? entry.value,
      },
      diameterEntries: {
        for (final entry in delivered.entries)
          entry.key: previousActual[entry.key] ?? 0,
      },
    );
  }

  void setPersonnel(String value) {
    state = state.copyWith(personnel: value);
  }

  void setRegion(String value) {
    state = state.copyWith(region: value);
  }

  void setActualCount(int diameter, double actual) {
    final delivered = _ref.read(deliveredDiametersForCountProvider);
    if (!delivered.containsKey(diameter)) return;

    final updated = Map<int, double>.from(state.diameterEntries);
    updated[diameter] = actual;

    state = state.copyWith(diameterEntries: updated);
  }

  Future<FieldCountRecord?> completeCount(List<CountDiameterLine> lines) async {
    final record = await _ref.read(fieldCountsProvider.notifier).addRecord(
          draft: state,
          lines: lines,
        );
    reset();
    return record;
  }

  void reset() {
    state = NewCountDraft(date: DateTime.now());
    syncFromSources();
  }
}
