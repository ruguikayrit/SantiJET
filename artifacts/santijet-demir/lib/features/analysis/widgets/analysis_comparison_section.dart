import 'package:flutter/material.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';

enum AnalysisComparisonKind {
  sourceVsRevised,
  pieceListVsRevised,
  strategyFire,
}

class AnalysisComparisonSection extends StatefulWidget {
  const AnalysisComparisonSection({super.key, required this.batch});

  final CuttingBendingBatch batch;

  @override
  State<AnalysisComparisonSection> createState() =>
      _AnalysisComparisonSectionState();
}

class _AnalysisComparisonSectionState extends State<AnalysisComparisonSection> {
  AnalysisComparisonKind _selected = AnalysisComparisonKind.sourceVsRevised;

  CuttingBendingBatch get batch => widget.batch;

  @override
  Widget build(BuildContext context) {
    final comparison =
        batch.isOptimized ? computeAnalysisComparison(batch) : null;
    final strategyRows = computeStrategyFireComparisons(batch);
    final hasStrategyData =
        strategyRows.any((row) => row.isAvailable);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Karşılaştırma seçeneği',
          style: AppTypography.labelMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Kaynak ile revize veriyi veya strateji sonuçlarını karşılaştırın',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        _ComparisonOptionBar(
          selected: _selected,
          onSelected: (kind) => setState(() => _selected = kind),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: switch (_selected) {
            AnalysisComparisonKind.sourceVsRevised => _SourceVsRevisedPanel(
                key: const ValueKey('source-vs-revised'),
                comparison: comparison,
              ),
            AnalysisComparisonKind.pieceListVsRevised => _PieceListComparisonPanel(
                key: const ValueKey('piece-list-vs-revised'),
                batch: batch,
              ),
            AnalysisComparisonKind.strategyFire => _StrategyFireComparisonPanel(
                key: const ValueKey('strategy-fire'),
                rows: strategyRows,
                hasAnyData: hasStrategyData,
              ),
          },
        ),
      ],
    );
  }
}

class _ComparisonOptionBar extends StatelessWidget {
  const _ComparisonOptionBar({
    required this.selected,
    required this.onSelected,
  });

  final AnalysisComparisonKind selected;
  final ValueChanged<AnalysisComparisonKind> onSelected;

  static const _options = [
    (
      kind: AnalysisComparisonKind.sourceVsRevised,
      label: 'Kaynak Veri ↔ Revize Veri',
      icon: Icons.compare_arrows,
    ),
    (
      kind: AnalysisComparisonKind.pieceListVsRevised,
      label: 'Ham ↔ Revize Parça',
      icon: Icons.table_rows_outlined,
    ),
    (
      kind: AnalysisComparisonKind.strategyFire,
      label: 'Strateji Fire & Kazanç',
      icon: Icons.insights_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in _options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ComparisonOptionTile(
              label: option.label,
              icon: option.icon,
              selected: selected == option.kind,
              onTap: () => onSelected(option.kind),
            ),
          ),
      ],
    );
  }
}

class _ComparisonOptionTile extends StatelessWidget {
  const _ComparisonOptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.electricBlue.withValues(alpha: 0.08)
          : AppColors.canvas,
      borderRadius: AppRadii.sm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadii.sm,
            border: Border.all(
              color: selected
                  ? AppColors.electricBlueLight.withValues(alpha: 0.45)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? AppColors.electricBlueLight
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: selected ? AppColors.electricBlueLight : null,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppColors.electricBlueLight,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceVsRevisedPanel extends StatelessWidget {
  const _SourceVsRevisedPanel({
    super.key,
    required this.comparison,
  });

  final AnalysisComparison? comparison;

  @override
  Widget build(BuildContext context) {
    if (comparison == null) {
      return const _ComparisonPlaceholder(
        message:
            'Kaynak ve revize veri karşılaştırması için fire analizi '
            'çalıştırın veya kayıtlı bir strateji yükleyin.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Kaynak veri → Revize veri', style: AppTypography.labelMedium),
          const SizedBox(height: 4),
          Text(
            'Ham parça listesi ile optimize edilmiş revize sonuç',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          _ComparisonTableHeader(cells: const ['', 'KAYNAK', 'REVİZE', 'FARK']),
          _ComparisonRow(
            label: 'Boy çeşidi',
            before: '${comparison!.rawLineCount} satır',
            after: '${comparison!.revisedLineCount} satır',
            delta: comparison!.savedLines > 0
                ? '−${comparison!.savedLines}'
                : null,
            positive: comparison!.savedLines > 0,
          ),
          _ComparisonRow(
            label: 'Toplam adet',
            before: AppFormat.integer(comparison!.rawPieceCount),
            after: AppFormat.integer(comparison!.revisedPieceCount),
            delta: comparison!.rawPieceCount != comparison!.revisedPieceCount
                ? '${comparison!.revisedPieceCount - comparison!.rawPieceCount >= 0 ? '+' : ''}${comparison!.revisedPieceCount - comparison!.rawPieceCount}'
                : null,
            positive: comparison!.revisedPieceCount >= comparison!.rawPieceCount,
          ),
          _ComparisonRow(
            label: 'Tonaj',
            before: '${AppFormat.tonnage(comparison!.rawMaterialTonnage)} t',
            after: '${AppFormat.tonnage(comparison!.revisedMaterialTonnage)} t',
          ),
          _ComparisonRow(
            label: 'Stok fire oranı',
            before: '%${comparison!.rawFirePercent.toStringAsFixed(1)}',
            after: '%${comparison!.plannedFirePercent.toStringAsFixed(1)}',
            delta: comparison!.savedFirePercent > 0.05
                ? '−%${comparison!.savedFirePercent.toStringAsFixed(1)}'
                : comparison!.savedFirePercent < -0.05
                    ? '+%${(-comparison!.savedFirePercent).toStringAsFixed(1)}'
                    : null,
            positive: comparison!.savedFirePercent > 0.05,
            negative: comparison!.savedFirePercent < -0.05,
          ),
          _ComparisonRow(
            label: 'Fire tonajı',
            before: '${AppFormat.tonnage(comparison!.rawFireTonnage)} t',
            after: '${AppFormat.tonnage(comparison!.plannedFireTonnage)} t',
            delta: comparison!.savedFireTonnage > 0
                ? '−${AppFormat.tonnage(comparison!.savedFireTonnage)} t'
                : null,
            positive: comparison!.savedFireTonnage > 0,
          ),
          if (comparison!.lengthMatchGroupsApplied > 0 ||
              comparison!.tahvilGroupsApplied > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (comparison!.lengthMatchGroupsApplied > 0)
                  _ChangeChip(
                    icon: Icons.straighten,
                    label:
                        '${comparison!.lengthMatchGroupsApplied} boy eşleştirme',
                  ),
                if (comparison!.tahvilGroupsApplied > 0)
                  _ChangeChip(
                    icon: Icons.swap_horiz,
                    label: '${comparison!.tahvilGroupsApplied} tahvil',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PieceListComparisonPanel extends StatelessWidget {
  const _PieceListComparisonPanel({
    super.key,
    required this.batch,
  });

  final CuttingBendingBatch batch;

  @override
  Widget build(BuildContext context) {
    if (!batch.isOptimized || batch.revisedPieceLines.isEmpty) {
      return const _ComparisonPlaceholder(
        message:
            'Ham ve revize parça listesi karşılaştırması için fire analizi '
            'tamamlanmalıdır.',
      );
    }

    final unchangedKeys = _unchangedPieceKeys(
      batch.pieceLines,
      batch.revisedPieceLines,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ham parça listesi ↔ Revize parça listesi',
            style: AppTypography.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${batch.pieceLines.length} ham satır · '
            '${batch.revisedPieceLines.length} revize satır',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          _PieceCompareLegend(
            unchangedCount: unchangedKeys.length,
            changedRawCount:
                batch.pieceLines.where((p) => !_isUnchangedPiece(p, unchangedKeys)).length,
            changedRevisedCount: batch.revisedPieceLines
                .where((p) => !_isUnchangedPiece(p, unchangedKeys))
                .length,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final sideBySide = constraints.maxWidth >= 520;
              if (sideBySide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PieceListBlock(
                        title: 'Ham parça listesi',
                        pieces: batch.pieceLines,
                        unchangedKeys: unchangedKeys,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PieceListBlock(
                        title: 'Revize parça listesi',
                        pieces: batch.revisedPieceLines,
                        unchangedKeys: unchangedKeys,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PieceListBlock(
                    title: 'Ham parça listesi',
                    pieces: batch.pieceLines,
                    unchangedKeys: unchangedKeys,
                  ),
                  const SizedBox(height: 16),
                  _PieceListBlock(
                    title: 'Revize parça listesi',
                    pieces: batch.revisedPieceLines,
                    unchangedKeys: unchangedKeys,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

String _pieceCompareKey(RebarPieceLine piece) =>
    '${piece.diameter}|${piece.lengthM.toStringAsFixed(4)}|${piece.quantity}';

Set<String> _unchangedPieceKeys(
  List<RebarPieceLine> raw,
  List<RebarPieceLine> revised,
) {
  final rawKeys = raw.map(_pieceCompareKey).toSet();
  final revisedKeys = revised.map(_pieceCompareKey).toSet();
  return rawKeys.intersection(revisedKeys);
}

bool _isUnchangedPiece(RebarPieceLine piece, Set<String> unchangedKeys) =>
    unchangedKeys.contains(_pieceCompareKey(piece));

class _PieceCompareLegend extends StatelessWidget {
  const _PieceCompareLegend({
    required this.unchangedCount,
    required this.changedRawCount,
    required this.changedRevisedCount,
  });

  final int unchangedCount;
  final int changedRawCount;
  final int changedRevisedCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _LegendItem(
          color: AppColors.success,
          label: 'Değişmeyen ($unchangedCount)',
        ),
        _LegendItem(
          color: AppColors.diameter28,
          label: 'Değişen (ham $changedRawCount · revize $changedRevisedCount)',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _PieceListBlock extends StatelessWidget {
  const _PieceListBlock({
    required this.title,
    required this.pieces,
    required this.unchangedKeys,
  });

  final String title;
  final List<RebarPieceLine> pieces;
  final Set<String> unchangedKeys;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        if (pieces.isEmpty)
          const ModuleEmptyState(type: EmptyStateType.noSearchResult, inline: true)
        else ...[
          const _PieceTableHeader(cells: ['ÇAP', 'BOY (m)', 'ADET']),
          ...pieces.map(
            (piece) {
              final unchanged = _isUnchangedPiece(piece, unchangedKeys);
              return _PieceTableRow(
                cells: [
                  'Ø${piece.diameter}',
                  piece.lengthM.toStringAsFixed(2),
                  AppFormat.integer(piece.quantity),
                ],
                textColor: unchanged ? AppColors.success : AppColors.diameter28,
              );
            },
          ),
        ],
      ],
    );
  }
}

class _StrategyFireComparisonPanel extends StatelessWidget {
  const _StrategyFireComparisonPanel({
    super.key,
    required this.rows,
    required this.hasAnyData,
  });

  final List<StrategyFireComparison> rows;
  final bool hasAnyData;

  @override
  Widget build(BuildContext context) {
    if (!hasAnyData) {
      return const _ComparisonPlaceholder(
        message:
            'Strateji fire karşılaştırması için her stratejiyi analiz edip '
            'kaydedin.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Fire azaltma stratejilerine göre plan fire & kazanç',
            style: AppTypography.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Ham fireye göre plan fire ve tonaj kazancı',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          const _ComparisonTableHeader(
            cells: ['STRATEJİ', 'PLAN FİRE', 'KAZANÇ', 'DURUM'],
          ),
          ...rows.map(
            (row) => _StrategyFireRow(row: row),
          ),
        ],
      ),
    );
  }
}

class _StrategyFireRow extends StatelessWidget {
  const _StrategyFireRow({required this.row});

  final StrategyFireComparison row;

  @override
  Widget build(BuildContext context) {
    final statusParts = <String>[];
    if (row.isActive) statusParts.add('Aktif');
    if (row.isSaved) statusParts.add('Kayıtlı');
    final status = row.isAvailable
        ? statusParts.join(' · ')
        : 'Analiz yok';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(row.strategy.label, style: AppTypography.bodySmall),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.isAvailable
                  ? '${AppFormat.tonnage(row.plannedFireTonnage!)} t\n'
                      '%${row.plannedFirePercent!.toStringAsFixed(1)}'
                  : '—',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.isAvailable && (row.savedFireTonnage ?? 0) > 0
                  ? '−${AppFormat.tonnage(row.savedFireTonnage!)} t\n'
                      '−%${row.savedFirePercent!.toStringAsFixed(1)}'
                  : row.isAvailable
                      ? '—'
                      : '—',
              style: AppTypography.bodySmall.copyWith(
                color: row.isAvailable && (row.savedFireTonnage ?? 0) > 0
                    ? AppColors.success
                    : null,
                fontWeight: row.isAvailable && (row.savedFireTonnage ?? 0) > 0
                    ? FontWeight.w600
                    : null,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              status,
              style: AppTypography.labelSmall.copyWith(
                color: row.isAvailable
                    ? AppColors.electricBlueLight
                    : AppColors.textMuted,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonPlaceholder extends StatelessWidget {
  const _ComparisonPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.compare_outlined, size: 36, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ComparisonTableHeader extends StatelessWidget {
  const _ComparisonTableHeader({required this.cells});

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

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.before,
    required this.after,
    this.delta,
    this.positive = false,
    this.negative = false,
  });

  final String label;
  final String before;
  final String after;
  final String? delta;
  final bool positive;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final afterColor = positive
        ? AppColors.success
        : negative
            ? AppColors.warning
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              before,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.end,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.arrow_forward, size: 14, color: AppColors.textMuted),
          ),
          Expanded(
            child: Text(
              after,
              style: AppTypography.bodySmall.copyWith(
                color: afterColor,
                fontWeight: (positive || negative) ? FontWeight.w600 : null,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          if (delta != null)
            SizedBox(
              width: 64,
              child: Text(
                delta!,
                style: AppTypography.labelMedium.copyWith(
                  color: positive
                      ? AppColors.success
                      : negative
                          ? AppColors.warning
                          : AppColors.textMuted,
                ),
                textAlign: TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  const _ChangeChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: AppRadii.full,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

class _PieceTableHeader extends StatelessWidget {
  const _PieceTableHeader({required this.cells});

  final List<String> cells;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              child: Text(
                cells[i],
                style: AppTypography.labelSmall,
                textAlign: i == cells.length - 1 ? TextAlign.end : TextAlign.start,
              ),
            ),
        ],
      ),
    );
  }
}

class _PieceTableRow extends StatelessWidget {
  const _PieceTableRow({
    required this.cells,
    this.accentColor,
    this.textColor,
  });

  final List<String> cells;
  final Color? accentColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              child: Text(
                cells[i],
                style: (i == 0 ? AppTypography.labelMedium : AppTypography.bodySmall)
                    .copyWith(
                  color: textColor ?? (i == 0 ? accentColor : null),
                  fontWeight: textColor != null ? FontWeight.w600 : null,
                ),
                textAlign: i == cells.length - 1 ? TextAlign.end : TextAlign.start,
              ),
            ),
        ],
      ),
    );
  }
}
