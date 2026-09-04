import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/production_triple_progress.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/verim_provider.dart';
import '../imalat/imalat_screen.dart';
import '../imalat/widgets/production_chart_panel.dart';

/// Verim — grafik + ekip özeti + ad/% listesi (detay İmalat kartında).
class VerimScreen extends ConsumerStatefulWidget {
  const VerimScreen({super.key, this.embedded = false});

  /// Hub içindeyken üst chrome (header) gösterilmez.
  final bool embedded;

  @override
  ConsumerState<VerimScreen> createState() => _VerimScreenState();
}

class _VerimScreenState extends ConsumerState<VerimScreen> {
  /// null = tüm imalatlar; dolu = ekip kartı filtresi.
  String? _teamFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = ref.watch(activeProjectProvider);
    final rows = ref.watch(verimRowsProvider);
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

    final filteredRows = _teamFilter == null
        ? rows
        : rows.where((r) => r.teamName == _teamFilter).toList();

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
              if (teamSummaries.length > 1) ...[
                Text('Ekip özeti', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                _TeamVerimSummaryStrip(
                  summaries: teamSummaries,
                  selectedTeam: _teamFilter,
                  onTeamTap: (team) {
                    setState(() {
                      _teamFilter = _teamFilter == team ? null : team;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _teamFilter == null
                          ? 'İmalatlar'
                          : 'İmalatlar · $_teamFilter',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (_teamFilter != null)
                    TextButton(
                      onPressed: () => setState(() => _teamFilter = null),
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
                for (final row in filteredRows) ...[
                  _VerimNamePercentCard(row: row),
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
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: summaries.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final s = summaries[i];
          final efficiency = s.unitEfficiency;
          final selected = selectedTeam == s.teamName;

          return SizedBox(
            width: 168,
            child: SJCard.builder(
              selected: selected,
              accentColor: selected ? AppColors.electricBlue : null,
              onTap: () => onTeamTap(s.teamName),
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
                      '${s.planLineCount} imalat',
                      style: theme.textTheme.labelSmall,
                    ),
                    const Spacer(),
                    if (efficiency != null)
                      Row(
                        children: [
                          UnitEfficiencyBadge(
                            efficiency: efficiency,
                            compact: true,
                          ),
                          const Spacer(),
                          Text(
                            '${_fmt(s.actualQty)} / ${_fmt(s.plannedQty)}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
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

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

class _VerimNamePercentCard extends ConsumerWidget {
  const _VerimNamePercentCard({required this.row});

  final VerimRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final efficiency = row.unitEfficiency;

    return SJCard.builder(
      onTap: () => openImalatProductionDetail(
        context,
        ref,
        productionId: row.production.id,
      ),
      builder: (context, theme) {
        return Row(
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
                  color: AppColors.statusInkOnCard(
                    efficiencyColorForRatio(efficiency),
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
          ],
        );
      },
    );
  }
}
