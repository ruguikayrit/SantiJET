import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_table_header.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';
import 'package:santijet_demir/features/analysis/widgets/paginated_list_section.dart';

enum AnalysisComparisonKind {
  sourceVsRevised,
  pieceListVsRevised,
  strategyFire,
}

class AnalysisComparisonSection extends ConsumerStatefulWidget {
  const AnalysisComparisonSection({super.key, required this.batch});

  final CuttingBendingBatch batch;

  @override
  ConsumerState<AnalysisComparisonSection> createState() =>
      _AnalysisComparisonSectionState();
}

class _AnalysisComparisonSectionState
    extends ConsumerState<AnalysisComparisonSection> {
  AnalysisComparisonKind _selected = AnalysisComparisonKind.sourceVsRevised;

  CuttingBendingBatch get batch => widget.batch;

  @override
  Widget build(BuildContext context) {
    final comparison = ref.watch(analysisComparisonProvider);
    final strategyRows = ref.watch(analysisStrategyComparisonProvider);
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

class _PieceListComparisonPanel extends ConsumerWidget {
  const _PieceListComparisonPanel({
    super.key,
    required this.batch,
  });

  final CuttingBendingBatch batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!batch.isOptimized || batch.revisedPieceLines.isEmpty) {
      return const _ComparisonPlaceholder(
        message:
            'Ham ve revize parça listesi karşılaştırması için fire analizi '
            'tamamlanmalıdır.',
      );
    }

    final rows = ref.watch(analysisPieceListComparisonProvider);
    final unchangedCount = rows.where((row) => !row.isChanged).length;
    final changedCount = rows.length - unchangedCount;

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
            unchangedCount: unchangedCount,
            changedCount: changedCount,
          ),
          const SizedBox(height: 12),
          _HamRevizePieceComparisonTable(rows: rows),
        ],
      ),
    );
  }
}

class _HamRevizePieceComparisonTable extends StatelessWidget {
  const _HamRevizePieceComparisonTable({required this.rows});

  final List<PieceListComparisonRow> rows;

  static const _capWidth = 48.0;
  static const _adetWidth = 56.0;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const ModuleEmptyState(type: EmptyStateType.noSearchResult, inline: true);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.sm,
        child: PaginatedListSection<PieceListComparisonRow>(
          pageSize: PaginatedListSection.defaultPageSize,
          items: rows,
          header: _headerRow(),
          itemBuilder: (context, row, index) => _dataRowWidget(row),
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _capWidth,
              child: const AppTableHeaderBadge('ÇAP', align: TextAlign.start),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 115,
              child: const AppTableHeaderBadge('ÖNCE', align: TextAlign.start),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 115,
              child: const AppTableHeaderBadge('SONRA', align: TextAlign.start),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 85,
              child: const AppTableHeaderBadge('Δ cm', align: TextAlign.end),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: _adetWidth,
              child: const AppTableHeaderBadge('ADET', align: TextAlign.end),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataRowWidget(PieceListComparisonRow row) {
    final accent = row.isChanged ? AppColors.warning : AppColors.success;
    final deltaText = _formatDeltaCm(row.deltaCm);

    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _capWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 4, 0),
              child: Text(
                'Ø${row.beforeDiameter}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.diameterColor(row.beforeDiameter),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 115,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
              child: _LengthCell(
                lengthM: row.beforeLengthM,
                emphasize: false,
              ),
            ),
          ),
          Expanded(
            flex: 115,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
              child: _LengthCell(
                diameter: row.afterDiameter,
                lengthM: row.afterLengthM,
                emphasize: row.isChanged,
                accent: accent,
                showDiameter: row.beforeDiameter != row.afterDiameter,
              ),
            ),
          ),
          Expanded(
            flex: 85,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                deltaText,
                style: AppTypography.labelMedium.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
          SizedBox(
            width: _adetWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
              child: Text(
                AppFormat.integer(row.quantity),
                style: AppTypography.bodySmall.copyWith(
                  color: row.isChanged ? accent : AppColors.textPrimary,
                  fontWeight: row.isChanged ? FontWeight.w600 : null,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDeltaCm(double deltaCm) {
    if (deltaCm.abs() < 0.05) return '0';
    final prefix = deltaCm > 0 ? '+' : '';
    return '$prefix${deltaCm.toStringAsFixed(1)}';
  }
}

class _LengthCell extends StatelessWidget {
  const _LengthCell({
    required this.lengthM,
    required this.emphasize,
    this.diameter,
    this.accent,
    this.showDiameter = false,
  });

  final int? diameter;
  final double lengthM;
  final bool emphasize;
  final Color? accent;
  final bool showDiameter;

  @override
  Widget build(BuildContext context) {
    final lengthText = '${lengthM.toStringAsFixed(2)} m';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDiameter && diameter != null)
          Text(
            'Ø$diameter',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.diameterColor(diameter!),
              fontWeight: FontWeight.w600,
            ),
          ),
        Text(
          lengthText,
          style: AppTypography.bodySmall.copyWith(
            color: emphasize ? accent : AppColors.textPrimary,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PieceCompareLegend extends StatelessWidget {
  const _PieceCompareLegend({
    required this.unchangedCount,
    required this.changedCount,
  });

  final int unchangedCount;
  final int changedCount;

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
          color: AppColors.warning,
          label: 'Değişen ($changedCount)',
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
    return AppTableHeaderRow(
      padding: const EdgeInsets.symmetric(vertical: 4),
      cells: [
        for (var i = 0; i < cells.length; i++)
          AppTableHeaderCell(
            cells[i],
            flex: i == 0 ? 2 : 3,
            align: i == 0 ? TextAlign.start : TextAlign.end,
          ),
      ],
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
