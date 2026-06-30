import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class DashboardKpiSummary {
  const DashboardKpiSummary({
    required this.totalSurvey,
    required this.totalOrdered,
    required this.totalDelivered,
    required this.remainingOrder,
    required this.pendingApproval,
    required this.inTransit,
  });

  final double totalSurvey;
  final double totalOrdered;
  final double totalDelivered;
  final double remainingOrder;
  final double pendingApproval;
  final double inTransit;

  String percentLabel(double value) {
    if (totalSurvey <= 0) return '%0';
    return '%${(value / totalSurvey * 100).toStringAsFixed(0)}';
  }
}

const _placedOrderStatuses = {
  OrderStatus.submitted,
  OrderStatus.inTransit,
  OrderStatus.completed,
};

final dashboardKpiProvider = Provider<DashboardKpiSummary>((ref) {
  final survey = ref.watch(surveyProjectProvider);
  final orders = ref.watch(ordersProvider);
  final incoming = ref.watch(incomingRebarDashboardSummaryProvider);

  final totalSurvey = survey.totalPlanned;

  final totalOrdered = orders
      .where((order) => _placedOrderStatuses.contains(order.status))
      .fold(0.0, (sum, order) => sum + order.tonnage);

  final totalDelivered = incoming.totalDelivered;
  final remainingOrder = (totalOrdered - totalDelivered).clamp(0.0, double.infinity);

  var pendingApproval = 0.0;
  var inTransit = 0.0;
  for (final order in orders) {
    if (order.status == OrderStatus.pendingApproval) {
      pendingApproval += order.tonnage;
    } else if (order.status == OrderStatus.inTransit) {
      inTransit += order.tonnage;
    }
  }

  return DashboardKpiSummary(
    totalSurvey: totalSurvey,
    totalOrdered: totalOrdered,
    totalDelivered: totalDelivered,
    remainingOrder: remainingOrder,
    pendingApproval: pendingApproval,
    inTransit: inTransit,
  );
});
