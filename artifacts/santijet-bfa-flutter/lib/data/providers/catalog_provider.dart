import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/tr_search.dart';
import '../../domain/entities/poz_analiz.dart';
import '../../domain/enums/app_enums.dart';
import '../datasources/catalog_local_datasource.dart';
import 'user_analiz_provider.dart';

/// Yüklenmiş resmi katalog verisi (disipline göre + düz liste + id indeksi).
class CatalogData {
  CatalogData({required Map<AnalizDiscipline, List<PozAnaliz>> byDiscipline})
      : byDiscipline = {
          for (final d in AnalizDiscipline.values)
            d: _sortByPoz(byDiscipline[d] ?? const []),
        },
        all = _sortByPoz([
          ...?byDiscipline[AnalizDiscipline.insaat],
          ...?byDiscipline[AnalizDiscipline.mekanik],
          ...?byDiscipline[AnalizDiscipline.elektrik],
        ]) {
    byId = {for (final a in all) a.id: a};
    _haystackById = {for (final a in all) a.id: TrSearch.buildHaystack(a)};
    categoriesByDiscipline = {
      for (final d in AnalizDiscipline.values) d: kategoriler(forDiscipline(d)),
    };
    allCategories = kategoriler(all);
  }

  final Map<AnalizDiscipline, List<PozAnaliz>> byDiscipline;
  final List<PozAnaliz> all;
  late final Map<String, PozAnaliz> byId;
  late final Map<String, String> _haystackById;
  late final Map<AnalizDiscipline, List<String>> categoriesByDiscipline;
  late final List<String> allCategories;

  int countFor(AnalizDiscipline d) => byDiscipline[d]?.length ?? 0;

  PozAnaliz? byIdOrNull(String id) => byId[id];

  /// TR arama (AND). Sonuç poz numarasına göre sıralanır, [limit] ile sınırlanır.
  List<PozAnaliz> search(String query, {int? limit}) {
    return searchIn(all, query, limit: limit);
  }

  /// Verilen [source] liste içinde önceden hesaplanmış haystack ile arar.
  ///
  /// [source] zaten poz numarasına göre sıralıysa sonuç da sıralı kalır; tekrar
  /// sort yapılmaz.
  List<PozAnaliz> searchIn(
    List<PozAnaliz> source,
    String query, {
    int? limit,
  }) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final tokens = TrSearch.tokenize(q);
    final results = <PozAnaliz>[];
    for (final a in source) {
      final haystack = _haystackById[a.id] ?? TrSearch.buildHaystack(a);
      if (TrSearch.matchesHaystack(haystack, tokens)) {
        results.add(a);
        if (limit != null && results.length >= limit) break;
      }
    }
    return results;
  }

  List<PozAnaliz> forDiscipline(AnalizDiscipline d) =>
      byDiscipline[d] ?? const [];

  List<String> categoriesForDiscipline(AnalizDiscipline d) =>
      categoriesByDiscipline[d] ?? const [];

  /// Verilen analiz listesindeki kategorileri sıklığa göre sıralı döndürür
  /// (React Native `buildPozKategoriFiltreleri` ile aynı).
  static List<String> kategoriler(List<PozAnaliz> list) {
    final counts = <String, int>{};
    for (final a in list) {
      final k = a.kategori.trim();
      if (k.isEmpty) continue;
      counts[k] = (counts[k] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return entries.map((e) => e.key).toList();
  }

  static List<PozAnaliz> _sortByPoz(List<PozAnaliz> list) {
    return [...list]..sort((a, b) => a.pozNo.compareTo(b.pozNo));
  }
}

final catalogDataSourceProvider = Provider<CatalogLocalDataSource>(
  (ref) => const CatalogLocalDataSource(),
);

/// Resmi katalog (13.436 kayıt) — assets'ten bir kez yüklenir.
final officialCatalogProvider = FutureProvider<CatalogData>((ref) async {
  final ds = ref.watch(catalogDataSourceProvider);
  final byDiscipline = await ds.loadAll();
  return CatalogData(byDiscipline: byDiscipline);
});

/// Resmi katalog + kullanıcı/kopya analizleri.
///
/// Kullanıcı analizleri değiştiğinde bu provider yeniden hesaplanır; resmi
/// katalog FutureProvider cache'inden gelir, tekrar dosya okunmaz.
final catalogProvider = FutureProvider<CatalogData>((ref) async {
  final official = await ref.watch(officialCatalogProvider.future);
  final userAnalizleri = ref.watch(userAnalizProvider);
  if (userAnalizleri.isEmpty) return official;

  final merged = {
    for (final d in AnalizDiscipline.values) d: [...official.forDiscipline(d)],
  };
  for (final analiz in userAnalizleri) {
    final discipline = analiz.discipline ?? AnalizDiscipline.insaat;
    merged[discipline] = [...?merged[discipline], analiz];
  }
  return CatalogData(byDiscipline: merged);
});
