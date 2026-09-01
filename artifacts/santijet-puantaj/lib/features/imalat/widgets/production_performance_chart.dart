import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/puantaj_date.dart';
import '../../../data/providers/production_performance_chart_options_provider.dart';
import '../../../data/services/production_performance_chart_options.dart';
import '../../../domain/entities/production.dart';

/// İmalat kartı — gerçekleşen metraj + plan karşılaştırması.
///
/// Mantık (değişmez):
/// - Çubuk = seçilen periyottaki gerçekleşen metraj
/// - Plan = aynı periyot için beklenen metraj (günlük tempo × gün sayısı)
class ProductionPerformanceChart extends ConsumerStatefulWidget {
  const ProductionPerformanceChart({
    required this.production,
    super.key,
    this.height = 132,
  });

  final Production production;
  final double height;

  static const visibleBucketCount = 12;

  @override
  ConsumerState<ProductionPerformanceChart> createState() =>
      _ProductionPerformanceChartState();
}

class _ProductionPerformanceChartState
    extends ConsumerState<ProductionPerformanceChart> {
  final ScrollController _scrollController = ScrollController();
  ProductionPerformancePeriod? _lastPeriod;
  int _lastBucketCount = 0;
  String? _lastProductionId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEndIfNeeded(int bucketCount, ProductionPerformancePeriod period) {
    if (bucketCount <= ProductionPerformanceChart.visibleBucketCount) return;
    if (widget.production.id != _lastProductionId) {
      _lastProductionId = widget.production.id;
      _lastPeriod = null;
      _lastBucketCount = 0;
    }
    if (_lastPeriod == period && _lastBucketCount == bucketCount) return;
    _lastPeriod = period;
    _lastBucketCount = bucketCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  static DateTime _weekStart(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  static Map<DateTime, double> _dailyTotals(Production p) {
    final byDay = <DateTime, double>{};
    for (final e in p.dailyEntries) {
      final d = PuantajDate.tryParse(e.date);
      if (d == null || e.completedQty <= 0) continue;
      final key = DateTime(d.year, d.month, d.day);
      byDay[key] = (byDay[key] ?? 0) + e.completedQty;
    }
    return byDay;
  }

  static List<_PeriodBucket> _buckets(
    Production p,
    ProductionPerformancePeriod period,
  ) {
    final daily = _dailyTotals(p);
    if (daily.isEmpty) return const [];

    final planQty = p.plannedQty;
    final planDays = p.plannedDays;
    final hasPlan = planQty > 0 && planDays > 0;
    final dailyPlan = hasPlan ? planQty / planDays : 0.0;

    switch (period) {
      case ProductionPerformancePeriod.daily:
        final keys = daily.keys.toList()..sort();
        return [
          for (final d in keys)
            _PeriodBucket(
              label: '${d.day}.${d.month}',
              tooltipTitle: PuantajDate.format(d),
              actual: daily[d]!,
              planned: dailyPlan,
            ),
        ];
      case ProductionPerformancePeriod.weekly:
        final byWeek = <DateTime, double>{};
        for (final e in daily.entries) {
          final w = _weekStart(e.key);
          byWeek[w] = (byWeek[w] ?? 0) + e.value;
        }
        final weeks = byWeek.keys.toList()..sort();
        return [
          for (final w in weeks)
            _PeriodBucket(
              label: '${w.day}.${w.month}',
              tooltipTitle: PuantajDate.weekLabel([
                PuantajDate.format(w),
                PuantajDate.format(w.add(const Duration(days: 6))),
              ]),
              actual: byWeek[w]!,
              planned: dailyPlan * 7,
            ),
        ];
      case ProductionPerformancePeriod.monthly:
        final byMonth = <(int y, int m), double>{};
        for (final e in daily.entries) {
          final key = (e.key.year, e.key.month);
          byMonth[key] = (byMonth[key] ?? 0) + e.value;
        }
        final months = byMonth.keys.toList()
          ..sort((a, b) {
            if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
            return a.$2.compareTo(b.$2);
          });
        return [
          for (final (y, m) in months)
            _PeriodBucket(
              label: PuantajDate.trMonths[m - 1].length > 3
                  ? PuantajDate.trMonths[m - 1].substring(0, 3)
                  : PuantajDate.trMonths[m - 1],
              tooltipTitle: PuantajDate.monthLabel(PuantajDate.format(DateTime(y, m, 1))),
              actual: byMonth[(y, m)]!,
              planned: dailyPlan * DateTime(y, m + 1, 0).day,
            ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = ref.watch(productionPerformanceChartOptionsProvider);
    final buckets = _buckets(widget.production, options.period);
    if (buckets.isEmpty) return const SizedBox.shrink();

    _scrollToEndIfNeeded(buckets.length, options.period);

    final unit =
        widget.production.unit.trim().isEmpty ? '' : widget.production.unit.trim();
    final planQty = widget.production.plannedQty;
    final planDays = widget.production.plannedDays;
    final hasPlan = planQty > 0 && planDays > 0;
    final dailyPlan = hasPlan ? planQty / planDays : 0.0;

    final totalActual = buckets.fold<double>(0, (s, b) => s + b.actual);
    final avgActual = totalActual / buckets.length;

    final planPerPeriod = buckets.isEmpty
        ? 0.0
        : buckets.fold<double>(0, (s, b) => s + b.planned) / buckets.length;

    final maxBar = buckets.fold<double>(0, (m, b) {
      final v = options.style == ProductionPerformanceStyle.compare
          ? (b.actual > b.planned ? b.actual : b.planned)
          : b.actual;
      return v > m ? v : m;
    });
    final refLine = options.period == ProductionPerformancePeriod.daily &&
            hasPlan &&
            options.style != ProductionPerformanceStyle.compare
        ? dailyPlan
        : 0.0;
    final maxY = [
      maxBar,
      refLine,
      for (final b in buckets)
        if (options.style != ProductionPerformanceStyle.compare && hasPlan)
          b.planned,
    ].fold<double>(0, (m, v) => v > m ? v : m);
    final top = maxY <= 0 ? 1.0 : maxY * 1.22;

    String? paceLabel;
    Color? paceColor;
    if (hasPlan && avgActual > 0 && planPerPeriod > 0) {
      final ratio = avgActual / planPerPeriod;
      if (ratio >= 1.05) {
        paceLabel = 'Plan temposunun önünde';
        paceColor = AppColors.success;
      } else if (ratio <= 0.95) {
        paceLabel = 'Plan temposunun gerisinde';
        paceColor = AppColors.critical;
      } else {
        paceLabel = 'Plan temposunda';
        paceColor = AppColors.info;
      }
    }

    final periodUnit = switch (options.period) {
      ProductionPerformancePeriod.daily => 'gün',
      ProductionPerformancePeriod.weekly => 'hafta',
      ProductionPerformancePeriod.monthly => 'ay',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Metraj · ${options.period.label}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (paceLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: paceColor!.withValues(alpha: 0.14),
                  borderRadius: AppRadii.full,
                  border: Border.all(color: paceColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  paceLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.statusInkOnCard(paceColor),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final p in ProductionPerformancePeriod.values)
              FilterChip(
                label: Text(p.label),
                selected: options.period == p,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => ref
                    .read(productionPerformanceChartOptionsProvider.notifier)
                    .save(options.copyWith(period: p)),
              ),
            for (final s in ProductionPerformanceStyle.values)
              FilterChip(
                label: Text(s.label),
                selected: options.style == s,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => ref
                    .read(productionPerformanceChartOptionsProvider.notifier)
                    .save(options.copyWith(style: s)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _hintText(options, hasPlan, dailyPlan, unit, periodUnit),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final viewportW = constraints.maxWidth - 30;
            final scrollable = buckets.length >
                ProductionPerformanceChart.visibleBucketCount;
            final slotW = scrollable
                ? viewportW / ProductionPerformanceChart.visibleBucketCount
                : viewportW / buckets.length;
            final chartW = scrollable ? slotW * buckets.length : viewportW;
            final barWidth = _barWidth(
              slotW: slotW,
              style: options.style,
              hasPlan: hasPlan,
            );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 30,
                  height: widget.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmt(top),
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                      ),
                      Text(
                        _fmt(top / 2),
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                      ),
                      Text(
                        '0',
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: scrollable
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: chartW,
                      height: widget.height,
                      child: BarChart(
                        _chartData(
                          theme: theme,
                          buckets: buckets,
                          top: top,
                          unit: unit,
                          hasPlan: hasPlan,
                          dailyPlan: dailyPlan,
                          style: options.style,
                          period: options.period,
                          barWidth: barWidth,
                          groupsSpace: scrollable ? 6 : (buckets.length <= 4 ? 16 : 8),
                          showLeftTitles: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (buckets.length > ProductionPerformanceChart.visibleBucketCount) ...[
          const SizedBox(height: 4),
          Text(
            'Daha eski ${options.period.label.toLowerCase()} kayıtları için grafiği kaydırın',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          hasPlan
              ? 'Ort. ${_fmt(avgActual)}${unit.isEmpty ? '' : ' $unit'}/$periodUnit'
                  ' · Plan ${_fmt(planPerPeriod)}${unit.isEmpty ? '' : ' $unit'}/$periodUnit'
                  ' · Toplam ${_fmt(totalActual)}${unit.isEmpty ? '' : ' $unit'}'
                  '${planQty > 0 ? ' / ${_fmt(planQty)}' : ''}'
              : 'Ort. ${_fmt(avgActual)}${unit.isEmpty ? '' : ' $unit'}/$periodUnit'
                  ' · Toplam ${_fmt(totalActual)}${unit.isEmpty ? '' : ' $unit'}'
                  ' · ${buckets.length} $periodUnit',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  static double _barWidth({
    required double slotW,
    required ProductionPerformanceStyle style,
    required bool hasPlan,
  }) {
    final pair = style == ProductionPerformanceStyle.compare && hasPlan;
    final usable = slotW - (pair ? 12 : 8);
    return pair ? (usable / 2).clamp(6.0, 14.0) : usable.clamp(8.0, 18.0);
  }

  static String _hintText(
    ProductionPerformanceChartOptions options,
    bool hasPlan,
    double dailyPlan,
    String unit,
    String periodUnit,
  ) {
    final u = unit.isEmpty ? '' : ' $unit';
    if (!hasPlan) {
      return 'Çubuk: $periodUnit gerçekleşen metraj';
    }
    return switch (options.style) {
      ProductionPerformanceStyle.compare =>
        'Mavi: gerçekleşen · turuncu: plan ($periodUnit)',
      ProductionPerformanceStyle.minimal =>
        'Çubuk: gerçekleşen · ince çizgi: plan',
      ProductionPerformanceStyle.classic =>
        switch (options.period) {
          ProductionPerformancePeriod.daily =>
            'Çubuk: gerçekleşen · çizgi: plan temposu (${_fmt(dailyPlan)}$u/gün)',
          _ => 'Çubuk: gerçekleşen · arka plan: plan ($periodUnit)',
        },
    };
  }

  static BarChartData _chartData({
    required ThemeData theme,
    required List<_PeriodBucket> buckets,
    required double top,
    required String unit,
    required bool hasPlan,
    required double dailyPlan,
    required ProductionPerformanceStyle style,
    required ProductionPerformancePeriod period,
    required double barWidth,
    required double groupsSpace,
    bool showLeftTitles = true,
  }) {
    Color actualColor(_PeriodBucket b) {
      if (!hasPlan || b.planned <= 0) return AppColors.electricBlue;
      return b.actual + 0.0001 >= b.planned
          ? AppColors.success
          : AppColors.electricBlue;
    }

    return BarChartData(
      maxY: top,
      minY: 0,
      alignment: BarChartAlignment.spaceBetween,
      groupsSpace: groupsSpace,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) =>
              theme.colorScheme.inverseSurface.withValues(alpha: 0.92),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final b = buckets[group.x.toInt()];
            final qtyLine = unit.isEmpty
                ? _fmt(rod.toY)
                : '${_fmt(rod.toY)} $unit';
            final planLine = hasPlan && b.planned > 0
                ? '\nPlan: ${_fmt(b.planned)}${unit.isEmpty ? '' : ' $unit'}'
                : '';
            final kind = style == ProductionPerformanceStyle.compare &&
                    rodIndex == 1
                ? 'Plan'
                : 'Gerçek';
            return BarTooltipItem(
              '${b.tooltipTitle}\n$kind: $qtyLine$planLine',
              TextStyle(
                color: theme.colorScheme.onInverseSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            );
          },
        ),
      ),
      gridData: FlGridData(
        show: style != ProductionPerformanceStyle.minimal,
        drawVerticalLine: false,
        horizontalInterval: top / 4,
        getDrawingHorizontalLine: (_) => FlLine(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: style == ProductionPerformanceStyle.minimal ? 0.25 : 0.4,
          ),
          strokeWidth: style == ProductionPerformanceStyle.minimal ? 0.5 : 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      extraLinesData: hasPlan &&
              period == ProductionPerformancePeriod.daily &&
              style != ProductionPerformanceStyle.compare
          ? ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: dailyPlan,
                  color: style == ProductionPerformanceStyle.minimal
                      ? AppColors.warning.withValues(alpha: 0.55)
                      : AppColors.warning,
                  strokeWidth: style == ProductionPerformanceStyle.minimal ? 1 : 1.5,
                  dashArray: style == ProductionPerformanceStyle.minimal
                      ? const [3, 3]
                      : const [6, 4],
                  label: HorizontalLineLabel(
                    show: style != ProductionPerformanceStyle.minimal,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(right: 4, bottom: 2),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                    labelResolver: (_) => 'Plan',
                  ),
                ),
              ],
            )
          : null,
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: showLeftTitles,
            reservedSize: 30,
            interval: top / 2,
            getTitlesWidget: (v, meta) {
              if (!showLeftTitles) return const SizedBox.shrink();
              if ((v - meta.min).abs() < 0.001 ||
                  (v - meta.max).abs() < 0.001 ||
                  (v - top / 2).abs() < top * 0.05) {
                return Text(
                  _fmt(v),
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (v, meta) {
              final i = v.toInt();
              if (i < 0 || i >= buckets.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  buckets[i].label,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ),
      barGroups: [
        for (var i = 0; i < buckets.length; i++)
          _barGroup(
            index: i,
            bucket: buckets[i],
            barWidth: barWidth,
            top: top,
            style: style,
            period: period,
            hasPlan: hasPlan,
            actualColor: actualColor(buckets[i]),
            theme: theme,
          ),
      ],
    );
  }

  static BarChartGroupData _barGroup({
    required int index,
    required _PeriodBucket bucket,
    required double barWidth,
    required double top,
    required ProductionPerformanceStyle style,
    required ProductionPerformancePeriod period,
    required bool hasPlan,
    required Color actualColor,
    required ThemeData theme,
  }) {
    if (style == ProductionPerformanceStyle.compare && hasPlan) {
      return BarChartGroupData(
        x: index,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: bucket.actual,
            width: barWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            color: actualColor,
          ),
          BarChartRodData(
            toY: bucket.planned,
            width: barWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            color: AppColors.warning.withValues(alpha: 0.85),
          ),
        ],
      );
    }

    final radius = style == ProductionPerformanceStyle.minimal ? 2.0 : 4.0;
    final planGhost = hasPlan &&
        bucket.planned > 0 &&
        period != ProductionPerformancePeriod.daily &&
        style != ProductionPerformanceStyle.compare;

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: bucket.actual,
          width: barWidth,
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
          color: style == ProductionPerformanceStyle.minimal
              ? actualColor.withValues(alpha: 0.88)
              : actualColor,
          gradient: style == ProductionPerformanceStyle.classic
              ? LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    actualColor.withValues(alpha: 0.85),
                    actualColor,
                  ],
                )
              : null,
          backDrawRodData: BackgroundBarChartRodData(
            show: planGhost ||
                (style == ProductionPerformanceStyle.classic &&
                    period == ProductionPerformancePeriod.daily),
            toY: planGhost ? bucket.planned : top,
            color: planGhost
                ? AppColors.warning.withValues(
                    alpha: style == ProductionPerformanceStyle.minimal ? 0.12 : 0.2,
                  )
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _PeriodBucket {
  const _PeriodBucket({
    required this.label,
    required this.tooltipTitle,
    required this.actual,
    required this.planned,
  });

  final String label;
  final String tooltipTitle;
  final double actual;
  final double planned;
}
