import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/data/services/export_service.dart';
import 'package:santijet_demir/data/mock/mock_field_counts.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/features/field_count/field_count_calculator.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
import 'package:santijet_demir/features/field_count/widgets/reconciliation_table.dart';

class ReconciliationScreen extends ConsumerWidget {
  const ReconciliationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(filteredReconciliationProvider);
    final filterIndex = ref.watch(reconciliationFilterProvider);
    final allRows = ref.watch(reconciliationRowsProvider);

    final displayRows = rows;
    final totals = computeReconciliationTotals(displayRows);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Mukayese Tablosu'),
        actions: [
          IconButton(
            tooltip: 'Excel Dışa Aktar',
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: allRows.isEmpty
                ? null
                : () => _exportExcel(context, allRows),
          ),
          IconButton(
            tooltip: 'PDF Görüntüle',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: allRows.isEmpty
                ? null
                : () => _previewPdf(context, allRows),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: FilterChips(
              labels: reconciliationFilterLabels,
              selectedIndex: filterIndex,
              onSelected: (i) =>
                  ref.read(reconciliationFilterProvider.notifier).state = i,
            ),
          ),
          if (allRows.isEmpty)
            const Expanded(
              child: ModuleEmptyState(type: EmptyStateType.noSurvey),
            )
          else if (displayRows.isEmpty)
            const Expanded(
              child: ModuleEmptyState(type: EmptyStateType.noSearchResult),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: ReconciliationTable(
                  rows: displayRows,
                  totals: totals,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static const _exportHeaders = [
    'Çap',
    'Keşif',
    'Sipariş',
    'Teslim',
    'Planlanan Kullanım',
    'Planlanan Stok',
    'Sayım',
    'Gerçek Kullanım',
    'Fire',
    'Fire %',
  ];

  List<List<String>> _buildExportRows(List<ReconciliationRow> rows) {
    return rows
        .map(
          (row) => [
            'Ø${row.diameter}',
            '${row.survey.toStringAsFixed(1)}t',
            '${row.ordered.toStringAsFixed(1)}t',
            '${row.delivered.toStringAsFixed(1)}t',
            '${row.plannedUsage.toStringAsFixed(1)}t',
            '${row.expectedStock.toStringAsFixed(1)}t',
            '${row.counted.toStringAsFixed(1)}t',
            '${row.used.toStringAsFixed(1)}t',
            '${row.fire.toStringAsFixed(1)}t',
            row.plannedUsage > 0
                ? '${row.firePercent.toStringAsFixed(1)}%'
                : '—',
          ],
        )
        .toList();
  }

  Future<void> _exportExcel(
    BuildContext context,
    List<ReconciliationRow> rows,
  ) async {
    try {
      await exportService.shareExcel(
        title: 'Mukayese Tablosu',
        headers: _exportHeaders,
        rows: _buildExportRows(rows),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mukayese tablosu Excel olarak dışa aktarıldı'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dışa aktarma hatası: $e')),
        );
      }
    }
  }

  Future<void> _previewPdf(
    BuildContext context,
    List<ReconciliationRow> rows,
  ) async {
    try {
      await exportService.previewPdf(
        title: 'Mukayese Tablosu',
        headers: _exportHeaders,
        rows: _buildExportRows(rows),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF önizleme hatası: $e')),
        );
      }
    }
  }
}
