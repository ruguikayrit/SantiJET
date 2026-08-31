import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sj_button.dart';
import '../../../core/design_system/sj_card.dart';
import '../../../core/design_system/sj_modal.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/providers/production_chart_options_provider.dart';
import '../../../data/providers/verim_provider.dart';
import '../../../data/services/production_chart_options.dart';
import '../../../domain/entities/production.dart';

class _ChartSlice {
  const _ChartSlice({
    required this.label,
    required this.value,
    required this.color,
    this.secondary,
  });

  final String label;
  final double value;
  final Color color;
  final double? secondary;
}

/// İmalat / Verim ortak grafik paneli + ayar butonu.
class ProductionChartPanel extends ConsumerWidget {
  const ProductionChartPanel.imalat({
    required this.productions,
    super.key,
  })  : verimRows = const [],
        teamSummaries = const [],
        _forVerim = false;

  const ProductionChartPanel.verim({
    required this.verimRows,
    required this.teamSummaries,
    super.key,
  })  : productions = const [],
        _forVerim = true;

  final List<Production> productions;
  final List<VerimRow> verimRows;
  final List<TeamVerimSummary> teamSummaries;
  final bool _forVerim;

  Future<void> _openSettings(BuildContext context, WidgetRef ref) async {
    final current = ref.read(productionChartOptionsProvider);
    final next = await showProductionChartSettingsSheet(
      context,
      initial: current,
      forVerim: _forVerim,
    );
    if (next == null) return;
    ref.read(productionChartOptionsProvider.notifier).save(next);
  }

  List<_ChartSlice> _imalatSlices(
    ProductionChartOptions options,
  ) {
    if (productions.isEmpty) return const [];
    switch (options.imalatMetric) {
      case ImalatChartMetric.phaseShare:
        var bekleyen = 0;
        var devam = 0;
        var tamam = 0;
        for (final p in productions) {
          if (p.isComplete) {
            tamam++;
          } else if (p.dailyEntries.isEmpty) {
            bekleyen++;
          } else {
            devam++;
          }
        }
        return [
          if (bekleyen > 0)
            _ChartSlice(
              label: 'Bekleyen',
              value: bekleyen.toDouble(),
              color: AppColors.warning,
            ),
          if (devam > 0)
            _ChartSlice(
              label: 'Devam',
              value: devam.toDouble(),
              color: AppColors.info,
            ),
          if (tamam > 0)
            _ChartSlice(
              label: 'Tamam',
              value: tamam.toDouble(),
              color: AppColors.success,
            ),
        ];
      case ImalatChartMetric.teamProgress:
        final byTeam = <String, List<Production>>{};
        for (final p in productions) {
          final t = p.teamName.trim().isEmpty ? 'Diğer' : p.teamName.trim();
          byTeam.putIfAbsent(t, () => []).add(p);
        }
        final teams = byTeam.keys.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        final palette = [
          AppColors.electricBlue,
          AppColors.info,
          AppColors.success,
          AppColors.warning,
          AppColors.partial,
          AppColors.critical,
        ];
        return [
          for (var i = 0; i < teams.length; i++)
            _ChartSlice(
              label: teams[i],
              value: () {
                final items = byTeam[teams[i]]!;
                final avg = items.fold<double>(
                      0,
                      (s, p) => s + p.metrics.metraj.progressPct,
                    ) /
                    items.length;
                return avg;
              }(),
              color: palette[i % palette.length],
            ),
        ];
      case ImalatChartMetric.metrajPlanActual:
        final planned = productions.fold<double>(
          0,
          (s, p) => s + (p.plannedQty > 0 ? p.plannedQty : 0),
        );
        final actual = productions.fold<double>(
          0,
          (s, p) => s + p.completedQty,
        );
        return [
          _ChartSlice(
            label: 'Plan',
            value: planned,
            color: AppColors.electricBlue.withValues(alpha: 0.55),
            secondary: actual,
          ),
          _ChartSlice(
            label: 'Gerçek',
            value: actual,
            color: AppColors.success,
          ),
        ];
    }
  }

  List<_ChartSlice> _verimSlices(ProductionChartOptions options) {
    final palette = [
      AppColors.electricBlue,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      AppColors.partial,
      AppColors.critical,
    ];
    switch (options.verimMetric) {
      case VerimChartMetric.teamEfficiency:
        final list = [
          for (final s in teamSummaries)
            if (s.unitEfficiency != null)
              _ChartSlice(
                label: s.teamName,
                value: (s.unitEfficiency! * 100).clamp(0, 200),
                color: AppColors.electricBlue,
              ),
        ];
        for (var i = 0; i < list.length; i++) {
          list[i] = _ChartSlice(
            label: list[i].label,
            value: list[i].value,
            color: palette[i % palette.length],
          );
        }
        return list;
      case VerimChartMetric.laborPlanActual:
        final planned = verimRows.fold<double>(
          0,
          (s, r) => s + r.plannedWorkerDays,
        );
        final actual = verimRows.fold<double>(
          0,
          (s, r) => s + r.actualWorkerDays,
        );
        return [
          _ChartSlice(
            label: 'Plan AG',
            value: planned,
            color: AppColors.electricBlue.withValues(alpha: 0.55),
          ),
          _ChartSlice(
            label: 'Gerçek AG',
            value: actual,
            color: AppColors.success,
          ),
        ];
      case VerimChartMetric.rowEfficiency:
        final rows = [
          for (final r in verimRows)
            if (r.unitEfficiency != null)
              (name: r.imalatName, eff: r.unitEfficiency!),
        ]..sort((a, b) => b.eff.compareTo(a.eff));
        final top = rows.take(8).toList();
        return [
          for (var i = 0; i < top.length; i++)
            _ChartSlice(
              label: top[i].name,
              value: (top[i].eff * 100).clamp(0, 200),
              color: palette[i % palette.length],
            ),
        ];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(productionChartOptionsProvider);
    final kind = _forVerim ? options.verimKind : options.imalatKind;
    final slices = _forVerim
        ? _verimSlices(options)
        : _imalatSlices(options);
    final metricLabel = _forVerim
        ? options.verimMetric.label
        : options.imalatMetric.label;
    final unitHint = switch (_forVerim
        ? options.verimMetric
        : null) {
      VerimChartMetric.teamEfficiency ||
      VerimChartMetric.rowEfficiency =>
        '%',
      VerimChartMetric.laborPlanActual => 'adam-gün',
      null => switch (options.imalatMetric) {
          ImalatChartMetric.phaseShare => 'adet',
          ImalatChartMetric.teamProgress => '%',
          ImalatChartMetric.metrajPlanActual => 'metraj',
        },
    };

    return SJCard.builder(
      builder: (context, theme) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grafik',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$metricLabel · ${kind.label}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Grafik ayarları',
                  onPressed: () => _openSettings(context, ref),
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (slices.isEmpty || slices.every((s) => s.value <= 0))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'Grafik için yeterli veri yok.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: kind == ProductionChartKind.horizontalBar
                    ? (48.0 * slices.length).clamp(120, 240)
                    : 200,
                child: switch (kind) {
                  ProductionChartKind.pie => _PieChart(slices: slices),
                  ProductionChartKind.bar => _BarChart(
                      slices: slices,
                      unitHint: unitHint,
                    ),
                  ProductionChartKind.horizontalBar => _HorizontalBarChart(
                      slices: slices,
                      unitHint: unitHint,
                    ),
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: 6,
                children: [
                  for (final s in slices.take(8))
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: s.color,
                            borderRadius: AppRadii.xs,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_short(s.label)} · ${_fmt(s.value)}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  static String _short(String s) {
    final t = s.trim();
    if (t.length <= 18) return t;
    return '${t.substring(0, 16)}…';
  }
}

class _PieChart extends StatelessWidget {
  const _PieChart({required this.slices});

  final List<_ChartSlice> slices;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return const SizedBox.shrink();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 36,
        sections: [
          for (final s in slices)
            PieChartSectionData(
              value: s.value,
              color: s.color,
              radius: 48,
              title: '${((s.value / total) * 100).round()}%',
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.slices, required this.unitHint});

  final List<_ChartSlice> slices;
  final String unitHint;

  @override
  Widget build(BuildContext context) {
    final maxY = slices.fold<double>(0, (m, s) => s.value > m ? s.value : m);
    final top = maxY <= 0 ? 1.0 : maxY * 1.15;

    return BarChart(
      BarChartData(
        maxY: top,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final s = slices[group.x.toInt()];
              return BarTooltipItem(
                '${s.label}\n${ProductionChartPanel._fmt(s.value)} $unitHint',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, meta) => Text(
                ProductionChartPanel._fmt(v),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= slices.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    ProductionChartPanel._short(slices[i].label),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < slices.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: slices[i].value,
                  color: slices[i].color,
                  width: slices.length <= 4 ? 22 : 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HorizontalBarChart extends StatelessWidget {
  const _HorizontalBarChart({required this.slices, required this.unitHint});

  final List<_ChartSlice> slices;
  final String unitHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxV = slices.fold<double>(0, (m, s) => s.value > m ? s.value : m);
    final top = maxV <= 0 ? 1.0 : maxV;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: slices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final s = slices[i];
        final ratio = (s.value / top).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ProductionChartPanel._short(s.label),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${ProductionChartPanel._fmt(s.value)} $unitHint',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: AppRadii.xs,
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                backgroundColor: s.color.withValues(alpha: 0.15),
                color: s.color,
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<ProductionChartOptions?> showProductionChartSettingsSheet(
  BuildContext context, {
  required ProductionChartOptions initial,
  required bool forVerim,
}) {
  final sheetTheme = SJModal.sheetThemeOf(context);
  return showModalBottomSheet<ProductionChartOptions>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: SJModal.sheetSurface,
    builder: (ctx) => Theme(
      data: sheetTheme,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          MediaQuery.paddingOf(ctx).bottom + AppSpacing.md,
        ),
        child: _ChartSettingsSheet(initial: initial, forVerim: forVerim),
      ),
    ),
  );
}

class _ChartSettingsSheet extends StatefulWidget {
  const _ChartSettingsSheet({
    required this.initial,
    required this.forVerim,
  });

  final ProductionChartOptions initial;
  final bool forVerim;

  @override
  State<_ChartSettingsSheet> createState() => _ChartSettingsSheetState();
}

class _ChartSettingsSheetState extends State<_ChartSettingsSheet> {
  late ProductionChartOptions _options = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Grafik ayarları',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Son seçimler hatırlanır.',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Grafik türü', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final kind in ProductionChartKind.values)
                FilterChip(
                  label: Text(kind.label),
                  selected: (widget.forVerim
                          ? _options.verimKind
                          : _options.imalatKind) ==
                      kind,
                  onSelected: (_) => setState(() {
                    _options = widget.forVerim
                        ? _options.copyWith(verimKind: kind)
                        : _options.copyWith(imalatKind: kind);
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Veri', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (widget.forVerim)
                for (final m in VerimChartMetric.values)
                  FilterChip(
                    label: Text(m.label),
                    selected: _options.verimMetric == m,
                    onSelected: (_) => setState(
                      () => _options = _options.copyWith(verimMetric: m),
                    ),
                  )
              else
                for (final m in ImalatChartMetric.values)
                  FilterChip(
                    label: Text(m.label),
                    selected: _options.imalatMetric == m,
                    onSelected: (_) => setState(
                      () => _options = _options.copyWith(imalatMetric: m),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SJButton(
            label: 'Uygula',
            expanded: true,
            onPressed: () => Navigator.pop(context, _options),
          ),
        ],
      ),
    );
  }
}
