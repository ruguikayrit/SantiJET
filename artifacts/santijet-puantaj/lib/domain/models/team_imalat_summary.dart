import '../../core/utils/puantaj_date.dart';
import '../entities/production.dart';
import 'production_metrics.dart';
import 'production_team_group.dart';

/// İmalat sekmesi — ekip + metraj birimi bazında kümülatif özet.
class TeamImalatSummary {
  const TeamImalatSummary({
    required this.groupKey,
    required this.teamName,
    required this.unit,
    required this.imalatCount,
    required this.axes,
    required this.updatedToday,
  });

  final String groupKey;
  final String teamName;
  final String unit;
  final int imalatCount;
  final List<ProductionProgressAxis> axes;
  final bool updatedToday;

  static String teamKey(Production p) =>
      ProductionTeamGroup.fromProduction(p).groupKey;

  static List<TeamImalatSummary> fromProductions(List<Production> items) {
    if (items.isEmpty) return const [];

    final byGroup = <String, List<Production>>{};
    for (final p in items) {
      final key = teamKey(p);
      byGroup.putIfAbsent(key, () => []).add(p);
    }

    bool updatedToday(List<Production> teamItems) {
      final today = PuantajDate.today();
      return teamItems.any(
        (p) => p.dailyEntries.any((e) => e.date.trim() == today),
      );
    }

    final summaries = <TeamImalatSummary>[];
    for (final entry in byGroup.entries) {
      final teamItems = entry.value;
      final group = ProductionTeamGroup.fromProduction(teamItems.first);

      var plannedQty = 0.0;
      var actualQty = 0.0;
      var plannedDays = 0.0;
      var workedDays = 0.0;
      var plannedAg = 0.0;
      var actualAg = 0.0;

      for (final p in teamItems) {
        final m = p.metrics;
        if (m.metraj.hasPlan) plannedQty += m.metraj.planned;
        actualQty += m.metraj.actual;
        if (m.sure.hasPlan) plannedDays += m.sure.planned;
        workedDays += m.sure.actual;
        if (m.labor.hasPlan) plannedAg += m.labor.planned;
        actualAg += m.labor.actual;
      }

      summaries.add(
        TeamImalatSummary(
          groupKey: entry.key,
          teamName: group.cardTitle,
          unit: group.unit,
          imalatCount: teamItems.length,
          updatedToday: updatedToday(teamItems),
          axes: [
            ProductionProgressAxis(
              label: 'Metraj',
              planned: plannedQty,
              actual: actualQty,
              unit: group.unit,
            ),
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
      return a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase());
    });

    return summaries;
  }
}
