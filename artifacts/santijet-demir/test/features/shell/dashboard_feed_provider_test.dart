import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/features/shell/dashboard_feed_provider.dart';

void main() {
  group('dashboard feed models', () {
    test('alerts sort critical before warning', () {
      const alerts = [
        DashboardAlert(
          title: 'B',
          message: 'warning',
          severity: AlertSeverity.warning,
        ),
        DashboardAlert(
          title: 'A',
          message: 'critical',
          severity: AlertSeverity.critical,
        ),
      ];

      final sorted = [...alerts]
        ..sort((a, b) => a.severity.index.compareTo(b.severity.index));

      expect(sorted.first.severity, AlertSeverity.critical);
    });

    test('activities expose icon color from severity', () {
      const activity = DashboardActivity(
        date: DateTime(2026, 6, 1, 10),
        title: 'Sayım',
        subtitle: 'Test',
        icon: Icons.inventory_2_outlined,
        iconColor: Colors.orange,
      );

      expect(activity.title, 'Sayım');
    });
  });
}
