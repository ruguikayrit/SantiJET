import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/tr_search.dart';
import '../../domain/entities/poz_analiz.dart';
import '../../domain/enums/app_enums.dart';
import '../datasources/catalog_local_datasource.dart';

/// Yüklenmiş resmi katalog verisi (disipline göre + düz liste + id indeksi).
class CatalogData {
  CatalogData({required this.byDiscipline})
      : all = [
          ...?byDiscipline[AnalizDiscipline.insaat],
          ...?byDiscipline[AnalizDiscipline.mekanik],
          ...?byDiscipline[AnalizDiscipline.elektrik],
        ],
        byId = {
          for (final list in byDiscipline.values)
            for (final a in list) a.id: a,
        };

  final Map<AnalizDiscipline, List<PozAnaliz>> byDiscipline;
  final List<PozAnaliz> all;
  final Map<String, PozAnaliz> byId;

  int countFor(AnalizDiscipline d) => byDiscipline[d]?.length ?? 0;

  PozAnaliz? byIdOrNull(String id) => byId[id];

  /// TR arama (AND). Sonuç poz numarasına göre sıralanır, [limit] ile sınırlanır.
  List<PozAnaliz> search(String query, {int? limit}) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final results = all.where((a) => TrSearch.matches(a, q)).toList()
      ..sort((a, b) => a.pozNo.compareTo(b.pozNo));
    if (limit != null && results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }

  List<PozAnaliz> forDiscipline(AnalizDiscipline d) =>
      byDiscipline[d] ?? const [];
}

final catalogDataSourceProvider = Provider<CatalogLocalDataSource>(
  (ref) => const CatalogLocalDataSource(),
);

/// Resmi katalog (13.436 kayıt) — assets'ten bir kez yüklenir.
final catalogProvider = FutureProvider<CatalogData>((ref) async {
  final ds = ref.watch(catalogDataSourceProvider);
  final byDiscipline = await ds.loadAll();
  return CatalogData(byDiscipline: byDiscipline);
});
