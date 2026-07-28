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

/// Ekip bazlı imalat icmali — plan / gerçekleşen / kalan + iş gücü + verim katsayıları.
class _TeamImalatSummary {
  const _TeamImalatSummary({
    required this.teamName,
    required this.jobCount,
    required this.lines,
    required this.workDayCount,
    required this.ustaTotal,
    required this.cirakTotal,
  });

  final String teamName;
  final int jobCount;
  final List<_UnitLine> lines;

  /// Benzersiz çalışma günü sayısı.
  final int workDayCount;

  /// Toplam usta ataması (tüm günlük kayıtlar).
  final double ustaTotal;

  /// Toplam düz işçi / çırak ataması.
  final double cirakTotal;

  /// Toplam adam.gün (usta + çırak atamaları).
  double get adamGunTotal => ustaTotal + cirakTotal;

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
          // unit -> date -> labor / qty
          final daily = <String, Map<String, ({double labor, double qty})>>{};
          final workDays = <String>{};
          var usta = 0.0;
          var cirak = 0.0;
          for (final p in jobs) {
            final unit = p.unit.trim().isEmpty ? 'adet' : p.unit.trim();
            var jobLabor = 0.0;
            final unitDaily = daily.putIfAbsent(unit, () => {});
            for (final e in p.dailyEntries) {
              final date = e.date.trim();
              if (date.isNotEmpty) workDays.add(date);
              usta += e.ustaCount;
              cirak += e.duzIsciCount;
              jobLabor += e.laborDays;
              final prevDay = unitDaily[date];
              unitDaily[date] = (
                labor: (prevDay?.labor ?? 0) + e.laborDays,
                qty: (prevDay?.qty ?? 0) + e.completedQty,
              );
            }
            final prev = byUnit[unit];
            byUnit[unit] = _UnitLine(
              unit: unit,
              planned: (prev?.planned ?? 0) + p.plannedQty,
              completed: (prev?.completed ?? 0) + p.completedQty,
              remaining: (prev?.remaining ?? 0) + p.remainingQty,
              laborAdamGun: (prev?.laborAdamGun ?? 0) + jobLabor,
              dailyAsRates: const [],
            );
          }

          final lines = <_UnitLine>[];
          for (final entry in byUnit.entries) {
            final unit = entry.key;
            final line = entry.value;
            final dayMap = daily[unit] ?? {};
            final sortedDates = dayMap.keys.toList()
              ..sort((a, b) {
                try {
                  return PuantajDate.parse(a).compareTo(PuantajDate.parse(b));
                } catch (_) {
                  return a.compareTo(b);
                }
              });
            final rates = <_AsRatePoint>[
              for (final d in sortedDates)
                if (dayMap[d]!.labor > 0 && dayMap[d]!.qty > 0)
                  _AsRatePoint(
                    date: d,
                    rate: dayMap[d]!.qty /
                        (dayMap[d]!.labor * _UnitLine.hoursPerDay),
                  ),
            ];
            lines.add(
              _UnitLine(
                unit: line.unit,
                planned: line.planned,
                completed: line.completed,
                remaining: line.remaining,
                laborAdamGun: line.laborAdamGun,
                dailyAsRates: rates,
              ),
            );
          }
          lines.sort((a, b) => a.unit.compareTo(b.unit));
          return _TeamImalatSummary(
            teamName: team,
            jobCount: jobs.length,
            lines: lines,
            workDayCount: workDays.length,
            ustaTotal: usta,
            cirakTotal: cirak,
          );
        }(),
    ];
  }
}

class _AsRatePoint {
  const _AsRatePoint({required this.date, required this.rate});

  final String date;
  final double rate;
}

class _UnitLine {
  const _UnitLine({
    required this.unit,
    required this.planned,
    required this.completed,
    required this.remaining,
    this.laborAdamGun = 0,
    this.dailyAsRates = const [],
  });

  final String unit;
  final double planned;
  final double completed;
  final double remaining;

  /// Bu birimdeki işlere yazılan toplam adam-gün (usta + çırak).
  final double laborAdamGun;

  /// Günlük adam-saat verim serisi (birim / as).
  final List<_AsRatePoint> dailyAsRates;

  /// Standart çalışma günü (yevmiye ile aynı).
  static const hoursPerDay = 8.0;

  /// Gerçekleşen miktar / adam-gün — 1 adam-gün başına üretim.
  double? get ratePerAdamGun {
    if (laborAdamGun <= 0 || completed <= 0) return null;
    return completed / laborAdamGun;
  }

  /// Adam-gün katsayısı / 8 — 1 adam-saat başına üretim.
  double? get ratePerAdamSaat {
    final perDay = ratePerAdamGun;
    if (perDay == null) return null;
    return perDay / hoursPerDay;
  }

  double? get averageDailyAsRate {
    if (dailyAsRates.isEmpty) return null;
    final sum = dailyAsRates.fold<double>(0, (s, p) => s + p.rate);
    return sum / dailyAsRates.length;
  }
}

class _TeamImalatCard extends StatelessWidget {
  const _TeamImalatCard({required this.summary});

  final _TeamImalatSummary summary;

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    if (v.abs() >= 10) return v.toStringAsFixed(1);
    if (v.abs() >= 1) return v.toStringAsFixed(2);
    return v.toStringAsFixed(3);
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
          const SizedBox(height: 4),
          Text(
            '${summary.workDayCount} gün · '
            '${_fmt(summary.ustaTotal)} usta · '
            '${_fmt(summary.cirakTotal)} çırak · '
            '${_fmt(summary.adamGunTotal)} adam-gün',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
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
            if (line.ratePerAdamGun != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _QtyCell(
                      label: 'Adam-gün',
                      value:
                          '${_fmt(line.ratePerAdamGun!)} ${line.unit}/ag',
                      valueColor: AppColors.info,
                    ),
                  ),
                  Expanded(
                    child: _QtyCell(
                      label: 'Adam-saat',
                      value:
                          '${_fmt(line.ratePerAdamSaat!)} ${line.unit}/as',
                      valueColor: AppColors.info,
                    ),
                  ),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
            if (line.dailyAsRates.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _AdamSaatEfficiencyChart(
                points: line.dailyAsRates,
                unit: line.unit,
                overallRate: line.ratePerAdamSaat,
              ),
            ],
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

/// Günlük adam-saat verim çubuk grafiği — zaman filtresi + dikey tarih etiketleri.
class _AdamSaatEfficiencyChart extends StatefulWidget {
  const _AdamSaatEfficiencyChart({
    required this.points,
    required this.unit,
    this.overallRate,
  });

  final List<_AsRatePoint> points;
  final String unit;
  final double? overallRate;

  @override
  State<_AdamSaatEfficiencyChart> createState() =>
      _AdamSaatEfficiencyChartState();
}

enum _AsRange {
  week(7, 'Haftalık'),
  month(30, 'Aylık'),
  m3(90, '3 Aylık'),
  m6(180, '6 Aylık'),
  m9(270, '9 Aylık'),
  year(365, 'Yıllık');

  const _AsRange(this.days, this.label);
  final int days;
  final String label;
}

class _AdamSaatEfficiencyChartState extends State<_AdamSaatEfficiencyChart> {
  _AsRange _range = _AsRange.month;

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    if (v.abs() >= 10) return v.toStringAsFixed(1);
    if (v.abs() >= 1) return v.toStringAsFixed(2);
    return v.toStringAsFixed(3);
  }

  List<_AsRatePoint> _filtered() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: _range.days - 1));
    final out = <_AsRatePoint>[];
    for (final p in widget.points) {
      try {
        final d = PuantajDate.parse(p.date);
        final day = DateTime(d.year, d.month, d.day);
        if (!day.isBefore(start)) out.add(p);
      } catch (_) {
        // Geçersiz tarih — atla.
      }
    }
    return out;
  }

  String _shortDate(String date) {
    // dd.MM
    if (date.length >= 5) return date.substring(0, 5);
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = _filtered();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: AppColors.electricBlue.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Verim · ${widget.unit}/as',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.electricBlue,
                  ),
                ),
              ),
              if (points.isNotEmpty)
                Builder(
                  builder: (context) {
                    final avg =
                        points.fold<double>(0, (s, p) => s + p.rate) /
                            points.length;
                    final latest = points.last.rate;
                    final vsAvg = avg <= 0 ? 0.0 : (latest - avg) / avg;
                    final verdictColor = vsAvg >= 0.05
                        ? AppColors.success
                        : vsAvg <= -0.05
                            ? AppColors.critical
                            : AppColors.warning;
                    final verdictLabel = vsAvg >= 0.05
                        ? 'Ortalamanın üstünde'
                        : vsAvg <= -0.05
                            ? 'Ortalamanın altında'
                            : 'Ortalama civarı';
                    return Text(
                      verdictLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: verdictColor,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final r in _AsRange.values) ...[
                  if (r != _AsRange.values.first)
                    const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(r.label),
                    selected: _range == r,
                    visualDensity: VisualDensity.compact,
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      fontWeight:
                          _range == r ? FontWeight.w700 : FontWeight.w500,
                      color: _range == r
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    selectedColor: AppColors.electricBlue,
                    backgroundColor:
                        theme.colorScheme.surface.withValues(alpha: 0.8),
                    side: BorderSide(
                      color: _range == r
                          ? AppColors.electricBlue
                          : theme.dividerColor,
                    ),
                    onSelected: (_) => setState(() => _range = r),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (points.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'Seçilen dönemde verim kaydı yok.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            Builder(
              builder: (context) {
                final avg = points.fold<double>(0, (s, p) => s + p.rate) /
                    points.length;
                final latest = points.last.rate;
                return Text(
                  'Ort ${_fmt(avg)} · Son ${_fmt(latest)}'
                  '${widget.overallRate != null ? ' · Genel ${_fmt(widget.overallRate!)}' : ''}'
                  ' ${widget.unit}/as',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final avg = points.fold<double>(0, (s, p) => s + p.rate) /
                    points.length;
                final minBarSlot = 22.0;
                final chartWidth = (points.length * minBarSlot)
                    .clamp(constraints.maxWidth, double.infinity);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth.toDouble(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 96,
                          child: CustomPaint(
                            painter: _AdamSaatBarPainter(
                              points: points,
                              average: avg,
                              barAbove: AppColors.success,
                              barNear: AppColors.info,
                              barBelow: AppColors.critical,
                              averageColor: AppColors.electricBlue,
                              axisColor: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.35),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 56,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final p in points)
                                Expanded(
                                  child: Center(
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: Text(
                                        _shortDate(p.date),
                                        style:
                                            theme.textTheme.labelSmall?.copyWith(
                                          fontSize: 9,
                                          height: 1,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        softWrap: false,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _AdamSaatBarPainter extends CustomPainter {
  _AdamSaatBarPainter({
    required this.points,
    required this.average,
    required this.barAbove,
    required this.barNear,
    required this.barBelow,
    required this.averageColor,
    required this.axisColor,
  });

  final List<_AsRatePoint> points;
  final double average;
  final Color barAbove;
  final Color barNear;
  final Color barBelow;
  final Color averageColor;
  final Color axisColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxRate = points.fold<double>(
      average,
      (m, p) => p.rate > m ? p.rate : m,
    );
    final top = maxRate <= 0 ? 1.0 : maxRate * 1.15;
    const padL = 2.0;
    const padR = 2.0;
    const padT = 6.0;
    const padB = 4.0;
    final chartW = size.width - padL - padR;
    final chartH = size.height - padT - padB;
    final n = points.length;
    final gap = n <= 1 ? 0.0 : chartW * 0.06 / n;
    final barW = n <= 1
        ? chartW * 0.35
        : ((chartW - gap * (n - 1)) / n).clamp(6.0, 36.0);
    final totalBars = n * barW + (n - 1) * gap;
    final startX = padL + (chartW - totalBars) / 2;

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(padL, padT + chartH),
      Offset(size.width - padR, padT + chartH),
      axisPaint,
    );

    if (average > 0) {
      final ay = padT + chartH * (1 - (average / top).clamp(0.0, 1.0));
      final avgPaint = Paint()
        ..color = averageColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      const dash = 4.0;
      var x = padL;
      while (x < size.width - padR) {
        canvas.drawLine(
          Offset(x, ay),
          Offset((x + dash).clamp(0, size.width - padR), ay),
          avgPaint,
        );
        x += dash * 2;
      }
    }

    for (var i = 0; i < n; i++) {
      final rate = points[i].rate;
      final h = chartH * (rate / top).clamp(0.0, 1.0);
      final left = startX + i * (barW + gap);
      final topY = padT + chartH - h;
      // Mum gövdesi
      final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, topY, barW, h < 3 ? 3 : h),
        const Radius.circular(2),
      );
      final delta = average <= 0 ? 0.0 : (rate - average) / average;
      final color = delta >= 0.05
          ? barAbove
          : delta <= -0.05
              ? barBelow
              : barNear;
      canvas.drawRRect(body, Paint()..color = color.withValues(alpha: 0.9));
      // Fitil (mum üst/alt çizgisi)
      final midX = left + barW / 2;
      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(midX, topY - 3),
        Offset(midX, topY + (h < 3 ? 3 : h) + 2),
        wickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AdamSaatBarPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.average != average ||
        oldDelegate.axisColor != axisColor;
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
  });

  final String label;
  final String value;
  final Color color;

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
            ],
          ),
        ],
      ),
    );
  }
}
