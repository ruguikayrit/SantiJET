import 'package:santijet_demir/domain/entities/analysis.dart';

AnalysisSummary getMockAnalysisSummary() {
  return const AnalysisSummary(
    healthScore: 0,
    totalSurvey: 0,
    totalOrdered: 0,
    totalDelivered: 0,
    variance: 0,
    insights: [],
    diameterRates: [],
    varianceBars: [],
    consumedDiameters: [],
  );
}

const supplierPerfBars = <(String, double)>[];
