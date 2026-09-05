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
    this.height = 168,
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

  /// Dokunulan periyot grubu (x); -1 = yok. Plan+gerçek tek tooltip.
  int _touchedGroupX = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProductionPerformanceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.production.id != widget.production.id) {
      _touchedGroupX = -1;
    }
  }

  void _scrollToCenterIfNeeded({
    required bool scrollable,
    required int bucketCount,
    required ProductionPerformancePeriod period,
  }) {
    if (!scrollable) return;
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

    final unit =
        widget.production.unit.trim().isEmpty ? '' : widget.production.unit.trim();
    final planQty = widget.production.plannedQty;
    final planDays = widget.production.plannedDays;
    final hasPlan = planQty > 0 && planDays > 0;

    final totalActual = buckets.fold<double>(0, (s, b) => s + b.actual);
    final avgActual = buckets.isEmpty ? 0.0 : totalActual / buckets.length;

    final planPerPeriod = buckets.isEmpty
        ? (hasPlan
            ? switch (options.period) {
                ProductionPerformancePeriod.daily => planQty / planDays,
                ProductionPerformancePeriod.weekly => planQty / planDays * 7,
                ProductionPerformancePeriod.monthly => planQty / planDays * 30,
              }
            : 0.0)
        : buckets.fold<double>(0, (s, b) => s + b.planned) / buckets.length;

    final maxBar = buckets.fold<double>(0, (m, b) {
      final v = hasPlan && b.planned > b.actual ? b.planned : b.actual;
      return v > m ? v : m;
    });
    final maxY = maxBar > 0
        ? maxBar
        : (planPerPeriod > 0 ? planPerPeriod : 1.0);
    final top = maxY * 1.22;

    String? paceLabel;
    Color? paceColor;
    if (buckets.isNotEmpty && hasPlan && avgActual > 0 && planPerPeriod > 0) {
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
        const SizedBox(height: 4),
        Text(
          buckets.isEmpty
              ? 'Günlük kayıt eklenince çubuklar burada ortalanır'
              : _hintText(hasPlan, unit, periodUnit),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final viewportW = constraints.maxWidth - 30;
            // Barlar sabit slot ile merkezde; çizim alanı (ızgara) her zaman
            // viewport genişliğine yaslanır.
            final naturalSlot = hasPlan ? 48.0 : 40.0;
            final naturalChartW = naturalSlot * buckets.length;
            final scrollable =
                buckets.isNotEmpty && naturalChartW > viewportW + 0.5;
            final slotW = scrollable
                ? viewportW / ProductionPerformanceChart.visibleBucketCount
                : naturalSlot;
            final chartW = scrollable ? slotW * buckets.length : viewportW;
            final barWidth = _barWidth(slotW: slotW, hasPlan: hasPlan);
            final groupsSpace = scrollable ? 6.0 : 10.0;

            _scrollToCenterIfNeeded(
              scrollable: scrollable,
              bucketCount: buckets.length,
              period: options.period,
            );

            final chart = SizedBox(
              width: chartW,
              height: widget.height,
              child: BarChart(
                _chartData(
                  theme: theme,
                  buckets: buckets,
                  // Tooltip bar üstünde kalsın diye ekstra dikey boşluk.
                  top: top * 1.38,
                  unit: unit,
                  hasPlan: hasPlan,
                  barWidth: barWidth,
                  groupsSpace: groupsSpace,
                  showLeftTitles: false,
                  touchedGroupX: _touchedGroupX,
                  onTouchedGroupX: (x) {
                    if (_touchedGroupX == x) return;
                    setState(() => _touchedGroupX = x);
                  },
                ),
              ),
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
                  child: scrollable
                      ? SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          physics: const BouncingScrollPhysics(),
                          child: chart,
                        )
                      : chart,
                ),
              ],
            );
          },
        ),
        if (buckets.length > ProductionPerformanceChart.visibleBucketCount) ...[
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
              ? 'Henüz metraj kaydı yok'
              : hasPlan
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
    required bool hasPlan,
  }) {
    final usable = slotW - (hasPlan ? 12 : 8);
    return hasPlan ? (usable / 2).clamp(6.0, 14.0) : usable.clamp(8.0, 18.0);
  }

  static String _hintText(bool hasPlan, String unit, String periodUnit) {
    if (!hasPlan) {
      return 'Çubuk: $periodUnit gerçekleşen metraj';
    }
    return 'Mavi: gerçekleşen · turuncu: plan ($periodUnit)';
  }

  static BarChartData _chartData({
    required ThemeData theme,
    required List<_PeriodBucket> buckets,
    required double top,
    required String unit,
    required bool hasPlan,
    required double barWidth,
    required double groupsSpace,
    required int touchedGroupX,
    required ValueChanged<int> onTouchedGroupX,
    bool showLeftTitles = true,
  }) {
    Color actualColor(_PeriodBucket b) {
      if (!hasPlan || b.planned <= 0) return AppColors.electricBlue;
      return b.actual + 0.0001 >= b.planned
          ? AppColors.success
          : AppColors.electricBlue;
    }

    int tooltipRodIndex(_PeriodBucket b) {
      if (!hasPlan) return 0;
      // Tooltip en yüksek çubuğun üstüne otursun.
      return b.planned > b.actual ? 1 : 0;
    }

    return BarChartData(
      maxY: top,
      minY: 0,
      alignment: BarChartAlignment.center,
      groupsSpace: groupsSpace,
      barTouchData: BarTouchData(
        enabled: true,
        handleBuiltInTouches: false,
        touchExtraThreshold: const EdgeInsets.symmetric(horizontal: 8),
        touchCallback: (event, response) {
          final spot = response?.spot;
          if (spot != null) {
            onTouchedGroupX(spot.touchedBarGroup.x);
            return;
          }
          // Masaüstünde imleç grafikten çıkınca vurguyu kaldır.
          // Mobilde seçim, başka çubuğa dokunulana kadar kalır (tooltip okunabilsin).
          if (event is FlPointerExitEvent) {
            onTouchedGroupX(-1);
          }
        },
        touchTooltipData: BarTouchTooltipData(
          // Barların önüne çekilmesin; üstte kalsın.
          fitInsideVertically: false,
          fitInsideHorizontally: true,
          direction: TooltipDirection.top,
          tooltipMargin: 10,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          getTooltipColor: (_) =>
              theme.colorScheme.inverseSurface.withValues(alpha: 0.94),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final ix = group.x.toInt();
            if (ix < 0 || ix >= buckets.length) return null;
            final b = buckets[ix];
            // Grupta yalnız bir rod için kutu (çift tooltip yok).
            if (rodIndex != tooltipRodIndex(b)) return null;

            final u = unit.isEmpty ? '' : ' $unit';
            final buf = StringBuffer(b.tooltipTitle)
              ..writeln()
              ..write('Gerçek: ${_fmt(b.actual)}$u');
            if (hasPlan && b.planned > 0) {
              buf
                ..writeln()
                ..write('Plan: ${_fmt(b.planned)}$u');
            }
            return BarTooltipItem(
              buf.toString(),
              TextStyle(
                color: theme.colorScheme.onInverseSurface,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            );
          },
        ),
      ),
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
            showTitles: buckets.isNotEmpty,
            reservedSize: buckets.isEmpty ? 8 : 22,
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
      // Boşken görünmez yer tutucu — ızgara tam genişlikte çizilsin.
      barGroups: buckets.isEmpty
          ? [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: 0,
                    width: 0.1,
                    color: Colors.transparent,
                  ),
                ],
              ),
            ]
          : [
              for (var i = 0; i < buckets.length; i++)
                _barGroup(
                  index: i,
                  bucket: buckets[i],
                  barWidth: barWidth,
                  hasPlan: hasPlan,
                  actualColor: actualColor(buckets[i]),
                  selected: touchedGroupX == i,
                  dimmed: touchedGroupX >= 0 && touchedGroupX != i,
                  showingTooltipIndicators: touchedGroupX == i
                      ? [tooltipRodIndex(buckets[i])]
                      : const [],
                ),
            ],
    );
  }

  static BarChartGroupData _barGroup({
    required int index,
    required _PeriodBucket bucket,
    required double barWidth,
    required bool hasPlan,
    required Color actualColor,
    required bool selected,
    required bool dimmed,
    List<int> showingTooltipIndicators = const [],
  }) {
    final w = selected ? barWidth + 1.5 : barWidth;
    final frame = selected
        ? BorderSide(
            color: AppColors.electricBlueLight.withValues(alpha: 0.95),
            width: 1.75,
          )
        : BorderSide.none;
    final radius = BorderRadius.vertical(
      top: Radius.circular(selected ? 4 : 3),
    );

    Color paint(Color base, {double selectedBoost = 1}) {
      if (dimmed) return base.withValues(alpha: 0.32);
      if (selected) {
        return Color.lerp(base, Colors.white, 0.12 * selectedBoost) ?? base;
      }
      return base;
    }

    BackgroundBarChartRodData halo(double toY) {
      if (!selected || toY <= 0) {
        return BackgroundBarChartRodData(show: false);
      }
      return BackgroundBarChartRodData(
        show: true,
        toY: toY,
        color: AppColors.electricBlue.withValues(alpha: 0.14),
      );
    }

    if (hasPlan) {
      final planColor = AppColors.warning.withValues(alpha: 0.85);
      return BarChartGroupData(
        x: index,
        barsSpace: selected ? 5 : 4,
        showingTooltipIndicators: showingTooltipIndicators,
        barRods: [
          BarChartRodData(
            toY: bucket.actual,
            width: w,
            borderRadius: radius,
            color: paint(actualColor),
            borderSide: frame,
            backDrawRodData: halo(
              bucket.actual > bucket.planned ? bucket.actual : bucket.planned,
            ),
          ),
          BarChartRodData(
            toY: bucket.planned,
            width: w,
            borderRadius: radius,
            color: paint(planColor, selectedBoost: 0.8),
            borderSide: frame,
            backDrawRodData: halo(
              bucket.actual > bucket.planned ? bucket.actual : bucket.planned,
            ),
          ),
        ],
      );
    }

    return BarChartGroupData(
      x: index,
      showingTooltipIndicators: showingTooltipIndicators,
      barRods: [
        BarChartRodData(
          toY: bucket.actual,
          width: w,
          borderRadius: radius,
          color: paint(actualColor),
          borderSide: frame,
          backDrawRodData: halo(bucket.actual),
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
