import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/enums/request_status.dart';
import '../../../data/providers/app_data_provider.dart';

final requestFilterProvider = StateProvider<int>((ref) => 0);

const requestFilterLabels = [
  'Tümü',
  'Beklemede',
  'Onaylandı',
  'Teslim Edildi',
  'Reddedildi',
];

const _filterStatuses = [
  RequestStatus.pending,
  RequestStatus.approved,
  RequestStatus.delivered,
  RequestStatus.rejected,
];

final requestFilterLabelsProvider = Provider<List<String>>((ref) {
  return requestFilterLabels;
});

final filteredRequestsProvider = Provider<List<MaterialRequest>>((ref) {
  final requests = ref.watch(activeRequestsProvider);
  final filterIndex = ref.watch(requestFilterProvider);
  if (filterIndex == 0) return requests;
  if (filterIndex < 1 || filterIndex > _filterStatuses.length) return requests;
  final status = _filterStatuses[filterIndex - 1];
  return requests.where((r) => r.status == status).toList();
});
