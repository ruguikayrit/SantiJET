import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/data/mock/mock_field_counts.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';

class ReconciliationScreen extends ConsumerWidget {
  const ReconciliationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(filteredReconciliationProvider);
    final filterIndex = ref.watch(reconciliationFilterProvider);
    final allRows = ref.watch(reconciliationRowsProvider);

    final totals = _computeTotals(allRows);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Mutabakat Tablosu')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FilterChips(
              labels: reconciliationFilterLabels,
              selectedIndex: filterIndex,
              onSelected: (i) =>
                  ref.read(reconciliationFilterProvider.notifier).state = i,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.surfaceHighlight),
                  dataRowMinHeight: 52,
                  columns: const [
                    DataColumn(label: Text('ÇAP')),
                    DataColumn(label: Text('KEŞİF')),
                    DataColumn(label: Text('SİP.')),
                    DataColumn(label: Text('TESLİM')),
                    DataColumn(label: Text('KUL.')),
                    DataColumn(label: Text('BEKL.')),
                    DataColumn(label: Text('SAYIM')),
                    DataColumn(label: Text('SAPMA')),
                  ],
                  rows: [
                    ...rows.map((row) => _buildRow(row)),
                    _buildTotalRow(totals),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(ReconciliationRow row) {
    final statusColor = switch (row.status) {
      'normal' => AppColors.success,
      'warning' => AppColors.warning,
      _ => AppColors.critical,
    };

    return DataRow(
      color: WidgetStateProperty.all(
        statusColor.withValues(alpha: 0.04),
      ),
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 3,
                height: 24,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: AppRadii.xs,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Ø${row.diameter}',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.diameterColor(row.diameter),
                ),
              ),
            ],
          ),
        ),
        DataCell(Text('${row.survey.toStringAsFixed(0)}t')),
        DataCell(Text('${row.ordered.toStringAsFixed(0)}t')),
        DataCell(Text('${row.delivered.toStringAsFixed(0)}t')),
        DataCell(Text('${row.used.toStringAsFixed(0)}t')),
        DataCell(Text('${row.expected.toStringAsFixed(0)}t')),
        DataCell(Text('${row.counted.toStringAsFixed(0)}t')),
        DataCell(SapmaTag(value: row.variance)),
      ],
    );
  }

  DataRow _buildTotalRow(Map<String, double> totals) {
    return DataRow(
      color: WidgetStateProperty.all(
        AppColors.electricBlue.withValues(alpha: 0.08),
      ),
      cells: [
        DataCell(Text('TOPLAM', style: AppTypography.titleMedium)),
        DataCell(Text('${totals['survey']!.toStringAsFixed(0)}t', style: AppTypography.titleMedium)),
        DataCell(Text('${totals['ordered']!.toStringAsFixed(0)}t', style: AppTypography.titleMedium)),
        DataCell(Text('${totals['delivered']!.toStringAsFixed(0)}t', style: AppTypography.titleMedium)),
        DataCell(Text('${totals['used']!.toStringAsFixed(0)}t', style: AppTypography.titleMedium)),
        DataCell(Text('${totals['expected']!.toStringAsFixed(0)}t', style: AppTypography.titleMedium)),
        DataCell(Text('${totals['counted']!.toStringAsFixed(0)}t', style: AppTypography.titleMedium)),
        DataCell(SapmaTag(value: totals['variance']!)),
      ],
    );
  }

  Map<String, double> _computeTotals(List<ReconciliationRow> rows) {
    return {
      'survey': rows.fold(0.0, (s, r) => s + r.survey),
      'ordered': rows.fold(0.0, (s, r) => s + r.ordered),
      'delivered': rows.fold(0.0, (s, r) => s + r.delivered),
      'used': rows.fold(0.0, (s, r) => s + r.used),
      'expected': rows.fold(0.0, (s, r) => s + r.expected),
      'counted': rows.fold(0.0, (s, r) => s + r.counted),
      'variance': rows.fold(0.0, (s, r) => s + r.variance),
    };
  }
}
