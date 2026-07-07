import 'package:flutter/material.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';

enum FireSummaryDetailKind {
  rawMaterial,
  rawFire,
  plannedFire,
  savings,
}

class FireSummaryDetailPanel extends StatelessWidget {
  const FireSummaryDetailPanel({
    super.key,
    required this.kind,
    required this.batch,
    required this.summary,
    this.comparison,
  });

  final FireSummaryDetailKind kind;
  final CuttingBendingBatch batch;
  final AnalysisFireSummary summary;
  final AnalysisComparison? comparison;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: AppRadii.sm,
          border: Border.all(color: AppColors.border),
        ),
        child: switch (kind) {
          FireSummaryDetailKind.rawMaterial => _RawMaterialDetail(batch: batch),
          FireSummaryDetailKind.rawFire => _RawFireDetail(
              batch: batch,
              summary: summary,
            ),
          FireSummaryDetailKind.plannedFire => _PlannedFireDetail(
              batch: batch,
              summary: summary,
            ),
          FireSummaryDetailKind.savings => _SavingsDetail(
              summary: summary,
              comparison: comparison,
              batch: batch,
            ),
        },
      ),
    );
  }
}

class _RawMaterialDetail extends StatelessWidget {
  const _RawMaterialDetail({required this.batch});

  final CuttingBendingBatch batch;

  @override
  Widget build(BuildContext context) {
    final byDiameter = computeMaterialSummaryByDiameter(batch.pieceLines);
    final totalPieces =
        batch.pieceLines.fold(0, (sum, piece) => sum + piece.quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Analiz edilen donatılar', style: AppTypography.labelMedium),
        const SizedBox(height: 4),
        Text(
          'Ham kaynak parça listesi · ${batch.pieceLines.length} satır · '
          '${AppFormat.integer(totalPieces)} adet',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        const _DetailTableHeader(
          cells: ['ÇAP', 'TONAJ', 'ADET', 'SATIR'],
        ),
        ...byDiameter.map(
          (item) => _DetailTableRow(
            cells: [
              'Ø${item.diameter}',
              '${AppFormat.tonnage(item.tonnage)} t',
              AppFormat.integer(item.pieceCount),
              '${item.lineCount}',
            ],
            accentColor: AppColors.diameterColor(item.diameter),
          ),
        ),
        const SizedBox(height: 10),
        Text('Parça detayı', style: AppTypography.labelMedium),
        const SizedBox(height: 6),
        ...batch.pieceLines.map(
          (piece) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Ø${piece.diameter} · ${piece.lengthM.toStringAsFixed(2)} m × '
              '${AppFormat.integer(piece.quantity)} ad',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.diameterColor(piece.diameter),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RawFireDetail extends StatelessWidget {
  const _RawFireDetail({
    required this.batch,
    required this.summary,
  });

  final CuttingBendingBatch batch;
  final AnalysisFireSummary summary;

  @override
  Widget build(BuildContext context) {
    final breakdown = computeRawFireBreakdown(batch);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ham fire hesabı', style: AppTypography.labelMedium),
        const SizedBox(height: 4),
        Text(
          '12 m stok simülasyonu · ham parça listesi',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        _FormulaRow(
          label: 'Fire tonajı',
          value: '${AppFormat.tonnage(summary.rawWasteTonnage)} t',
        ),
        _FormulaRow(
          label: 'Stok tonajı',
          value: '${AppFormat.tonnage(summary.rawStockTonnage)} t',
        ),
        _FormulaRow(
          label: 'Fire oranı',
          value:
              '${AppFormat.tonnage(summary.rawWasteTonnage)} ÷ '
              '${AppFormat.tonnage(summary.rawStockTonnage)} = '
              '%${summary.rawWastePercent.toStringAsFixed(1)}',
          highlight: true,
        ),
        const SizedBox(height: 10),
        const _DetailTableHeader(
          cells: ['ÇAP', 'STOK', 'FİRE', 'FİRE %', 'ÇUBUK'],
        ),
        ...breakdown.map(
          (item) => _DetailTableRow(
            cells: [
              'Ø${item.diameter}',
              '${AppFormat.tonnage(item.stockTonnage)} t',
              '${AppFormat.tonnage(item.wasteTonnage)} t',
              '%${item.wastePercent.toStringAsFixed(1)}',
              '${item.totalBars}',
            ],
            accentColor: AppColors.diameterColor(item.diameter),
          ),
        ),
      ],
    );
  }
}

class _PlannedFireDetail extends StatelessWidget {
  const _PlannedFireDetail({
    required this.batch,
    required this.summary,
  });

  final CuttingBendingBatch batch;
  final AnalysisFireSummary summary;

  @override
  Widget build(BuildContext context) {
    if (!summary.isPlannedReady) {
      return Text(
        'Plan fire, analiz tamamlandıktan sonra görünür.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      );
    }

    final breakdown = computePlannedFireBreakdown(batch);
    final strategy = batch.optimizationStrategy?.label ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Plan fire hesabı', style: AppTypography.labelMedium),
        const SizedBox(height: 4),
        Text(
          'Revize liste · strateji: $strategy',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        _FormulaRow(
          label: 'Fire tonajı',
          value: '${AppFormat.tonnage(summary.plannedWasteTonnage!)} t',
        ),
        _FormulaRow(
          label: 'Stok tonajı',
          value: '${AppFormat.tonnage(summary.plannedStockTonnage!)} t',
        ),
        _FormulaRow(
          label: 'Fire oranı',
          value:
              '${AppFormat.tonnage(summary.plannedWasteTonnage!)} ÷ '
              '${AppFormat.tonnage(summary.plannedStockTonnage!)} = '
              '%${summary.plannedWastePercent!.toStringAsFixed(1)}',
          highlight: true,
        ),
        const SizedBox(height: 10),
        const _DetailTableHeader(
          cells: ['ÇAP', 'STOK', 'FİRE', 'FİRE %', 'ÇUBUK'],
        ),
        ...breakdown.map(
          (item) => _DetailTableRow(
            cells: [
              'Ø${item.diameter}',
              '${AppFormat.tonnage(item.stockTonnage)} t',
              '${AppFormat.tonnage(item.wasteTonnage)} t',
              '%${item.wastePercent.toStringAsFixed(1)}',
              '${item.totalBars}',
            ],
            accentColor: AppColors.diameterColor(item.diameter),
          ),
        ),
      ],
    );
  }
}

class _SavingsDetail extends StatelessWidget {
  const _SavingsDetail({
    required this.summary,
    required this.comparison,
    required this.batch,
  });

  final AnalysisFireSummary summary;
  final AnalysisComparison? comparison;
  final CuttingBendingBatch batch;

  @override
  Widget build(BuildContext context) {
    if (!summary.isPlannedReady || comparison == null) {
      return Text(
        'Kazanç, ham ve plan fire karşılaştırmasından hesaplanır.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      );
    }

    final comp = comparison!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Fire kazancı', style: AppTypography.labelMedium),
        const SizedBox(height: 4),
        Text(
          batch.optimizationStrategy?.label ?? 'Optimize analiz',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        _FormulaRow(
          label: 'Ham fire',
          value:
              '${AppFormat.tonnage(summary.rawWasteTonnage)} t '
              '(%${summary.rawWastePercent.toStringAsFixed(1)})',
        ),
        _FormulaRow(
          label: 'Plan fire',
          value:
              '${AppFormat.tonnage(summary.plannedWasteTonnage!)} t '
              '(%${summary.plannedWastePercent!.toStringAsFixed(1)})',
        ),
        _FormulaRow(
          label: 'Tonaj kazancı',
          value: '−${AppFormat.tonnage(summary.savedWasteTonnage)} t',
          highlight: summary.savedWasteTonnage > 0,
        ),
        _FormulaRow(
          label: 'Oran kazancı',
          value: summary.savedWastePercent > 0
              ? '−%${summary.savedWastePercent.toStringAsFixed(1)}'
              : '—',
          highlight: summary.savedWastePercent > 0,
        ),
        if (comp.lengthMatchGroupsApplied > 0 ||
            comp.tahvilGroupsApplied > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${comp.lengthMatchGroupsApplied} boy eşleştirme · '
            '${comp.tahvilGroupsApplied} tahvil uygulandı',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _FormulaRow extends StatelessWidget {
  const _FormulaRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: highlight ? AppColors.success : null,
                fontWeight: highlight ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTableHeader extends StatelessWidget {
  const _DetailTableHeader({required this.cells});

  final List<String> cells;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: i == 0 ? 2 : 3,
              child: Text(
                cells[i],
                style: AppTypography.labelSmall,
                textAlign: i == 0 ? TextAlign.start : TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailTableRow extends StatelessWidget {
  const _DetailTableRow({
    required this.cells,
    this.accentColor,
  });

  final List<String> cells;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: i == 0 ? 2 : 3,
              child: Text(
                cells[i],
                style: (i == 0 ? AppTypography.labelMedium : AppTypography.bodySmall)
                    .copyWith(color: i == 0 ? accentColor : null),
                textAlign: i == 0 ? TextAlign.start : TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }
}
