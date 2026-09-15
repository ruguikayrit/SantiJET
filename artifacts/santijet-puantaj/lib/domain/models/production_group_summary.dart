import '../../core/utils/puantaj_date.dart';
import '../catalogs/production_work_group.dart';
import '../catalogs/task_tags.dart';
import '../entities/production.dart';
import 'production_metrics.dart';

/// Grup özeti — İnşaat / Elektrik / Mekanik; süre, adam-gün, birim verim.
class ProductionGroupSummary {
  const ProductionGroupSummary({
    required this.groupKey,
    required this.title,
    required this.itemCount,
    required this.axes,
    required this.updatedToday,
    this.groupUnitEfficiency,
  });

  final String groupKey;
  final String title;
  final int itemCount;
  final List<ProductionProgressAxis> axes;
  final bool updatedToday;

  /// Plan AG ağırlıklı toplu birim verim (metraj ÷ AG, grafikle uyumlu).
  final double? groupUnitEfficiency;

  /// Grup birim verimi — [groupUnitEfficiency] (1.0 = plan).
  double? get groupScheduleLaborEfficiency => groupUnitEfficiency;

  /// Σ plan metraj / Σ plan AG ile gerçekleşenlerden birim verim.
  static double? pooledUnitEfficiency({
    required double plannedQty,
    required double plannedWorkerDays,
    required double actualQty,
    required double actualWorkerDays,
  }) {
    return ProductionMetrics.computeUnitEfficiency(
      plannedQty: plannedQty,
      plannedWorkerDays: plannedWorkerDays,
      actualQty: actualQty,
      actualWorkerDays: actualWorkerDays,
    );
  }

  /// İmalat satırları — plan AG ile ağırlıklı ortalama birim verim.
  static double? weightedUnitEfficiencyFromProductions(
    Iterable<Production> items,
  ) {
    var weightSum = 0.0;
    var weighted = 0.0;
    for (final p in items) {
      final eff = p.metrics.unitEfficiency;
      final w = p.plannedWorkerDays;
      if (eff == null || w <= 0) continue;
      weighted += eff * w;
      weightSum += w;
    }
    if (weightSum <= 0) return null;
    return weighted / weightSum;
  }

  static double? _groupUnitEfficiencyFromTotals({
    required double plannedQty,
    required double plannedWorkerDays,
    required double actualQty,
    required double actualWorkerDays,
  }) {
    return pooledUnitEfficiency(
      plannedQty: plannedQty,
      plannedWorkerDays: plannedWorkerDays,
      actualQty: actualQty,
      actualWorkerDays: actualWorkerDays,
    );
  }

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
      var plannedQty = 0.0;
      var actualQty = 0.0;

      for (final p in groupItems) {
        final m = p.metrics;
        if (m.sure.hasPlan) plannedDays += m.sure.planned;
        workedDays += m.sure.actual;
        if (m.labor.hasPlan) plannedAg += m.labor.planned;
        actualAg += m.labor.actual;
        if (m.metraj.hasPlan) plannedQty += m.metraj.planned;
        actualQty += m.metraj.actual;
      }

      final groupEff = _groupUnitEfficiencyFromTotals(
        plannedQty: plannedQty,
        plannedWorkerDays: plannedAg,
        actualQty: actualQty,
        actualWorkerDays: actualAg,
      ) ??
          weightedUnitEfficiencyFromProductions(groupItems);

      summaries.add(
        ProductionGroupSummary(
          groupKey: entry.key,
          title: ProductionWorkGroupCatalog.displayTitle(entry.key),
          itemCount: groupItems.length,
          updatedToday: updatedToday(groupItems),
          groupUnitEfficiency: groupEff,
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

  /// Haftalık / aylık rapor — yalnızca dönemde kaydı olan imalatlar.
  static List<ProductionGroupSummary> forPeriod(
    List<Production> items,
    Set<String> daySet,
  ) {
    if (items.isEmpty || daySet.isEmpty) return const [];

    final active = <Production>[];
    for (final p in items) {
      if (p.dailyEntries.any((e) => daySet.contains(e.date))) {
        active.add(p);
      }
    }
    if (active.isEmpty) return const [];

    final byGroup = <String, List<Production>>{};
    for (final p in active) {
      final key = ProductionWorkGroupCatalog.resolve(p);
      byGroup.putIfAbsent(key, () => []).add(p);
    }

    bool updatedInPeriod(List<Production> groupItems) {
      return groupItems.any(
        (p) => p.dailyEntries.any((e) => daySet.contains(e.date)),
      );
    }

    double periodWorkedDays(Production p) {
      return p.dailyEntries
          .where((e) => daySet.contains(e.date))
          .map((e) => e.date)
          .toSet()
          .length
          .toDouble();
    }

    double periodLabor(Production p) {
      return p.dailyEntries
          .where((e) => daySet.contains(e.date))
          .fold<double>(0, (s, e) => s + e.laborDays);
    }

    double periodPlannedDays(Production p, double workedInPeriod) {
      final plan = p.plannedDays.toDouble();
      if (plan <= 0) return 0;
      final totalWorked = p.workedDays.toDouble();
      if (totalWorked <= 0) return workedInPeriod.clamp(0, plan);
      return (plan * (workedInPeriod / totalWorked)).clamp(0, plan);
    }

    double periodPlannedAg(Production p, double workedInPeriod) {
      final planAg = p.plannedWorkerDays;
      if (planAg <= 0) return 0;
      final planDays = p.plannedDays.toDouble();
      if (planDays <= 0) return 0;
      return planAg * (workedInPeriod / planDays);
    }

    final summaries = <ProductionGroupSummary>[];
    for (final entry in byGroup.entries) {
      final groupItems = entry.value;
      var plannedDays = 0.0;
      var workedDays = 0.0;
      var plannedAgAxis = 0.0;
      var actualAg = 0.0;
      var plannedQtyEff = 0.0;
      var plannedAgEff = 0.0;
      var actualQtyEff = 0.0;
      var actualAgEff = 0.0;

      for (final p in groupItems) {
        final w = periodWorkedDays(p);
        workedDays += w;
        plannedDays += periodPlannedDays(p, w);
        final labor = periodLabor(p);
        actualAg += labor;
        plannedAgAxis += periodPlannedAg(p, w);
        final periodEntries =
            p.dailyEntries.where((e) => daySet.contains(e.date));
        actualQtyEff += periodEntries.fold<double>(
          0,
          (s, e) => s + e.completedQty,
        );
        actualAgEff += labor;
        if (p.plannedQty > 0 && p.plannedWorkerDays > 0) {
          plannedQtyEff += p.plannedQty;
          plannedAgEff += p.plannedWorkerDays;
        }
      }

      final groupEff = _groupUnitEfficiencyFromTotals(
        plannedQty: plannedQtyEff,
        plannedWorkerDays: plannedAgEff,
        actualQty: actualQtyEff,
        actualWorkerDays: actualAgEff,
      ) ??
          weightedUnitEfficiencyFromProductions(
            groupItems.where(
              (p) => p.dailyEntries.any((e) => daySet.contains(e.date)),
            ),
          );

      summaries.add(
        ProductionGroupSummary(
          groupKey: entry.key,
          title: ProductionWorkGroupCatalog.displayTitle(entry.key),
          itemCount: groupItems.length,
          updatedToday: updatedInPeriod(groupItems),
          groupUnitEfficiency: groupEff,
          axes: [
            ProductionProgressAxis(
              label: 'Süre',
              planned: plannedDays,
              actual: workedDays,
              unit: 'gün',
            ),
            ProductionProgressAxis(
              label: 'Adam-gün',
              planned: plannedAgAxis,
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
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return summaries;
  }
}
