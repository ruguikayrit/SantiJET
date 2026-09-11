import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/puantaj_date.dart';
import '../../../data/providers/production_performance_chart_options_provider.dart';
import '../../../data/services/production_performance_chart_options.dart';
import '../../../data/services/production_performance_plan.dart';
import '../../../domain/entities/production.dart';

/// İmalat kartı — plan vs gerçekleşen çizgi grafiği (metraj · adam-gün).
class ProductionPerformanceLineChart extends ConsumerStatefulWidget {
  const ProductionPerformanceLineChart({
    required this.production,
    super.key,
    this.height = 220,
  });

  final Production production;
  final double height;

  static const visibleBucketCount = 12;
  static const tooltipReservePx = 76.0;
  static const bottomTitlesPx = 22.0;

  @override
  ConsumerState<ProductionPerformanceLineChart> createState() =>
      _ProductionPerformanceLineChartState();
}

class _ProductionPerformanceLineChartState
    extends ConsumerState<ProductionPerformanceLineChart> {
  final ScrollController _scrollController = ScrollController();
  ProductionPerformancePeriod? _lastPeriod;
  ProductionPerformanceMetric? _lastMetric;
  int _lastBucketCount = 0;
  String? _lastProductionId;
  int _touchedIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProductionPerformanceLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.production.id != widget.production.id) {
      _touchedIndex = -1;
    }
  }

  void _scrollToCenterIfNeeded({
    required bool scrollable,
    required int bucketCount,
    required ProductionPerformancePeriod period,
    required ProductionPerformanceMetric metric,
  }) {
    if (!scrollable) return;
    if (widget.production.id != _lastProductionId) {
      _lastProductionId = widget.production.id;
      _lastPeriod = null;
      _lastMetric = null;
      _lastBucketCount = 0;
    }
    if (_lastPeriod == period &&
        _lastMetric == metric &&
        _lastBucketCount == bucketCount) {
      return;
    }
    _lastPeriod = period;
    _lastMetric = metric;
    _lastBucketCount = bucketCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (max <= 0) return;
      _scrollController.jumpTo(max / 2);
    });
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  static DateTime _weekStart(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  static Map<DateTime, double> _dailyMetraj(Production p) {
    final byDay = <DateTime, double>{};
    for (final e in p.dailyEntries) {
      final d = PuantajDate.tryParse(e.date);
      if (d == null || e.completedQty <= 0) continue;
      final key = DateTime(d.year, d.month, d.day);
      byDay[key] = (byDay[key] ?? 0) + e.completedQty;
    }
    return byDay;
  }

  static Map<DateTime, double> _dailyLabor(Production p) {
    final byDay = <DateTime, double>{};
    for (final e in p.dailyEntries) {
      final d = PuantajDate.tryParse(e.date);
      if (d == null || e.laborDays <= 0) continue;
      final key = DateTime(d.year, d.month, d.day);
      byDay[key] = (byDay[key] ?? 0) + e.laborDays;
    }
    return byDay;
  }

  static List<_PeriodBucket> _buckets(
    Production p,
    ProductionPerformancePeriod period,
    ProductionPerformanceMetric metric,
  ) {
    final daily = switch (metric) {
      ProductionPerformanceMetric.metraj => _dailyMetraj(p),
      ProductionPerformanceMetric.laborDays => _dailyLabor(p),
    };
    if (daily.isEmpty) return const [];

    final (planTotal, planDays, hasPlan) = switch (metric) {
      ProductionPerformanceMetric.metraj => (
          p.plannedQty,
          p.plannedDays,
          p.plannedQty > 0 && p.plannedDays > 0,
        ),
      ProductionPerformanceMetric.laborDays => (
          p.plannedWorkerDays,
          p.plannedDays,
          p.plannedLabor > 0 && p.plannedDays > 0,
        ),
    };
    final budget = ProductionPerformancePlanBudget(
      planQty: planTotal,
      planDays: planDays,
    );

    List<_PeriodBucket> incremental;
    switch (period) {
      case ProductionPerformancePeriod.daily:
        final keys = daily.keys.toList()..sort();
        incremental = [
          for (final d in keys)
            _PeriodBucket(
              label: '${d.day}.${d.month}',
              tooltipTitle: PuantajDate.format(d),
              actual: daily[d]!,
              planned: hasPlan ? budget.allocate(workedDaysInPeriod: 1) : 0,
            ),
        ];
      case ProductionPerformancePeriod.weekly:
        final byWeek = <DateTime, double>{};
        final daysByWeek = <DateTime, int>{};
        for (final e in daily.entries) {
          final w = _weekStart(e.key);
          byWeek[w] = (byWeek[w] ?? 0) + e.value;
        }
        for (final d in daily.keys) {
          final w = _weekStart(d);
          daysByWeek[w] = (daysByWeek[w] ?? 0) + 1;
        }
        final weeks = byWeek.keys.toList()..sort();
        incremental = [
          for (final w in weeks)
            _PeriodBucket(
              label: '${w.day}.${w.month}',
              tooltipTitle: PuantajDate.weekLabel([
                PuantajDate.format(w),
                PuantajDate.format(w.add(const Duration(days: 6))),
              ]),
              actual: byWeek[w]!,
              planned: hasPlan
                  ? budget.allocate(workedDaysInPeriod: daysByWeek[w] ?? 0)
                  : 0,
            ),
        ];
      case ProductionPerformancePeriod.monthly:
        final byMonth = <(int y, int m), double>{};
        final daysByMonth = <(int y, int m), int>{};
        for (final e in daily.entries) {
          final key = (e.key.year, e.key.month);
          byMonth[key] = (byMonth[key] ?? 0) + e.value;
        }
        for (final d in daily.keys) {
          final key = (d.year, d.month);
          daysByMonth[key] = (daysByMonth[key] ?? 0) + 1;
        }
        final months = byMonth.keys.toList()
          ..sort((a, b) {
            if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
            return a.$2.compareTo(b.$2);
          });
        if (hasPlan && months.length == 1) {
          final (y, m) = months.single;
          incremental = [
            _PeriodBucket(
              label: PuantajDate.trMonths[m - 1].length > 3
                  ? PuantajDate.trMonths[m - 1].substring(0, 3)
                  : PuantajDate.trMonths[m - 1],
              tooltipTitle: PuantajDate.monthLabel(
                PuantajDate.format(DateTime(y, m, 1)),
              ),
              actual: byMonth[(y, m)]!,
              planned: planTotal,
            ),
          ];
        } else {
          incremental = [
            for (final (y, m) in months)
              _PeriodBucket(
                label: PuantajDate.trMonths[m - 1].length > 3
                    ? PuantajDate.trMonths[m - 1].substring(0, 3)
                    : PuantajDate.trMonths[m - 1],
                tooltipTitle: PuantajDate.monthLabel(
                  PuantajDate.format(DateTime(y, m, 1)),
                ),
                actual: byMonth[(y, m)]!,
                planned: hasPlan
                    ? budget.allocate(workedDaysInPeriod: daysByMonth[(y, m)] ?? 0)
                    : 0,
              ),
          ];
        }
    }

    return _toCumulative(incremental);
  }

  static List<_PeriodBucket> _toCumulative(List<_PeriodBucket> buckets) {
    var accActual = 0.0;
    var accPlanned = 0.0;
    return [
      for (final b in buckets)
        () {
          accActual += b.actual;
          accPlanned += b.planned;
          return _PeriodBucket(
            label: b.label,
            tooltipTitle: b.tooltipTitle,
            actual: accActual,
            planned: accPlanned,
          );
        }(),
    ];
  }

  bool _hasPlan(Production p, ProductionPerformanceMetric metric) {
    return switch (metric) {
      ProductionPerformanceMetric.metraj =>
        p.plannedQty > 0 && p.plannedDays > 0,
      ProductionPerformanceMetric.laborDays =>
        p.plannedLabor > 0 && p.plannedDays > 0,
    };
  }

  String _unitLabel(Production p, ProductionPerformanceMetric metric) {
    return switch (metric) {
      ProductionPerformanceMetric.metraj =>
        p.unit.trim().isEmpty ? '' : p.unit.trim(),
      ProductionPerformanceMetric.laborDays => 'AG',
    };
  }

  double _planTotal(Production p, ProductionPerformanceMetric metric) {
    return switch (metric) {
      ProductionPerformanceMetric.metraj => p.plannedQty,
      ProductionPerformanceMetric.laborDays => p.plannedWorkerDays,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = ref.watch(productionPerformanceChartOptionsProvider);
    final metric = options.metric;
    final buckets = _buckets(widget.production, options.period, metric);
    final unit = _unitLabel(widget.production, metric);
    final hasPlan = _hasPlan(widget.production, metric);
    final planTotal = _planTotal(widget.production, metric);

    final lastActual =
        buckets.isEmpty ? 0.0 : buckets.last.actual;
    final lastPlanned =
        buckets.isEmpty ? 0.0 : buckets.last.planned;

    final maxY = buckets.fold<double>(0, (m, b) {
      final v = b.actual > b.planned ? b.actual : b.planned;
      return v > m ? v : m;
    });
    final top = (maxY <= 0 ? 1.0 : maxY * 1.12);

    String? paceLabel;
    Color? paceColor;
    if (buckets.isNotEmpty && hasPlan && lastPlanned > 0) {
      final ratio = lastActual / lastPlanned;
      if (ratio >= 1.05) {
        paceLabel = 'Planın önünde';
        paceColor = AppColors.success;
      } else if (ratio <= 0.95) {
        paceLabel = 'Planın gerisinde';
        paceColor = AppColors.critical;
      } else {
        paceLabel = 'Planda';
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
                'Plan · Gerçekleşen · ${metric.label}',
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
            for (final m in ProductionPerformanceMetric.values)
              FilterChip(
                showCheckmark: false,
                label: Text(m.label),
                selected: metric == m,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => ref
                    .read(productionPerformanceChartOptionsProvider.notifier)
                    .save(options.copyWith(metric: m)),
              ),
            for (final p in ProductionPerformancePeriod.values)
              FilterChip(
                showCheckmark: false,
                label: Text(p.label),
                selected: options.period == p,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => ref
                    .read(productionPerformanceChartOptionsProvider.notifier)
                    .save(options.copyWith(period: p)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _LegendDot(
              color: AppColors.electricBlue,
              label: 'Gerçekleşen',
              dashed: false,
            ),
            const SizedBox(width: AppSpacing.md),
            if (hasPlan)
              _LegendDot(
                color: AppColors.warning,
                label: 'Plan',
                dashed: true,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          buckets.isEmpty
              ? 'Günlük kayıt eklenince kümülatif çizgiler burada görünür'
              : hasPlan
                  ? 'Kümülatif $periodUnit · ${metric.label.toLowerCase()}'
                  : 'Plan verisi yok · yalnız gerçekleşen',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            const axisW = 34.0;
            const edgeInset = 6.0;
            final viewportW =
                (constraints.maxWidth - axisW - edgeInset * 2).clamp(0.0, double.infinity);
            final slotW = buckets.length <= ProductionPerformanceLineChart.visibleBucketCount
                ? (viewportW / ProductionPerformanceLineChart.visibleBucketCount)
                    .clamp(28.0, 56.0)
                : 44.0;
            final chartW = buckets.isEmpty
                ? viewportW
                : slotW * buckets.length.clamp(1, buckets.length);
            final scrollable = buckets.length > ProductionPerformanceLineChart.visibleBucketCount;

            _scrollToCenterIfNeeded(
              scrollable: scrollable,
              bucketCount: buckets.length,
              period: options.period,
              metric: metric,
            );

            final chart = SizedBox(
              width: chartW,
              height: widget.height,
              child: LineChart(
                _lineData(
                  theme: theme,
                  buckets: buckets,
                  top: top,
                  unit: unit,
                  hasPlan: hasPlan,
                  touchedIndex: _touchedIndex,
                  onTouchedIndex: (i) {
                    if (_touchedIndex == i) return;
                    setState(() => _touchedIndex = i);
                  },
                ),
              ),
            );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: axisW,
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: edgeInset),
                    child: ClipRect(
                      clipper: const _HorizontalOnlyClipper(),
                      child: scrollable
                          ? SingleChildScrollView(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.hardEdge,
                              physics: const BouncingScrollPhysics(),
                              child: chart,
                            )
                          : chart,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (buckets.length > ProductionPerformanceLineChart.visibleBucketCount) ...[
          const SizedBox(height: 4),
          Text(
            'Daha fazla ${options.period.label.toLowerCase()} için grafiği kaydırın',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          buckets.isEmpty
              ? metric == ProductionPerformanceMetric.metraj
                  ? 'Henüz metraj kaydı yok'
                  : 'Henüz adam-gün kaydı yok'
              : hasPlan
                  ? 'Kümülatif ${_fmt(lastActual)}${unit.isEmpty ? '' : ' $unit'}'
                      ' · Plan ${_fmt(lastPlanned)}${unit.isEmpty ? '' : ' $unit'}'
                      '${planTotal > 0 ? ' / ${_fmt(planTotal)}' : ''}'
                  : 'Kümülatif ${_fmt(lastActual)}${unit.isEmpty ? '' : ' $unit'}'
                      ' · ${buckets.length} $periodUnit',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  LineChartData _lineData({
    required ThemeData theme,
    required List<_PeriodBucket> buckets,
    required double top,
    required String unit,
    required bool hasPlan,
    required int touchedIndex,
    required ValueChanged<int> onTouchedIndex,
  }) {
    List<FlSpot> spots(List<double> values) => [
          for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
        ];

    final actualSpots = spots([for (final b in buckets) b.actual]);
    final planSpots = spots([for (final b in buckets) b.planned]);

    return LineChartData(
      minX: 0,
      maxX: buckets.isEmpty ? 1 : (buckets.length - 1).toDouble(),
      minY: 0,
      maxY: top,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: top / 4,
        getDrawingHorizontalLine: (_) => FlLine(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: buckets.isNotEmpty,
            reservedSize: buckets.isEmpty ? 8 : 22,
            interval: 1,
            getTitlesWidget: (v, meta) {
              final i = v.round();
              if (i < 0 || i >= buckets.length) return const SizedBox.shrink();
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
      lineTouchData: LineTouchData(
        enabled: buckets.isNotEmpty,
        handleBuiltInTouches: true,
        touchCallback: (event, response) {
          final spot = response?.lineBarSpots?.firstOrNull;
          if (spot != null) {
            final i = spot.x.round();
            if (event is FlTapUpEvent) {
              onTouchedIndex(touchedIndex == i ? -1 : i);
            } else if (event is! FlTapDownEvent) {
              onTouchedIndex(i);
            }
            return;
          }
          if (event is FlPointerExitEvent) {
            onTouchedIndex(-1);
          }
        },
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipMargin: 8,
          getTooltipColor: (_) =>
              theme.colorScheme.inverseSurface.withValues(alpha: 0.94),
          getTooltipItems: (spots) {
            if (spots.isEmpty) return [];
            final i = spots.first.x.round();
            if (i < 0 || i >= buckets.length) return [];
            final b = buckets[i];
            final u = unit.isEmpty ? '' : ' $unit';
            final buf = StringBuffer(b.tooltipTitle)
              ..writeln()
              ..write('Gerçek: ${_fmt(b.actual)}$u');
            if (hasPlan && b.planned > 0) {
              buf
                ..writeln()
                ..write('Plan: ${_fmt(b.planned)}$u');
            }
            final style = TextStyle(
              color: theme.colorScheme.onInverseSurface,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.3,
            );
            return [
              LineTooltipItem(buf.toString(), style),
              for (var j = 1; j < spots.length; j++)
                LineTooltipItem('', style.copyWith(fontSize: 0, height: 0)),
            ];
          },
        ),
      ),
      lineBarsData: [
        if (hasPlan && planSpots.isNotEmpty)
          LineChartBarData(
            spots: planSpots,
            isCurved: true,
            curveSmoothness: 0.22,
            color: AppColors.warning.withValues(alpha: 0.9),
            barWidth: 2,
            isStrokeCapRound: true,
            dashArray: const [6, 4],
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final selected = touchedIndex == index;
                return FlDotCirclePainter(
                  radius: selected ? 4.5 : 3,
                  color: AppColors.warning,
                  strokeWidth: selected ? 2 : 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        if (actualSpots.isNotEmpty)
          LineChartBarData(
            spots: actualSpots,
            isCurved: true,
            curveSmoothness: 0.22,
            color: AppColors.electricBlue,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final selected = touchedIndex == index;
                final ahead = hasPlan &&
                    index < buckets.length &&
                    buckets[index].actual + 0.0001 >= buckets[index].planned;
                return FlDotCirclePainter(
                  radius: selected ? 5 : 3.5,
                  color: hasPlan && ahead ? AppColors.success : AppColors.electricBlue,
                  strokeWidth: selected ? 2 : 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.electricBlue.withValues(alpha: 0.08),
            ),
          ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.dashed,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(20, 3),
          painter: _LineLegendPainter(color: color, dashed: dashed),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _LineLegendPainter extends CustomPainter {
  _LineLegendPainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (dashed) {
      const dash = 4.0;
      const gap = 3.0;
      var x = 0.0;
      while (x < size.width) {
        final end = (x + dash).clamp(0.0, size.width);
        canvas.drawLine(
          Offset(x, size.height / 2),
          Offset(end, size.height / 2),
          paint,
        );
        x += dash + gap;
      }
    } else {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineLegendPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashed != dashed;
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

class _HorizontalOnlyClipper extends CustomClipper<Rect> {
  const _HorizontalOnlyClipper();

  @override
  Rect getClip(Size size) {
    const topSlop = ProductionPerformanceLineChart.tooltipReservePx;
    return Rect.fromLTRB(0, -topSlop, size.width, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}
