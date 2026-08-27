import 'package:flutter/material.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/services/period_site_report_builder.dart';
import 'attendance_summary_table.dart';

String _fmtNum(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}

/// Haftalık / aylık rapor — puantaj + imalat + verim bölümleri.
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
        _SectionTitle(
          icon: Icons.fact_check_outlined,
          title: 'Personel puantajı',
          subtitle: report.personelSummary.subtitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        PeriodPersonnelSummaryTable(summary: report.personelSummary),
        _SummaryLines(lines: report.personelSummary.summaryLines),
        const SizedBox(height: AppSpacing.md),
        _SectionTitle(
          icon: Icons.groups_outlined,
          title: 'Ekip puantajı',
          subtitle:
              'Adam.gün · Çalışılan gün · Günlük ortalama adam',
        ),
        const SizedBox(height: AppSpacing.sm),
        PeriodTeamSummaryTable(
          headers: report.ekipPuantaj.headers,
          rows: report.ekipPuantaj.rows,
        ),
        _SummaryLines(lines: report.ekipPuantaj.summaryLines),
        const SizedBox(height: AppSpacing.md),
        _SectionTitle(
          icon: Icons.construction_outlined,
          title: 'Yapılan işler (İmalat)',
          subtitle: 'İmalat sekmesi — dönem gerçekleşen',
        ),
        const SizedBox(height: AppSpacing.sm),
        _ImalatTableSection(rows: report.imalatRows),
        const SizedBox(height: AppSpacing.md),
        _SectionTitle(
          icon: Icons.speed_outlined,
          title: 'Verim',
          subtitle: 'Plan: İş Programı + Keşif · Gerçekleşen: İmalat kayıtları',
        ),
        const SizedBox(height: AppSpacing.sm),
        _VerimTableSection(rows: report.verimRows),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryLines extends StatelessWidget {
  const _SummaryLines({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                line,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImalatTableSection extends StatelessWidget {
  const _ImalatTableSection({required this.rows});

  final List<PeriodImalatRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return SJCard.builder(
        builder: (context, theme) => Text(
          'Bu dönemde imalat kaydı yok. İmalat sekmesinden günlük giriş yapın.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return SJCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 36,
          columns: const [
            DataColumn(label: Text('İmalat')),
            DataColumn(label: Text('Konum')),
            DataColumn(label: Text('Ekip')),
            DataColumn(label: Text('Dönem')),
            DataColumn(label: Text('Birim')),
            DataColumn(label: Text('Adam-gün')),
            DataColumn(label: Text('Kümülatif')),
            DataColumn(label: Text('Plan')),
            DataColumn(label: Text('%')),
          ],
          rows: [
            for (final r in rows)
              DataRow(
                cells: [
                  DataCell(Text(r.name)),
                  DataCell(Text(r.location.isEmpty ? '—' : r.location)),
                  DataCell(Text(r.teamName.isEmpty ? '—' : r.teamName)),
                  DataCell(Text('${_fmtNum(r.periodQty)} ${r.unit}')),
                  DataCell(Text(r.unit)),
                  DataCell(Text(_fmtNum(r.periodLaborDays))),
                  DataCell(Text('${_fmtNum(r.totalQty)} ${r.unit}')),
                  DataCell(Text('${_fmtNum(r.plannedQty)} ${r.unit}')),
                  DataCell(Text('${r.progressPct.toStringAsFixed(0)}%')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _VerimTableSection extends StatelessWidget {
  const _VerimTableSection({required this.rows});

  final List<PeriodVerimRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return SJCard.builder(
        builder: (context, theme) => Text(
          'Verim için İş Programı + Keşif bulut verisi ve dönemde imalat kaydı gerekir.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return SJCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 36,
          columns: const [
            DataColumn(label: Text('İmalat')),
            DataColumn(label: Text('Plan AG')),
            DataColumn(label: Text('Dönem AG')),
            DataColumn(label: Text('Plan metraj')),
            DataColumn(label: Text('Dönem metraj')),
            DataColumn(label: Text('Verim')),
          ],
          rows: [
            for (final r in rows)
              DataRow(
                cells: [
                  DataCell(Text(r.imalatName)),
                  DataCell(Text(_fmtNum(r.plannedWorkerDays))),
                  DataCell(Text(_fmtNum(r.periodActualWorkerDays))),
                  DataCell(Text(
                    r.plannedQty != null
                        ? '${_fmtNum(r.plannedQty!)} ${r.unit ?? ''}'
                        : '—',
                  )),
                  DataCell(Text(
                    '${_fmtNum(r.periodActualQty)} ${r.unit ?? ''}',
                  )),
                  DataCell(Text(
                    r.unitEfficiency != null
                        ? '%${(r.unitEfficiency! * 100).toStringAsFixed(0)}'
                        : '—',
                  )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
