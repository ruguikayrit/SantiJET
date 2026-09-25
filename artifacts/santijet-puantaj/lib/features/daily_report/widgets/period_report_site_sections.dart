import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/providers/production_provider.dart';
import '../../../data/services/period_site_report_builder.dart';
import 'attendance_summary_table.dart';
import 'period_site_report_visual_widgets.dart';

/// Haftalık / aylık rapor — her bölüm ayrı sayfada açılır.
class PeriodSiteReportSections extends StatelessWidget {
  const PeriodSiteReportSections({
    required this.report,
    super.key,
  });

  final PeriodSiteReportData report;

  void _openPage(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => _PeriodReportDetailPage(
          title: title,
          rangeLabel: report.rangeLabel,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionNavTile(
          icon: Icons.fact_check_outlined,
          title: 'Personel puantajı',
          onTap: () => _openPage(
            context,
            title: 'Personel puantajı',
            child: PeriodPersonnelSummaryTable(summary: report.personelSummary),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionNavTile(
          icon: Icons.groups_outlined,
          title: 'Ekip puantajı',
          onTap: () => _openPage(
            context,
            title: 'Ekip puantajı',
            child: PeriodTeamSummaryTable(
              headers: report.ekipPuantaj.headers,
              rows: report.ekipPuantaj.rows,
              sumColumnIndexes: report.ekipPuantaj.sumColumnIndexes,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionNavTile(
          icon: Icons.handyman_outlined,
          title: 'Yevmiyeli işler',
          onTap: () => _openPage(
            context,
            title: 'Yevmiyeli işler',
            child: PeriodTeamSummaryTable(
              headers: report.yevmiyeli.headers,
              rows: report.yevmiyeli.rows,
              emptyMessage: 'Bu dönemde yevmiyeli iş kaydı yok',
              sumColumnIndexes: report.yevmiyeli.sumColumnIndexes,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionNavTile(
          icon: Icons.agriculture_outlined,
          title: 'İş makinesi puantajı',
          onTap: () => _openPage(
            context,
            title: 'İş makinesi puantajı',
            child: PeriodTeamSummaryTable(
              headers: report.machines.headers,
              rows: report.machines.rows,
              emptyMessage: 'Bu dönemde iş makinesi kaydı yok',
              sumColumnIndexes: report.machines.sumColumnIndexes,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionNavTile(
          icon: Icons.directions_car_outlined,
          title: 'Vasıta puantajı',
          onTap: () => _openPage(
            context,
            title: 'Vasıta puantajı',
            child: PeriodTeamSummaryTable(
              headers: report.vehicles.headers,
              rows: report.vehicles.rows,
              emptyMessage: 'Bu dönemde vasıta kaydı yok',
              sumColumnIndexes: report.vehicles.sumColumnIndexes,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionNavTile(
          icon: Icons.construction_outlined,
          title: 'Yapılan işler (İmalat)',
          onTap: () => _openPage(
            context,
            title: 'Yapılan işler (İmalat)',
            child: _ImalatReportSection(report: report),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionNavTile(
          icon: Icons.speed_outlined,
          title: 'Verim',
          onTap: () => _openPage(
            context,
            title: 'Verim',
            child: _VerimReportSection(report: report),
          ),
        ),
      ],
    );
  }
}

class _SectionNavTile extends StatelessWidget {
  const _SectionNavTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.sm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodReportDetailPage extends StatelessWidget {
  const _PeriodReportDetailPage({
    required this.title,
    required this.rangeLabel,
    required this.child,
  });

  final String title;
  final String rangeLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        padding: AppLayout.scrollPadding(),
        children: [
          Text(
            rangeLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
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
