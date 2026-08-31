import 'package:flutter/material.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/production_triple_progress.dart';
import '../../../data/services/period_site_report_builder.dart';
import 'attendance_summary_table.dart';

String _fmtNum(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}

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
          child: _ImalatTableSection(rows: report.imalatRows),
        ),
        const SizedBox(height: AppSpacing.md),
        _CollapsibleSection(
          icon: Icons.speed_outlined,
          title: 'Verim',
          child: _VerimTableSection(rows: report.verimRows),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _ImalatPeriodCard(row: rows[i]),
        ],
      ],
    );
  }
}

class _ImalatPeriodCard extends StatelessWidget {
  const _ImalatPeriodCard({required this.row});

  final PeriodImalatRow row;

  @override
  Widget build(BuildContext context) {
    final pct = row.progressPct.clamp(0, 999).toDouble();
    final barColor = completionColorForPct(pct);
    final meta = [
      if (row.location.trim().isNotEmpty) row.location.trim(),
      if (row.teamName.trim().isNotEmpty) row.teamName.trim(),
      if (row.unit.trim().isNotEmpty) row.unit.trim(),
    ].join(' · ');

    return SJCard.builder(
      builder: (context, theme) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _PctBadge(pct: pct, color: barColor),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadii.xs,
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: barColor.withValues(alpha: 0.14),
                color: barColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Dönem',
                    value: '${_fmtNum(row.periodQty)} ${row.unit}'.trim(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _MetricTile(
                    label: 'Adam-gün',
                    value: _fmtNum(row.periodLaborDays),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Kümülatif',
                    value: '${_fmtNum(row.totalQty)} ${row.unit}'.trim(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _MetricTile(
                    label: 'Plan',
                    value: '${_fmtNum(row.plannedQty)} ${row.unit}'.trim(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
          'Verim için İmalat sekmesinde planlanan değerler ve dönemde günlük kayıt gerekir.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _VerimPeriodCard(row: rows[i]),
        ],
      ],
    );
  }
}

class _VerimPeriodCard extends StatelessWidget {
  const _VerimPeriodCard({required this.row});

  final PeriodVerimRow row;

  @override
  Widget build(BuildContext context) {
    final unit = (row.unit ?? '').trim();
    final efficiency = row.unitEfficiency;

    return SJCard.builder(
      builder: (context, theme) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    row.imalatName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (efficiency != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  UnitEfficiencyBadge(efficiency: efficiency, compact: true),
                ],
              ],
            ),
            if (efficiency != null) ...[
              const SizedBox(height: AppSpacing.sm),
              UnitEfficiencyBar(efficiency: efficiency, height: 5),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Plan AG',
                    value: _fmtNum(row.plannedWorkerDays),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _MetricTile(
                    label: 'Dönem AG',
                    value: _fmtNum(row.periodActualWorkerDays),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Plan metraj',
                    value: row.plannedQty != null
                        ? '${_fmtNum(row.plannedQty!)}${unit.isEmpty ? '' : ' $unit'}'
                        : '—',
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _MetricTile(
                    label: 'Dönem metraj',
                    value:
                        '${_fmtNum(row.periodActualQty)}${unit.isEmpty ? '' : ' $unit'}',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PctBadge extends StatelessWidget {
  const _PctBadge({required this.pct, required this.color});

  final double pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadii.sm,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '%${pct.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.statusInkOnCard(color),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.electricBlue.withValues(alpha: 0.06),
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
