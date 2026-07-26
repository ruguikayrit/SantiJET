import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/puantaj_date.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/production_provider.dart';
import '../../data/providers/verim_provider.dart';
import '../../domain/enums/attendance_status.dart';
import '../../domain/yevmiye/yevmiye_calculator.dart';

/// Ana sayfa — bugünkü puantaj, imalat ve verim özetleri.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
          child: SJEmptyState(
            title: 'Önce proje ekleyin',
            message: 'Puantaj tutmak için en az bir projeniz olmalı.',
            icon: Icons.apartment_outlined,
            actionLabel: 'Projelere Git',
            onAction: () => context.go(AppRoutes.projeler),
          ),
        ),
      );
    }

    // —— Puantaj özeti ——
    final todayRecords = attendance
        .where((a) => a.projectId == project.id && a.date == today)
        .toList();
    final enteredIds = todayRecords.map((a) => a.personId).toSet();
    final missing = people.where((p) => !enteredIds.contains(p.id)).length;
    final present = todayRecords
        .where((a) =>
            a.status == AttendanceStatus.present ||
            a.status == AttendanceStatus.half)
        .length;
    final absent = todayRecords
        .where((a) => a.status == AttendanceStatus.absent)
        .length;
    final totalYevmiye =
        todayRecords.fold<double>(0, (sum, a) => sum + a.yevmiye);
    final overtimeHours =
        todayRecords.fold<double>(0, (sum, a) => sum + a.overtimeHours);

    // —— İmalat özeti ——
    final todayImalat =
        productions.where((p) => p.date == today).toList();
    final plannedQty =
        todayImalat.fold<double>(0, (s, p) => s + p.plannedQty);
    final doneQty =
        todayImalat.fold<double>(0, (s, p) => s + p.completedQty);
    final imalatYevmiye = todayImalat.fold<double>(0, (s, p) {
      return s +
          YevmiyeCalculator.forTeam(
            projectId: project.id,
            date: p.date,
            teamName: p.teamName,
            people: people,
            attendance: attendance,
          );
    });
    final imalatPct = plannedQty <= 0
        ? (doneQty > 0 ? 100.0 : 0.0)
        : ((doneQty / plannedQty) * 100).clamp(0, 999);

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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/s_logo.png',
                      width: 36,
                      height: 36,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.apartment,
                        color: AppColors.electricBlue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppInfo.displayName,
                            style: theme.textTheme.headlineMedium,
                          ),
                          Text(
                            AppInfo.tagline,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      today,
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
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
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                label: 'Mevcut / Yarım',
                                value: '$present',
                                color: AttendanceStatus.present.color,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
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
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                label: 'Girilmedi',
                                value: '$missing',
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _MiniStat(
                                label: 'Yevmiye',
                                value: _fmt(totalYevmiye),
                                color: AppColors.electricBlue,
                                unit: 'yv',
                              ),
                            ),
                          ],
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
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SummarySection(
                    title: 'Özet İmalat',
                    icon: Icons.precision_manufacturing_outlined,
                    onTap: () => context.go(AppRoutes.imalat),
                    child: todayImalat.isEmpty
                        ? Text(
                            'Bugün için imalat kaydı yok.',
                            style: theme.textTheme.bodyMedium,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Kayıt',
                                      value: '${todayImalat.length}',
                                      color: AppColors.info,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Tamamlanma',
                                      value: '%${imalatPct.toStringAsFixed(0)}',
                                      color: imalatPct >= 80
                                          ? AppColors.success
                                          : imalatPct >= 50
                                              ? AppColors.warning
                                              : AppColors.critical,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Gerçek / Plan',
                                      value:
                                          '${_fmt(doneQty)} / ${_fmt(plannedQty)}',
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Ekip yevmiye',
                                      value: _fmt(imalatYevmiye),
                                      color: AppColors.electricBlue,
                                      unit: 'yv',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ClipRRect(
                                borderRadius: AppRadii.xs,
                                child: LinearProgressIndicator(
                                  value: (imalatPct / 100).clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor:
                                      AppColors.info.withValues(alpha: 0.15),
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SummarySection(
                    title: 'Özet Verim',
                    icon: Icons.speed_outlined,
                    onTap: () => context.go(AppRoutes.verim),
                    child: !verim.hasCloudPlan
                        ? Text(
                            'İş Programı bulut verisi yok. Verim için '
                            'buluttan plan çekilmesi gerekir.',
                            style: theme.textTheme.bodyMedium,
                          )
                        : Column(
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
    final theme = Theme.of(context);
    return SJCard(
      onTap: onTap,
      child: Column(
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
