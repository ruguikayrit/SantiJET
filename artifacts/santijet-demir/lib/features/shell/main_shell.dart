import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/animations/app_animations.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/theme/theme_rebuild_gate.dart';
import 'package:santijet_demir/core/widgets/app_bottom_nav_bar.dart';
import 'package:santijet_demir/core/widgets/project_permission_gate.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/core/widgets/shell_tab_guard.dart';
import 'package:santijet_demir/core/widgets/summary_kpi_grid.dart';
import 'package:santijet_demir/features/analysis/widgets/analysis_running_lock_overlay.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/projects/widgets/project_switcher.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';
import 'package:santijet_demir/features/shell/dashboard_feed_provider.dart';
import 'package:santijet_demir/features/shell/dashboard_summary_provider.dart';
import 'package:santijet_demir/features/shell/widgets/dashboard_feed_section.dart';
import 'package:santijet_demir/features/shell/widgets/project_progress_section.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tema değişince shell + nav yeniden çizilsin (AppColors Theme bağımlısı değil).
    final themeMode = ref.watch(appSettingsProvider.select((s) => s.themeMode));
    AppColors.applyPaletteFromMode(themeMode, Theme.of(context).brightness);

    // Saha ile aynı: klavye açıkken nav gizlenir; gövde daralsın.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Stack yalnızca analiz kilidi için — nav yüksekliğini etkilemez.
    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          backgroundColor: AppColors.canvas,
          resizeToAvoidBottomInset: true,
          // Üst SafeArea: ayar dişlisi status bar altında kalmasın.
          // Alt false: nav kendi viewPadding inset'ini çizer.
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReadOnlyBanner(),
                Expanded(child: ThemeRebuildGate(child: navigationShell)),
              ],
            ),
          ),
          bottomNavigationBar: keyboardOpen
              ? null
              : MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: AppBottomNavBar(navigationShell: navigationShell),
                ),
        ),
        const AnalysisRunningLockOverlay(),
      ],
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _dashboardSectionGap = 12.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveProject = ref.watch(activeProjectProvider) != null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SantijetHeader(showWordmark: true),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: ProjectSwitcher(),
              ),
            ),
            if (!hasActiveProject)
              const ActiveProjectSliverGate()
            else ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    _dashboardSectionGap,
                    AppSpacing.md,
                    0,
                  ),
                  child: StaggeredFadeIn(
                    index: 0,
                    child: _DashboardSurveyBar(),
                  ),
                ),
              ),
              _DashboardKpiSliver(sectionGap: _dashboardSectionGap),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const StaggeredFadeIn(
                      index: 2,
                      child: ProjectProgressSection(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const StaggeredFadeIn(
                      index: 3,
                      child: _DashboardAlertsBlock(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const StaggeredFadeIn(
                      index: 4,
                      child: _DashboardActivitiesBlock(),
                    ),
                    SizedBox(height: AppSpacing.lg),
                  ]),
                ),
              ),
            ],
            if (!hasActiveProject)
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.lg),
              ),
          ],
        ),
    );
  }
}

class _DashboardKpiSliver extends ConsumerWidget {
  const _DashboardKpiSliver({required this.sectionGap});

  final double sectionGap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardKpiProvider);

    return SummaryKpiSliverGrid(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        sectionGap,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      items: [
        SummaryKpiItem(
          label: 'Toplam Keşif',
          value: AppFormat.tonnage(dashboard.totalSurvey),
          percent: dashboard.percentLabel(dashboard.totalSurvey),
          accentColor: AppColors.electricBlueLight,
          onTap: () => context.push(AppRoutes.survey),
        ),
        SummaryKpiItem(
          label: 'Toplam Sipariş',
          value: AppFormat.tonnage(dashboard.totalOrdered),
          percent: dashboard.percentLabel(dashboard.totalOrdered),
          accentColor: AppColors.info,
          onTap: () => context.go(AppRoutes.orders),
        ),
        SummaryKpiItem(
          label: 'Sahaya Gelen',
          value: AppFormat.tonnage(dashboard.totalDelivered),
          percent: dashboard.percentLabel(dashboard.totalDelivered),
          accentColor: AppColors.success,
          onTap: () => context.go(AppRoutes.incomingRebar),
        ),
        SummaryKpiItem(
          label: 'Kalan Sipariş',
          value: AppFormat.tonnage(dashboard.remainingOrder),
          percent: dashboard.percentLabel(dashboard.remainingOrder),
          accentColor: AppColors.critical,
          onTap: () => context.go(AppRoutes.orders),
        ),
        SummaryKpiItem(
          label: 'Onayda',
          value: AppFormat.tonnage(dashboard.pendingApproval),
          percent: dashboard.percentLabel(dashboard.pendingApproval),
          accentColor: AppColors.warning,
          onTap: () => context.go(AppRoutes.orders),
        ),
        SummaryKpiItem(
          label: 'Yolda',
          value: AppFormat.tonnage(dashboard.inTransit),
          percent: dashboard.percentLabel(dashboard.inTransit),
          accentColor: AppColors.partial,
          onTap: () => context.go(AppRoutes.orders),
        ),
      ],
    );
  }
}

class _DashboardSurveyBar extends ConsumerWidget {
  const _DashboardSurveyBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surveySummary = ref.watch(surveyDashboardSummaryProvider);
    final surveyImalatLabel = surveySummary.imalatCount == 0
        ? 'Henüz imalat yok'
        : '${surveySummary.imalatCount} imalat';

    return _SurveyQuickAccessBar(
      subtitle: surveyImalatLabel,
      onTap: () => context.push(AppRoutes.survey),
    );
  }
}

class _DashboardAlertsBlock extends ConsumerWidget {
  const _DashboardAlertsBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(dashboardCriticalAlertsProvider);
    return DashboardAlertsSection(alerts: alerts);
  }
}

class _DashboardActivitiesBlock extends ConsumerWidget {
  const _DashboardActivitiesBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(dashboardRecentActivitiesProvider);
    return DashboardActivitiesSection(activities: activities);
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
            Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}