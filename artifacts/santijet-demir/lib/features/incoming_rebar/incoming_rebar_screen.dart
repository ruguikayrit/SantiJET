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
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/incoming_rebar/widgets/delivered_diameter_table.dart';
import 'package:santijet_demir/features/incoming_rebar/widgets/delivery_card.dart';

class IncomingRebarScreen extends ConsumerWidget {
  const IncomingRebarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveries = ref.watch(deliveriesProvider);
    final summary = ref.watch(incomingRebarDashboardSummaryProvider);
    final diameterRows = ref.watch(deliveredDiameterRowsProvider);
    final recent = deliveries.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SantijetHeader(
                subtitle: 'GELEN DEMİR',
                showNotification: false,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1.15,
                              child: KpiCard(
                                label: 'Toplam Sipariş',
                                value: AppFormat.tonnage(summary.totalOrdered),
                                unit: 't',
                                accentColor: AppColors.electricBlueLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1.15,
                              child: KpiCard(
                                label: 'Teslim Alınan',
                                value: AppFormat.tonnage(summary.totalDelivered),
                                unit: 't',
                                accentColor: AppColors.success,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1.15,
                              child: KpiCard(
                                label: 'Teslim Oranı',
                                value: summary.fulfillmentPercent
                                    .round()
                                    .clamp(0, 100)
                                    .toString(),
                                unit: '%',
                                accentColor: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1.15,
                              child: KpiCard(
                                label: 'Kalan Sipariş',
                                value: AppFormat.tonnage(summary.remainingOrder),
                                unit: 't',
                                accentColor: AppColors.warning,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1.15,
                              child: KpiCard(
                                label: 'Eksik',
                                value: AppFormat.tonnage(summary.missing),
                                unit: 't',
                                accentColor: AppColors.critical,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1.15,
                              child: KpiCard(
                                label: 'Fazla',
                                value: AppFormat.tonnage(summary.excess),
                                unit: 't',
                                accentColor: AppColors.partial,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Sahaya Gelen Demir', style: AppTypography.headlineMedium),
                  const SizedBox(height: 8),
                  DeliveredDiameterTable(rows: diameterRows),
                  const SizedBox(height: 16),
                  Text('Kritik Uyarılar', style: AppTypography.headlineMedium),
                  const SizedBox(height: 8),
                  const ModuleEmptyState(type: EmptyStateType.noAlert),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Son Teslimatlar', style: AppTypography.headlineMedium),
                      if (recent.isNotEmpty)
                        TextButton(
                          onPressed: () => context.push(AppRoutes.deliveryList),
                          child: const Text('Tümünü Gör →'),
                        ),
                    ],
                  ),
                  if (recent.isEmpty)
                    const ModuleEmptyState(type: EmptyStateType.noDelivery)
                  else
                    Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppRadii.md,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: recent.map((d) {
                        return CompactDeliveryTile(
                          delivery: d,
                          onTap: () => context.push(AppRoutes.deliveryDetail(d.id)),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _NavCard(
                    icon: Icons.bar_chart,
                    title: 'Performans Analizi',
                    subtitle: 'Sapma grafikleri · tedarikçi karşılaştırma',
                    onTap: () => context.push(AppRoutes.performanceAnalysis),
                  ),
                  const SizedBox(height: 10),
                  _SupplierShortcut(
                    supplierCount: ref.watch(supplierPerformanceProvider).length,
                    onTap: () => context.push(AppRoutes.supplierPerformance),
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AppFab(
        label: 'Yeni Teslimat',
        onPressed: () => context.push(AppRoutes.selectInTransitOrder),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.electricBlueLight),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium),
                    Text(subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupplierShortcut extends StatelessWidget {
  const _SupplierShortcut({
    required this.supplierCount,
    required this.onTap,
  });

  final int supplierCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withValues(alpha: 0.15),
                  borderRadius: AppRadii.sm,
                ),
                child: const Icon(Icons.bar_chart, color: AppColors.electricBlueLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tedarikçi Performansı', style: AppTypography.titleMedium),
                    Text(
                      supplierCount == 0
                          ? 'Henüz tedarikçi verisi yok'
                          : '$supplierCount firma karşılaştırması',
                      style: AppTypography.bodySmall,
                    ),
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
