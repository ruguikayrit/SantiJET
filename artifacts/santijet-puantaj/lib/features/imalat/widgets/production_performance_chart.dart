import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/puantaj_date.dart';
import '../../../domain/entities/production.dart';

/// Günlük kayıtlardan kümülatif metraj / ilerleme çizgi grafiği.
class ProductionPerformanceChart extends StatelessWidget {
  const ProductionPerformanceChart({
    required this.production,
    super.key,
    this.height = 88,
  });

  final Production production;
  final double height;

  static List<_PerfPoint> _pointsFor(Production p) {
    if (p.dailyEntries.isEmpty) return const [];

    final byDay = <DateTime, double>{};
    for (final e in p.dailyEntries) {
      final d = PuantajDate.tryParse(e.date);
      if (d == null) continue;
      final key = DateTime(d.year, d.month, d.day);
      byDay[key] = (byDay[key] ?? 0) + e.completedQty;
    }
    if (byDay.isEmpty) return const [];

    final days = byDay.keys.toList()..sort();
    var cum = 0.0;
    final planned = p.plannedQty;
    final out = <_PerfPoint>[];
    for (final day in days) {
      cum += byDay[day]!;
      final y =
          planned > 0 ? ((cum / planned) * 100).clamp(0.0, 150.0) : cum;
      out.add(_PerfPoint(day: day, cumulativeQty: cum, y: y));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = _pointsFor(production);
    if (points.isEmpty) return const SizedBox.shrink();

    final asPct = production.plannedQty > 0;
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].y),
    ];
    final maxY = spots.fold<double>(0, (m, s) => s.y > m ? s.y : m);
    final top = maxY <= 0 ? 1.0 : (asPct ? (maxY < 100 ? 100.0 : maxY * 1.05) : maxY * 1.15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          asPct ? 'Performans (kümülatif %)' : 'Performans (kümülatif metraj)',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: height,
          child: IgnorePointer(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).clamp(0, 999).toDouble(),
                minY: 0,
                maxY: top,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: asPct ? 25 : null,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.45),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
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
                      reservedSize: 28,
                      interval: asPct ? 50 : null,
                      getTitlesWidget: (v, meta) {
                        if (asPct) {
                          if (v != 0 && v != 50 && v != 100 && v != meta.max) {
                            return const SizedBox.shrink();
                          }
                        } else if (v != meta.min && v != meta.max) {
                          return const SizedBox.shrink();
                        }
                        final label = asPct
                            ? '${v.round()}'
                            : (v == v.roundToDouble()
                                ? v.toInt().toString()
                                : v.toStringAsFixed(1));
                        return Text(
                          label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      interval: 1,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= points.length) {
                          return const SizedBox.shrink();
                        }
                        // İlk / son / ara seyrek etiket
                        if (points.length > 4 &&
                            i != 0 &&
                            i != points.length - 1 &&
                            i != points.length ~/ 2) {
                          return const SizedBox.shrink();
                        }
                        final d = points[i].day;
                        return Text(
                          '${d.day}.${d.month}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: points.length > 2,
                    curveSmoothness: 0.2,
                    color: AppColors.electricBlue,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: points.length <= 8 ? 3 : 2,
                        color: AppColors.electricBlue,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.electricBlue.withValues(alpha: 0.12),
                    ),
                  ),
                  if (asPct)
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 100),
                        FlSpot((spots.length - 1).toDouble(), 100),
                      ],
                      color: AppColors.success.withValues(alpha: 0.45),
                      barWidth: 1,
                      dashArray: const [4, 4],
                      dotData: const FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PerfPoint {
  const _PerfPoint({
    required this.day,
    required this.cumulativeQty,
    required this.y,
  });

  final DateTime day;
  final double cumulativeQty;
  final double y;
}
