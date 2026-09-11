import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/daily_crew_entry.dart';
import '../../domain/man_day_progress.dart';
import '../../domain/program_item.dart';
import '../../state/app_state.dart';
import '../../ui/design_system.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final site = ref.watch(activeSiteProvider);
    final logs = ref.watch(dailyCrewProvider);
    final items = ref
        .watch(programItemsProvider)
        .where((item) => item.santiyeId == site)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SantijetHeader(subtitle: 'Gantt'),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Henüz görev yok.'))
                  : _GanttChart(items: items, logs: logs),
            ),
          ],
        ),
      ),
    );
  }
}

class _GanttChart extends StatelessWidget {
  const _GanttChart({required this.items, required this.logs});

  final List<ProgramItem> items;
  final List<DailyCrewEntry> logs;

  static const _nameWidth = 118.0;
  static const _rowHeight = 36.0;

  @override
  Widget build(BuildContext context) {
    final earliest = items
        .map((item) => item.startDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = items
        .map((item) => item.endDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final start = DateTime(
      earliest.year,
      earliest.month,
      earliest.day,
    ).subtract(const Duration(days: 2));
    final end = DateTime(
      latest.year,
      latest.month,
      latest.day,
    ).add(const Duration(days: 3));
    final span = math.max(1, end.difference(start).inDays);
    final dayWidth = span <= 21
        ? 22.0
        : span <= 60
        ? 14.0
        : 10.0;
    final timelineWidth = span * dayWidth;
    final today = DateTime.now();
    final todayX = today.difference(start).inDays / span;
    final ticks = _ticks(start, span);

    final chartWidth = math.max(timelineWidth, 240.0);
    final todayLeft = _nameWidth + chartWidth * todayX;
    return ColoredBox(
      color: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 88),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _nameWidth + chartWidth,
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Scale(
                        start: start,
                        span: span,
                        ticks: ticks,
                        width: chartWidth,
                        nameWidth: _nameWidth,
                      ),
                      for (final item in items)
                        _GanttRow(
                          item: item,
                          logs: logs,
                          start: start,
                          span: span,
                          width: chartWidth,
                          rowHeight: _rowHeight,
                          nameWidth: _nameWidth,
                        ),
                    ],
                  ),
                  if (todayX >= 0 && todayX <= 1)
                    Positioned(
                      left: todayLeft,
                      top: 22,
                      height: items.length * _rowHeight,
                      child: const IgnorePointer(
                        child: ColoredBox(
                          color: AppColors.critical,
                          child: SizedBox(width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<DateTime> _ticks(DateTime start, int span) {
    final step = span <= 21
        ? 1
        : span <= 60
        ? 7
        : 14;
    return [for (var i = 0; i <= span; i += step) start.add(Duration(days: i))];
  }
}

class _Scale extends StatelessWidget {
  const _Scale({
    required this.start,
    required this.span,
    required this.ticks,
    required this.width,
    required this.nameWidth,
  });

  final DateTime start;
  final int span;
  final List<DateTime> ticks;
  final double width;
  final double nameWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          SizedBox(width: nameWidth),
          SizedBox(
            width: width,
            child: Stack(
              children: [
                const SizedBox.expand(),
                for (final tick in ticks)
                  Positioned(
                    left: tick.difference(start).inDays / span * width,
                    top: 6,
                    child: Text(
                      '${tick.day.toString().padLeft(2, '0')}.'
                      '${tick.month.toString().padLeft(2, '0')}',
                      style: AppTypography.cardBodySmall.copyWith(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GanttRow extends StatelessWidget {
  const _GanttRow({
    required this.item,
    required this.logs,
    required this.start,
    required this.span,
    required this.width,
    required this.rowHeight,
    required this.nameWidth,
  });

  final ProgramItem item;
  final List<DailyCrewEntry> logs;
  final DateTime start;
  final int span;
  final double width;
  final double rowHeight;
  final double nameWidth;

  @override
  Widget build(BuildContext context) {
    final progress = ManDayProgress.of(item, logs);
    final left = item.startDate.difference(start).inDays / span * width;
    final barWidth = math
        .max(item.isMilestone ? 10.0 : 8.0, item.calculatedDays / span * width)
        .toDouble();
    final color = programStatusColor(progress.effectiveStatus);
    final indent = (item.outlineLevel - 1).clamp(0, 6) * 8.0;
    final fill = (progress.progress / 100).clamp(0.0, 1.0);

    return SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: nameWidth,
            child: Padding(
              padding: EdgeInsets.only(left: 8 + indent, right: 6),
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: item.outlineLevel <= 1
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                const Divider(height: 1),
                Positioned(
                  left: left,
                  child: item.isMilestone
                      ? _Milestone(color: color)
                      : _Bar(
                          width: barWidth,
                          color: color,
                          fill: fill,
                          label: '%${progress.progress}',
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.width,
    required this.color,
    required this.fill,
    required this.label,
  });

  final double width;
  final Color color;
  final double fill;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 16,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.85)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: fill,
            child: ColoredBox(color: color),
          ),
          if (width > 28)
            Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Milestone extends StatelessWidget {
  const _Milestone({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(width: 10, height: 10, color: color),
    );
  }
}
