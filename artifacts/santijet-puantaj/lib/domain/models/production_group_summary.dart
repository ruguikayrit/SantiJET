import '../../core/utils/puantaj_date.dart';
import '../entities/production.dart';
import 'production_metrics.dart';
import 'production_team_group.dart';

/// Grup özeti — ekip adı bazında; yalnızca süre ve adam-gün (metraj yok).
class ProductionGroupSummary {
  const ProductionGroupSummary({
    required this.teamKey,
    required this.title,
    required this.itemCount,
    required this.axes,
    required this.updatedToday,
  });

  final String teamKey;
  final String title;
  final int itemCount;
  final List<ProductionProgressAxis> axes;
  final bool updatedToday;

  static List<ProductionGroupSummary> fromProductions(List<Production> items) {
    if (items.isEmpty) return const [];

    final byTeam = <String, List<Production>>{};
    for (final p in items) {
      final key = ProductionTeamGroup.teamOnlyKey(p);
      byTeam.putIfAbsent(key, () => []).add(p);
    }

    bool updatedToday(List<Production> teamItems) {
      final today = PuantajDate.today();
      return teamItems.any(
        (p) => p.dailyEntries.any((e) => e.date.trim() == today),
      );
    }

    final summaries = <ProductionGroupSummary>[];
    for (final entry in byTeam.entries) {
      final teamItems = entry.value;
      var plannedDays = 0.0;
      var workedDays = 0.0;
      var plannedAg = 0.0;
      var actualAg = 0.0;

      for (final p in teamItems) {
        final m = p.metrics;
        if (m.sure.hasPlan) plannedDays += m.sure.planned;
        workedDays += m.sure.actual;
        if (m.labor.hasPlan) plannedAg += m.labor.planned;
        actualAg += m.labor.actual;
      }

      summaries.add(
        ProductionGroupSummary(
          teamKey: entry.key,
          title: ProductionTeamGroup.teamOnlyCardTitle(entry.key),
          itemCount: teamItems.length,
          updatedToday: updatedToday(teamItems),
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
