import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/production_triple_progress.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/verim_provider.dart';
import '../../domain/catalogs/production_work_group.dart';
import '../../domain/models/production_team_group.dart';
import '../imalat/widgets/production_chart_panel.dart';
import '../imalat/widgets/production_group_summary_strip.dart';
import '../../core/theme/production_list_row_colors.dart';
import 'widgets/verim_production_detail_sheet.dart';

/// Verim — grafik + ekip özeti + ad/% listesi (detay İmalat kartında).
class VerimScreen extends ConsumerStatefulWidget {
  const VerimScreen({super.key, this.embedded = false});

  /// Hub içindeyken üst chrome (header) gösterilmez.
  final bool embedded;

  @override
  ConsumerState<VerimScreen> createState() => _VerimScreenState();
}

class _VerimScreenState extends ConsumerState<VerimScreen> {
  /// null = tüm gruplar; dolu = grup özet kartı filtresi.
  String? _groupFilter;

  /// null = tüm imalatlar; dolu = ekip kartı filtresi (ekip + birim).
  String? _teamFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = ref.watch(activeProjectProvider);
    final rows = ref.watch(verimRowsProvider);
    final groupSummaries = ref.watch(groupVerimSummariesProvider);
    final teamSummaries = ref.watch(teamVerimSummariesProvider);

    if (project == null) {
      final empty = SJEmptyState(
        title: 'Önce proje ekleyin',
        message: 'Verim hesabı aktif projeye bağlıdır.',
        icon: Icons.apartment_outlined,
        actionLabel: 'Projelere Git',
        onAction: () => context.go(AppRoutes.projeler),
      );
      if (widget.embedded) return empty;
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SantijetHeader(subtitle: 'Verim'),
              Expanded(child: empty),
            ],
          ),
        ),
      );
    }

    var filteredRows = rows;
    if (_groupFilter != null) {
      filteredRows = filteredRows
          .where(
            (r) => ProductionWorkGroupCatalog.matches(
              r.production,
              _groupFilter!,
            ),
          )
          .toList();
    }
    if (_teamFilter != null) {
      filteredRows =
          filteredRows.where((r) => r.summaryGroupKey == _teamFilter).toList();
    }

    final groupFilterLabel = _groupFilter == null
        ? null
        : groupSummaries
            .where((s) => s.groupKey == _groupFilter)
            .map((s) => s.title)
            .firstOrNull;

    final teamFilterLabel = _teamFilter == null
        ? null
        : teamSummaries
            .where((s) => s.groupKey == _teamFilter)
            .map((s) => s.teamName)
            .firstOrNull;

    final listFilterActive = _groupFilter != null || _teamFilter != null;
    final listFilterLabel = _teamFilter != null
        ? (teamFilterLabel ?? _teamFilter)
        : (groupFilterLabel ?? _groupFilter);

    final body = rows.isEmpty
        ? SJEmptyState(
            title: 'Henüz imalat yok',
            message:
                'Verim, İmalat sekmesindeki plan ve günlük kayıtlardan '
                'hesaplanır.',
            icon: Icons.speed_outlined,
            actionLabel: 'İmalat',
            onAction: () => context.go(AppRoutes.imalat),
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              ProductionChartPanel.verim(
                verimRows: rows,
                teamSummaries: teamSummaries,
              ),
              const SizedBox(height: AppSpacing.md),
              if (groupSummaries.isNotEmpty) ...[
                Text('Grup özeti', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                ProductionGroupSummaryStrip(
                  summaries: groupSummaries,
                  selectedTeamKey: _groupFilter,
                  onTeamTap: (teamKey) {
                    setState(() {
                      if (_groupFilter == teamKey) {
                        _groupFilter = null;
                      } else {
                        _groupFilter = teamKey;
                        _teamFilter = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (teamSummaries.length > 1) ...[
                Text('Ekip özeti', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                _TeamVerimSummaryStrip(
                  summaries: teamSummaries,
                  selectedTeam: _teamFilter,
                  onTeamTap: (team) {
                    setState(() {
                      if (_teamFilter == team) {
                        _teamFilter = null;
                      } else {
                        _teamFilter = team;
                        _groupFilter = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      !listFilterActive
                          ? 'İmalatlar'
                          : 'İmalatlar · $listFilterLabel',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (listFilterActive)
                    TextButton(
                      onPressed: () => setState(() {
                        _groupFilter = null;
                        _teamFilter = null;
                      }),
                      child: const Text('Tümünü göster'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (filteredRows.isEmpty)
                Text(
                  'Bu ekibe atanmış imalat yok',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                for (var i = 0; i < filteredRows.length; i++) ...[
                  _VerimNamePercentCard(
                    row: filteredRows[i],
                    colorIndex: i,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          );

    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SantijetHeader(subtitle: 'Verim'),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _TeamVerimSummaryStrip extends StatelessWidget {
  const _TeamVerimSummaryStrip({
    required this.summaries,
    required this.selectedTeam,
    required this.onTeamTap,
  });

  final List<TeamVerimSummary> summaries;
  final String? selectedTeam;
  final ValueChanged<String> onTeamTap;

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
          final efficiency = s.unitEfficiency;
          final selected = selectedTeam == s.groupKey;

          return SizedBox(
            width: 200,
            child: SJCard.builder(
              selected: selected,
              accentColor: selected ? AppColors.electricBlue : null,
              onTap: () => onTeamTap(s.groupKey),
              builder: (context, theme) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.planLineCount} imalat · ${s.unit}',
                      style: theme.textTheme.labelSmall,
                    ),
                    const Spacer(),
                    if (efficiency != null)
                      UnitEfficiencyBadge(
                        efficiency: efficiency,
                        compact: true,
                      )
                    else
                      Text(
                        'Verim için plan + kayıt gerekli',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.statusInkOnCard(AppColors.warning),
                        ),
                      ),
                    if (efficiency != null) ...[
                      const SizedBox(height: 6),
                      UnitEfficiencyBar(efficiency: efficiency, height: 4),
                    ],
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

class _VerimNamePercentCard extends StatefulWidget {
  const _VerimNamePercentCard({
    required this.row,
    required this.colorIndex,
  });

  final VerimRow row;
  final int colorIndex;

  @override
  State<_VerimNamePercentCard> createState() => _VerimNamePercentCardState();
}

class _VerimNamePercentCardState extends State<_VerimNamePercentCard> {
  bool _chartsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final efficiency = row.unitEfficiency;
    final hasEntries = row.production.dailyEntries.isNotEmpty;
    final cardBg = ProductionListRowColors.at(widget.colorIndex);

    return SJCard.builder(
      backgroundColor: cardBg,
      builder: (context, theme) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: hasEntries
                  ? () => setState(() => _chartsExpanded = !_chartsExpanded)
                  : null,
              borderRadius: AppRadii.sm,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.imalatName.trim().isEmpty
                                ? 'İmalat'
                                : row.imalatName.trim(),
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.teamName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (efficiency != null)
                      Text(
                        '%${(efficiency * 100).toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusInk(
                            efficiencyColorForRatio(efficiency),
                            surface: cardBg,
                          ),
                        ),
                      )
                    else
                      Text(
                        '—',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (hasEntries) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        _chartsExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 22,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (hasEntries && _chartsExpanded) ...[
              const SizedBox(height: AppSpacing.md),
              VerimProductionCharts(
                production: row.production,
                inline: true,
              ),
            ],
          ],
        );
      },
    );
  }
}
