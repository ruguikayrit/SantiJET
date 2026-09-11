import 'package:flutter/material.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/design_system/sj_status_badge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/production_triple_progress.dart';
import '../../../domain/models/team_imalat_summary.dart';

/// İmalat — yatay ekip özet kartları (Verim ekip özeti ile aynı kurgu).
class ImalatTeamSummaryStrip extends StatelessWidget {
  const ImalatTeamSummaryStrip({
    super.key,
    required this.summaries,
    required this.selectedTeam,
    required this.onTeamTap,
  });

  final List<TeamImalatSummary> summaries;
  final String? selectedTeam;
  final ValueChanged<String> onTeamTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: summaries.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final s = summaries[i];
          final selected = selectedTeam == s.groupKey;

          return SizedBox(
            width: 200,
            child: SJCard.builder(
              selected: selected,
              accentColor: selected ? AppColors.electricBlue : null,
              onTap: () => onTeamTap(s.groupKey),
              builder: (context, theme) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.teamName,
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
                      '${s.imalatCount} imalat · ${s.unit}',
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ProductionTripleProgress(
                        axes: s.axes,
                        dense: true,
                        showPctLabels: false,
                        colorMode: ProductionProgressColorMode.axisFillIntensity,
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
