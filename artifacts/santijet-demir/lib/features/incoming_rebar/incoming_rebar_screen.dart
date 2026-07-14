import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/core/widgets/shell_tab_guard.dart';
import 'package:santijet_demir/core/widgets/summary_kpi_grid.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/incoming_rebar/widgets/delivered_diameter_table.dart';
import 'package:santijet_demir/features/incoming_rebar/widgets/delivery_card.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

class IncomingRebarScreen extends ConsumerWidget {
  const IncomingRebarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveProject = ref.watch(activeProjectProvider) != null;
    final deliveries = ref.watch(deliveriesProvider);
    final summary = ref.watch(incomingRebarDashboardSummaryProvider);
    final diameterRows = ref.watch(deliveredDiameterRowsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SantijetHeader(
                subtitle: 'GELEN DEMİR',
                showNotification: false,
              ),
            ),
            if (!hasActiveProject)
              const ActiveProjectSliverGate()
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SummaryKpiRow(
                      items: [
                        SummaryKpiItem(
                          label: 'Toplam Sipariş',
                          value: AppFormat.tonnage(summary.totalOrdered),
                          accentColor: AppColors.electricBlueLight,
                        ),
                        SummaryKpiItem(
                          label: 'Teslim Alınan',
                          value: AppFormat.tonnage(summary.totalDelivered),
                          accentColor: AppColors.success,
                        ),
                        SummaryKpiItem(
                          label: 'Teslim Oranı',
                          value: summary.fulfillmentPercent
                              .round()
                              .clamp(0, 100)
                              .toString(),
                          unit: '%',
                          accentColor: AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SummaryKpiRow(
                      items: [
                        SummaryKpiItem(
                          label: 'Kalan Sipariş',
                          value: AppFormat.tonnage(summary.remainingOrder),
                          accentColor: AppColors.warning,
                        ),
                        SummaryKpiItem(
                          label: 'Eksik',
                          value: AppFormat.tonnage(summary.missing),
                          accentColor: AppColors.critical,
                        ),
                        SummaryKpiItem(
                          label: 'Fazla',
                          value: AppFormat.tonnage(summary.excess),
                          accentColor: AppColors.partial,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Sahaya Gelen Demir', style: AppTypography.headlineMedium),
                    const SizedBox(height: 8),
                    DeliveredDiameterTable(rows: diameterRows),
                    const SizedBox(height: 16),
                    Text('Teslimat kayıtları', style: AppTypography.headlineMedium),
                    const SizedBox(height: 8),
                    if (deliveries.isEmpty)
                      const ModuleEmptyState(type: EmptyStateType.noDelivery)
                    else
                      ...deliveries.map(
                        (delivery) => DeliveryCard(
                          delivery: delivery,
                          onTap: () =>
                              context.push(AppRoutes.deliveryDetail(delivery.id)),
                        ),
                      ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
          ],
        ),
      floatingActionButton: hasActiveProject
          ? AppFab(
              label: 'Yeni Teslimat',
              onPressed: () => context.push(AppRoutes.selectInTransitOrder),
            )
          : null,
    );
  }
}
