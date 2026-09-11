import 'package:flutter/material.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/design_system/sj_status_badge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/production_triple_progress.dart';
import '../../../domain/models/production_group_summary.dart';

/// Grup özeti — süre + adam-gün (metraj yok). İmalat / Verim ortak.
class ProductionGroupSummaryStrip extends StatelessWidget {
  const ProductionGroupSummaryStrip({
    super.key,
    required this.summaries,
    required this.selectedTeamKey,
    required this.onTeamTap,
    this.subtitleBuilder,
  });

  final List<ProductionGroupSummary> summaries;
  final String? selectedTeamKey;
  final ValueChanged<String> onTeamTap;
  final String Function(ProductionGroupSummary summary)? subtitleBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: summaries.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final s = summaries[i];
          final selected = selectedTeamKey == s.teamKey;
          final subtitle = subtitleBuilder?.call(s) ??
              '${s.itemCount} imalat';

          return SizedBox(
            width: 200,
            child: SJCard.builder(
              selected: selected,
              accentColor: selected ? AppColors.electricBlue : null,
              onTap: () => onTeamTap(s.teamKey),
              builder: (context, theme) {
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
                        if (s.updatedToday)
                          SJStatusBadge(
                            label: 'Bugün',
                            color: AppColors.info,
                          ),
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
                        colorMode:
                            ProductionProgressColorMode.axisFillIntensity,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
