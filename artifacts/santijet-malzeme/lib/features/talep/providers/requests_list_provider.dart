import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/app_data_provider.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/request_status.dart';

/// Demir `orderFilterProvider` — seçili filtre indeksi.
final requestFilterProvider = StateProvider<int>((ref) => 0);

const requestFilterLabels = [
  'Tümü',
  'Taslak',
  'Teklifte',
  'Sipariş',
  'Kısmi',
  'Kapandı',
];

const _filterStatuses = [
  RequestStatus.taslak,
  RequestStatus.teklifte,
  RequestStatus.siparis,
  RequestStatus.kismi,
  RequestStatus.kapandi,
];

final requestFilterLabelsProvider = Provider<List<String>>((ref) {
  return requestFilterLabels;
});

/// Aktif proje talepleri + durum filtresi (Demir `filteredOrdersProvider`).
final filteredRequestsProvider = Provider<List<MaterialRequest>>((ref) {
  final requests = ref.watch(activeRequestsProvider);
  final filterIndex = ref.watch(requestFilterProvider);

  if (filterIndex == 0) return requests;
  if (filterIndex < 1 || filterIndex > _filterStatuses.length) return requests;

  final status = _filterStatuses[filterIndex - 1];
  return requests.where((r) => r.status == status).toList();
});

final requestQuoteRoundProvider =
    Provider.family<QuoteRound?, String>((ref, requestId) {
  final rounds = ref.watch(activeQuoteRoundsProvider);
  for (final r in rounds) {
    if (r.requestId == requestId) return r;
  }
  return null;
});
