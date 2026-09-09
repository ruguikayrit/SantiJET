import 'package:flutter/material.dart';

import '../../../core/design_system/sj_modal.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/puantaj_date.dart';
import '../../../data/services/puantaj_report_builder.dart';

/// Puantaj AL — dönem türüne göre takvim / ay seçici satırı.
class PuantajExportPeriodField extends StatelessWidget {
  const PuantajExportPeriodField({
    required this.period,
    required this.anchorDate,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final PuantajReportPeriod period;
  final String anchorDate;
  final ValueChanged<String> onChanged;
  final bool enabled;

  String get _title => switch (period) {
        PuantajReportPeriod.daily => 'Gün',
        PuantajReportPeriod.weekly => 'Hafta',
        PuantajReportPeriod.monthly => 'Ay',
      };

  String get _valueLabel => switch (period) {
        PuantajReportPeriod.daily => PuantajDate.withDayName(anchorDate),
        PuantajReportPeriod.weekly =>
          PuantajDate.weekLabel(PuantajDate.weekDays(anchorDate)),
        PuantajReportPeriod.monthly => PuantajDate.monthLabel(anchorDate),
      };

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;
    final picked = switch (period) {
      PuantajReportPeriod.daily => await _pickDaily(context),
      PuantajReportPeriod.weekly => await _pickWeekly(context),
      PuantajReportPeriod.monthly => await _pickMonthly(context),
    };
    if (picked != null) onChanged(picked);
  }

  Future<String?> _pickDaily(BuildContext context) async {
    final initial = PuantajDate.parse(anchorDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Gün seçin',
    );
    return picked == null ? null : PuantajDate.format(picked);
  }

  Future<String?> _pickWeekly(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => _WeeklyPickerDialog(anchorDate: anchorDate),
    );
  }

  Future<String?> _pickMonthly(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => _MonthlyPickerDialog(anchorDate: anchorDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surfaceContainerHighest.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.55,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: surface,
          borderRadius: AppRadii.md,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? () => _openPicker(context) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: enabled
                        ? AppColors.electricBlue
                        : theme.disabledColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _valueLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (period == PuantajReportPeriod.weekly) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Herhangi bir güne dokunun; haftanın tamamı seçilir.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _WeeklyPickerDialog extends StatefulWidget {
  const _WeeklyPickerDialog({required this.anchorDate});

  final String anchorDate;

  @override
  State<_WeeklyPickerDialog> createState() => _WeeklyPickerDialogState();
}

class _WeeklyPickerDialogState extends State<_WeeklyPickerDialog> {
  late DateTime _month;
  late Set<String> _selectedWeek;

  @override
  void initState() {
    super.initState();
    final anchor = PuantajDate.parse(widget.anchorDate);
    _month = DateTime(anchor.year, anchor.month);
    _selectedWeek = PuantajDate.weekDays(widget.anchorDate).toSet();
  }

  void _selectDay(DateTime day) {
    final anchor = PuantajDate.format(day);
    setState(() => _selectedWeek = PuantajDate.weekDays(anchor).toSet());
    Navigator.of(context).pop(anchor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = SJModal.sheetThemeOf(context);
    return Theme(
      data: theme,
      child: AlertDialog(
        title: const Text('Hafta seçin'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MonthNavHeader(
                month: _month,
                onPrev: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
                onNext: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _WeekCalendarGrid(
                month: _month,
                selectedWeek: _selectedWeek,
                onDayTap: _selectDay,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }
}

class _MonthlyPickerDialog extends StatefulWidget {
  const _MonthlyPickerDialog({required this.anchorDate});

  final String anchorDate;

  @override
  State<_MonthlyPickerDialog> createState() => _MonthlyPickerDialogState();
}

class _MonthlyPickerDialogState extends State<_MonthlyPickerDialog> {
  late int _year;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final anchor = PuantajDate.parse(widget.anchorDate);
    _year = anchor.year;
    _selectedMonth = anchor.month;
  }

  void _selectMonth(int month) {
    final anchor = PuantajDate.format(DateTime(_year, month, 1));
    Navigator.of(context).pop(anchor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = SJModal.sheetThemeOf(context);
    return Theme(
      data: theme,
      child: AlertDialog(
        title: const Text('Ay seçin'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _year--),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      '$_year',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _year++),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.xs,
                crossAxisSpacing: AppSpacing.xs,
                childAspectRatio: 2.2,
                children: [
                  for (var m = 1; m <= 12; m++)
                    _MonthTile(
                      label: PuantajDate.trMonths[m - 1],
                      selected: m == _selectedMonth,
                      onTap: () {
                        setState(() => _selectedMonth = m);
                        _selectMonth(m);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  const _MonthTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? AppColors.electricBlue
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: AppRadii.sm,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthNavHeader extends StatelessWidget {
  const _MonthNavHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(
            PuantajDate.monthLabel(PuantajDate.format(month)),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _WeekCalendarGrid extends StatelessWidget {
  const _WeekCalendarGrid({
    required this.month,
    required this.selectedWeek,
    required this.onDayTap,
  });

  final DateTime month;
  final Set<String> selectedWeek;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1;
    final totalCells = leading + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();
    final todayKey =
        PuantajDate.format(DateTime(today.year, today.month, today.day));

    return Column(
      children: [
        Row(
          children: [
            for (final d in PuantajDate.trDaysShort)
              Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < rows; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final idx = r * 7 + c;
                        final dayNum = idx - leading + 1;
                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return const SizedBox(height: 40);
                        }
                        final day = DateTime(month.year, month.month, dayNum);
                        final key = PuantajDate.format(day);
                        final inWeek = selectedWeek.contains(key);
                        final isToday = key == todayKey;

                        return Padding(
                          padding: const EdgeInsets.all(2),
                          child: Material(
                            color: inWeek
                                ? AppColors.electricBlue
                                : isToday
                                    ? AppColors.electricBlue
                                        .withValues(alpha: 0.12)
                                    : Colors.transparent,
                            borderRadius: AppRadii.sm,
                            child: InkWell(
                              borderRadius: AppRadii.sm,
                              onTap: () => onDayTap(day),
                              child: SizedBox(
                                height: 40,
                                child: Center(
                                  child: Text(
                                    '$dayNum',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: inWeek || isToday
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: inWeek
                                          ? Colors.white
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
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
