import 'package:flutter/material.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/design_system/sj_status_badge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/production_triple_progress.dart';
import '../../../domain/catalogs/task_tags.dart';
import '../../../domain/models/production_group_summary.dart';

/// Grup özeti — süre + adam-gün (metraj yok). İmalat / Verim ortak.
class ProductionGroupSummaryStrip extends StatelessWidget {
  const ProductionGroupSummaryStrip({
    super.key,
    required this.summaries,
    required this.selectedTeamKey,
    required this.onTeamTap,
    this.subtitleBuilder,
    this.verimTitleOnly = false,
    this.wrapForExport = false,
  });

  final List<ProductionGroupSummary> summaries;
  final String? selectedTeamKey;
  final ValueChanged<String> onTeamTap;
  final String Function(ProductionGroupSummary summary)? subtitleBuilder;

  /// Verim sekmesi — başlıkta yalnızca verim %; süre / AG çubukları yok.
  final bool verimTitleOnly;

  /// PDF / dışa aktarma — yatay kaydırma yerine satır kırılımlı ızgarada göster.
  final bool wrapForExport;

  static String _fmtVerimPct(double? ratio) {
    if (ratio == null) return '—';
    return '%${(ratio * 100).toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    if (wrapForExport) {
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (var i = 0; i < summaries.length; i++)
            SizedBox(
              width: 200,
              height: verimTitleOnly ? 108 : 148,
              child: _summaryCard(context, summaries[i]),
            ),
        ],
      );
    }
    return SizedBox(
      height: verimTitleOnly ? 108 : 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: summaries.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          return SizedBox(
            width: 200,
            child: _summaryCard(context, summaries[i]),
          );
        },
      ),
    );
  }

  Widget _summaryCard(BuildContext context, ProductionGroupSummary s) {
    final theme = Theme.of(context);
    final selected = selectedTeamKey == s.groupKey;
    final accent = TaskTagCatalog.accentFor(s.groupKey);
    final subtitle =
        subtitleBuilder?.call(s) ?? '${s.itemCount} imalat';
    final verim = s.groupScheduleLaborEfficiency;
    final verimInk = verim == null
        ? theme.colorScheme.onSurfaceVariant
        : AppColors.statusInkOnCard(
            efficiencyColorForRatio(verim),
          );

    return SJCard.builder(
              selected: selected,
              accentColor: selected ? accent : null,
              onTap: () => onTeamTap(s.groupKey),
              builder: (context, theme) {
                if (verimTitleOnly) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _fmtVerimPct(verim),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: verimInk,
                                height: 1,
                              ),
                            ),
                          ),
                          if (s.updatedToday)
                            SJStatusBadge(
                              label: 'Bugün',
                              color: AppColors.info,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${s.title} · $subtitle',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (verim != null) ...[
                        const Spacer(),
                        UnitEfficiencyBar(
                          efficiency: verim.clamp(0.0, 2.0),
                          height: 4,
                        ),
                      ],
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (verim != null)
                          Text(
                            _fmtVerimPct(verim),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: verimInk,
                            ),
                          ),
                        if (s.updatedToday) ...[
                          const SizedBox(width: 4),
                          SJStatusBadge(
                            label: 'Bugün',
                            color: AppColors.info,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ProductionTripleProgress(
                        axes: s.axes,
                        dense: true,
                        showPctLabels: false,
                        showPctAtBarEnd: true,
                        fitStripLabelRow: true,
                        colorMode:
                            ProductionProgressColorMode.axisFillIntensity,
                      ),
                    ),
                  ],
                );
              },
            );
  }
}
