import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/widgets/app_description_lines.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';
import 'package:santijet_demir/features/analysis/widgets/stock_bar_cut_visual.dart';

String _formatLengthM(double lengthM) {
  if (lengthM >= 100) return AppFormat.integer(lengthM.round());
  return lengthM.toStringAsFixed(2).replaceAll('.', ',');
}

String _formatFireM(double lengthM) =>
    lengthM.toStringAsFixed(2).replaceAll('.', ',');

String _formatFirePercent(double percent) {
  final rounded = (percent * 10).round() / 10;
  if ((rounded - rounded.roundToDouble()).abs() < 0.05) {
    return rounded.round().toString();
  }
  return rounded.toStringAsFixed(1);
}

Color _fireAccentColor(double wastePercent) {
  if (wastePercent <= 1.5) return AppColors.success;
  if (wastePercent <= 4) return AppColors.warning;
  return AppColors.critical;
}

class StockCutSection extends StatelessWidget {
  const StockCutSection({
    super.key,
    required this.batchId,
    required this.plans,
    this.stockLengthM = CuttingBendingBatch.defaultStockBarLengthM,
  });

  final String batchId;
  final List<StockCutPlan> plans;
  final double stockLengthM;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const AppDescriptionLines([
        'Parça listesi boş.',
        'Kesim planı oluşturulamadı.',
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDescriptionLines([
          '${stockLengthM.toStringAsFixed(0)} m stok uzunluğu.',
          'Planlı minimum fire kesim.',
        ]),
        const SizedBox(height: 8),
        ...plans.map(
          (plan) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CollapsibleDiameterCutPlanCard(
              batchId: batchId,
              plan: plan,
              stockLengthM: stockLengthM,
            ),
          ),
        ),
      ],
    );
  }
}

class _CollapsibleDiameterCutPlanCard extends ConsumerWidget {
  const _CollapsibleDiameterCutPlanCard({
    required this.batchId,
    required this.plan,
    required this.stockLengthM,
  });

  final String batchId;
  final StockCutPlan plan;
  final double stockLengthM;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionId = AnalysisSectionIds.stockCutDiameter(batchId, plan.diameter);
    final expanded = ref.watch(analysisSectionExpandedProvider(sectionId));
    final diameterColor = AppColors.diameterColor(plan.diameter);
    final fireColor = _fireAccentColor(plan.wastePercent);
    final firePercentLabel = '%${_formatFirePercent(plan.wastePercent)}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref
                    .read(analysisSectionExpandedProvider(sectionId).notifier)
                    .state = !expanded;
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: diameterColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: diameterColor.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        'Ø${plan.diameter}',
                        style: AppTypography.titleMedium.copyWith(
                          color: diameterColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ø${plan.diameter} Kesim Özeti',
                            style: AppTypography.titleMedium,
                          ),
                          if (!expanded) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${AppFormat.integer(plan.totalBars)} ad · '
                              '${AppFormat.tonnage(plan.totalUsedTonnage)} t · '
                              'fire $firePercentLabel',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 22,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CutPlanSummaryGrid(
                    plan: plan,
                    diameterColor: diameterColor,
                    fireColor: fireColor,
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Text('Kesim Planı', style: AppTypography.labelMedium),
                  const SizedBox(height: 10),
                  _PaginatedStockBarCutList(
                    bars: plan.bars,
                    totalBars: plan.totalBars,
                    stockLengthM: stockLengthM,
                    diameterColor: diameterColor,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CutPlanSummaryGrid extends StatelessWidget {
  const _CutPlanSummaryGrid({
    required this.plan,
    required this.diameterColor,
    required this.fireColor,
  });

  final StockCutPlan plan;
  final Color diameterColor;
  final Color fireColor;

  @override
  Widget build(BuildContext context) {
    final firePercentLabel = '%${_formatFirePercent(plan.wastePercent)}';
    final cards = [
      _CutSummaryCard(
        label: 'Toplam Çubuk',
        value: AppFormat.integer(plan.totalBars),
        unit: 'ad',
        accentColor: diameterColor,
      ),
      _CutSummaryCard(
        label: 'Kullanılan Metraj',
        value: _formatLengthM(plan.totalUsedM),
        unit: 'mt',
        accentColor: AppColors.electricBlueLight,
      ),
      _CutSummaryCard(
        label: 'Fire Metraj',
        value: _formatFireM(plan.totalWasteM),
        unit: 'm',
        subValue: firePercentLabel,
        accentColor: fireColor,
      ),
      _CutSummaryCard(
        label: 'Kesilen Tonaj',
        value: AppFormat.tonnage(plan.totalStockTonnage),
        unit: 't',
        accentColor: AppColors.electricBlueLight,
      ),
      _CutSummaryCard(
        label: 'Kullanılan Tonaj',
        value: AppFormat.tonnage(plan.totalUsedTonnage),
        unit: 't',
        accentColor: AppColors.success,
      ),
      _CutSummaryCard(
        label: 'Fire Tonaj',
        value: AppFormat.tonnage(plan.totalWasteTonnage),
        unit: 't',
        subValue: firePercentLabel,
        accentColor: fireColor,
      ),
    ];

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: cards[i],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 3; i < 6; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
                  child: cards[i],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CutSummaryCard extends StatelessWidget {
  const _CutSummaryCard({
    required this.label,
    required this.value,
    required this.accentColor,
    this.unit,
    this.subValue,
  });

  final String label;
  final String value;
  final String? unit;
  final String? subValue;
  final Color accentColor;

  static const _cardHeight = 86.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _cardHeight,
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 26,
            child: _SummaryLabel(label: label),
          ),
          const Spacer(),
          LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: AppTypography.titleMedium.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      if (unit != null && unit!.isNotEmpty) ...[
                        const SizedBox(width: 3),
                        Text(
                          unit!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(
            height: 15,
            child: Align(
              alignment: Alignment.centerLeft,
              child: subValue == null
                  ? const SizedBox.shrink()
                  : Text(
                      subValue!,
                      style: AppTypography.labelSmall.copyWith(
                        color: accentColor.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLabel extends StatelessWidget {
  const _SummaryLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final parts = label.trim().split(RegExp(r'\s+'));
    if (parts.length == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            parts[0],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              height: 1.15,
            ),
          ),
          Text(
            parts[1],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              height: 1.15,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textMuted,
        height: 1.15,
      ),
    );
  }
}

class _PaginatedStockBarCutList extends StatefulWidget {
  const _PaginatedStockBarCutList({
    required this.bars,
    required this.totalBars,
    required this.stockLengthM,
    required this.diameterColor,
  });

  static const pageSize = 10;

  final List<StockBarCut> bars;
  final int totalBars;
  final double stockLengthM;
  final Color diameterColor;

  @override
  State<_PaginatedStockBarCutList> createState() =>
      _PaginatedStockBarCutListState();
}

class _PaginatedStockBarCutListState extends State<_PaginatedStockBarCutList> {
  static const _pageSize = _PaginatedStockBarCutList.pageSize;

  int _visibleCount = _pageSize;

  @override
  void didUpdateWidget(covariant _PaginatedStockBarCutList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bars.length != widget.bars.length ||
        oldWidget.bars != widget.bars) {
      _visibleCount = _pageSize;
    }
  }

  void _showMore() {
    final groupCount = groupIdenticalStockBarCuts(widget.bars).length;
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, groupCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = groupIdenticalStockBarCuts(widget.bars);
    if (groups.isEmpty) {
      return Text(
        'Kesim planı boş.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      );
    }

    final visibleGroups = groups.take(_visibleCount).toList();
    final remaining = groups.length - _visibleCount;
    final nextBatch = remaining > _pageSize ? _pageSize : remaining;
    final listedBarCount =
        groups.fold<int>(0, (sum, group) => sum + group.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.totalBars > listedBarCount) ...[
          AppDescriptionLines([
            'Önizleme: ilk $listedBarCount / ${AppFormat.integer(widget.totalBars)} çubuk.',
            '${groups.length} kesim grubu.',
            'Özet tonaj ve fire değerleri tam plana göredir.',
          ]),
          const SizedBox(height: 8),
        ] else if (groups.length < listedBarCount) ...[
          AppDescriptionLines([
            '$listedBarCount çubuk.',
            '${groups.length} kesim grubu (aynı kesimler birleştirildi).',
          ]),
          const SizedBox(height: 8),
        ],
        ...visibleGroups.map(
          (group) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: StockBarCutVisualCard.fromGroup(
              group: group,
              stockLengthM: widget.stockLengthM,
              diameterColor: widget.diameterColor,
              remainderLabelStyle: StockBarRemainderLabel.fire,
            ),
          ),
        ),
        if (remaining > 0) ...[
          const SizedBox(height: 4),
          OutlinedButton(
            onPressed: _showMore,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              foregroundColor: AppColors.electricBlueLight,
              side: BorderSide(
                color: AppColors.electricBlue.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              nextBatch == _pageSize
                  ? '10 grup daha göster ($remaining kaldı)'
                  : '$nextBatch grup daha göster',
            ),
          ),
        ] else if (groups.length > _pageSize) ...[
          const SizedBox(height: 4),
          Text(
            '${groups.length} kesim grubu listelendi',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
