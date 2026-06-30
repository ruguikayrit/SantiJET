import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/shell/dashboard_summary_provider.dart';

class DashboardAlert {
  const DashboardAlert({
    required this.title,
    required this.message,
    required this.severity,
    this.route,
  });

  final String title;
  final String message;
  final AlertSeverity severity;
  final String? route;

  Color get color => Color(severity.colorValue);
}

class DashboardActivity {
  const DashboardActivity({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.route,
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String? route;
}

final dashboardCriticalAlertsProvider = Provider<List<DashboardAlert>>((ref) {
  final counts = ref.watch(fieldCountsProvider);
  final reconciliation = ref.watch(reconciliationRowsProvider);
  final incoming = ref.watch(incomingRebarDashboardSummaryProvider);
  final dashboard = ref.watch(dashboardKpiProvider);
  final orders = ref.watch(ordersProvider);
  final deliveries = ref.watch(deliveriesProvider);

  final alerts = <DashboardAlert>[];

  for (final record in counts.where((item) => item.status == 'critical')) {
    alerts.add(
      DashboardAlert(
        title: 'Kritik sayım sapması',
        message:
            '${record.title} · ${AppFormat.tonnage(record.variance.abs())}t sapma',
        severity: AlertSeverity.critical,
        route: AppRoutes.countDetail(record.id),
      ),
    );
  }

  for (final row in reconciliation.where((item) => item.status == 'critical')) {
    alerts.add(
      DashboardAlert(
        title: 'Ø${row.diameter} yüksek fire',
        message:
            'Gerçek − planlanan kullanım: ${AppFormat.tonnage(row.fire.abs())}t',
        severity: AlertSeverity.critical,
        route: AppRoutes.reconciliation,
      ),
    );
  }

  for (final record in counts.where((item) => item.status == 'warning')) {
    alerts.add(
      DashboardAlert(
        title: 'Sayım sapması',
        message:
            '${record.title} · ${AppFormat.tonnage(record.variance.abs())}t',
        severity: AlertSeverity.warning,
        route: AppRoutes.countDetail(record.id),
      ),
    );
  }

  for (final row in reconciliation.where((item) => item.status == 'warning')) {
    alerts.add(
      DashboardAlert(
        title: 'Ø${row.diameter} fire uyarısı',
        message:
            'Gerçek − planlanan kullanım: ${AppFormat.tonnage(row.fire)}t',
        severity: AlertSeverity.warning,
        route: AppRoutes.reconciliation,
      ),
    );
  }

  if (incoming.missing > 2) {
    alerts.add(
      DashboardAlert(
        title: 'Eksik teslimat',
        message: '${AppFormat.tonnage(incoming.missing)}t henüz gelmedi',
        severity: AlertSeverity.warning,
        route: AppRoutes.incomingRebar,
      ),
    );
  }

  if (incoming.excess > 2) {
    alerts.add(
      DashboardAlert(
        title: 'Fazla teslimat',
        message: '${AppFormat.tonnage(incoming.excess)}t plan üstü teslim',
        severity: AlertSeverity.info,
        route: AppRoutes.incomingRebar,
      ),
    );
  }

  if (dashboard.pendingApproval > 0) {
    final pendingCount =
        orders.where((order) => order.status == OrderStatus.pendingApproval).length;
    alerts.add(
      DashboardAlert(
        title: 'Onay bekleyen sipariş',
        message:
            '$pendingCount sipariş · ${AppFormat.tonnage(dashboard.pendingApproval)}t',
        severity: AlertSeverity.warning,
        route: AppRoutes.orders,
      ),
    );
  }

  if (dashboard.inTransit > 0) {
    final inTransitCount =
        orders.where((order) => order.status == OrderStatus.inTransit).length;
    alerts.add(
      DashboardAlert(
        title: 'Yoldaki sipariş',
        message:
            '$inTransitCount sipariş · ${AppFormat.tonnage(dashboard.inTransit)}t',
        severity: AlertSeverity.info,
        route: AppRoutes.orders,
      ),
    );
  }

  for (final delivery in deliveries.where(
    (item) => item.fulfillmentPercent > 0 && item.fulfillmentPercent < 99,
  )) {
    alerts.add(
      DashboardAlert(
        title: 'Kısmi teslimat',
        message:
            '${delivery.orderNo} · %${delivery.fulfillmentPercent.toStringAsFixed(0)} teslim',
        severity: AlertSeverity.warning,
        route: AppRoutes.deliveryDetail(delivery.id),
      ),
    );
  }

  alerts.sort((a, b) {
    final severityRank = a.severity.index.compareTo(b.severity.index);
    if (severityRank != 0) return severityRank;
    return a.title.compareTo(b.title);
  });

  return alerts.take(5).toList();
});

final dashboardRecentActivitiesProvider =
    Provider<List<DashboardActivity>>((ref) {
  final deliveries = ref.watch(deliveriesProvider);
  final counts = ref.watch(fieldCountsProvider);
  final orders = ref.watch(ordersProvider);

  final activities = <DashboardActivity>[
    for (final delivery in deliveries)
      DashboardActivity(
        date: delivery.date,
        title: 'Teslimat · ${delivery.orderNo}',
        subtitle:
            '${AppFormat.tonnage(delivery.tonnage)}t · ${delivery.supplier}',
        icon: Icons.local_shipping_outlined,
        iconColor: Color(DeliveryStatus.received.colorValue),
        route: AppRoutes.deliveryDetail(delivery.id),
      ),
    for (final record in counts)
      DashboardActivity(
        date: record.date,
        title: 'Sayım · ${record.title}',
        subtitle:
            '${AppFormat.tonnage(record.actual)}t sayım · ${record.region.isNotEmpty ? record.region : record.personnel}',
        icon: Icons.inventory_2_outlined,
        iconColor: switch (record.status) {
          'critical' => Color(AlertSeverity.critical.colorValue),
          'warning' => Color(AlertSeverity.warning.colorValue),
          _ => Color(OrderStatus.completed.colorValue),
        },
        route: AppRoutes.countDetail(record.id),
      ),
    for (final order in orders)
      DashboardActivity(
        date: order.date,
        title: 'Sipariş · ${order.orderNo}',
        subtitle:
            '${order.status.label} · ${AppFormat.tonnage(order.tonnage)}t',
        icon: Icons.receipt_long_outlined,
        iconColor: Color(order.status.colorValue),
        route: AppRoutes.orders,
      ),
  ];

  activities.sort((a, b) => b.date.compareTo(a.date));
  return activities.take(8).toList();
});
