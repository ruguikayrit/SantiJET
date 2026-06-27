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
import 'package:santijet_demir/features/projects/widgets/project_switcher.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/incoming_rebar/widgets/delivery_card.dart';

class IncomingRebarScreen extends ConsumerWidget {
  const IncomingRebarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveries = ref.watch(deliveriesProvider);
    final summary = ref.watch(incomingRebarDashboardSummaryProvider);
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ProjectSwitcher(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      KpiCard(
                        label: 'Toplam Sipariş',
                        value: AppFormat.tonnage(summary.totalOrdered),
                        unit: 't',
                        accentColor: AppColors.electricBlueLight,
                      ),
                      KpiCard(
                        label: 'Teslim Alınan',
                        value: AppFormat.tonnage(summary.totalDelivered),
                        unit: 't',
                        accentColor: AppColors.success,
                      ),
                      KpiCard(
                        label: 'Bekleyen',
                        value: AppFormat.tonnage(summary.pending),
                        unit: 't',
                        accentColor: AppColors.warning,
                      ),
                      KpiCard(
                        label: 'Eksik',
                        value: AppFormat.tonnage(summary.missing),
                        unit: 't',
                        accentColor: AppColors.critical,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FulfillmentBar(percent: summary.fulfillmentPercent),
                  const SizedBox(height: 16),
                  Text('Kritik Uyarılar', style: AppTypography.headlineMedium),
                  const SizedBox(height: 8),
                  const AlertCard(
                    title: 'Eksik Teslimat',
                    message: 'SIP-2025-0042 — 12t eksik (Ø16/Ø22)',
                    severityColor: AppColors.critical,
                  ),
                  const SizedBox(height: 8),
                  const AlertCard(
                    title: 'Kısmi Teslimat',
                    message: 'SIP-2025-0047 — %85 karşılama',
                    severityColor: AppColors.warning,
                  ),
                  const SizedBox(height: 8),
                  const AlertCard(
                    title: 'Fazla Teslimat',
                    message: 'SIP-2025-0040 — +3t fazla (Ø12)',
                    severityColor: Color(0xFFFBBF24),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Son Teslimatlar', style: AppTypography.headlineMedium),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.deliveryList),
                        child: const Text('Tümünü Gör →'),
                      ),
                    ],
                  ),
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
                  _SupplierShortcut(
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
        onPressed: () => context.push(AppRoutes.newDelivery),
      ),
    );
  }
}

class _FulfillmentBar extends StatelessWidget {
  const _FulfillmentBar({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Karşılama Oranı', style: AppTypography.titleMedium),
              Text(
                '%${percent.toStringAsFixed(1)}',
                style: AppTypography.kpiValue.copyWith(
                  fontSize: 22,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: AppRadii.full,
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierShortcut extends StatelessWidget {
  const _SupplierShortcut({required this.onTap});

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
                    Text('4 firma karşılaştırması', style: AppTypography.bodySmall),
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
