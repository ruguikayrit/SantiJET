import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/features/shell/dashboard_feed_provider.dart';

class DashboardAlertsSection extends StatelessWidget {
  const DashboardAlertsSection({super.key, required this.alerts});

  final List<DashboardAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return _AlertsContent(alerts: alerts);
  }
}

class ScopedDashboardAlertsSection extends ConsumerWidget {
  const ScopedDashboardAlertsSection({
    super.key,
    required this.scope,
    this.inline = false,
  });

  final DashboardAlertScope scope;
  final bool inline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(dashboardScopedAlertsProvider(scope));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kritik Uyarılar', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        _AlertsContent(alerts: alerts, inline: inline),
      ],
    );
  }
}

class _AlertsContent extends StatelessWidget {
  const _AlertsContent({
    required this.alerts,
    this.inline = false,
  });

  final List<DashboardAlert> alerts;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return ModuleEmptyState(type: EmptyStateType.noAlert, inline: inline);
    }

    return Column(
      children: [
        for (var i = 0; i < alerts.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          AlertCard(
            title: alerts[i].title,
            message: alerts[i].message,
            severityColor: alerts[i].color,
            onTap: alerts[i].route == null
                ? null
                : () => context.push(alerts[i].route!),
          ),
        ],
      ],
    );
  }
}

class DashboardActivitiesSection extends StatelessWidget {
  const DashboardActivitiesSection({super.key, required this.activities});

  final List<DashboardActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Son Aktiviteler', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        if (activities.isEmpty)
          ModuleEmptyState(
            type: EmptyStateType.noActivity,
            inline: true,
            actionLabel: 'Yeni Sipariş',
            onAction: () => context.push(AppRoutes.newOrder),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < activities.length; i++)
                  _ActivityTile(
                    activity: activities[i],
                    showDivider: i < activities.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
    required this.showDivider,
  });

  final DashboardActivity activity;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM · HH:mm').format(activity.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            activity.route == null ? null : () => context.push(activity.route!),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(bottom: BorderSide(color: AppColors.border))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: activity.iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(activity.icon, size: 18, color: activity.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.title, style: AppTypography.titleMedium),
                    Text(activity.subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(dateLabel, style: AppTypography.labelMedium),
                  if (activity.route != null)
                    Icon(Icons.chevron_right,
                        color: AppColors.textMuted, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
