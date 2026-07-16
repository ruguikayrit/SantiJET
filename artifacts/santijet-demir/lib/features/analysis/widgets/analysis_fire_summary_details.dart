import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_table_header.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';
import 'package:santijet_demir/features/analysis/widgets/paginated_list_section.dart';

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

class _RawMaterialDetail extends ConsumerWidget {
  const _RawMaterialDetail({required this.batch});

  final CuttingBendingBatch batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byDiameter = ref.watch(analysisMaterialSummaryProvider);
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
        PaginatedListSection<RebarPieceLine>(
          items: batch.pieceLines,
          pageSize: 30,
          itemBuilder: (context, piece, index) => Padding(
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

class _RawFireDetail extends ConsumerStatefulWidget {
  const _RawFireDetail({
    required this.batch,
    required this.summary,
  });

  final CuttingBendingBatch batch;
  final AnalysisFireSummary summary;

  @override
  ConsumerState<_RawFireDetail> createState() => _RawFireDetailState();
}

class _RawFireDetailState extends ConsumerState<_RawFireDetail> {
  int? _selectedDiameter;

  @override
  Widget build(BuildContext context) {
    final breakdown = ref.watch(analysisRawFireBreakdownProvider);
    final plans = ref.watch(analysisRawStockCutPlansProvider);
    final selectedPlan = _selectedDiameter == null
        ? null
        : findStockCutPlanForDiameter(plans, _selectedDiameter!);
    final selectedBreakdown = _findBreakdown(breakdown, _selectedDiameter);

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
          value: '${AppFormat.tonnage(widget.summary.rawWasteTonnage)} t',
        ),
        _FormulaRow(
          label: 'Stok tonajı',
          value: '${AppFormat.tonnage(widget.summary.rawStockTonnage)} t',
        ),
        _FormulaRow(
          label: 'Fire oranı',
          value:
              '${AppFormat.tonnage(widget.summary.rawWasteTonnage)} ÷ '
              '${AppFormat.tonnage(widget.summary.rawStockTonnage)} = '
              '%${widget.summary.rawWastePercent.toStringAsFixed(1)}',
          highlight: true,
        ),
        const SizedBox(height: 10),
        Text(
          'Çap satırına dokunarak kesim listesi fire detayını görün',
          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
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
            selected: _selectedDiameter == item.diameter,
            onTap: () => setState(() {
              _selectedDiameter =
                  _selectedDiameter == item.diameter ? null : item.diameter;
            }),
          ),
        ),
        if (selectedPlan != null && selectedBreakdown != null)
          _FireDiameterDrillDown(
            plan: selectedPlan,
            breakdown: selectedBreakdown,
            stockLengthM: CuttingBendingBatch.defaultStockBarLengthM,
            onClose: () => setState(() => _selectedDiameter = null),
          ),
      ],
    );
  }
}

class _PlannedFireDetail extends ConsumerStatefulWidget {
  const _PlannedFireDetail({
    required this.batch,
    required this.summary,
  });

  final CuttingBendingBatch batch;
  final AnalysisFireSummary summary;

  @override
  ConsumerState<_PlannedFireDetail> createState() => _PlannedFireDetailState();
}

class _PlannedFireDetailState extends ConsumerState<_PlannedFireDetail> {
  int? _selectedDiameter;

  @override
  Widget build(BuildContext context) {
    if (!widget.summary.isPlannedReady) {
      return Text(
        'Plan fire, analiz tamamlandıktan sonra görünür.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      );
    }

    final breakdown = ref.watch(analysisPlannedFireBreakdownProvider);
    final strategy = widget.batch.optimizationStrategy?.label ?? '—';
    final selectedPlan = _selectedDiameter == null
        ? null
        : findStockCutPlanForDiameter(
            widget.batch.stockCutPlans,
            _selectedDiameter!,
          );
    final selectedBreakdown = _findBreakdown(breakdown, _selectedDiameter);

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
          value: '${AppFormat.tonnage(widget.summary.plannedWasteTonnage!)} t',
        ),
        _FormulaRow(
          label: 'Stok tonajı',
          value: '${AppFormat.tonnage(widget.summary.plannedStockTonnage!)} t',
        ),
        _FormulaRow(
          label: 'Fire oranı',
          value:
              '${AppFormat.tonnage(widget.summary.plannedWasteTonnage!)} ÷ '
              '${AppFormat.tonnage(widget.summary.plannedStockTonnage!)} = '
              '%${widget.summary.plannedWastePercent!.toStringAsFixed(1)}',
          highlight: true,
        ),
        const SizedBox(height: 10),
        Text(
          'Çap satırına dokunarak kesim listesi fire detayını görün',
          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
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
            selected: _selectedDiameter == item.diameter,
            onTap: () => setState(() {
              _selectedDiameter =
                  _selectedDiameter == item.diameter ? null : item.diameter;
            }),
          ),
        ),
        if (selectedPlan != null && selectedBreakdown != null)
          _FireDiameterDrillDown(
            plan: selectedPlan,
            breakdown: selectedBreakdown,
            stockLengthM: CuttingBendingBatch.defaultStockBarLengthM,
            onClose: () => setState(() => _selectedDiameter = null),
          ),
      ],
    );
  }
}

class _FireDiameterDrillDown extends StatefulWidget {
  const _FireDiameterDrillDown({
    required this.plan,
    required this.breakdown,
    required this.stockLengthM,
    required this.onClose,
  });

  final StockCutPlan plan;
  final FireDiameterBreakdown breakdown;
  final double stockLengthM;
  final VoidCallback onClose;

  @override
  State<_FireDiameterDrillDown> createState() => _FireDiameterDrillDownState();
}

enum _FireCutFilter {
  noWaste('Firesiz kesim'),
  withWaste('Fireli kesim');

  const _FireCutFilter(this.label);
  final String label;
}

class _FireDiameterDrillDownState extends State<_FireDiameterDrillDown> {
  late _FireCutFilter _filter;

  @override
  void initState() {
    super.initState();
    final hasWasteBars = stockBarWasteCount(widget.plan) > 0;
    _filter = hasWasteBars ? _FireCutFilter.withWaste : _FireCutFilter.noWaste;
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final breakdown = widget.breakdown;
    final stockLengthM = widget.stockLengthM;
    final diameterColor = AppColors.diameterColor(plan.diameter);
    final wasteBuckets = computeFireWasteLengthBuckets(plan);
    final wasteBarCount = stockBarWasteCount(plan);
    final noWasteBarCount = stockBarNoWasteCount(plan);
    final wasteBars = listStockBarsWithWaste(plan);
    final noWasteBars = listStockBarsWithoutWaste(plan);
    final visibleBars =
        _filter == _FireCutFilter.withWaste ? wasteBars : noWasteBars;
    final visibleTotalCount =
        _filter == _FireCutFilter.withWaste ? wasteBarCount : noWasteBarCount;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: diameterColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ø${plan.diameter} · Kesim listesi fire detayı',
                  style: AppTypography.titleMedium.copyWith(
                    color: diameterColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.textMuted,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${breakdown.totalBars} çubuk · '
            '${plan.totalWasteM.toStringAsFixed(2)} m fire · '
            '${AppFormat.tonnage(breakdown.wasteTonnage)} t · '
            '%${breakdown.wastePercent.toStringAsFixed(1)}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          if (wasteBuckets.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Kalan uzunluk özeti', style: AppTypography.labelMedium),
            const SizedBox(height: 4),
            Text(
              'Kullanılamayan fire parçaları — hangi uzunlukta ne kadar kaldı',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            const _DetailTableHeader(
              cells: ['KALAN UZUNLUK', 'ÇUBUK', 'TOPLAM FİRE', 'TONAJ'],
            ),
            ...wasteBuckets.map(
              (bucket) => _DetailTableRow(
                cells: [
                  '${bucket.wasteLengthM.toStringAsFixed(2)} m',
                  '${bucket.barCount}',
                  '${bucket.totalWasteM.toStringAsFixed(2)} m',
                  '${AppFormat.tonnage(bucket.wasteTonnage)} t',
                ],
                accentColor: diameterColor,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text('Çubuk kesim listesi', style: AppTypography.labelMedium),
          const SizedBox(height: 4),
          Text(
            wasteBarCount == 0
                ? 'Bu çapta fire oluşmadı · ${noWasteBarCount} firesiz çubuk'
                : '${noWasteBarCount} çubuk fire oluşturmadı · '
                    '${wasteBarCount} çubukta kalan parça var',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          _FireCutFilterTabs(
            selected: _filter,
            noWasteCount: noWasteBarCount,
            wasteCount: wasteBarCount,
            onSelected: (value) => setState(() => _filter = value),
          ),
          if (visibleTotalCount == 0) ...[
            const SizedBox(height: 10),
            Text(
              _filter == _FireCutFilter.withWaste
                  ? 'Fireli kesim bulunamadı.'
                  : 'Firesiz kesim bulunamadı.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ] else ...[
            if (visibleBars.length < visibleTotalCount) ...[
              const SizedBox(height: 10),
              Text(
                'Önizleme: ${visibleBars.length} / $visibleTotalCount çubuk gösteriliyor. '
                'Özet adetler tam plana göredir.',
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 8),
            PaginatedListSection<StockBarCut>(
              items: visibleBars,
              pageSize: 15,
              itemBuilder: (context, bar, index) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _FireBarCutRow(
                  bar: bar,
                  stockLengthM: stockLengthM,
                  diameterColor: diameterColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FireCutFilterTabs extends StatelessWidget {
  const _FireCutFilterTabs({
    required this.selected,
    required this.noWasteCount,
    required this.wasteCount,
    required this.onSelected,
  });

  final _FireCutFilter selected;
  final int noWasteCount;
  final int wasteCount;
  final ValueChanged<_FireCutFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in _FireCutFilter.values) ...[
          if (option != _FireCutFilter.values.first) const SizedBox(width: 8),
          Expanded(
            child: _FireCutFilterTab(
              label: option.label,
              count: option == _FireCutFilter.noWaste ? noWasteCount : wasteCount,
              selected: selected == option,
              onTap: () => onSelected(option),
            ),
          ),
        ],
      ],
    );
  }
}

class _FireCutFilterTab extends StatelessWidget {
  const _FireCutFilterTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? AppColors.electricBlueLight : AppColors.textMuted;

    return Material(
      color: selected
          ? AppColors.electricBlueLight.withValues(alpha: 0.12)
          : AppColors.canvas,
      borderRadius: AppRadii.sm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadii.sm,
            border: Border.all(
              color: selected
                  ? AppColors.electricBlueLight.withValues(alpha: 0.45)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(color: accent),
              ),
              const SizedBox(height: 2),
              Text(
                '$count çubuk',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FireBarCutRow extends StatelessWidget {
  const _FireBarCutRow({
    required this.bar,
    required this.stockLengthM,
    required this.diameterColor,
  });

  final StockBarCut bar;
  final double stockLengthM;
  final Color diameterColor;

  @override
  Widget build(BuildContext context) {
    final parts = bar.members
        .expand(
          (member) => List.filled(
            member.count,
            '${member.lengthM.toStringAsFixed(2)} m',
          ),
        )
        .join(' + ');
    final isZeroWaste = bar.wasteLengthM <= 0.001;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isZeroWaste
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.canvas,
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: isZeroWaste
              ? AppColors.success.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Çubuk ${bar.barIndex}',
            style: AppTypography.labelMedium.copyWith(color: diameterColor),
          ),
          const SizedBox(height: 4),
          Text(
            parts.isEmpty ? '—' : '$parts = ${bar.usedLengthM.toStringAsFixed(2)} m',
            style: AppTypography.bodySmall,
          ),
          Text(
            isZeroWaste
                ? 'Fire yok · ${stockLengthM.toStringAsFixed(0)} m stok tam kullanım'
                : 'Kalan: ${bar.wasteLengthM.toStringAsFixed(2)} m / '
                    '${stockLengthM.toStringAsFixed(0)} m stok',
            style: AppTypography.bodySmall.copyWith(
              color: isZeroWaste ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
            '${comp.lengthMatchGroupsApplied} uzunluk eşleştirme · '
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
    return AppTableHeaderRow(
      padding: const EdgeInsets.symmetric(vertical: 4),
      cells: [
        for (var i = 0; i < cells.length; i++)
          AppTableHeaderCell(
            cells[i],
            flex: i == 0 ? 2 : 3,
          ),
      ],
    );
  }
}

class _DetailTableRow extends StatelessWidget {
  const _DetailTableRow({
    required this.cells,
    this.accentColor,
    this.onTap,
    this.selected = false,
  });

  final List<String> cells;
  final Color? accentColor;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.electricBlueLight.withValues(alpha: 0.08)
            : null,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
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
                textAlign: TextAlign.center,
              ),
            ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              selected ? Icons.expand_less : Icons.chevron_right,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: row,
      ),
    );
  }
}

FireDiameterBreakdown? _findBreakdown(
  List<FireDiameterBreakdown> breakdown,
  int? diameter,
) {
  if (diameter == null) return null;
  for (final item in breakdown) {
    if (item.diameter == diameter) return item;
  }
  return null;
}
