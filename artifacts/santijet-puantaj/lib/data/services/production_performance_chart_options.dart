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

/// Çizgi (plan/gerçekleşen) veya klasik metraj çubuk grafiği.
enum ProductionPerformanceChartStyle {
  line,
  bar;

  String get label => switch (this) {
        line => 'Çizgi',
        bar => 'Çubuk',
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
    this.style = ProductionPerformanceChartStyle.line,
  });

  final ProductionPerformancePeriod period;
  final ProductionPerformanceMetric metric;
  final ProductionPerformanceChartStyle style;

  ProductionPerformanceChartOptions copyWith({
    ProductionPerformancePeriod? period,
    ProductionPerformanceMetric? metric,
    ProductionPerformanceChartStyle? style,
  }) {
    return ProductionPerformanceChartOptions(
      period: period ?? this.period,
      metric: metric ?? this.metric,
      style: style ?? this.style,
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period.name,
        'metric': metric.name,
        'style': style.name,
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

    ProductionPerformanceChartStyle style(String? name) {
      for (final s in ProductionPerformanceChartStyle.values) {
        if (s.name == name) return s;
      }
      return ProductionPerformanceChartStyle.line;
    }

    return ProductionPerformanceChartOptions(
      period: period(json['period'] as String?),
      metric: metric(json['metric'] as String?),
      style: style(json['style'] as String?),
    );
  }
}
