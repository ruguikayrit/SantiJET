import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/hareket_filters.dart';
import '../domain/kasa_hareket.dart';
import 'hareketler_store.dart';

class HareketFiltersNotifier extends StateNotifier<HareketFilters> {
  HareketFiltersNotifier() : super(const HareketFilters());

  void setQuery(String query) => state = state.copyWith(query: query);

  void setSantiye(String? value) => state = value == null
      ? state.copyWith(clearSantiye: true)
      : state.copyWith(santiye: value);

  void setTedarikci(String? value) => state = value == null
      ? state.copyWith(clearTedarikci: true)
      : state.copyWith(tedarikci: value);

  void setOdemeSekli(String? value) => state = value == null
      ? state.copyWith(clearOdemeSekli: true)
      : state.copyWith(odemeSekli: value);

  void setBelgeTuru(String? value) => state = value == null
      ? state.copyWith(clearBelgeTuru: true)
      : state.copyWith(belgeTuru: value);

  void setOnlyGelir(bool value) =>
      state = state.copyWith(onlyGelir: value, onlyGider: value ? false : state.onlyGider);

  void setOnlyGider(bool value) =>
      state = state.copyWith(onlyGider: value, onlyGelir: value ? false : state.onlyGelir);

  void setDateRange({DateTime? from, DateTime? to}) {
    state = state.copyWith(
      from: from,
      to: to,
      clearFrom: from == null,
      clearTo: to == null,
    );
  }

  void clear() => state = const HareketFilters();
}

final hareketFiltersProvider =
    StateNotifierProvider<HareketFiltersNotifier, HareketFilters>(
  (ref) => HareketFiltersNotifier(),
);

final filteredHareketlerProvider = Provider<List<KasaHareket>>((ref) {
  final all = ref.watch(hareketlerProvider);
  final filters = ref.watch(hareketFiltersProvider);
  return filterHareketler(all, filters);
});
