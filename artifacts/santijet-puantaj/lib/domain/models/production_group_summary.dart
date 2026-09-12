import '../../core/utils/puantaj_date.dart';
import '../catalogs/production_work_group.dart';
import '../catalogs/task_tags.dart';
import '../entities/production.dart';
import 'production_metrics.dart';

/// Grup özeti — İnşaat / Elektrik / Mekanik; yalnızca süre ve adam-gün.
class ProductionGroupSummary {
  const ProductionGroupSummary({
    required this.groupKey,
    required this.title,
    required this.itemCount,
    required this.axes,
    required this.updatedToday,
  });

  final String groupKey;
  final String title;
  final int itemCount;
  final List<ProductionProgressAxis> axes;
  final bool updatedToday;

  static List<ProductionGroupSummary> fromProductions(List<Production> items) {
    if (items.isEmpty) return const [];

    final byGroup = <String, List<Production>>{};
    for (final p in items) {
      final key = ProductionWorkGroupCatalog.resolve(p);
      byGroup.putIfAbsent(key, () => []).add(p);
    }

    bool updatedToday(List<Production> groupItems) {
      final today = PuantajDate.today();
      return groupItems.any(
        (p) => p.dailyEntries.any((e) => e.date.trim() == today),
      );
    }

    final summaries = <ProductionGroupSummary>[];
    for (final entry in byGroup.entries) {
      final groupItems = entry.value;
      var plannedDays = 0.0;
      var workedDays = 0.0;
      var plannedAg = 0.0;
      var actualAg = 0.0;

      for (final p in groupItems) {
        final m = p.metrics;
        if (m.sure.hasPlan) plannedDays += m.sure.planned;
        workedDays += m.sure.actual;
        if (m.labor.hasPlan) plannedAg += m.labor.planned;
        actualAg += m.labor.actual;
      }

      summaries.add(
        ProductionGroupSummary(
          groupKey: entry.key,
          title: ProductionWorkGroupCatalog.displayTitle(entry.key),
          itemCount: groupItems.length,
          updatedToday: updatedToday(groupItems),
          axes: [
            ProductionProgressAxis(
              label: 'Süre',
              planned: plannedDays,
              actual: workedDays,
              unit: 'gün',
            ),
            ProductionProgressAxis(
              label: 'Adam-gün',
              planned: plannedAg,
              actual: actualAg,
              unit: 'adam-gün',
            ),
          ],
        ),
      );
    }

    summaries.sort((a, b) {
      final ai = TaskTagCatalog.all.indexOf(a.groupKey);
      final bi = TaskTagCatalog.all.indexOf(b.groupKey);
      if (ai >= 0 && bi >= 0 && ai != bi) return ai.compareTo(bi);
      if (a.updatedToday != b.updatedToday) {
        return a.updatedToday ? -1 : 1;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return summaries;
  }

  static List<ProductionGroupSummary> fromVerimRows(
    Iterable<Production> productions,
  ) =>
      fromProductions(productions.toList());
}
