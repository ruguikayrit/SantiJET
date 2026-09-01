/// İmalat kartı performans grafiği — periyot ve görsel stil.
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

enum ProductionPerformanceStyle {
  classic,
  compare,
  minimal;

  String get label => switch (this) {
        classic => 'Klasik',
        compare => 'Karşılaştırma',
        minimal => 'Sade',
      };
}

class ProductionPerformanceChartOptions {
  const ProductionPerformanceChartOptions({
    this.period = ProductionPerformancePeriod.daily,
    this.style = ProductionPerformanceStyle.classic,
  });

  final ProductionPerformancePeriod period;
  final ProductionPerformanceStyle style;

  ProductionPerformanceChartOptions copyWith({
    ProductionPerformancePeriod? period,
    ProductionPerformanceStyle? style,
  }) {
    return ProductionPerformanceChartOptions(
      period: period ?? this.period,
      style: style ?? this.style,
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period.name,
        'style': style.name,
      };

  factory ProductionPerformanceChartOptions.fromJson(Map<String, dynamic> json) {
    ProductionPerformancePeriod period(String? name) {
      for (final p in ProductionPerformancePeriod.values) {
        if (p.name == name) return p;
      }
      return ProductionPerformancePeriod.daily;
    }

    ProductionPerformanceStyle style(String? name) {
      for (final s in ProductionPerformanceStyle.values) {
        if (s.name == name) return s;
      }
      return ProductionPerformanceStyle.classic;
    }

    return ProductionPerformanceChartOptions(
      period: period(json['period'] as String?),
      style: style(json['style'] as String?),
    );
  }
}
