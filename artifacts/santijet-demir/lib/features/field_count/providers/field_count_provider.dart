import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/mock/mock_field_counts.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';

final reconciliationRowsProvider = Provider<List<ReconciliationRow>>((ref) {
  return getMockReconciliationRows();
});

final fieldCountsProvider = Provider<List<FieldCountRecord>>((ref) {
  return getMockFieldCounts();
});

final reconciliationFilterProvider = StateProvider<int>((ref) => 0);

final filteredReconciliationProvider = Provider<List<ReconciliationRow>>((ref) {
  final rows = ref.watch(reconciliationRowsProvider);
  final filterIndex = ref.watch(reconciliationFilterProvider);

  if (filterIndex == 0) return rows;

  final statusMap = ['', 'normal', 'warning', 'critical'];
  final status = statusMap[filterIndex];
  return rows.where((r) => r.status == status).toList();
});

final newCountDraftProvider =
    StateNotifierProvider<NewCountDraftNotifier, NewCountDraft>(
  (ref) => NewCountDraftNotifier(),
);

class NewCountDraftNotifier extends StateNotifier<NewCountDraft> {
  NewCountDraftNotifier() : super(NewCountDraft(date: DateTime.now()));

  void setPersonnel(String value) {
    state = state.copyWith(personnel: value);
  }

  void setRegion(String value) {
    state = state.copyWith(region: value);
  }

  void setDiameterEntry(int diameter, double expected, double actual) {
    final updated = Map<int, double>.from(state.diameterEntries);
    updated[diameter] = actual;
    state = state.copyWith(diameterEntries: updated);
  }

  void reset() {
    state = NewCountDraft(date: DateTime.now());
  }
}
