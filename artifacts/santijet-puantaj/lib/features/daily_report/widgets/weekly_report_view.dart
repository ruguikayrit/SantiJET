import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/design_system/sj_empty_state.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/puantaj_date.dart';
import '../../../data/providers/daily_report_provider.dart';
import '../../../domain/daily_report/period_report_aggregator.dart';
import 'period_report_shared.dart';

/// Haftalık rapor — günlük kayıtlardan türetilmiş özet.
class WeeklyReportView extends ConsumerWidget {
  const WeeklyReportView({
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(dailyReportsProvider);
    final summary = PeriodReportAggregator.buildWeekly(
      anchorDate: anchorDate,
      reports: reports,
      projectId: projectId,
    );
    final isCurrentWeek =
        PuantajDate.weekDays(anchorDate).contains(PuantajDate.today());

    if (summary.filledDayCount == 0) {
      return Column(
        children: [
          PeriodNavigator(
            label: summary.label,
            subtitle: isCurrentWeek ? 'Bu hafta' : null,
            onPrevious: () => onAnchorChanged(PuantajDate.shift(anchorDate, -7)),
            onNext: () => onAnchorChanged(PuantajDate.shift(anchorDate, 7)),
          ),
          const Expanded(
            child: SJEmptyState(
              title: 'Bu haftada rapor yok',
              message:
                  'Günlük rapor girdikçe haftalık özet burada görünür.',
              icon: Icons.calendar_view_week_outlined,
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
          subtitle: isCurrentWeek ? 'Bu hafta' : null,
          onPrevious: () => onAnchorChanged(PuantajDate.shift(anchorDate, -7)),
          onNext: () => onAnchorChanged(PuantajDate.shift(anchorDate, 7)),
        ),
        const SizedBox(height: AppSpacing.md),
        SJCard(
          child: Text(
            'Haftalık özet günlük rapor kayıtlarından türetilir. '
            'Gün satırına dokunarak detayı açın; günlük rapora geçebilirsiniz.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PeriodSummaryStats(
          filledDays: summary.filledDayCount,
          totalDays: summary.days.length,
          photos: summary.totalPhotos,
          incoming: summary.totalIncoming,
          adamSaat: summary.totalAdamSaat,
          yevmiye: summary.totalYevmiye,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Günler',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final day in summary.days) ...[
          DaySummaryTile(
            summary: day,
            onOpenDaily: onOpenDaily,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
