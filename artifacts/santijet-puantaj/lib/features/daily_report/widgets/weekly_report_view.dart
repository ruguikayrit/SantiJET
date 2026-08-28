import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/puantaj_date.dart';
import '../../../data/providers/period_site_report_provider.dart';
import '../../../data/services/puantaj_report_builder.dart';
import 'period_report_shared.dart';
import 'period_report_site_sections.dart';

/// Haftalık rapor — puantaj + imalat + verim (Puantaj AL ile aynı kaynaklar).
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
    final siteReport = ref.watch(
      periodSiteReportProvider((
        projectId: projectId,
        anchorDate: anchorDate,
        period: PuantajReportPeriod.weekly,
      )),
    );
    final isCurrentWeek =
        PuantajDate.weekDays(anchorDate).contains(PuantajDate.today());
    final rangeLabel = siteReport?.rangeLabel ??
        PuantajDate.weekLabel(PuantajDate.weekDays(anchorDate));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        PeriodNavigator(
          label: rangeLabel,
          subtitle: isCurrentWeek ? 'Bu hafta' : null,
          onPrevious: () => onAnchorChanged(PuantajDate.shift(anchorDate, -7)),
          onNext: () => onAnchorChanged(PuantajDate.shift(anchorDate, 7)),
        ),
        const SizedBox(height: AppSpacing.md),
        SJCard.builder(
          builder: (context, theme) => Text(
            'Haftalık özet: personel ve ekip puantajı (Puantaj sekmesi), '
            'yapılan işler (İmalat), verim (İmalat plan/gerçekleşen). '
            'Rapor AL ile PDF veya Excel dışa aktarın.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (siteReport != null)
          PeriodSiteReportSections(report: siteReport)
        else
          SJCard.builder(
            builder: (context, theme) => Text(
              'Proje seçili değil veya rapor yüklenemedi.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}
