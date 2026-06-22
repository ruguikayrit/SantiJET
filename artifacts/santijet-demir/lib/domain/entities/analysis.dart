class AiInsight {
  const AiInsight({
    required this.title,
    required this.message,
    required this.colorValue,
    required this.iconName,
  });

  final String title;
  final String message;
  final int colorValue;
  final String iconName;
}

class DiameterDeliveryRate {
  const DiameterDeliveryRate({
    required this.diameter,
    required this.rate,
    required this.variance,
  });

  final int diameter;
  final double rate;
  final double variance;
}

class VarianceBarItem {
  const VarianceBarItem({
    required this.label,
    required this.value,
    required this.status,
  });

  final String label;
  final double value;
  final String status;
}

class ConsumedDiameterItem {
  const ConsumedDiameterItem({
    required this.diameter,
    required this.tonnage,
    required this.isTop,
  });

  final int diameter;
  final double tonnage;
  final bool isTop;
}

class AnalysisSummary {
  const AnalysisSummary({
    required this.healthScore,
    required this.totalSurvey,
    required this.totalOrdered,
    required this.totalDelivered,
    required this.variance,
    required this.insights,
    required this.diameterRates,
    required this.varianceBars,
    required this.consumedDiameters,
  });

  final int healthScore;
  final double totalSurvey;
  final double totalOrdered;
  final double totalDelivered;
  final double variance;
  final List<AiInsight> insights;
  final List<DiameterDeliveryRate> diameterRates;
  final List<VarianceBarItem> varianceBars;
  final List<ConsumedDiameterItem> consumedDiameters;
}
