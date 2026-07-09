import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/field_count/field_count_calculator.dart';

class ReportContext {
  const ReportContext({
    required this.projectName,
    required this.hasActiveProject,
    required this.survey,
    required this.orders,
    required this.deliveries,
    required this.fieldCounts,
    required this.reconciliationRows,
    required this.summary,
  });

  final String projectName;
  final bool hasActiveProject;
  final SurveyProject survey;
  final List<OrderItem> orders;
  final List<DeliveryItem> deliveries;
  final List<FieldCountRecord> fieldCounts;
  final List<ReconciliationRow> reconciliationRows;
  final ReconciliationTotals summary;

  bool get hasSurveyData =>
      survey.imalats.any((imalat) => imalat.planned > 0 || imalat.totalTonnage > 0);

  bool get hasOrders => orders.isNotEmpty;

  bool get hasDeliveries => deliveries.isNotEmpty;

  bool get hasFieldCounts => fieldCounts.isNotEmpty;

  bool get hasReconciliationData =>
      reconciliationRows.any((row) => row.survey > 0 || row.counted > 0);

  bool get hasMonthlyActivity {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    bool inMonth(DateTime date) =>
        !date.isBefore(monthStart) && date.isBefore(nextMonth);

    if (orders.any((o) => inMonth(o.date))) return true;
    if (deliveries.any((d) => inMonth(d.date))) return true;
    if (fieldCounts.any((c) => inMonth(c.date))) return true;
    if (inMonth(survey.date)) return true;
    return false;
  }
}

class ReportPayload {
  const ReportPayload({
    required this.title,
    required this.headers,
    required this.rows,
  });

  final String title;
  final List<String> headers;
  final List<List<String>> rows;
}

class ReportValidation {
  const ReportValidation({
    required this.isValid,
    required this.missingRequirements,
  });

  final bool isValid;
  final List<String> missingRequirements;
}
