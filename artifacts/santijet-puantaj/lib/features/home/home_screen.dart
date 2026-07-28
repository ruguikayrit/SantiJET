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
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final project = ref.read(activeProjectProvider);
      if (project == null) return;
      ref.read(productionProvider.notifier).ensureYearlyChartDemo(project.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(activeProjectIdProvider, (prev, next) {
      if (next == null || next == prev) return;
      ref.read(productionProvider.notifier).ensureYearlyChartDemo(next);
    });

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

/// Adam-saat verim grafiği — dönem filtresi, mum/çizgi, günlük–haftalık–aylık.
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

/// Grafik tipi — borsa tarzı mum veya çizgi.
enum _AsChartStyle {
  candle('Mum'),
  line('Çizgi');

  const _AsChartStyle(this.label);
  final String label;
}

/// Mum/çizgi periyodu — günlük · haftalık · aylık (OHLC agregasyon).
enum _AsInterval {
  day('1G'),
  week('1H'),
  month('1A');

  const _AsInterval(this.label);
  final String label;
}

/// Tek mum / periyot noktası (açılış–yüksek–düşük–kapanış).
class _AsOhlc {
  const _AsOhlc({
    required this.label,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  final String label;
  final double open;
  final double high;
  final double low;
  final double close;

  bool get bullish => close >= open;
}

class _AdamSaatEfficiencyChartState extends State<_AdamSaatEfficiencyChart> {
  _AsRange _range = _AsRange.year;
  _AsChartStyle _style = _AsChartStyle.candle;
  _AsInterval _interval = _AsInterval.day;

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

  /// Günlük noktaları seçilen periyotta OHLC mumlarına toplar.
  List<_AsOhlc> _aggregate(List<_AsRatePoint> points) {
    if (points.isEmpty) return const [];

    String bucketKey(DateTime d) {
      switch (_interval) {
        case _AsInterval.day:
          return '${d.year}-${d.month}-${d.day}';
        case _AsInterval.week:
          final monday = d.subtract(Duration(days: d.weekday - 1));
          return '${monday.year}-W${monday.month}-${monday.day}';
        case _AsInterval.month:
          return '${d.year}-${d.month}';
      }
    }

    String labelFor(DateTime d) {
      switch (_interval) {
        case _AsInterval.day:
          return PuantajDate.format(d).substring(0, 5); // dd.MM
        case _AsInterval.week:
          final monday = d.subtract(Duration(days: d.weekday - 1));
          return PuantajDate.format(monday).substring(0, 5);
        case _AsInterval.month:
          final mm = d.month.toString().padLeft(2, '0');
          final yy = (d.year % 100).toString().padLeft(2, '0');
          return '$mm.$yy';
      }
    }

    final buckets = <String, List<({DateTime day, double rate})>>{};
    final order = <String>[];
    for (final p in points) {
      DateTime day;
      try {
        final d = PuantajDate.parse(p.date);
        day = DateTime(d.year, d.month, d.day);
      } catch (_) {
        continue;
      }
      final key = bucketKey(day);
      if (!buckets.containsKey(key)) {
        order.add(key);
        buckets[key] = [];
      }
      buckets[key]!.add((day: day, rate: p.rate));
    }

    return [
      for (final key in order)
        () {
          final rows = buckets[key]!;
          rows.sort((a, b) => a.day.compareTo(b.day));
          final rates = rows.map((e) => e.rate).toList();
          var high = rates.first;
          var low = rates.first;
          for (final r in rates) {
            if (r > high) high = r;
            if (r < low) low = r;
          }
          return _AsOhlc(
            label: labelFor(rows.last.day),
            open: rates.first,
            high: high,
            low: low,
            close: rates.last,
          );
        }(),
    ];
  }

  Widget _chipRow({
    required ThemeData theme,
    required List<({Object value, String label})> items,
    required Object selected,
    required ValueChanged<Object> onSelect,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            ChoiceChip(
              label: Text(items[i].label),
              selected: selected == items[i].value,
              visualDensity: VisualDensity.compact,
              labelStyle: theme.textTheme.labelSmall?.copyWith(
                fontWeight: selected == items[i].value
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected == items[i].value
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
              selectedColor: AppColors.electricBlue,
              backgroundColor:
                  theme.colorScheme.surface.withValues(alpha: 0.8),
              side: BorderSide(
                color: selected == items[i].value
                    ? AppColors.electricBlue
                    : theme.dividerColor,
              ),
              onSelected: (_) => onSelect(items[i].value),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candles = _aggregate(_filtered());

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
              if (candles.isNotEmpty)
                Builder(
                  builder: (context) {
                    final avg =
                        candles.fold<double>(0, (s, c) => s + c.close) /
                            candles.length;
                    final latest = candles.last.close;
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
          _chipRow(
            theme: theme,
            selected: _range,
            onSelect: (v) => setState(() => _range = v as _AsRange),
            items: [
              for (final r in _AsRange.values) (value: r, label: r.label),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _chipRow(
                  theme: theme,
                  selected: _style,
                  onSelect: (v) =>
                      setState(() => _style = v as _AsChartStyle),
                  items: [
                    for (final s in _AsChartStyle.values)
                      (value: s, label: s.label),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chipRow(
                  theme: theme,
                  selected: _interval,
                  onSelect: (v) =>
                      setState(() => _interval = v as _AsInterval),
                  items: [
                    for (final i in _AsInterval.values)
                      (value: i, label: i.label),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (candles.isEmpty)
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
                final avg =
                    candles.fold<double>(0, (s, c) => s + c.close) /
                        candles.length;
                final latest = candles.last.close;
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
                final avg =
                    candles.fold<double>(0, (s, c) => s + c.close) /
                        candles.length;
                final minSlot = _style == _AsChartStyle.line ? 14.0 : 18.0;
                final chartWidth = (candles.length * minSlot)
                    .clamp(constraints.maxWidth, double.infinity);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth.toDouble(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 110,
                          child: CustomPaint(
                            painter: _AdamSaatChartPainter(
                              candles: candles,
                              average: avg,
                              style: _style,
                              bullish: AppColors.success,
                              bearish: AppColors.critical,
                              lineColor: AppColors.electricBlue,
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
                              for (final c in candles)
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: Text(
                                        c.label,
                                        textAlign: TextAlign.center,
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

class _AdamSaatChartPainter extends CustomPainter {
  _AdamSaatChartPainter({
    required this.candles,
    required this.average,
    required this.style,
    required this.bullish,
    required this.bearish,
    required this.lineColor,
    required this.averageColor,
    required this.axisColor,
  });

  final List<_AsOhlc> candles;
  final double average;
  final _AsChartStyle style;
  final Color bullish;
  final Color bearish;
  final Color lineColor;
  final Color averageColor;
  final Color axisColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    var maxRate = average;
    var minRate = average > 0 ? average : candles.first.low;
    for (final c in candles) {
      if (c.high > maxRate) maxRate = c.high;
      if (c.low < minRate) minRate = c.low;
    }
    final span = (maxRate - minRate).abs();
    final top = maxRate <= 0
        ? 1.0
        : maxRate + (span <= 0 ? maxRate * 0.08 : span * 0.12);
    // Alt boşluk: düşük fitiller kesilmesin.
    final floor = (minRate - (span <= 0 ? maxRate * 0.04 : span * 0.08))
        .clamp(0.0, double.infinity);

    const padL = 0.0;
    const padR = 0.0;
    const padT = 6.0;
    const padB = 4.0;
    final chartW = size.width - padL - padR;
    final chartH = size.height - padT - padB;
    final n = candles.length;
    final slotW = chartW / n;

    double mapY(double v) {
      final t = top - floor;
      if (t <= 0) return padT + chartH / 2;
      return padT + chartH * (1 - ((v - floor) / t).clamp(0.0, 1.0));
    }

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(padL, padT + chartH),
      Offset(size.width - padR, padT + chartH),
      axisPaint,
    );

    if (average > 0) {
      final ay = mapY(average);
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

    if (style == _AsChartStyle.line) {
      final path = Path();
      final fillPath = Path();
      for (var i = 0; i < n; i++) {
        final midX = padL + slotW * (i + 0.5);
        final y = mapY(candles[i].close);
        if (i == 0) {
          path.moveTo(midX, y);
          fillPath.moveTo(midX, padT + chartH);
          fillPath.lineTo(midX, y);
        } else {
          path.lineTo(midX, y);
          fillPath.lineTo(midX, y);
        }
      }
      if (n > 0) {
        final lastX = padL + slotW * (n - 0.5);
        fillPath
          ..lineTo(lastX, padT + chartH)
          ..close();
        canvas.drawPath(
          fillPath,
          Paint()
            ..color = lineColor.withValues(alpha: 0.12)
            ..style = PaintingStyle.fill,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      for (var i = 0; i < n; i++) {
        final midX = padL + slotW * (i + 0.5);
        final y = mapY(candles[i].close);
        canvas.drawCircle(
          Offset(midX, y),
          2.5,
          Paint()..color = lineColor,
        );
      }
      return;
    }

    // Mum (OHLC)
    final barW = n <= 1
        ? (chartW * 0.28).clamp(8.0, 36.0)
        : (slotW * 0.55).clamp(3.0, 28.0);
    for (var i = 0; i < n; i++) {
      final c = candles[i];
      final midX = padL + slotW * (i + 0.5);
      final yHigh = mapY(c.high);
      final yLow = mapY(c.low);
      final yOpen = mapY(c.open);
      final yClose = mapY(c.close);
      final color = c.bullish ? bullish : bearish;
      final wick = Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(midX, yHigh), Offset(midX, yLow), wick);
      final bodyTop = yOpen < yClose ? yOpen : yClose;
      final bodyBot = yOpen < yClose ? yClose : yOpen;
      final bodyH = (bodyBot - bodyTop).abs() < 2 ? 2.0 : (bodyBot - bodyTop);
      final left = midX - barW / 2;
      final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, bodyTop, barW, bodyH),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(
        body,
        Paint()
          ..color = color.withValues(alpha: 0.92)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AdamSaatChartPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.average != average ||
        oldDelegate.style != style ||
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
