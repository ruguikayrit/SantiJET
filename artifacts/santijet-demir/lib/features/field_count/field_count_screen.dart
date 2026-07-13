import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/core/widgets/shell_tab_guard.dart';
import 'package:santijet_demir/core/widgets/summary_kpi_grid.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/shell/dashboard_feed_provider.dart';
import 'package:santijet_demir/features/shell/widgets/dashboard_feed_section.dart';

class FieldCountScreen extends ConsumerWidget {
  const FieldCountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveProject = ref.watch(activeProjectProvider) != null;
    final counts = ref.watch(fieldCountsProvider);
    final reconciliationRows = ref.watch(reconciliationRowsProvider);
    final summary = ref.watch(fieldCountDashboardSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SantijetHeader(subtitle: 'SAHA SAYIM', showNotification: false),
            ),
            if (!hasActiveProject)
              const ActiveProjectSliverGate()
            else ...[
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Özet', style: AppTypography.headlineMedium),
                      const SizedBox(height: 12),
                      SummaryKpiRow(
                        items: [
                          SummaryKpiItem(
                            label: 'Keşif',
                            value: AppFormat.tonnage(summary.survey),
                            accentColor: AppColors.electricBlueLight,
                            onTap: () => context.push(AppRoutes.survey),
                          ),
                          SummaryKpiItem(
                            label: 'Sipariş',
                            value: AppFormat.tonnage(summary.ordered),
                            accentColor: AppColors.info,
                            onTap: () => context.go(AppRoutes.orders),
                          ),
                          SummaryKpiItem(
                            label: 'Teslim',
                            value: AppFormat.tonnage(summary.delivered),
                            accentColor: AppColors.success,
                            onTap: () => context.go(AppRoutes.incomingRebar),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SummaryKpiRow(
                        dense: true,
                        spacing: 8,
                        items: [
                          SummaryKpiItem(
                            label: 'Planlanan Kullanım',
                            value: AppFormat.tonnage(summary.plannedUsage),
                            accentColor: AppColors.partial,
                          ),
                          SummaryKpiItem(
                            label: 'Gerçek Kullanım',
                            value: AppFormat.tonnage(summary.actualUsage),
                            accentColor: AppColors.warning,
                          ),
                          SummaryKpiItem(
                            label: 'Planlanan Stok',
                            value: AppFormat.tonnage(summary.plannedStock),
                            accentColor: AppColors.electricBlueLight,
                          ),
                          SummaryKpiItem(
                            label: 'Gerçek Stok',
                            value: AppFormat.tonnage(summary.fieldCount),
                            accentColor: AppColors.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _FireSummaryCard(
                        fire: summary.fire,
                        plannedUsage: summary.plannedUsage,
                        onTap: () => context.push(AppRoutes.reconciliation),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ReconciliationShortcut(
                      rowCount: reconciliationRows.length,
                      onTap: () => context.push(AppRoutes.reconciliation),
                    ),
                    const SizedBox(height: 12),
                    _CountRecordsShortcut(
                      recordCount: counts.length,
                      onTap: () => context.push(AppRoutes.countRecords),
                    ),
                    const SizedBox(height: 16),
                    const ScopedDashboardAlertsSection(
                      scope: DashboardAlertScope.fieldCount,
                      inline: true,
                    ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ],
        ),
      floatingActionButton: hasActiveProject
          ? AppFab(
              label: 'Yeni Sayım',
              onPressed: () => context.push(AppRoutes.newCount),
            )
          : null,
    );
  }
}

class _FireSummaryCard extends StatelessWidget {
  const _FireSummaryCard({
    required this.fire,
    required this.plannedUsage,
    required this.onTap,
  });

  final double fire;
  final double plannedUsage;
  final VoidCallback onTap;

  Color get _accentColor => fire > 2
      ? AppColors.critical
      : fire > 0
          ? AppColors.warning
          : AppColors.success;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final topCardWidth = (constraints.maxWidth - 2 * spacing) / 3;
        final cardHeight = topCardWidth / 1.15;
        final firePercent =
            plannedUsage > 0 ? (fire / plannedUsage) * 100 : null;

        return SizedBox(
          height: cardHeight,
          child: KpiCard(
            label: 'Fire',
            value: AppFormat.tonnage(fire),
            unit: 't',
            accentColor: _accentColor,
            percent: firePercent != null
                ? '${firePercent.toStringAsFixed(1)}% planlanan kullanıma göre'
                : null,
            onTap: onTap,
          ),
        );
      },
    );
  }
}

class _CountRecordsShortcut extends StatelessWidget {
  const _CountRecordsShortcut({
    required this.recordCount,
    required this.onTap,
  });

  final int recordCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = recordCount == 0
        ? 'Henüz sayım kaydı yok'
        : '$recordCount kayıt · Tamamlanan sayımlar';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.08),
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sayım Kayıtları', style: AppTypography.titleMedium),
                    Text(subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReconciliationShortcut extends StatelessWidget {
  const _ReconciliationShortcut({
    required this.rowCount,
    required this.onTap,
  });

  final int rowCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = rowCount == 0
        ? 'Henüz mukayese verisi yok'
        : '$rowCount çap · Keşif → teslim → sayım karşılaştırma';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.electricBlue.withValues(alpha: 0.08),
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.table_chart, color: AppColors.electricBlueLight),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mukayese Tablosu', style: AppTypography.titleMedium),
                    Text(subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}