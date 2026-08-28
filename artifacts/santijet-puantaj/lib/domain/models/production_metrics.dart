import '../entities/production.dart';

/// Tek bir plan vs gerçekleşen ekseni (metraj, süre veya adam-gün).
class ProductionProgressAxis {
  const ProductionProgressAxis({
    required this.label,
    required this.planned,
    required this.actual,
    required this.unit,
  });

  final String label;
  final double planned;
  final double actual;
  final String unit;

  bool get hasPlan => planned > 0;

  /// Gerçekleşen / planlanan yüzdesi (0–100).
  double get progressPct {
    if (planned <= 0) return actual > 0 ? 100 : 0;
    return ((actual / planned) * 100).clamp(0, 100);
  }

  String formatValue(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  String get detail {
    final u = unit.trim();
    if (!hasPlan) {
      if (actual <= 0) return 'Plan girilmemiş';
      return u.isEmpty ? formatValue(actual) : '${formatValue(actual)} $u';
    }
    final suffix = u.isEmpty ? '' : ' $u';
    return '${formatValue(actual)} / ${formatValue(planned)}$suffix';
  }
}

/// İmalat kartı ve Verim sekmesi için ortak metrik kaynağı.
///
/// Üç eksen:
/// - **Metraj** — gerçekleşen miktar / plan miktar
/// - **Süre** — çalışılan gün / planlanan gün
/// - **Adam-gün** — gerçekleşen AG / plan AG (iş gücü × gün)
///
/// Birim verim yalnızca metraj + adam-gün eksenlerinden türetilir:
/// `(gerçek metraj / gerçek AG) ÷ (plan metraj / plan AG)`.
class ProductionMetrics {
  const ProductionMetrics(this.production);

  final Production production;

  ProductionProgressAxis get metraj => ProductionProgressAxis(
        label: 'Metraj',
        planned: production.plannedQty,
        actual: production.completedQty,
        unit: production.unit,
      );

  ProductionProgressAxis get sure => ProductionProgressAxis(
        label: 'Süre',
        planned: production.plannedDays.toDouble(),
        actual: production.workedDays.toDouble(),
        unit: 'gün',
      );

  ProductionProgressAxis get labor => ProductionProgressAxis(
        label: 'Adam-gün',
        planned: production.plannedWorkerDays,
        actual: production.actualLaborDays,
        unit: 'adam-gün',
      );

  List<ProductionProgressAxis> get axes => [metraj, sure, labor];

  bool get canComputeEfficiency =>
      metraj.hasPlan && labor.hasPlan && labor.actual > 0;

  /// Birim verim oranı (1.0 = planla aynı, >1 daha verimli).
  double? get unitEfficiency => computeUnitEfficiency(
        plannedQty: production.plannedQty,
        plannedWorkerDays: production.plannedWorkerDays,
        actualQty: production.completedQty,
        actualWorkerDays: production.actualLaborDays,
      );

  static double? computeUnitEfficiency({
    required double plannedQty,
    required double plannedWorkerDays,
    required double actualQty,
    required double actualWorkerDays,
  }) {
    if (plannedQty <= 0 || plannedWorkerDays <= 0 || actualWorkerDays <= 0) {
      return null;
    }
    final planRate = plannedQty / plannedWorkerDays;
    if (planRate <= 0) return null;
    return (actualQty / actualWorkerDays) / planRate;
  }
}
