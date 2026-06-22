import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/mock/mock_reports.dart';
import 'package:santijet_demir/domain/entities/report.dart';

final reportCategoriesProvider = Provider((ref) => reportCategories);

final reportsProvider = Provider<List<ReportItem>>((ref) => getMockReports());
