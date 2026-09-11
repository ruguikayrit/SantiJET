import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/daily_crew_entry.dart';
import '../../domain/gantt_layout.dart';
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

  @override
  Widget build(BuildContext context) {
    final layout = GanttLayout.fromItems(items);
    final today = DateTime.now();
    final showToday = layout.contains(today);

    return ColoredBox(
      color: AppColors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 88),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: GanttLayout.nameWidth,
              child: Column(
                children: [
                  const SizedBox(height: GanttLayout.scaleHeight),
                  for (final item in items) _NameCell(item: item),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: layout.width,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Column(
                        children: [
                          _Scale(layout: layout),
                          for (final item in items)
                            _BarRow(item: item, logs: logs, layout: layout),
                        ],
                      ),
                      if (showToday)
                        Positioned(
                          left: layout.xFor(today) + layout.dayWidth / 2,
                          top: GanttLayout.scaleHeight - 6,
                          height: 6 + items.length * GanttLayout.rowHeight,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _Scale extends StatelessWidget {
  const _Scale({required this.layout});
  final GanttLayout layout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GanttLayout.scaleHeight,
      width: layout.width,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          for (final tick in layout.ticks())
            Positioned(
              left: layout.xFor(tick).clamp(0, layout.width - 36),
              top: 6,
              width: 36,
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
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell({required this.item});
  final ProgramItem item;

  @override
  Widget build(BuildContext context) {
    final indent = (item.outlineLevel - 1).clamp(0, 6) * 8.0;
    return SizedBox(
      height: GanttLayout.rowHeight,
      child: Padding(
        padding: EdgeInsets.only(left: 8 + indent, right: 6),
        child: Align(
          alignment: Alignment.centerLeft,
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
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.item, required this.logs, required this.layout});

  final ProgramItem item;
  final List<DailyCrewEntry> logs;
  final GanttLayout layout;

  @override
  Widget build(BuildContext context) {
    final progress = ManDayProgress.of(item, logs);
    final color = programStatusColor(progress.effectiveStatus);
    final left = layout.barLeft(item);
    final width = layout.barWidth(item);
    final fill = (progress.progress / 100).clamp(0.0, 1.0);

    return SizedBox(
      height: GanttLayout.rowHeight,
      width: layout.width,
      child: Stack(
        alignment: Alignment.centerLeft,
        clipBehavior: Clip.hardEdge,
        children: [
          const Divider(height: 1),
          Positioned(
            left: left,
            child: item.isMilestone
                ? _Milestone(color: color)
                : _Bar(
                    width: width,
                    color: color,
                    fill: fill,
                    label: '%${progress.progress}',
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
