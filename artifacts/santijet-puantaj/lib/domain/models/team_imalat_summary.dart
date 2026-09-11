import '../../core/utils/puantaj_date.dart';
import '../entities/production.dart';
import 'production_metrics.dart';

/// İmalat sekmesi — ekip bazında kümülatif metraj · süre · adam-gün özeti.
class TeamImalatSummary {
  const TeamImalatSummary({
    required this.teamName,
    required this.imalatCount,
    required this.axes,
    required this.updatedToday,
  });

  final String teamName;
  final int imalatCount;
  final List<ProductionProgressAxis> axes;
  final bool updatedToday;

  static String teamKey(Production p) {
    final t = p.teamName.trim();
    return t.isEmpty ? 'Ekip seçilmedi' : t;
  }

  static List<TeamImalatSummary> fromProductions(List<Production> items) {
    if (items.isEmpty) return const [];

    final byTeam = <String, List<Production>>{};
    for (final p in items) {
      byTeam.putIfAbsent(teamKey(p), () => []).add(p);
    }

    bool updatedToday(List<Production> teamItems) {
      final today = PuantajDate.today();
      return teamItems.any(
        (p) => p.dailyEntries.any((e) => e.date.trim() == today),
      );
    }

    String unitLabel(List<Production> teamItems) {
      final units = teamItems
          .map((p) => p.unit.trim())
          .where((u) => u.isNotEmpty)
          .toSet();
      if (units.length == 1) return units.single;
      return '';
    }

    final summaries = <TeamImalatSummary>[];
    for (final entry in byTeam.entries) {
      final teamItems = entry.value;
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

      final unit = unitLabel(teamItems);
      summaries.add(
        TeamImalatSummary(
          teamName: entry.key,
          imalatCount: teamItems.length,
          updatedToday: updatedToday(teamItems),
          axes: [
            ProductionProgressAxis(
              label: 'Metraj',
              planned: plannedQty,
              actual: actualQty,
              unit: unit,
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
