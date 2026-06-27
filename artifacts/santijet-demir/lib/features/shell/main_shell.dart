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
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/core/widgets/project_permission_gate.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/projects/widgets/project_switcher.dart';
import 'package:santijet_demir/features/settings/providers/profile_provider.dart';
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
    final incomingSummary = ref.watch(incomingRebarDashboardSummaryProvider);
    final orders = ref.watch(ordersProvider);
    final surveyTonnageLabel = AppFormat.tonnage(surveySummary.totalTonnage);
    final surveyImalatLabel = surveySummary.imalatCount == 0
        ? 'Henüz imalat yok'
        : '${surveySummary.imalatCount} imalat';
    final ordersSubtitle = orders.isEmpty
        ? 'Henüz sipariş yok'
        : '${orders.length} kayıt';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SantijetHeader(avatarInitial: avatarInitial),
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
                      crossAxisCount: ResponsiveLayout.isTablet(context) ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        KpiCard(
                          label: 'Toplam Keşif',
                          value: surveyTonnageLabel,
                          unit: 't',
                          accentColor: AppColors.electricBlueLight,
                        ),
                        KpiCard(
                          label: 'Toplam Sipariş',
                          value: AppFormat.tonnage(incomingSummary.totalOrdered),
                          unit: 't',
                          accentColor: AppColors.info,
                        ),
                        KpiCard(
                          label: 'Sahaya Gelen',
                          value: AppFormat.tonnage(incomingSummary.totalDelivered),
                          unit: 't',
                          accentColor: AppColors.success,
                        ),
                        KpiCard(
                          label: 'Beklenen Stok',
                          value: AppFormat.tonnage(incomingSummary.pending),
                          unit: 't',
                          accentColor: AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  StaggeredFadeIn(
                    index: 1,
                    child: _QuickAccessRow(
                      surveySubtitle: surveyImalatLabel,
                      ordersSubtitle: ordersSubtitle,
                      onSurveyTap: () => context.push(AppRoutes.survey),
                      onMetrajTap: () => context.push(AppRoutes.surveyMetraj),
                      onOrdersTap: () => context.go(AppRoutes.orders),
                      onReportsTap: () => context.push(AppRoutes.reports),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  StaggeredFadeIn(
                    index: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kritik Uyarılar', style: AppTypography.headlineMedium),
                        const SizedBox(height: AppSpacing.sm),
                        const ModuleEmptyState(type: EmptyStateType.noAlert),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  StaggeredFadeIn(
                    index: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Süreç Durumu', style: AppTypography.headlineMedium),
                        const SizedBox(height: AppSpacing.sm),
                        const ProgressCard(label: 'Keşif', percentage: 0, color: AppColors.electricBlueLight),
                        const SizedBox(height: 8),
                        const ProgressCard(label: 'Sipariş', percentage: 0, color: AppColors.info),
                        const SizedBox(height: 8),
                        const ProgressCard(label: 'Teslimat', percentage: 0, color: AppColors.success),
                        const SizedBox(height: 8),
                        const ProgressCard(label: 'Saha Sayım', percentage: 0, color: AppColors.warning),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  StaggeredFadeIn(
                    index: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Son Aktiviteler', style: AppTypography.headlineMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Henüz aktivite kaydı yok',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
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
    required this.ordersSubtitle,
    required this.onSurveyTap,
    required this.onMetrajTap,
    required this.onOrdersTap,
    required this.onReportsTap,
  });

  final String surveySubtitle;
  final String ordersSubtitle;
  final VoidCallback onSurveyTap;
  final VoidCallback onMetrajTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onReportsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
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
                icon: Icons.receipt_long,
                label: 'Siparişler',
                subtitle: ordersSubtitle,
                color: AppColors.info,
                onTap: onOrdersTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _QuickAccessCard(
                icon: Icons.architecture,
                label: 'Otomatik Metraj',
                subtitle: 'DWG · DXF',
                color: AppColors.success,
                onTap: onMetrajTap,
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
