import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/santijet_header.dart';
import '../../core/utils/puantaj_date.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/production_provider.dart';
import '../../data/providers/verim_provider.dart';
import '../../domain/entities/production.dart';
import '../../domain/enums/attendance_status.dart';
import '../projects/widgets/project_switcher.dart';

/// Ana sayfa — bugünkü puantaj, imalat ve verim özetleri.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final people = ref.watch(activePersonnelProvider);
    final attendance = ref.watch(attendanceProvider);
    final productions = ref.watch(activeProductionProvider);
    final verim = ref.watch(verimProvider);
    final verimRows = ref.watch(verimRowsProvider);
    final todayWorkers = ref.watch(todayWorkerDaysProvider);
    final today = PuantajDate.today();

    if (project == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SantijetHeader(showWordmark: true, avatarInitial: 'SJ'),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: ProjectSwitcher(),
              ),
              Expanded(
                child: SJEmptyState(
                  title: 'Önce proje ekleyin',
                  message: 'Puantaj tutmak için en az bir projeniz olmalı.',
                  icon: Icons.apartment_outlined,
                  actionLabel: 'Projelere Git',
                  onAction: () => context.go(AppRoutes.projeler),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // —— Puantaj özeti ——
    final todayRecords = attendance
        .where((a) => a.projectId == project.id && a.date == today)
        .toList();
    final present = todayRecords
        .where((a) => a.status == AttendanceStatus.present)
        .length;
    final half = todayRecords
        .where((a) => a.status == AttendanceStatus.half)
        .length;
    // Yok = kayıtlı personel − mevcut − yarım
    final absent = (people.length - present - half).clamp(0, people.length);
    final totalYevmiye =
        todayRecords.fold<double>(0, (sum, a) => sum + a.yevmiye);
    final overtimeHours =
        todayRecords.fold<double>(0, (sum, a) => sum + a.overtimeHours);

    // —— İmalat özeti (ekip icmali) ——
    final teamSummaries = _TeamImalatSummary.fromProductions(productions);

    // —— Verim özeti ——
    double? avgEff;
    if (verimRows.isNotEmpty) {
      final ratios = <double>[
        for (final r in verimRows)
          if (r.qtyEfficiency != null)
            r.qtyEfficiency!
          else if (r.workerEfficiency != null)
            r.workerEfficiency!,
      ];
      if (ratios.isNotEmpty) {
        avgEff = ratios.reduce((a, b) => a + b) / ratios.length;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SantijetHeader(showWordmark: true, avatarInitial: 'SJ'),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: ProjectSwitcher(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SummarySection(
                    title: 'Günlük Puantaj',
                    icon: Icons.fact_check_outlined,
                    onTap: () => context.go(AppRoutes.puantaj),
                    child: Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _MiniStat(
                                    label: 'Mevcut',
                                    value: '$present',
                                    color: AttendanceStatus.present.color,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: _MiniStat(
                                    label: 'Yarım',
                                    value: '$half',
                                    color: AttendanceStatus.half.color,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: _MiniStat(
                                    label: 'Yok',
                                    value: '$absent',
                                    color: AttendanceStatus.absent.color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _MiniStat(
                              label: 'Yevmiye',
                              value: _fmt(totalYevmiye),
                              color: AppColors.electricBlue,
                              unit: 'yv',
                            ),
                            if (overtimeHours > 0) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Mesai: ${_fmt(overtimeHours)} sa',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SummarySection(
                    title: 'Özet İmalat',
                    icon: Icons.precision_manufacturing_outlined,
                    onTap: () => context.go(AppRoutes.imalat),
                    child: teamSummaries.isEmpty
                        ? Builder(
                            builder: (context) => Text(
                              'Henüz imalat yok. İmalat ekleyince ekip '
                              'icmali burada görünür.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < teamSummaries.length; i++) ...[
                                if (i > 0)
                                  const SizedBox(height: AppSpacing.sm),
                                _TeamImalatCard(summary: teamSummaries[i]),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SummarySection(
                    title: 'Özet Verim',
                    icon: Icons.speed_outlined,
                    onTap: () => context.go(AppRoutes.verim),
                    child: Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        if (!verim.hasCloudPlan) {
                          return Text(
                            'İş Programı bulut verisi yok. Verim için '
                            'buluttan plan çekilmesi gerekir.',
                            style: theme.textTheme.bodyMedium,
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _MiniStat(
                                    label: 'Bugün adam-gün',
                                    value: _fmt(todayWorkers),
                                    color: AppColors.electricBlue,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _MiniStat(
                                    label: 'Plan satırı',
                                    value: '${verimRows.length}',
                                    color: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _MiniStat(
                              label: 'Ortalama verim',
                              value: avgEff == null
                                  ? '—'
                                  : '%${(avgEff * 100).toStringAsFixed(0)}',
                              color: avgEff == null
                                  ? theme.colorScheme.onSurfaceVariant
                                  : avgEff >= 0.8
                                      ? AppColors.success
                                      : avgEff >= 0.5
                                          ? AppColors.warning
                                          : AppColors.critical,
                            ),
                            if (verim.message != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                verim.message!,
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

/// Ekip bazlı imalat icmali — plan / gerçekleşen / kalan.
class _TeamImalatSummary {
  const _TeamImalatSummary({
    required this.teamName,
    required this.jobCount,
    required this.lines,
  });

  final String teamName;
  final int jobCount;
  final List<_UnitLine> lines;

  double get plannedQty => lines.fold(0, (s, l) => s + l.planned);
  double get completedQty => lines.fold(0, (s, l) => s + l.completed);
  double get remainingQty => lines.fold(0, (s, l) => s + l.remaining);

  double get progressPct {
    if (plannedQty <= 0) return completedQty > 0 ? 100 : 0;
    return ((completedQty / plannedQty) * 100).clamp(0, 100);
  }

  static List<_TeamImalatSummary> fromProductions(List<Production> productions) {
    final byTeam = <String, List<Production>>{};
    for (final p in productions) {
      final team =
          p.teamName.trim().isEmpty ? 'Ekip seçilmedi' : p.teamName.trim();
      byTeam.putIfAbsent(team, () => []).add(p);
    }

    final teams = byTeam.keys.toList()..sort();
    return [
      for (final team in teams)
        () {
          final jobs = byTeam[team]!;
          final byUnit = <String, _UnitLine>{};
          for (final p in jobs) {
            final unit = p.unit.trim().isEmpty ? 'adet' : p.unit.trim();
            final prev = byUnit[unit];
            byUnit[unit] = _UnitLine(
              unit: unit,
              planned: (prev?.planned ?? 0) + p.plannedQty,
              completed: (prev?.completed ?? 0) + p.completedQty,
              remaining: (prev?.remaining ?? 0) + p.remainingQty,
            );
          }
          final lines = byUnit.values.toList()
            ..sort((a, b) => a.unit.compareTo(b.unit));
          return _TeamImalatSummary(
            teamName: team,
            jobCount: jobs.length,
            lines: lines,
          );
        }(),
    ];
  }
}

class _UnitLine {
  const _UnitLine({
    required this.unit,
    required this.planned,
    required this.completed,
    required this.remaining,
  });

  final String unit;
  final double planned;
  final double completed;
  final double remaining;
}

class _TeamImalatCard extends StatelessWidget {
  const _TeamImalatCard({required this.summary});

  final _TeamImalatSummary summary;

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = summary.progressPct;
    final color = pct >= 100
        ? AppColors.success
        : pct >= 50
            ? AppColors.warning
            : AppColors.critical;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.electricBlue.withValues(alpha: 0.06),
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: AppColors.electricBlue.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  summary.teamName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.electricBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${summary.jobCount} imalat · %${pct.toStringAsFixed(0)}',
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final line in summary.lines) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _QtyCell(
                    label: 'Plan',
                    value: '${_fmt(line.planned)} ${line.unit}',
                  ),
                ),
                Expanded(
                  child: _QtyCell(
                    label: 'Gerçekleşen',
                    value: '${_fmt(line.completed)} ${line.unit}',
                    valueColor: AppColors.success,
                  ),
                ),
                Expanded(
                  child: _QtyCell(
                    label: 'Kalan',
                    value: '${_fmt(line.remaining)} ${line.unit}',
                    valueColor: line.remaining > 0
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadii.xs,
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyCell extends StatelessWidget {
  const _QtyCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.title,
    required this.icon,
    required this.child,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      onTap: onTap,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              child,
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    this.unit,
  });

  final String label;
  final String value;
  final Color color;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadii.sm,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(unit!, style: theme.textTheme.labelSmall),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
