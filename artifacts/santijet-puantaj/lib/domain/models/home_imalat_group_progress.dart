import '../catalogs/production_work_group.dart';
import '../catalogs/task_tags.dart';
import '../entities/production.dart';

/// Ana sayfa — disiplin kartı (Süre · Metraj · Adam-gün ilerleme %).
class HomeImalatGroupProgress {
  const HomeImalatGroupProgress({
    required this.groupKey,
    required this.title,
    required this.totalImalatCount,
    required this.includedCount,
    this.sureDisplayPct,
    this.metrajDisplayPct,
    this.laborDisplayPct,
  });

  final String groupKey;
  final String title;
  final int totalImalatCount;
  final int includedCount;
  final double? sureDisplayPct;
  final double? metrajDisplayPct;
  final double? laborDisplayPct;

  int get excludedCount => totalImalatCount - includedCount;

  bool get hasExcludedImalats => excludedCount > 0;

  /// Plan metraj, plan süre ve plan adam-gün tanımlı imalatlar.
  static bool isEligible(Production p) {
    return p.plannedQty > 0 && p.plannedDays > 0 && p.plannedWorkerDays > 0;
  }

  static List<HomeImalatGroupProgress> fromProductions(List<Production> items) {
    final byGroup = <String, List<Production>>{};
    for (final p in items) {
      final key = ProductionWorkGroupCatalog.resolve(p);
      byGroup.putIfAbsent(key, () => []).add(p);
    }

    final out = <HomeImalatGroupProgress>[];
    for (final tag in TaskTagCatalog.all) {
      final groupItems = byGroup[tag] ?? const [];
      out.add(_compute(tag, groupItems));
    }
    return out;
  }

  static HomeImalatGroupProgress _compute(
    String groupKey,
    List<Production> groupItems,
  ) {
    final title = ProductionWorkGroupCatalog.displayTitle(groupKey);
    final total = groupItems.length;
    final eligible = groupItems.where(isEligible).toList(growable: false);

    if (eligible.isEmpty) {
      return HomeImalatGroupProgress(
        groupKey: groupKey,
        title: title,
        totalImalatCount: total,
        includedCount: 0,
      );
    }

    var planDays = 0.0;
    var workedDays = 0.0;
    var planAg = 0.0;
    var actualAg = 0.0;
    for (final p in eligible) {
      planDays += p.plannedDays.toDouble();
      workedDays += p.workedDays.toDouble();
      planAg += p.plannedWorkerDays;
      actualAg += p.actualLaborDays;
    }

    final totalPlanAg = planAg;
    var metrajWeighted = 0.0;
    for (final p in eligible) {
      final w = p.plannedWorkerDays / totalPlanAg;
      final ratio = p.completedQty / p.plannedQty;
      metrajWeighted += w * ratio;
    }

    return HomeImalatGroupProgress(
      groupKey: groupKey,
      title: title,
      totalImalatCount: total,
      includedCount: eligible.length,
      sureDisplayPct: planDays > 0 ? (workedDays / planDays) * 100 : null,
      metrajDisplayPct: metrajWeighted * 100,
      laborDisplayPct: planAg > 0 ? (actualAg / planAg) * 100 : null,
    );
  }
}
