import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';

class FieldCountScreen extends ConsumerWidget {
  const FieldCountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(fieldCountsProvider);
    final reconciliationRows = ref.watch(reconciliationRowsProvider);
    final summary = ref.watch(fieldCountDashboardSummaryProvider);

    final recent = counts.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: CustomScrollView(
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
                          onTap: () => context.go(AppRoutes.dashboard),
                        ),
                        _SummaryKpiSpec(
                          label: 'Gerçek Kullanım',
                          value: AppFormat.tonnage(summary.actualUsage),
                          accentColor: AppColors.warning,
                          onTap: () => context.push(AppRoutes.reconciliation),
                        ),
                        _SummaryKpiSpec(
                          label: 'Planlanan Stok',
                          value: AppFormat.tonnage(summary.plannedStock),
                          accentColor: AppColors.electricBlueLight,
                          onTap: () => context.push(AppRoutes.reconciliation),
                        ),
                        _SummaryKpiSpec(
                          label: 'Gerçek Stok',
                          value: AppFormat.tonnage(summary.fieldCount),
                          accentColor: AppColors.info,
                          onTap: () => context.push(AppRoutes.countRecords),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SummaryKpiRow(
                      aspectRatio: 9.2,
                      cards: [
                        _SummaryKpiSpec(
                          label: 'Fire',
                          value: AppFormat.tonnage(summary.fire),
                          accentColor: summary.fire < 0
                              ? AppColors.critical
                              : summary.fire > 8
                                  ? AppColors.critical
                                  : summary.fire > 0
                                      ? AppColors.warning
                                      : AppColors.success,
                          onTap: () => context.push(AppRoutes.reconciliation),
                        ),
                      ],
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Son Sayımlar', style: AppTypography.headlineMedium),
                      if (counts.isNotEmpty)
                        TextButton(
                          onPressed: () => context.push(AppRoutes.countRecords),
                          child: const Text('Tümünü Gör →'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    const ModuleEmptyState(type: EmptyStateType.noCount, inline: true)
                  else
                    ...recent.map((c) => _CountTimelineTile(
                          record: c,
                          onTap: () => context.push(AppRoutes.countDetail(c.id)),
                        )),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
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
    required this.onTap,
  });

  final String label;
  final String value;
  final Color accentColor;
  final VoidCallback onTap;
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

class _CountTimelineTile extends StatelessWidget {
  const _CountTimelineTile({required this.record, this.onTap});

  final FieldCountRecord record;
  final VoidCallback? onTap;

  Color get _statusColor => switch (record.status) {
        'completed' => AppColors.success,
        'critical' => AppColors.critical,
        'warning' => AppColors.warning,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory_2, size: 18, color: _statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.title, style: AppTypography.titleMedium),
                    Text(
                      '${record.region} · ${DateFormat('d MMM').format(record.date)}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              SapmaTag(value: record.variance),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
