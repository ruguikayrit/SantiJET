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

class ProductionPerformanceChartOptions {
  const ProductionPerformanceChartOptions({
    this.period = ProductionPerformancePeriod.daily,
  });

  final ProductionPerformancePeriod period;

  ProductionPerformanceChartOptions copyWith({
    ProductionPerformancePeriod? period,
  }) {
    return ProductionPerformanceChartOptions(
      period: period ?? this.period,
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period.name,
      };

  factory ProductionPerformanceChartOptions.fromJson(Map<String, dynamic> json) {
    ProductionPerformancePeriod period(String? name) {
      for (final p in ProductionPerformancePeriod.values) {
        if (p.name == name) return p;
      }
      return ProductionPerformancePeriod.daily;
    }

    return ProductionPerformanceChartOptions(
      period: period(json['period'] as String?),
    );
  }
}
