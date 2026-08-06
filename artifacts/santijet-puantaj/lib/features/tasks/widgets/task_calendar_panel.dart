import 'package:flutter/material.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/design_system/sj_modal.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/puantaj_date.dart';
import '../../../domain/entities/site_task.dart';

/// Açılır ay takvimi — yeşil: en erken başlangıç, kırmızı: en geç teslimat.
class TaskCalendarPanel extends StatefulWidget {
  const TaskCalendarPanel({
    super.key,
    required this.tasks,
    this.onDaySelected,
  });

  final List<SiteTask> tasks;
  final ValueChanged<DateTime>? onDaySelected;

  @override
  State<TaskCalendarPanel> createState() => _TaskCalendarPanelState();
}

class _TaskCalendarPanelState extends State<TaskCalendarPanel> {
  bool _expanded = false;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  Set<String> get _startKeys {
    final keys = <String>{};
    for (final t in widget.tasks) {
      final d = t.earliestStartDate;
      if (d != null) keys.add(PuantajDate.format(d));
    }
    return keys;
  }

  Set<String> get _dueKeys {
    final keys = <String>{};
    for (final t in widget.tasks) {
      final d = t.latestDeliveryDate;
      if (d != null) keys.add(PuantajDate.format(d));
    }
    return keys;
  }

  List<SiteTask> _tasksOn(DateTime day) {
    final key = PuantajDate.format(day);
    return widget.tasks
        .where(
          (t) =>
              t.earliestStart == key ||
              t.dueDate == key ||
              (t.earliestStartDate != null &&
                  PuantajDate.format(t.earliestStartDate!) == key) ||
              (t.latestDeliveryDate != null &&
                  PuantajDate.format(t.latestDeliveryDate!) == key),
        )
        .toList();
  }

  Future<void> _showDayTasks(DateTime day) async {
    final list = _tasksOn(day);
    if (list.isEmpty) {
      widget.onDaySelected?.call(day);
      return;
    }
    if (!mounted) return;
    final sheetTheme = SJModal.sheetThemeOf(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: SJModal.sheetSurface,
      builder: (ctx) {
        final theme = sheetTheme;
        return Theme(
          data: sheetTheme,
          child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  PuantajDate.longLabel(PuantajDate.format(day)),
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final t in list) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.title),
                    subtitle: Text(
                      [
                        if (t.assignee.isNotEmpty) 'Atanan: ${t.assignee}',
                        if (t.earliestStart.isNotEmpty)
                          'Başlangıç ${t.earliestStart}',
                        if (t.dueDate.isNotEmpty) 'Teslimat ${t.dueDate}',
                      ].join(' · '),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Kapat'),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
    widget.onDaySelected?.call(day);
  }

  @override
  Widget build(BuildContext context) {
    final starts = _startKeys;
    final dues = _dueKeys;
    final label = PuantajDate.monthLabel(PuantajDate.format(_month));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SJCard(
        padding: EdgeInsets.zero,
        // Kart kontrast teması: mürekkep kart yüzeyine göre çözülür.
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            return Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: AppRadii.md,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Görev takvimi',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _expanded
                                ? label
                                : 'Yeşil başlangıç · kırmızı teslimat',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.md,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Önceki ay',
                          onPressed: () => setState(() {
                            _month = DateTime(_month.year, _month.month - 1);
                          }),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Sonraki ay',
                          onPressed: () => setState(() {
                            _month = DateTime(_month.year, _month.month + 1);
                          }),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        for (final d in PuantajDate.trDaysShort)
                          Expanded(
                            child: Text(
                              d,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _MonthGrid(
                      month: _month,
                      startKeys: starts,
                      dueKeys: dues,
                      onDayTap: _showDayTasks,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _LegendDot(color: AppColors.success, label: 'Başlangıç'),
                        const SizedBox(width: AppSpacing.md),
                        _LegendDot(
                          color: AppColors.critical,
                          label: 'Teslimat',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
            );
          },
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.startKeys,
    required this.dueKeys,
    required this.onDayTap,
  });

  final DateTime month;
  final Set<String> startKeys;
  final Set<String> dueKeys;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Pazartesi = 1 → grid offset 0
    final leading = first.weekday - 1;
    final totalCells = leading + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();
    final todayKey = PuantajDate.format(DateTime(today.year, today.month, today.day));

    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final index = r * 7 + c;
                        final dayNum = index - leading + 1;
                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return const SizedBox(height: 40);
                        }
                        final day = DateTime(month.year, month.month, dayNum);
                        final key = PuantajDate.format(day);
                        final isStart = startKeys.contains(key);
                        final isDue = dueKeys.contains(key);
                        final isToday = key == todayKey;
                        return _DayCell(
                          day: dayNum,
                          isToday: isToday,
                          isStart: isStart,
                          isDue: isDue,
                          onTap: () => onDayTap(day),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isStart,
    required this.isDue,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isStart;
  final bool isDue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMark = isStart || isDue;

    Color? bg;
    if (isStart && isDue) {
      bg = null; // özel boyama
    } else if (isStart) {
      bg = AppColors.success.withValues(alpha: 0.35);
    } else if (isDue) {
      bg = AppColors.critical.withValues(alpha: 0.35);
    }

    return Padding(
      padding: const EdgeInsets.all(1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 40,
            child: Stack(
              children: [
                if (isStart && isDue)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.4),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.critical.withValues(alpha: 0.4),
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (bg != null)
                  Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Text(
                    '$day',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: hasMark || isToday
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: hasMark
                          ? AppColors.readableOn(
                              Color.lerp(
                                AppColors.cardSurface,
                                isDue && !isStart
                                    ? AppColors.critical
                                    : AppColors.success,
                                0.45,
                              )!,
                            )
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
