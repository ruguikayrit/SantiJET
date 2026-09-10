import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/puantaj_date.dart';
import '../../../core/widgets/production_triple_progress.dart';
import '../../../domain/entities/production.dart';
import '../../../domain/models/production_metrics.dart';

/// Verim imalat satırı — metraj · süre · adam-gün · verim (alt alta).
class VerimProductionCharts extends StatelessWidget {
  const VerimProductionCharts({
    required this.production,
    super.key,
    this.inline = false,
    this.chartHeight = 150,
  });

  final Production production;

  /// Liste kartında üst bilgi zaten gösteriliyorsa ekip/rozet gizlenir.
  final bool inline;
  final double chartHeight;

  List<_VerimTimelinePoint> _timeline() {
    final byDay = <DateTime, ({double qty, double labor})>{};
    for (final e in production.dailyEntries) {
      final d = PuantajDate.tryParse(e.date);
      if (d == null) continue;
      if (e.completedQty <= 0 && e.laborDays <= 0) continue;
      final key = DateTime(d.year, d.month, d.day);
      final prev = byDay[key];
      byDay[key] = (
        qty: (prev?.qty ?? 0) + e.completedQty,
        labor: (prev?.labor ?? 0) + e.laborDays,
      );
    }
    if (byDay.isEmpty) return const [];

    final keys = byDay.keys.toList()..sort();
    final plannedDays = production.plannedDays;
    final hasMetrajPlan = production.plannedQty > 0 && plannedDays > 0;
    final hasSurePlan = plannedDays > 0;
    final hasLaborPlan = production.plannedWorkerDays > 0 && plannedDays > 0;

    final dailyPlanQty =
        hasMetrajPlan ? production.plannedQty / plannedDays : 0.0;
    final dailyPlanLabor = hasLaborPlan
        ? production.plannedWorkerDays / plannedDays
        : 0.0;

    var cumQty = 0.0;
    var cumLabor = 0.0;
    var dayIndex = 0;

    return [
      for (final d in keys)
        () {
          dayIndex++;
          cumQty += byDay[d]!.qty;
          cumLabor += byDay[d]!.labor;
          final eff = ProductionMetrics.computeUnitEfficiency(
            plannedQty: production.plannedQty,
            plannedWorkerDays: production.plannedWorkerDays,
            actualQty: cumQty,
            actualWorkerDays: cumLabor,
          );
          final workedDays = dayIndex.toDouble();
          final plannedWorkedDays = hasSurePlan
              ? workedDays.clamp(0.0, plannedDays.toDouble()).toDouble()
              : 0.0;
          return _VerimTimelinePoint(
            label: '${d.day}.${d.month}',
            tooltip: PuantajDate.format(d),
            cumulativeQty: cumQty,
            plannedCumulativeQty: hasMetrajPlan ? dailyPlanQty * dayIndex : 0,
            cumulativeWorkedDays: workedDays,
            plannedCumulativeWorkedDays: plannedWorkedDays,
            cumulativeLabor: cumLabor,
            plannedCumulativeLabor: hasLaborPlan ? dailyPlanLabor * dayIndex : 0,
            efficiencyPct: eff != null ? eff * 100 : null,
          );
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = _timeline();
    final metrics = ProductionMetrics(production);
    final unit = production.unit.trim();
    final team = production.teamName.trim().isEmpty
        ? 'Diğer'
        : production.teamName.trim();

    if (points.isEmpty) {
      return Text(
        'Günlük kayıt yok. İmalat sekmesinden metraj ve adam-gün girişi yapın.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!inline) ...[
          Text(
            team,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (metrics.unitEfficiency != null) ...[
            const SizedBox(height: AppSpacing.xs),
            UnitEfficiencyBadge(
              efficiency: metrics.unitEfficiency,
              compact: true,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
        _VerimChartSection(
          title: 'Metraj · Kümülatif',
          points: points,
          height: chartHeight,
          unitSuffix: unit.isEmpty ? '' : ' $unit',
          primaryValue: (p) => p.cumulativeQty,
          secondaryValue: (p) => p.plannedCumulativeQty,
          showSecondary: metrics.metraj.hasPlan,
          primaryLabel: 'Gerçek',
          secondaryLabel: 'Plan',
        ),
        const SizedBox(height: AppSpacing.lg),
        _VerimChartSection(
          title: 'Süre · Çalışılan gün',
          points: points,
          height: chartHeight,
          unitSuffix: ' gün',
          primaryValue: (p) => p.cumulativeWorkedDays,
          secondaryValue: (p) => p.plannedCumulativeWorkedDays,
          showSecondary: metrics.sure.hasPlan,
          primaryLabel: 'Gerçek',
          secondaryLabel: 'Plan',
        ),
        const SizedBox(height: AppSpacing.lg),
        _VerimChartSection(
          title: 'Adam-gün · Kümülatif',
          points: points,
          height: chartHeight,
          unitSuffix: ' AG',
          primaryValue: (p) => p.cumulativeLabor,
          secondaryValue: (p) => p.plannedCumulativeLabor,
          showSecondary: metrics.labor.hasPlan,
          primaryLabel: 'Gerçek',
          secondaryLabel: 'Plan',
        ),
        const SizedBox(height: AppSpacing.lg),
        _VerimChartSection(
          title: 'Verim · Birim verim',
          points: points,
          height: chartHeight,
          unitSuffix: '%',
          primaryValue: (p) => p.efficiencyPct,
          secondaryValue: (_) => 100,
          showSecondary: metrics.canComputeEfficiency,
          primaryLabel: 'Verim',
          secondaryLabel: 'Plan',
          minY: 0,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Her nokta o güne kadar kümülatif metraj, süre, adam-gün ve birim '
          'verimi gösterir.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _VerimTimelinePoint {
  const _VerimTimelinePoint({
    required this.label,
    required this.tooltip,
    required this.cumulativeQty,
    required this.plannedCumulativeQty,
    required this.cumulativeWorkedDays,
    required this.plannedCumulativeWorkedDays,
    required this.cumulativeLabor,
    required this.plannedCumulativeLabor,
    required this.efficiencyPct,
  });

  final String label;
  final String tooltip;
  final double cumulativeQty;
  final double plannedCumulativeQty;
  final double cumulativeWorkedDays;
  final double plannedCumulativeWorkedDays;
  final double cumulativeLabor;
  final double plannedCumulativeLabor;
  final double? efficiencyPct;
}

class _VerimChartSection extends StatelessWidget {
  const _VerimChartSection({
    required this.title,
    required this.points,
    required this.height,
    required this.unitSuffix,
    required this.primaryValue,
    required this.secondaryValue,
    required this.showSecondary,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.minY = 0,
  });

  final String title;
  final List<_VerimTimelinePoint> points;
  final double height;
  final String unitSuffix;
  final double? Function(_VerimTimelinePoint) primaryValue;
  final double Function(_VerimTimelinePoint) secondaryValue;
  final bool showSecondary;
  final String primaryLabel;
  final String secondaryLabel;
  final double minY;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        _LegendRow(
          items: const [
            _LegendItem(color: AppColors.electricBlue, label: 'Gerçekleşen'),
            _LegendItem(
              color: AppColors.warning,
              label: 'Plan',
              dashed: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _DualLineChart(
          points: points,
          height: height,
          unitSuffix: unitSuffix,
          primaryValue: primaryValue,
          secondaryValue: secondaryValue,
          showSecondary: showSecondary,
          primaryLabel: primaryLabel,
          secondaryLabel: secondaryLabel,
          minY: minY,
        ),
      ],
    );
  }
}

class _LegendItem {
  const _LegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.items});

  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final item in items) _LegendDot(item: item),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.item});

  final _LegendItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(18, 3),
          painter: _MiniLinePainter(
            color: item.color,
            dashed: item.dashed,
          ),
        ),
        const SizedBox(width: 6),
        Text(item.label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _MiniLinePainter extends CustomPainter {
  _MiniLinePainter({required this.color, required this.dashed});

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
  bool shouldRepaint(covariant _MiniLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashed != dashed;
}

class _DualLineChart extends StatelessWidget {
  const _DualLineChart({
    required this.points,
    required this.height,
    required this.unitSuffix,
    required this.primaryValue,
    required this.secondaryValue,
    required this.showSecondary,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.minY = 0,
  });

  final List<_VerimTimelinePoint> points;
  final double height;
  final String unitSuffix;
  final double? Function(_VerimTimelinePoint) primaryValue;
  final double Function(_VerimTimelinePoint) secondaryValue;
  final bool showSecondary;
  final String primaryLabel;
  final String secondaryLabel;
  final double minY;

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primarySpots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final v = primaryValue(points[i]);
      if (v == null || v.isNaN) continue;
      primarySpots.add(FlSpot(i.toDouble(), v));
    }

    if (primarySpots.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Grafik için yeterli veri yok',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final secondarySpots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), secondaryValue(points[i])),
    ];

    var maxY = primarySpots.fold<double>(
      minY,
      (m, s) => s.y > m ? s.y : m,
    );
    if (showSecondary) {
      for (final s in secondarySpots) {
        if (s.y > maxY) maxY = s.y;
      }
    }
    final top = maxY <= minY ? 1.0 : maxY * 1.12;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: minY,
          maxY: top,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: top / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: top / 2,
                getTitlesWidget: (v, meta) {
                  if ((v - minY).abs() < 0.001 ||
                      (v - top).abs() < 0.001 ||
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
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final i = v.round();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      points[i].label,
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) =>
                  theme.colorScheme.inverseSurface.withValues(alpha: 0.94),
              getTooltipItems: (spots) {
                if (spots.isEmpty) return [];
                final i = spots.first.x.round();
                if (i < 0 || i >= points.length) return [];
                final p = points[i];
                final buf = StringBuffer(p.tooltip);
                final primary = primaryValue(p);
                if (primary != null && !primary.isNaN) {
                  buf
                    ..writeln()
                    ..write('$primaryLabel: ${_fmt(primary)}$unitSuffix');
                }
                if (showSecondary) {
                  buf
                    ..writeln()
                    ..write(
                      '$secondaryLabel: ${_fmt(secondaryValue(p))}$unitSuffix',
                    );
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
            if (showSecondary)
              LineChartBarData(
                spots: secondarySpots,
                isCurved: true,
                curveSmoothness: 0.2,
                color: AppColors.warning.withValues(alpha: 0.9),
                barWidth: 2,
                dashArray: const [6, 4],
                dotData: const FlDotData(show: false),
              ),
            LineChartBarData(
              spots: primarySpots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: AppColors.electricBlue,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3.5,
                  color: AppColors.electricBlue,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.electricBlue.withValues(alpha: 0.07),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
