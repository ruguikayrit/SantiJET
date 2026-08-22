import 'package:flutter/material.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/design_system/sj_stat_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/puantaj_date.dart';
import '../../../domain/daily_report/period_report_aggregator.dart';

/// Haftalık / aylık dönem gezintisi.
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    this.subtitle,
    super.key,
  });

  final String label;
  final String? subtitle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subtitle != null)
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.electricBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class PeriodSummaryStats extends StatelessWidget {
  const PeriodSummaryStats({
    required this.filledDays,
    required this.totalDays,
    required this.photos,
    required this.incoming,
    required this.adamSaat,
    required this.yevmiye,
    super.key,
  });

  final int filledDays;
  final int totalDays;
  final int photos;
  final int incoming;
  final double adamSaat;
  final double yevmiye;

  static String _num(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        SizedBox(
          width: 160,
          child: SJStatCard(
            label: 'Dolu gün',
            value: '$filledDays',
            unit: '/ $totalDays',
          ),
        ),
        SizedBox(
          width: 160,
          child: SJStatCard(
            label: 'Fotoğraf',
            value: '$photos',
          ),
        ),
        SizedBox(
          width: 160,
          child: SJStatCard(
            label: 'Gelen malzeme',
            value: '$incoming',
            unit: 'kalem',
          ),
        ),
        SizedBox(
          width: 160,
          child: SJStatCard(
            label: 'Adam-saat',
            value: _num(adamSaat),
          ),
        ),
        SizedBox(
          width: 160,
          child: SJStatCard(
            label: 'Yevmiye',
            value: _num(yevmiye),
          ),
        ),
      ],
    );
  }
}

class DaySummaryTile extends StatefulWidget {
  const DaySummaryTile({
    required this.summary,
    required this.onOpenDaily,
    this.inMonth = true,
    super.key,
  });

  final DailyReportDaySummary summary;
  final ValueChanged<String> onOpenDaily;
  final bool inMonth;

  @override
  State<DaySummaryTile> createState() => _DaySummaryTileState();
}

class _DaySummaryTileState extends State<DaySummaryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.summary;
    final opacity = widget.inMonth ? 1.0 : 0.55;

    return Opacity(
      opacity: opacity,
      child: SJCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: AppRadii.md,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            PuantajDate.withDayName(s.date),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.hasContent
                                ? '${s.photoCount} foto · ${s.incomingCount} malzeme · ${_num(s.adamSaat)} sa'
                                : 'Kayıt yok',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: s.hasContent
                            ? AppColors.success.withValues(alpha: 0.15)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: AppRadii.sm,
                      ),
                      child: Text(
                        s.hasContent ? 'Dolu' : 'Boş',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: s.hasContent
                              ? AppColors.success
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _metricRow(theme, 'Fotoğraf', '${s.photoCount}'),
                    _metricRow(
                      theme,
                      'Malzeme (gelen)',
                      '${s.incomingCount}',
                    ),
                    _metricRow(
                      theme,
                      'Makine / vasıta',
                      '${s.machineCount} · ${_num(s.machineHours)} sa',
                    ),
                    _metricRow(
                      theme,
                      'Puantaj',
                      '${s.presentCount} mevcut · ${_num(s.yevmiye)} yv',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => widget.onOpenDaily(s.date),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Günlük raporu aç'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _num(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  Widget _metricRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
