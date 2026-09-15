import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/design_system/sj_modal.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/providers/production_chart_options_provider.dart';
import '../../../data/providers/verim_provider.dart';
import '../../../data/services/production_chart_options.dart';
import '../../../domain/catalogs/task_tags.dart';
import '../../../domain/entities/production.dart';
import 'production_summary_charts.dart';

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
    this.chartWorkGroupFilter,
    this.onChartWorkGroupFilterChanged,
  })  : productions = const [],
        _forVerim = true;

  final List<Production> productions;
  final List<VerimRow> verimRows;
  final List<TeamVerimSummary> teamSummaries;
  final bool _forVerim;

  /// Verim grafiği — İnşaat / Elektrik / Mekanik (null = tümü).
  final String? chartWorkGroupFilter;
  final ValueChanged<String?>? onChartWorkGroupFilterChanged;

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

  List<ProductionChartSlice> _imalatSlices(
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
            ProductionChartSlice(
              label: 'Bekleyen',
              value: bekleyen.toDouble(),
              color: AppColors.warning,
            ),
          if (devam > 0)
            ProductionChartSlice(
              label: 'Devam',
              value: devam.toDouble(),
              color: AppColors.info,
            ),
          if (tamam > 0)
            ProductionChartSlice(
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
            ProductionChartSlice(
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
          ProductionChartSlice(
            label: 'Plan',
            value: planned,
            color: AppColors.electricBlue.withValues(alpha: 0.55),
            secondary: actual,
          ),
          ProductionChartSlice(
            label: 'Gerçek',
            value: actual,
            color: AppColors.success,
          ),
        ];
    }
  }

  List<ProductionChartSlice> _verimSlices(ProductionChartOptions options) {
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
              ProductionChartSlice(
                label: s.teamName,
                value: s.unitEfficiency! * 100,
                color: AppColors.electricBlue,
              ),
        ];
        for (var i = 0; i < list.length; i++) {
          list[i] = ProductionChartSlice(
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
          ProductionChartSlice(
            label: 'Plan Adam-gün',
            value: planned,
            color: AppColors.electricBlue.withValues(alpha: 0.55),
          ),
          ProductionChartSlice(
            label: 'Gerçek Adam-gün',
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
            ProductionChartSlice(
              label: top[i].name,
              value: top[i].eff * 100,
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
            if (_forVerim && onChartWorkGroupFilterChanged != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _VerimChartGroupFilter(
                selected: chartWorkGroupFilter,
                onSelected: onChartWorkGroupFilterChanged!,
              ),
            ],
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
              if (kind == ProductionChartKind.horizontalBar)
                ProductionSummaryHorizontalBarChart(
                  slices: slices,
                  unitHint: unitHint,
                )
              else
                SizedBox(
                  height: 200,
                  child: ProductionSummaryPieChart(slices: slices),
                ),
            ],
          ],
        );
      },
    );
  }

}

const _chartGroupSelectedGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [AppColors.electricBlue, AppColors.electricBlueLight],
);

class _VerimChartGroupFilter extends StatelessWidget {
  const _VerimChartGroupFilter({
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        _chip(
          theme: theme,
          label: 'Tümü',
          selected: selected == null,
          onTap: () => onSelected(null),
        ),
        for (final tag in TaskTagCatalog.all)
          _chip(
            theme: theme,
            label: TaskTagCatalog.cardLabel(tag),
            selected: selected == tag,
            onTap: () => onSelected(selected == tag ? null : tag),
          ),
      ],
    );
  }

  Widget _chip({
    required ThemeData theme,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: selected ? Colors.white : AppColors.textSecondary,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: selected
              ? BoxDecoration(
                  gradient: _chartGroupSelectedGradient,
                  borderRadius: AppRadii.sm,
                  border: Border.all(
                    color: AppColors.electricBlueLight.withValues(alpha: 0.9),
                  ),
                )
              : BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppRadii.sm,
                  border: Border.all(color: AppColors.border),
                ),
          child: Text(label, style: labelStyle),
        ),
      ),
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

  ProductionChartKind get _kind =>
      widget.forVerim ? _options.verimKind : _options.imalatKind;

  String get _metricLabel => widget.forVerim
      ? _options.verimMetric.label
      : _options.imalatMetric.label;

  String get _metricHint => widget.forVerim
      ? _options.verimMetric.hint
      : _options.imalatMetric.hint;

  void _setKind(ProductionChartKind kind) {
    setState(() {
      _options = widget.forVerim
          ? _options.copyWith(verimKind: kind)
          : _options.copyWith(imalatKind: kind);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
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
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tür ve veri kaynağını seçin. Son seçimler hatırlanır.',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ChartSettingsPreviewCard(
              metricLabel: _metricLabel,
              kindLabel: _kind.label,
              kindHint: _kind.hint,
              metricHint: _metricHint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Grafik türü',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<ProductionChartKind>(
              segments: [
                for (final kind in ProductionChartKind.values)
                  ButtonSegment(
                    value: kind,
                    label: Text(kind.label),
                    icon: Icon(
                      kind == ProductionChartKind.pie
                          ? Icons.pie_chart_outline
                          : Icons.align_horizontal_left,
                      size: 18,
                    ),
                  ),
              ],
              selected: {_kind},
              onSelectionChanged: (next) {
                if (next.isEmpty) return;
                _setKind(next.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                _kind.hint,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Veri',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (widget.forVerim)
              for (final m in VerimChartMetric.values)
                _ChartMetricTile(
                  title: m.label,
                  subtitle: m.hint,
                  selected: _options.verimMetric == m,
                  onTap: () => setState(
                    () => _options = _options.copyWith(verimMetric: m),
                  ),
                )
            else
              for (final m in ImalatChartMetric.values)
                _ChartMetricTile(
                  title: m.label,
                  subtitle: m.hint,
                  selected: _options.imalatMetric == m,
                  onTap: () => setState(
                    () => _options = _options.copyWith(imalatMetric: m),
                  ),
                ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _options),
                    child: const Text('Uygula'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartSettingsPreviewCard extends StatelessWidget {
  const _ChartSettingsPreviewCard({
    required this.metricLabel,
    required this.kindLabel,
    required this.kindHint,
    required this.metricHint,
  });

  final String metricLabel;
  final String kindLabel;
  final String kindHint;
  final String metricHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.insights_outlined,
            size: 22,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Önizleme',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$metricLabel · $kindLabel',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metricHint,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                Text(
                  kindHint,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartMetricTile extends StatelessWidget {
  const _ChartMetricTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    final fill = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : theme.colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: fill,
        borderRadius: AppRadii.sm,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.sm,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadii.sm,
              border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
