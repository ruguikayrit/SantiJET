import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/mock/mock_reports.dart';
import 'package:santijet_demir/domain/entities/report.dart';
import 'package:santijet_demir/features/field_count/field_count_calculator.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/reports/report_context.dart';
import 'package:santijet_demir/features/reports/report_service.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

final reportCategoriesProvider = Provider((ref) => reportCategories);

final reportsProvider = Provider<List<ReportItem>>((ref) => getMockReports());

final reportServiceProvider = Provider<ReportService>((ref) {
  return const ReportService();
});

final reportContextProvider = Provider<ReportContext>((ref) {
  final project = ref.watch(activeProjectProvider);
  final survey = ref.watch(surveyProjectProvider);
  final orders = ref.watch(ordersProvider);
  final deliveries = ref.watch(deliveriesProvider);
  final fieldCounts = ref.watch(fieldCountsProvider);
  final reconciliationRows = ref.watch(reconciliationRowsProvider);

  return ReportContext(
    projectName: project?.name ?? 'Proje seçilmedi',
    hasActiveProject: project != null,
    survey: survey,
    orders: orders,
    deliveries: deliveries,
    fieldCounts: fieldCounts,
    reconciliationRows: reconciliationRows,
    summary: computeReconciliationTotals(reconciliationRows),
  );
});
