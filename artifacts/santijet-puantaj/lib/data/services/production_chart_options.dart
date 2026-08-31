/// İmalat / Verim grafik görünümü ayarları.
enum ProductionChartKind {
  pie,
  bar,
  horizontalBar;

  String get label => switch (this) {
        pie => 'Pasta',
        bar => 'Çubuk',
        horizontalBar => 'Yatay çubuk',
      };

  String get hint => switch (this) {
        pie => 'Pay dağılımı',
        bar => 'Karşılaştırma',
        horizontalBar => 'Sıralı karşılaştırma',
      };
}

/// İmalat grafiğinde ne gösterilsin.
enum ImalatChartMetric {
  phaseShare,
  teamProgress,
  metrajPlanActual;

  String get label => switch (this) {
        phaseShare => 'Durum dağılımı',
        teamProgress => 'Ekip ilerlemesi',
        metrajPlanActual => 'Metraj plan / gerçek',
      };
}

/// Verim grafiğinde ne gösterilsin.
enum VerimChartMetric {
  teamEfficiency,
  laborPlanActual,
  rowEfficiency;

  String get label => switch (this) {
        teamEfficiency => 'Ekip verimi',
        laborPlanActual => 'Adam-gün plan / gerçek',
        rowEfficiency => 'İmalat verimi',
      };
}

class ProductionChartOptions {
  const ProductionChartOptions({
    this.imalatKind = ProductionChartKind.pie,
    this.imalatMetric = ImalatChartMetric.phaseShare,
    this.verimKind = ProductionChartKind.bar,
    this.verimMetric = VerimChartMetric.teamEfficiency,
  });

  final ProductionChartKind imalatKind;
  final ImalatChartMetric imalatMetric;
  final ProductionChartKind verimKind;
  final VerimChartMetric verimMetric;

  ProductionChartOptions copyWith({
    ProductionChartKind? imalatKind,
    ImalatChartMetric? imalatMetric,
    ProductionChartKind? verimKind,
    VerimChartMetric? verimMetric,
  }) {
    return ProductionChartOptions(
      imalatKind: imalatKind ?? this.imalatKind,
      imalatMetric: imalatMetric ?? this.imalatMetric,
      verimKind: verimKind ?? this.verimKind,
      verimMetric: verimMetric ?? this.verimMetric,
    );
  }

  Map<String, dynamic> toJson() => {
        'imalatKind': imalatKind.name,
        'imalatMetric': imalatMetric.name,
        'verimKind': verimKind.name,
        'verimMetric': verimMetric.name,
      };

  factory ProductionChartOptions.fromJson(Map<String, dynamic> json) {
    ProductionChartKind kind(String? name, ProductionChartKind fallback) {
      for (final k in ProductionChartKind.values) {
        if (k.name == name) return k;
      }
      return fallback;
    }

    ImalatChartMetric imalatMetric(String? name) {
      for (final m in ImalatChartMetric.values) {
        if (m.name == name) return m;
      }
      return ImalatChartMetric.phaseShare;
    }

    VerimChartMetric verimMetric(String? name) {
      for (final m in VerimChartMetric.values) {
        if (m.name == name) return m;
      }
      return VerimChartMetric.teamEfficiency;
    }

    return ProductionChartOptions(
      imalatKind: kind(json['imalatKind'] as String?, ProductionChartKind.pie),
      imalatMetric: imalatMetric(json['imalatMetric'] as String?),
      verimKind: kind(json['verimKind'] as String?, ProductionChartKind.bar),
      verimMetric: verimMetric(json['verimMetric'] as String?),
    );
  }
}
