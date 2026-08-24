import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/puantaj_date.dart';
import '../../../data/providers/period_site_report_provider.dart';
import '../../../data/services/puantaj_report_builder.dart';
import 'period_report_shared.dart';
import 'period_report_site_sections.dart';

/// Aylık rapor — puantaj + imalat + verim (Puantaj AL ile aynı kaynaklar).
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteReport = ref.watch(
      periodSiteReportProvider((
        projectId: projectId,
        anchorDate: anchorDate,
        period: PuantajReportPeriod.monthly,
      )),
    );
    final anchor = PuantajDate.parse(anchorDate);
    final isCurrentMonth = anchor.year == DateTime.now().year &&
        anchor.month == DateTime.now().month;
    final rangeLabel =
        siteReport?.rangeLabel ?? PuantajDate.monthLabel(anchorDate);

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
            'Aylık özet: personel ve ekip puantajı (Puantaj sekmesi), '
            'yapılan işler (İmalat), verim (İş Programı + Keşif). '
            'Rapor AL ile PDF veya Excel dışa aktarın.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (siteReport != null)
          PeriodSiteReportSections(report: siteReport)
        else
          SJCard(
            child: Text(
              'Proje seçili değil veya rapor yüklenemedi.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}
