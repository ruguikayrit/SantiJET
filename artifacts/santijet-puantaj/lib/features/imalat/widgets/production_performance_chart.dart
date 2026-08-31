import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/puantaj_date.dart';
import '../../../domain/entities/production.dart';

/// İmalat kartı — günlük metraj + plan temposu karşılaştırması.
///
/// Mantık:
/// - Her günlük kayıt bir çubuk (o gün yapılan metraj)
/// - Plan varsa yatay çizgi = planlanan günlük tempo (metraj ÷ plan gün)
/// - Özet satır: ortalama tempo vs plan temposu (önde / geride)
class ProductionPerformanceChart extends StatelessWidget {
  const ProductionPerformanceChart({
    required this.production,
    super.key,
    this.height = 132,
  });

  final Production production;
  final double height;

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  static List<_DayQty> _daysFor(Production p) {
    final byDay = <DateTime, double>{};
    for (final e in p.dailyEntries) {
      final d = PuantajDate.tryParse(e.date);
      if (d == null) continue;
      if (e.completedQty <= 0) continue;
      final key = DateTime(d.year, d.month, d.day);
      byDay[key] = (byDay[key] ?? 0) + e.completedQty;
    }
    if (byDay.isEmpty) return const [];
    final keys = byDay.keys.toList()..sort();
    return [
      for (final d in keys) _DayQty(day: d, qty: byDay[d]!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _daysFor(production);
    if (days.isEmpty) return const SizedBox.shrink();

    final unit = production.unit.trim().isEmpty ? '' : production.unit.trim();
    final planQty = production.plannedQty;
    final planDays = production.plannedDays;
    final hasTempo = planQty > 0 && planDays > 0;
    final planRate = hasTempo ? planQty / planDays : 0.0;

    final workDayCount = days.length;
    final totalQty = days.fold<double>(0, (s, d) => s + d.qty);
    final avgRate = workDayCount > 0 ? totalQty / workDayCount : 0.0;

    final maxBar = days.fold<double>(0, (m, d) => d.qty > m ? d.qty : m);
    final maxY = [
      maxBar,
      if (hasTempo) planRate,
    ].fold<double>(0, (m, v) => v > m ? v : m);
    final top = maxY <= 0 ? 1.0 : maxY * 1.25;

    String? paceLabel;
    Color? paceColor;
    if (hasTempo && avgRate > 0) {
      final ratio = avgRate / planRate;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Günlük metraj',
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
        const SizedBox(height: 2),
        Text(
          hasTempo
              ? 'Çubuk: o gün yapılan · çizgi: plan temposu '
                  '(${_fmt(planRate)}${unit.isEmpty ? '' : ' $unit'}/gün)'
              : 'Her çubuk, o güne girilen gerçekleşen metrajı gösterir',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              maxY: top,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              groupsSpace: days.length <= 4 ? 18 : 8,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) =>
                      theme.colorScheme.inverseSurface.withValues(alpha: 0.92),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final d = days[group.x.toInt()];
                    final date =
                        '${d.day.day.toString().padLeft(2, '0')}.'
                        '${d.day.month.toString().padLeft(2, '0')}';
                    final qtyLine = unit.isEmpty
                        ? _fmt(d.qty)
                        : '${_fmt(d.qty)} $unit';
                    return BarTooltipItem(
                      '$date\n$qtyLine',
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
                show: true,
                drawVerticalLine: false,
                horizontalInterval: top / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: hasTempo
                  ? ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: planRate,
                          color: AppColors.warning,
                          strokeWidth: 1.5,
                          dashArray: const [6, 4],
                          label: HorizontalLineLabel(
                            show: true,
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
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: top / 2,
                    getTitlesWidget: (v, meta) {
                      if ((v - meta.min).abs() < 0.001 ||
                          (v - meta.max).abs() < 0.001 ||
                          (v - top / 2).abs() < top * 0.05) {
                        return Text(
                          _fmt(v),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                          ),
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
                      if (i < 0 || i >= days.length) {
                        return const SizedBox.shrink();
                      }
                      if (days.length > 6 &&
                          i != 0 &&
                          i != days.length - 1 &&
                          i % ((days.length / 3).ceil()) != 0) {
                        return const SizedBox.shrink();
                      }
                      final d = days[i].day;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${d.day}.${d.month}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < days.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: days[i].qty,
                        width: days.length <= 5
                            ? 18
                            : (days.length <= 10 ? 12 : 8),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        color: hasTempo && days[i].qty + 0.0001 >= planRate
                            ? AppColors.success
                            : AppColors.electricBlue,
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: top,
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                    showingTooltipIndicators: const [],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          hasTempo
              ? 'Ort. ${_fmt(avgRate)}${unit.isEmpty ? '' : ' $unit'}/gün'
                  ' · Plan ${_fmt(planRate)}${unit.isEmpty ? '' : ' $unit'}/gün'
                  ' · Toplam ${_fmt(totalQty)}${unit.isEmpty ? '' : ' $unit'}'
                  '${planQty > 0 ? ' / ${_fmt(planQty)}' : ''}'
              : 'Ort. ${_fmt(avgRate)}${unit.isEmpty ? '' : ' $unit'}/gün'
                  ' · Toplam ${_fmt(totalQty)}${unit.isEmpty ? '' : ' $unit'}'
                  ' · $workDayCount gün',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DayQty {
  const _DayQty({required this.day, required this.qty});

  final DateTime day;
  final double qty;
}
