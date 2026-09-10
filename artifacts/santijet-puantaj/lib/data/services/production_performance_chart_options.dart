/// İmalat kartı performans grafiği — zaman periyodu.
enum ProductionPerformancePeriod {
  daily,
  weekly,
  monthly;

  String get label => switch (this) {
        daily => 'Günlük',
        weekly => 'Haftalık',
        monthly => 'Aylık',
      };
}

/// Metraj veya adam-gün plan / gerçekleşen çizgisi.
enum ProductionPerformanceMetric {
  metraj,
  laborDays;

  String get label => switch (this) {
        metraj => 'Metraj',
        laborDays => 'Adam-gün',
      };
}

class ProductionPerformanceChartOptions {
  const ProductionPerformanceChartOptions({
    this.period = ProductionPerformancePeriod.daily,
    this.metric = ProductionPerformanceMetric.metraj,
  });

  final ProductionPerformancePeriod period;
  final ProductionPerformanceMetric metric;

  ProductionPerformanceChartOptions copyWith({
    ProductionPerformancePeriod? period,
    ProductionPerformanceMetric? metric,
  }) {
    return ProductionPerformanceChartOptions(
      period: period ?? this.period,
      metric: metric ?? this.metric,
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period.name,
        'metric': metric.name,
      };

  factory ProductionPerformanceChartOptions.fromJson(Map<String, dynamic> json) {
    ProductionPerformancePeriod period(String? name) {
      for (final p in ProductionPerformancePeriod.values) {
        if (p.name == name) return p;
      }
      return ProductionPerformancePeriod.daily;
    }

    ProductionPerformanceMetric metric(String? name) {
      for (final m in ProductionPerformanceMetric.values) {
        if (m.name == name) return m;
      }
      return ProductionPerformanceMetric.metraj;
    }

    return ProductionPerformanceChartOptions(
      period: period(json['period'] as String?),
      metric: metric(json['metric'] as String?),
    );
  }
}
