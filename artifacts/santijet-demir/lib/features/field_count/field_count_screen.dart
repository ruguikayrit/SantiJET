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

    final expectedStock = counts.fold<double>(0, (sum, c) => sum + c.expected);
    final actualCount = counts.fold<double>(0, (sum, c) => sum + c.actual);
    final totalVariance = counts.fold<double>(0, (sum, c) => sum + c.variance);
    final criticalCount = counts.where((c) => c.status == 'critical').length;

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
                        label: 'Beklenen Stok',
                        value: AppFormat.tonnage(expectedStock),
                        unit: 't',
                        accentColor: AppColors.electricBlueLight,
                      ),
                      KpiCard(
                        label: 'Gerçek Sayım',
                        value: AppFormat.tonnage(actualCount),
                        unit: 't',
                        accentColor: AppColors.info,
                      ),
                      KpiCard(
                        label: 'Toplam Sapma',
                        value: AppFormat.tonnage(totalVariance),
                        unit: 't',
                        accentColor: AppColors.warning,
                      ),
                      KpiCard(
                        label: 'Kritik Çap',
                        value: AppFormat.integer(criticalCount),
                        unit: '',
                        accentColor: AppColors.critical,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ReconciliationShortcut(
                    rowCount: reconciliationRows.length,
                    onTap: () => context.push(AppRoutes.reconciliation),
                  ),
                  const SizedBox(height: 16),
                  Text('Kritik Uyarılar', style: AppTypography.headlineMedium),
                  const SizedBox(height: 8),
                  const ModuleEmptyState(type: EmptyStateType.noAlert),
                  const SizedBox(height: 16),
                  Text('Sayım Durumu', style: AppTypography.headlineMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatusChip(
                        label: 'Tamamlanan',
                        count: counts.where((c) => c.status == 'completed').length,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: 'Bekleyen',
                        count: counts.where((c) => c.status == 'pending').length,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: 'Kritik',
                        count: criticalCount,
                        color: AppColors.critical,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Son Sayımlar', style: AppTypography.headlineMedium),
                  const SizedBox(height: 8),
                  if (counts.isEmpty)
                    const ModuleEmptyState(type: EmptyStateType.noCount)
                  else
                    ...counts.map((c) => _CountTimelineTile(
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
        ? 'Henüz mutabakat verisi yok'
        : '$rowCount çap · Keşif → Sayım karşılaştırma';

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
                    Text('Mutabakat Tablosu', style: AppTypography.titleMedium),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadii.md,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text('$count', style: AppTypography.kpiValue.copyWith(fontSize: 22, color: color)),
            Text(label, style: AppTypography.labelMedium, textAlign: TextAlign.center),
          ],
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
