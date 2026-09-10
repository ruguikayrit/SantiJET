import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/daily_crew_entry.dart';
import '../../domain/man_day_progress.dart';
import '../../domain/program_item.dart';
import '../../state/app_state.dart';
import '../../ui/design_system.dart';

enum _CalendarView { list, gantt }

enum _DateFilter { all, thisWeek, overdue }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  _CalendarView view = _CalendarView.list;
  ProgramStatus? status;
  String? responsible;
  _DateFilter dateFilter = _DateFilter.all;

  @override
  Widget build(BuildContext context) {
    final site = ref.watch(activeSiteProvider);
    final logs = ref.watch(dailyCrewProvider);
    ManDayProgress row(ProgramItem item) => ManDayProgress.of(item, logs);
    final source = ref
        .watch(programItemsProvider)
        .where((item) => item.santiyeId == site)
        .toList();
    final people =
        source
            .map((item) => item.responsible)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));
    final items = source.where((item) {
      if (status != null && row(item).effectiveStatus != status) return false;
      if (responsible != null && item.responsible != responsible) return false;
      return switch (dateFilter) {
        _DateFilter.all => true,
        _DateFilter.thisWeek =>
          !item.endDate.isBefore(now) && !item.startDate.isAfter(weekEnd),
        _DateFilter.overdue => row(item).effectiveStatus == ProgramStatus.delayed,
      };
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SantijetHeader(subtitle: 'Takvim'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  SegmentedButton<_CalendarView>(
                    segments: const [
                      ButtonSegment(
                        value: _CalendarView.list,
                        icon: Icon(Icons.view_agenda_outlined),
                        label: Text('Liste'),
                      ),
                      ButtonSegment(
                        value: _CalendarView.gantt,
                        icon: Icon(Icons.view_timeline_outlined),
                        label: Text('Gantt'),
                      ),
                    ],
                    selected: {view},
                    onSelectionChanged: (value) =>
                        setState(() => view = value.first),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterMenu<ProgramStatus?>(
                          label: status?.label ?? 'Durum',
                          value: status,
                          entries: [
                            const DropdownMenuEntry(value: null, label: 'Tümü'),
                            ...ProgramStatus.values.map(
                              (value) => DropdownMenuEntry(
                                value: value,
                                label: value.label,
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => status = value),
                        ),
                        const SizedBox(width: 8),
                        _FilterMenu<String?>(
                          label: responsible ?? 'Sorumlu',
                          value: responsible,
                          entries: [
                            const DropdownMenuEntry(value: null, label: 'Tümü'),
                            ...people.map(
                              (name) =>
                                  DropdownMenuEntry(value: name, label: name),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => responsible = value),
                        ),
                        const SizedBox(width: 8),
                        _FilterMenu<_DateFilter>(
                          label: switch (dateFilter) {
                            _DateFilter.all => 'Tarih',
                            _DateFilter.thisWeek => 'Önümüzdeki 7 gün',
                            _DateFilter.overdue => 'Süresi geçen',
                          },
                          value: dateFilter,
                          entries: const [
                            DropdownMenuEntry(
                              value: _DateFilter.all,
                              label: 'Tümü',
                            ),
                            DropdownMenuEntry(
                              value: _DateFilter.thisWeek,
                              label: 'Önümüzdeki 7 gün',
                            ),
                            DropdownMenuEntry(
                              value: _DateFilter.overdue,
                              label: 'Süresi geçen',
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => dateFilter = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Filtreye uyan faaliyet yok.'))
                  : view == _CalendarView.list
                  ? _CalendarList(items: items, logs: logs)
                  : _GanttView(items: items, logs: logs),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.entries,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<DropdownMenuEntry<T>> entries;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownMenu<T>(
    initialSelection: value,
    dropdownMenuEntries: entries,
    onSelected: onChanged,
    width: 170,
    inputDecorationTheme: const InputDecorationTheme(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12),
    ),
    hintText: label,
  );
}

class _CalendarList extends StatelessWidget {
  const _CalendarList({required this.items, required this.logs});
  final List<ProgramItem> items;
  final List<DailyCrewEntry> logs;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd.MM.yyyy');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final progress = ManDayProgress.of(item, logs);
        return SJCard(
          child: Row(
            children: [
              SizedBox(
                width: 58,
                child: Column(
                  children: [
                    Text(
                      '%${progress.progress}',
                      style: AppTypography.kpiValue.copyWith(fontSize: 20),
                    ),
                    Text(
                      '${progress.plannedManDays} AG',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${format.format(item.startDate)} – '
                      '${format.format(item.endDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ProgramStatusBadge(status: item.effectiveStatus()),
            ],
          ),
        );
      },
    );
  }
}

class _GanttView extends StatelessWidget {
  const _GanttView({required this.items, required this.logs});
  final List<ProgramItem> items;
  final List<DailyCrewEntry> logs;

  @override
  Widget build(BuildContext context) {
    final earliest = items
        .map((item) => item.startDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = items
        .map((item) => item.endDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final start = earliest.subtract(const Duration(days: 2));
    final end = latest.add(const Duration(days: 2));
    final span = math.max(1, end.difference(start).inDays);
    final todayX = DateTime.now().difference(start).inDays / span;

    return SJCard(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final timelineWidth = math.max(420.0, constraints.maxWidth - 138);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: timelineWidth + 138,
              child: Stack(
                children: [
                  Column(
                    children: [
                      SizedBox(
                        height: 32,
                        child: Row(
                          children: [
                            const SizedBox(width: 138, child: Text('FAALİYET')),
                            Text(DateFormat('dd.MM').format(start)),
                            const Spacer(),
                            Text(DateFormat('dd.MM').format(end)),
                          ],
                        ),
                      ),
                      ...items.map(
                        (item) => _GanttRow(
                          item: item,
                          logs: logs,
                          start: start,
                          span: span,
                          width: timelineWidth,
                        ),
                      ),
                    ],
                  ),
                  if (todayX >= 0 && todayX <= 1)
                    Positioned(
                      left: 138 + timelineWidth * todayX,
                      top: 24,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: AppColors.critical,
                        child: const Align(
                          alignment: Alignment.topCenter,
                          child: Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.critical,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
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
  });
  final ProgramItem item;
  final List<DailyCrewEntry> logs;
  final DateTime start;
  final int span;
  final double width;

  @override
  Widget build(BuildContext context) {
    final progress = ManDayProgress.of(item, logs);
    final left = item.startDate.difference(start).inDays / span * width;
    final barWidth = math
        .max(12.0, item.calculatedDays / span * width)
        .toDouble();
    final color = switch (progress.effectiveStatus) {
      ProgramStatus.delayed => AppColors.critical,
      ProgramStatus.completed => AppColors.success,
      ProgramStatus.inProgress => AppColors.electricBlue,
      ProgramStatus.planned => const Color(0xFF8B95A7),
    };
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          SizedBox(
            width: 138,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                const Divider(),
                Positioned(
                  left: left,
                  child: Tooltip(
                    message:
                        '${item.name} · ${progress.realizedManDays}/${progress.plannedManDays} AG',
                    child: Container(
                      width: barWidth,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '%${progress.progress}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
