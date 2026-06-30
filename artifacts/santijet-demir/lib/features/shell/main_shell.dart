import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/animations/app_animations.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/responsive/responsive_layout.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_bottom_nav_bar.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/core/widgets/project_permission_gate.dart';
import 'package:santijet_demir/features/projects/widgets/project_switcher.dart';
import 'package:santijet_demir/features/settings/providers/profile_provider.dart';
import 'package:santijet_demir/features/shell/dashboard_feed_provider.dart';
import 'package:santijet_demir/features/shell/dashboard_summary_provider.dart';
import 'package:santijet_demir/features/shell/widgets/dashboard_feed_section.dart';
import 'package:santijet_demir/features/shell/widgets/project_progress_section.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      resizeToAvoidBottomInset: false,
      body: ResponsiveLayout(child: navigationShell),
      bottomNavigationBar: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: AppBottomNavBar(navigationShell: navigationShell),
      ),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarInitial = ref.watch(profileInitialProvider);
    final surveySummary = ref.watch(surveyDashboardSummaryProvider);
    final dashboard = ref.watch(dashboardKpiProvider);
    final alerts = ref.watch(dashboardCriticalAlertsProvider);
    final activities = ref.watch(dashboardRecentActivitiesProvider);
    final surveyTonnageLabel = AppFormat.tonnage(dashboard.totalSurvey);
    final surveyImalatLabel = surveySummary.imalatCount == 0
        ? 'Henüz imalat yok'
        : '${surveySummary.imalatCount} imalat';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SantijetHeader(
                avatarInitial: avatarInitial,
                showWordmark: true,
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 8),
                child: ProjectSwitcher(),
              ),
            ),
            const SliverToBoxAdapter(child: ReadOnlyBanner()),
            const SliverToBoxAdapter(child: GreetingSection()),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  StaggeredFadeIn(
                    index: 0,
                    child: GridView.count(
                      crossAxisCount: ResponsiveLayout.isTablet(context) ? 3 : 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.25,
                      children: [
                        KpiCard(
                          label: 'Toplam Keşif',
                          value: surveyTonnageLabel,
                          unit: 't',
                          percent: dashboard.percentLabel(dashboard.totalSurvey),
                          accentColor: AppColors.electricBlueLight,
                        ),
                        KpiCard(
                          label: 'Toplam Sipariş',
                          value: AppFormat.tonnage(dashboard.totalOrdered),
                          unit: 't',
                          percent: dashboard.percentLabel(dashboard.totalOrdered),
                          accentColor: AppColors.info,
                        ),
                        KpiCard(
                          label: 'Sahaya Gelen',
                          value: AppFormat.tonnage(dashboard.totalDelivered),
                          unit: 't',
                          percent: dashboard.percentLabel(dashboard.totalDelivered),
                          accentColor: AppColors.success,
                        ),
                        KpiCard(
                          label: 'Kalan Sipariş',
                          value: AppFormat.tonnage(dashboard.remainingOrder),
                          unit: 't',
                          percent: dashboard.percentLabel(dashboard.remainingOrder),
                          accentColor: AppColors.critical,
                        ),
                        KpiCard(
                          label: 'Onayda',
                          value: AppFormat.tonnage(dashboard.pendingApproval),
                          unit: 't',
                          percent: dashboard.percentLabel(dashboard.pendingApproval),
                          accentColor: AppColors.warning,
                        ),
                        KpiCard(
                          label: 'Yolda',
                          value: AppFormat.tonnage(dashboard.inTransit),
                          unit: 't',
                          percent: dashboard.percentLabel(dashboard.inTransit),
                          accentColor: AppColors.partial,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  StaggeredFadeIn(
                    index: 1,
                    child: _QuickAccessRow(
                      surveySubtitle: surveyImalatLabel,
                      onSurveyTap: () => context.push(AppRoutes.survey),
                      onReportsTap: () => context.push(AppRoutes.reports),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  StaggeredFadeIn(
                    index: 2,
                    child: const ProjectProgressSection(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  StaggeredFadeIn(
                    index: 3,
                    child: DashboardAlertsSection(alerts: alerts),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  StaggeredFadeIn(
                    index: 4,
                    child: DashboardActivitiesSection(activities: activities),
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow({
    required this.surveySubtitle,
    required this.onSurveyTap,
    required this.onReportsTap,
  });

  final String surveySubtitle;
  final VoidCallback onSurveyTap;
  final VoidCallback onReportsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.search,
            label: 'Keşif',
            subtitle: surveySubtitle,
            color: AppColors.electricBlueLight,
            onTap: onSurveyTap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.description,
            label: 'Raporlar',
            subtitle: 'Henüz rapor yok',
            color: AppColors.partial,
            onTap: onReportsTap,
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(label, style: AppTypography.titleMedium),
            Text(subtitle, style: AppTypography.bodySmall),
          ],
        ),
      ),
    );
  }
}
