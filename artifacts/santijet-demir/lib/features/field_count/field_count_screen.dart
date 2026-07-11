import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/format/app_format.dart';import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
class FieldCountScreen extends ConsumerWidget {
  const FieldCountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(fieldCountsProvider);
    final reconciliationRows = ref.watch(reconciliationRowsProvider);
    final summary = ref.watch(fieldCountDashboardSummaryProvider);

    return Scaffold(      backgroundColor: AppColors.canvas,
      body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SantijetHeader(subtitle: 'SAHA SAYIM', showNotification: false),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Özet', style: AppTypography.headlineMedium),
                    const SizedBox(height: 12),
                    _SummaryKpiRow(cards: [
                      _SummaryKpiSpec(
                        label: 'Keşif',
                        value: AppFormat.tonnage(summary.survey),
                        accentColor: AppColors.electricBlueLight,
                        onTap: () => context.push(AppRoutes.survey),
                      ),
                      _SummaryKpiSpec(
                        label: 'Sipariş',
                        value: AppFormat.tonnage(summary.ordered),
                        accentColor: AppColors.info,
                        onTap: () => context.go(AppRoutes.orders),
                      ),
                      _SummaryKpiSpec(
                        label: 'Teslim',
                        value: AppFormat.tonnage(summary.delivered),
                        accentColor: AppColors.success,
                        onTap: () => context.go(AppRoutes.incomingRebar),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _SummaryKpiRow(
                      dense: true,
                      spacing: 8,
                      cards: [
                        _SummaryKpiSpec(
                          label: 'Planlanan Kullanım',
                          value: AppFormat.tonnage(summary.plannedUsage),
                          accentColor: AppColors.partial,
                        ),
                        _SummaryKpiSpec(
                          label: 'Gerçek Kullanım',
                          value: AppFormat.tonnage(summary.actualUsage),
                          accentColor: AppColors.warning,
                        ),
                        _SummaryKpiSpec(
                          label: 'Planlanan Stok',
                          value: AppFormat.tonnage(summary.plannedStock),
                          accentColor: AppColors.electricBlueLight,
                        ),
                        _SummaryKpiSpec(
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
                  Text('Kritik Uyarılar', style: AppTypography.headlineMedium),
                  const SizedBox(height: 8),
                  const ModuleEmptyState(type: EmptyStateType.noAlert, inline: true),
                  const SizedBox(height: 80),                ]),
              ),
            ),
          ],
        ),
      floatingActionButton: AppFab(
        label: 'Yeni Sayım',
        onPressed: () => context.push(AppRoutes.newCount),
      ),
    );
  }
}

class _SummaryKpiSpec {
  const _SummaryKpiSpec({
    required this.label,
    required this.value,
    required this.accentColor,
    this.onTap,
  });

  final String label;
  final String value;
  final Color accentColor;
  final VoidCallback? onTap;
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

class _SummaryKpiRow extends StatelessWidget {
  const _SummaryKpiRow({
    required this.cards,
    this.aspectRatio = 1.15,
    this.dense = false,
    this.spacing = 12,
  });

  final List<_SummaryKpiSpec> cards;
  final double aspectRatio;
  final bool dense;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: KpiCard(
                label: cards[i].label,
                value: cards[i].value,
                unit: 't',
                accentColor: cards[i].accentColor,
                onTap: cards[i].onTap,
                dense: dense,
                compactHeight: aspectRatio >= 2,
              ),
            ),
          ),
        ],
      ],
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