import 'package:flutter/material.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/services/period_site_report_builder.dart';
import '../../../data/services/puantaj_report_builder.dart';
import '../../../domain/enums/attendance_status.dart';

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
          subtitle: report.personelPuantaj.subtitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        _PuantajMatrixSection(data: report.personelPuantaj),
        _SummaryLines(lines: report.personelPuantaj.summaryLines),
        const SizedBox(height: AppSpacing.md),
        _SectionTitle(
          icon: Icons.groups_outlined,
          title: 'Ekip puantajı',
          subtitle:
              'Firma Adı · Ekip Adı · Toplam çalışan · Çalışılan gün · Ortalama',
        ),
        const SizedBox(height: AppSpacing.sm),
        _PlainTableSection(
          headers: report.ekipPuantaj.headers,
          rows: report.ekipPuantaj.rows,
          emptyMessage: 'Bu dönemde ekip puantaj kaydı yok.',
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

class _PuantajMatrixSection extends StatelessWidget {
  const _PuantajMatrixSection({required this.data});

  final PuantajReportData data;

  @override
  Widget build(BuildContext context) {
    final visual = data.visual;
    if (!visual.isMatrix || visual.companies.isEmpty) {
      return _PlainTableSection(
        headers: data.headers,
        rows: data.rows,
        emptyMessage: 'Personel puantaj kaydı yok.',
      );
    }

    final theme = Theme.of(context);
    final dayHeaders = visual.dayHeaders;
    final nameW = visual.firstColumnLabel.length > 8 ? 132.0 : 120.0;

    return SJCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _headCell(theme, visual.firstColumnLabel, width: nameW),
                for (final h in dayHeaders) _headCell(theme, h, width: 36),
                _headCell(theme, 'Top.', width: 44),
              ],
            ),
            for (final company in visual.companies) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  company.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final row in company.rows)
                Row(
                  children: [
                    _bodyCell(theme, row.name, width: nameW),
                    if (row.usesDayLabels)
                      for (var i = 0; i < dayHeaders.length; i++)
                        _bodyCell(
                          theme,
                          i < row.dayLabels.length ? row.dayLabels[i] : '',
                          width: 36,
                          center: true,
                        )
                    else
                      for (var i = 0; i < row.statuses.length; i++)
                        _statusCell(theme, row.statuses[i], width: 36),
                    _bodyCell(
                      theme,
                      row.totalLabel,
                      width: 44,
                      center: true,
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headCell(ThemeData theme, String text, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _bodyCell(
    ThemeData theme,
    String text, {
    required double width,
    bool center = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(border: Border.all(color: theme.dividerColor)),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall,
      ),
    );
  }

  Widget _statusCell(ThemeData theme, AttendanceStatus? status, {required double width}) {
    if (status == null) {
      return Container(
        width: width,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          color: const Color(0xFFD1D5DB).withValues(alpha: 0.35),
        ),
      );
    }
    return Container(
      width: width,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        color: status.color.withValues(alpha: 0.85),
      ),
      child: Text(
        status.short,
        style: TextStyle(
          fontSize: status.short.length > 1 ? 8 : 10,
          fontWeight: FontWeight.w700,
          color: AppColors.readableOn(status.color),
        ),
      ),
    );
  }
}

class _PlainTableSection extends StatelessWidget {
  const _PlainTableSection({
    required this.headers,
    required this.rows,
    required this.emptyMessage,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return SJCard(
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          dataRowMinHeight: 32,
          dataRowMaxHeight: 48,
          columns: [
            for (final h in headers) DataColumn(label: Text(h)),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  for (final cell in row) DataCell(Text(cell)),
                ],
              ),
          ],
        ),
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
      return SJCard(
        child: Text(
          'Bu dönemde imalat kaydı yok. İmalat sekmesinden günlük giriş yapın.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      return SJCard(
        child: Text(
          'Verim için İş Programı + Keşif bulut verisi ve dönemde imalat kaydı gerekir.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
