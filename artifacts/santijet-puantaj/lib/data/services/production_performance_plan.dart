/// İmalat performans grafiği — periyot plan payı.
///
/// Tempo = plan metraj / plan gün. Periyot planı, o periyottaki **iş günü**
/// sayısıyla çarpılır; [planDays] ve [planQty] tavanını aşmaz.
/// (Takvim ayı/hafta gün sayısı kullanılmaz.)
class ProductionPerformancePlanBudget {
  ProductionPerformancePlanBudget({
    required double planQty,
    required int planDays,
  })  : _remainingQty = planQty,
        _remainingDays = planDays,
        _dailyPlan = planDays > 0 && planQty > 0 ? planQty / planDays : 0;

  final double _dailyPlan;
  double _remainingQty;
  int _remainingDays;

  double allocate({required int workedDaysInPeriod}) {
    if (_dailyPlan <= 0 || workedDaysInPeriod <= 0) return 0;
    if (_remainingDays <= 0 || _remainingQty <= 0) return 0;

    final allocDays = workedDaysInPeriod.clamp(0, _remainingDays);
    if (allocDays <= 0) return 0;

    final planned = (_dailyPlan * allocDays).clamp(0.0, _remainingQty);
    _remainingDays -= allocDays;
    _remainingQty -= planned;
    return planned;
  }

  /// Boş grafik / tempo rozeti için günlük plan temposu.
  static double dailyPlan({required double planQty, required int planDays}) {
    if (planDays <= 0 || planQty <= 0) return 0;
    return planQty / planDays;
  }
}
