import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/mock/mock_analysis.dart';

final analysisSummaryProvider = Provider((ref) => getMockAnalysisSummary());

final supplierPerfBarsProvider = Provider((ref) => supplierPerfBars);
