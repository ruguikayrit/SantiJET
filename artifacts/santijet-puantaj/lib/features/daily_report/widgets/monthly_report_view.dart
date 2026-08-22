import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/design_system/sj_empty_state.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/puantaj_date.dart';
import '../../../data/providers/daily_report_provider.dart';
import '../../../domain/daily_report/period_report_aggregator.dart';
import 'period_report_shared.dart';

/// Aylık rapor — haftalık özetlerden türetilmiş görünüm.
class MonthlyReportView extends ConsumerWidget {
  const MonthlyReportView({
    required this.projectId,
    required this.anchorDate,
    required this.onAnchorChanged,
    required this.onOpenDaily,
    super.key,
  });

  final String projectId;
  final String anchorDate;
  final ValueChanged<String> onAnchorChanged;
  final ValueChanged<String> onOpenDaily;

  static bool _isInMonth(String date, String anchorDate) {
    final d = PuantajDate.parse(date);
    final a = PuantajDate.parse(anchorDate);
    return d.year == a.year && d.month == a.month;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(dailyReportsProvider);
    final summary = PeriodReportAggregator.buildMonthly(
      anchorDate: anchorDate,
      reports: reports,
      projectId: projectId,
    );
    final theme = Theme.of(context);
    final anchor = PuantajDate.parse(anchorDate);
    final isCurrentMonth = anchor.year == DateTime.now().year &&
        anchor.month == DateTime.now().month;

    if (summary.filledDayCount == 0) {
      return Column(
        children: [
          PeriodNavigator(
            label: summary.label,
            subtitle: isCurrentMonth ? 'Bu ay' : null,
            onPrevious: () {
              final prev = DateTime(anchor.year, anchor.month - 1, 1);
              onAnchorChanged(PuantajDate.format(prev));
            },
            onNext: () {
              final next = DateTime(anchor.year, anchor.month + 1, 1);
              onAnchorChanged(PuantajDate.format(next));
            },
          ),
          const Expanded(
            child: SJEmptyState(
              title: 'Bu ayda rapor yok',
              message:
                  'Günlük rapor girdikçe aylık özet haftalara göre burada görünür.',
              icon: Icons.calendar_month_outlined,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        PeriodNavigator(
          label: summary.label,
          subtitle: isCurrentMonth ? 'Bu ay' : null,
          onPrevious: () {
            final prev = DateTime(anchor.year, anchor.month - 1, 1);
            onAnchorChanged(PuantajDate.format(prev));
          },
          onNext: () {
            final next = DateTime(anchor.year, anchor.month + 1, 1);
            onAnchorChanged(PuantajDate.format(next));
          },
        ),
        const SizedBox(height: AppSpacing.md),
        SJCard(
          child: Text(
            'Aylık özet, ay içindeki haftalık raporlardan türetilir. '
            'Ay dışı günler soluk gösterilir.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PeriodSummaryStats(
          filledDays: summary.filledDayCount,
          totalDays: summary.totalDays,
          photos: summary.totalPhotos,
          incoming: summary.totalIncoming,
          adamSaat: summary.totalAdamSaat,
          yevmiye: summary.totalYevmiye,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final week in summary.weeks) ...[
          _WeekBlock(
            week: week,
            monthAnchor: anchorDate,
            onOpenDaily: onOpenDaily,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _WeekBlock extends StatefulWidget {
  const _WeekBlock({
    required this.week,
    required this.monthAnchor,
    required this.onOpenDaily,
  });

  final WeeklyReportSummary week;
  final String monthAnchor;
  final ValueChanged<String> onOpenDaily;

  @override
  State<_WeekBlock> createState() => _WeekBlockState();
}

class _WeekBlockState extends State<_WeekBlock> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final week = widget.week;
    final inMonthDays = week.days
        .where((d) => MonthlyReportView._isInMonth(d.date, widget.monthAnchor))
        .toList();
    final filledInMonth = inMonthDays.where((d) => d.hasContent).length;

    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hafta ${week.label}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$filledInMonth / ${inMonthDays.length} gün (bu ay) · '
                        '${week.totalPhotos} foto · '
                        '${week.totalIncoming} malzeme',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final day in week.days) ...[
              DaySummaryTile(
                summary: day,
                onOpenDaily: widget.onOpenDaily,
                inMonth: MonthlyReportView._isInMonth(
                  day.date,
                  widget.monthAnchor,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}
