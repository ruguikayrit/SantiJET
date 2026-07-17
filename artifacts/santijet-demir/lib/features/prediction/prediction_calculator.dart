import 'package:santijet_demir/domain/entities/prediction_models.dart';

/// Calculator girişleri — saf veri, UI/Riverpod yok.
class PredictionStockPoint {
  const PredictionStockPoint({
    required this.date,
    required this.stockByDiameter,
  });

  final DateTime date;
  final Map<int, double> stockByDiameter;

  double get totalStock =>
      stockByDiameter.values.fold(0.0, (a, b) => a + b);
}

class PredictionCalculatorInput {
  const PredictionCalculatorInput({
    required this.projectId,
    required this.config,
    required this.plannedByDiameter,
    required this.orderedByDiameter,
    required this.deliveredByDiameter,
    required this.stockSeries,
    required this.plannedDailyByDiameter,
    required this.workerDayUnitsInWindow,
    required this.supplierLeadDays,
    this.asOf,
  });

  final String projectId;
  final PredictionConfig config;
  final Map<int, double> plannedByDiameter;
  final Map<int, double> orderedByDiameter;
  final Map<int, double> deliveredByDiameter;

  /// Kronolojik saha sayımları (eski → yeni).
  final List<PredictionStockPoint> stockSeries;

  /// İş programından türetilen çap bazlı ortalama günlük plan (t/gün).
  final Map<int, double> plannedDailyByDiameter;

  /// Penceredeki toplam işçi-gün (puantaj).
  final double workerDayUnitsInWindow;

  final int supplierLeadDays;
  final DateTime? asOf;
}

/// Saf hesaplama motoru — veri uydurmaz.
abstract final class PredictionCalculator {
  static PredictionRiskLevel riskForDays(
    double? daysRemaining,
    PredictionConfig config,
  ) {
    if (daysRemaining == null) return PredictionRiskLevel.unknown;
    if (daysRemaining <= config.criticalDays) return PredictionRiskLevel.red;
    if (daysRemaining <= config.purchaseSoonDays) {
      return PredictionRiskLevel.orange;
    }
    if (daysRemaining <= config.monitorDays) {
      return PredictionRiskLevel.yellow;
    }
    return PredictionRiskLevel.green;
  }

  static int calendarDaysBetween(DateTime a, DateTime b) {
    final aa = DateTime(a.year, a.month, a.day);
    final bb = DateTime(b.year, b.month, b.day);
    return bb.difference(aa).inDays.abs().clamp(1, 3650);
  }

  /// Ardışık sayımlardan gerçek günlük tüketim (çap bazlı).
  static Map<int, double> actualDailyConsumptionByDiameter(
    List<PredictionStockPoint> series,
  ) {
    if (series.length < 2) return {};
    final sorted = [...series]
      ..sort((a, b) => a.date.compareTo(b.date));
    final first = sorted.first;
    final last = sorted.last;
    final days = calendarDaysBetween(first.date, last.date);
    final diameters = <int>{
      ...first.stockByDiameter.keys,
      ...last.stockByDiameter.keys,
    };
    final out = <int, double>{};
    for (final d in diameters) {
      final start = first.stockByDiameter[d] ?? 0;
      final end = last.stockByDiameter[d] ?? 0;
      final consumed = start - end;
      // Stok artışı (teslimat) tüketimi maskeler; negatif tüketim sayılmaz.
      out[d] = consumed > 0 ? consumed / days : 0;
    }
    return out;
  }

  static double sumMap(Map<int, double> map) =>
      map.values.fold(0.0, (a, b) => a + b);

  static PredictionRiskLevel worstRisk(Iterable<PredictionRiskLevel> risks) {
    const order = [
      PredictionRiskLevel.red,
      PredictionRiskLevel.orange,
      PredictionRiskLevel.yellow,
      PredictionRiskLevel.green,
      PredictionRiskLevel.unknown,
    ];
    for (final level in order) {
      if (risks.contains(level)) return level;
    }
    return PredictionRiskLevel.unknown;
  }

  static ({
    List<DiameterPrediction> diameters,
    double actualDaily,
    double plannedDaily,
    double? tonsPerWorkerDay,
    double? deviationPercent,
    DateTime? depletionDate,
    PurchaseRecommendation purchase,
    List<PredictionWarning> warnings,
    PredictionRiskLevel overallRisk,
  }) compute(PredictionCalculatorInput input) {
    final asOf = input.asOf ?? DateTime.now();
    final actualByD = actualDailyConsumptionByDiameter(input.stockSeries);
    final latest = input.stockSeries.isEmpty
        ? null
        : ([...input.stockSeries]
              ..sort((a, b) => a.date.compareTo(b.date)))
            .last;

    final diameters = <int>{
      ...input.plannedByDiameter.keys,
      ...input.orderedByDiameter.keys,
      ...input.deliveredByDiameter.keys,
      ...actualByD.keys,
      ...input.plannedDailyByDiameter.keys,
      if (latest != null) ...latest.stockByDiameter.keys,
    }.toList()
      ..sort();

    final diameterPredictions = <DiameterPrediction>[];
    final warnings = <PredictionWarning>[];

    for (final d in diameters) {
      final stock = latest?.stockByDiameter[d] ?? 0;
      final actualDaily = actualByD[d] ?? 0;
      final plannedDaily = input.plannedDailyByDiameter[d] ?? 0;
      final rate = actualDaily > 0
          ? actualDaily
          : (plannedDaily > 0 ? plannedDaily : 0);
      final usable = (stock - rate * input.config.safetyStockDays)
          .clamp(0.0, double.infinity);
      final daysRemaining = rate > 0 ? usable / rate : null;

      final planned = input.plannedByDiameter[d] ?? 0;
      final ordered = input.orderedByDiameter[d] ?? 0;
      final delivered = input.deliveredByDiameter[d] ?? 0;
      final inTransit = (ordered - delivered).clamp(0.0, double.infinity);
      final used = (delivered - stock).clamp(0.0, double.infinity);
      final remainingReq = (planned - used).clamp(0.0, double.infinity);
      final recommended =
          (remainingReq - stock - inTransit).clamp(0.0, double.infinity);

      final risk = riskForDays(daysRemaining, input.config);
      diameterPredictions.add(
        DiameterPrediction(
          diameter: d,
          currentStock: stock,
          actualDailyConsumption: actualDaily,
          plannedDailyConsumption: plannedDaily,
          daysRemaining: daysRemaining,
          remainingRequirement: remainingReq,
          inTransit: inTransit,
          recommendedPurchase: recommended,
          risk: risk,
        ),
      );

      if (risk == PredictionRiskLevel.red && daysRemaining != null) {
        warnings.add(
          PredictionWarning(
            code: 'critical_diameter',
            severity: PredictionRiskLevel.red,
            message:
                'Ø$d demiri ${daysRemaining.toStringAsFixed(1)} gün içinde '
                'kritik seviyeye düşecek.',
          ),
        );
      } else if (risk == PredictionRiskLevel.orange && daysRemaining != null) {
        warnings.add(
          PredictionWarning(
            code: 'purchase_soon_diameter',
            severity: PredictionRiskLevel.orange,
            message:
                'Ø$d demiri ${daysRemaining.toStringAsFixed(1)} gün içinde '
                'sipariş eşiğine yaklaşacak.',
          ),
        );
      }

      if (plannedDaily > 0 &&
          actualDaily > 0 &&
          actualDaily > plannedDaily *
              (1 + input.config.deviationWarningPercent / 100)) {
        final pct =
            ((actualDaily - plannedDaily) / plannedDaily * 100);
        warnings.add(
          PredictionWarning(
            code: 'deviation_diameter',
            severity: PredictionRiskLevel.orange,
            message:
                'Ø$d tüketimi plandan %${pct.toStringAsFixed(0)} fazla '
                '(plan ${plannedDaily.toStringAsFixed(1)} t/gün, '
                'gerçek ${actualDaily.toStringAsFixed(1)} t/gün).',
          ),
        );
      }
    }

    final actualDaily = sumMap(actualByD);
    final plannedDaily = sumMap(input.plannedDailyByDiameter);
    double? tonsPerWorkerDay;
    if (input.workerDayUnitsInWindow > 0 && actualDaily > 0) {
      // actualDaily * days ≈ total consumed; worker units already sum over window
      final sorted = [...input.stockSeries]
        ..sort((a, b) => a.date.compareTo(b.date));
      final windowDays = sorted.length >= 2
          ? calendarDaysBetween(sorted.first.date, sorted.last.date)
          : 1;
      final totalConsumed = actualDaily * windowDays;
      tonsPerWorkerDay = totalConsumed / input.workerDayUnitsInWindow;

      if (plannedDaily > 0) {
        final capacity = tonsPerWorkerDay * input.workerDayUnitsInWindow / windowDays;
        if (capacity + 1e-9 < plannedDaily) {
          warnings.add(
            const PredictionWarning(
              code: 'workforce_shortfall',
              severity: PredictionRiskLevel.orange,
              message:
                  'Mevcut işgücü verimliliği planlı günlük üretimi karşılamıyor.',
            ),
          );
        }
      }
    }

    double? deviationPercent;
    if (plannedDaily > 0 && actualDaily > 0) {
      deviationPercent = (actualDaily - plannedDaily) / plannedDaily * 100;
      if (deviationPercent.abs() >= input.config.deviationWarningPercent) {
        warnings.add(
          PredictionWarning(
            code: 'deviation_total',
            severity: PredictionRiskLevel.orange,
            message: deviationPercent > 0
                ? 'Demir tüketimi plandan %${deviationPercent.toStringAsFixed(0)} fazla.'
                : 'Demir tüketimi plandan %${deviationPercent.abs().toStringAsFixed(0)} az.',
          ),
        );
      }
    }

    final totalStock = latest?.totalStock ?? 0;
    final totalRate = actualDaily > 0
        ? actualDaily
        : (plannedDaily > 0 ? plannedDaily : 0);
    DateTime? depletionDate;
    if (totalRate > 0) {
      final usable = (totalStock - totalRate * input.config.safetyStockDays)
          .clamp(0.0, double.infinity);
      final days = usable / totalRate;
      depletionDate = DateTime(asOf.year, asOf.month, asOf.day)
          .add(Duration(days: days.ceil()));
    }

    final byDiameterPurchase = {
      for (final d in diameterPredictions)
        if (d.recommendedPurchase > 0) d.diameter: d.recommendedPurchase,
    };
    final totalPurchase = sumMap(byDiameterPurchase);

    DateTime? requiredPurchaseDate;
    if (depletionDate != null) {
      requiredPurchaseDate = depletionDate.subtract(
        Duration(days: input.supplierLeadDays),
      );
      final today = DateTime(asOf.year, asOf.month, asOf.day);
      if (!requiredPurchaseDate.isAfter(today) && totalPurchase > 0) {
        warnings.add(
          PredictionWarning(
            code: 'order_today',
            severity: PredictionRiskLevel.red,
            message:
                'Tedarikçi ortalama teslimat süresi ${input.supplierLeadDays} gün. '
                'Sipariş bugün verilmeli.',
          ),
        );
      }
    }

    warnings.add(
      PredictionWarning(
        code: 'lead_time',
        severity: PredictionRiskLevel.yellow,
        message:
            'Tedarikçi ortalama teslimat süresi ${input.supplierLeadDays} gün.',
      ),
    );

    final overall = worstRisk(diameterPredictions.map((d) => d.risk));

    return (
      diameters: diameterPredictions,
      actualDaily: actualDaily,
      plannedDaily: plannedDaily,
      tonsPerWorkerDay: tonsPerWorkerDay,
      deviationPercent: deviationPercent,
      depletionDate: depletionDate,
      purchase: PurchaseRecommendation(
        totalRequired: totalPurchase,
        byDiameter: byDiameterPurchase,
        requiredPurchaseDate: requiredPurchaseDate,
        supplierLeadDays: input.supplierLeadDays,
      ),
      warnings: warnings,
      overallRisk: overall,
    );
  }
}
