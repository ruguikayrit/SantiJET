import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/providers/production_provider.dart';
import '../../../data/services/period_site_report_builder.dart';
import 'attendance_summary_table.dart';
import 'period_site_report_visual_widgets.dart';

/// Haftalık / aylık rapor — puantaj + imalat + verim bölümleri.
///
/// Tüm alt başlıklar açılır-kapanır; varsayılan kapalı.
class PeriodSiteReportSections extends StatelessWidget {
  const PeriodSiteReportSections({
    required this.report,
    super.key,
  });

  final PeriodSiteReportData report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CollapsibleSection(
          icon: Icons.fact_check_outlined,
          title: 'Personel puantajı',
          child: PeriodPersonnelSummaryTable(summary: report.personelSummary),
        ),
        const SizedBox(height: AppSpacing.md),
        _CollapsibleSection(
          icon: Icons.groups_outlined,
          title: 'Ekip puantajı',
          child: PeriodTeamSummaryTable(
            headers: report.ekipPuantaj.headers,
            rows: report.ekipPuantaj.rows,
            sumColumnIndexes: report.ekipPuantaj.sumColumnIndexes,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CollapsibleSection(
          icon: Icons.handyman_outlined,
          title: 'Yevmiyeli işler',
          child: PeriodTeamSummaryTable(
            headers: report.yevmiyeli.headers,
            rows: report.yevmiyeli.rows,
            emptyMessage: 'Bu dönemde yevmiyeli iş kaydı yok',
            sumColumnIndexes: report.yevmiyeli.sumColumnIndexes,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CollapsibleSection(
          icon: Icons.construction_outlined,
          title: 'Yapılan işler (İmalat)',
          child: _ImalatReportSection(report: report),
        ),
        const SizedBox(height: AppSpacing.md),
        _CollapsibleSection(
          icon: Icons.speed_outlined,
          title: 'Verim',
          child: _VerimReportSection(report: report),
        ),
      ],
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  const _CollapsibleSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: AppRadii.sm,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.sm),
          widget.child,
        ],
      ],
    );
  }
}

class _ImalatReportSection extends ConsumerWidget {
  const _ImalatReportSection({required this.report});

  final PeriodSiteReportData report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productions = ref.watch(productionProvider);
    final byId = {for (final p in productions) p.id: p};
    return PeriodImalatReportVisual(
      report: report,
      productionsById: byId,
      expandAllCharts: true,
    );
  }
}

class _VerimReportSection extends ConsumerWidget {
  const _VerimReportSection({required this.report});

  final PeriodSiteReportData report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productions = ref.watch(productionProvider);
    final byId = {for (final p in productions) p.id: p};
    return PeriodVerimReportVisual(
      report: report,
      productionsById: byId,
      expandAllCharts: true,
    );
  }
}
