import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/animations/app_animations.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/responsive/app_safe_area.dart';
import 'package:santijet_demir/core/responsive/responsive_layout.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_bottom_nav_bar.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/core/widgets/project_permission_gate.dart';
import 'package:santijet_demir/features/analysis/widgets/analysis_running_lock_overlay.dart';
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          backgroundColor: AppColors.canvas,
          resizeToAvoidBottomInset: false,
          extendBody: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: MediaQuery.of(context).padding.copyWith(bottom: 0),
                    viewPadding:
                        MediaQuery.of(context).viewPadding.copyWith(bottom: 0),
                  ),
                  child: ResponsiveLayout(
                    child: AppSafeArea(
                      bottom: false,
                      child: navigationShell,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppBottomNavBar(navigationShell: navigationShell),
              ),
            ],
          ),
        ),
        const AnalysisRunningLockOverlay(),
      ],
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
      body: CustomScrollView(
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
                    child: _SurveyQuickAccessBar(
                      subtitle: surveyImalatLabel,
                      onTap: () => context.push(AppRoutes.survey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StaggeredFadeIn(
                    index: 1,
                    child: GridView.count(
                      crossAxisCount: ResponsiveLayout.isTablet(context) ? 3 : 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.25 / 1.2,
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
                  SizedBox(height: AppBottomNavBar.totalHeightOf(context) + 16),
                ]),
              ),
            ),
          ],
        ),
    );
  }
}

class _SurveyQuickAccessBar extends StatelessWidget {
  const _SurveyQuickAccessBar({
    required this.subtitle,
    required this.onTap,
  });

  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.electricBlueLight, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Keşif · $subtitle',
                style: AppTypography.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}