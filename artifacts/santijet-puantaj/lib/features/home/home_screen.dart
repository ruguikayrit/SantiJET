import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_modal.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/santijet_header.dart';
import '../../core/utils/puantaj_date.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/production_provider.dart';
import '../../domain/entities/production.dart';
import '../../domain/entities/project.dart';
import '../../domain/enums/attendance_status.dart';
import '../projects/widgets/project_switcher.dart';
import 'home_daily_report_pdf_sheet.dart';

/// Ana sayfa — bugünkü puantaj, imalat ve verim özetleri.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _dailyReportBusy = false;

  Future<void> _exportDailyReportForDates(
    Project project,
    List<String> dates, {
    required String successLabel,
  }) async {
    if (_dailyReportBusy) return;
    setState(() => _dailyReportBusy = true);
    try {
      await exportHomeDailyReportPdf(
        ref,
        project: project,
        dates: dates,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successLabel PDF dışa aktarıldı')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF oluşturulamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _dailyReportBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final people = ref.watch(activePersonnelProvider);
    final attendance = ref.watch(attendanceProvider);
    final productions = ref.watch(activeProductionProvider);
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
                  _ImalatOverviewSection(
                    summaries: teamSummaries,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SummarySection(
                    title: 'Günlük rapor',
                    icon: Icons.edit_calendar_outlined,
                    child: _DailyReportQuickActions(
                      busy: _dailyReportBusy,
                      onDun: () => _exportDailyReportForDates(
                        project,
                        [PuantajDate.shift(today, -1)],
                        successLabel: 'Dünün raporu',
                      ),
                      onBugun: () => _exportDailyReportForDates(
                        project,
                        [today],
                        successLabel: 'Bugünün raporu',
                      ),
                      onOzel: () => showHomeDailyReportPdfSheet(
                        context,
                        ref,
                        project: project,
                      ),
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

class _ImalatOverviewSection extends StatelessWidget {
  const _ImalatOverviewSection({
    required this.summaries,
  });

  final List<_TeamImalatSummary> summaries;

  static Color _progressColor(double pct) {
    if (pct >= 100) return AppColors.success;
    if (pct >= 50) return AppColors.warning;
    return AppColors.critical;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summaries.isEmpty)
          SJCard(
            child: Builder(
              builder: (context) => Text(
                'Henüz imalat yok. İmalat ekleyince ekip icmali burada görünür.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          for (var i = 0; i < summaries.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            SJCard(
              accentColor: _progressColor(summaries[i].progressPct),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: _TeamImalatCard(summary: summaries[i]),
            ),
          ],
      ],
    );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          summary.teamName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.useDarkCards
                                ? AppColors.electricBlueLight
                                : AppColors.electricBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.workDayCount} gün · '
                    '${_fmt(summary.ustaTotal)} usta · '
                    '${_fmt(summary.cirakTotal)} çırak',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${summary.jobCount} imalat',
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(summary.adamGunTotal)} adam-gün',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
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
          if (line.ratePerAdamGun != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _QtyCell(
                    label: 'Adam-gün',
                    value: '${_fmt(line.ratePerAdamGun!)} ${line.unit}/ag',
                    valueColor: AppColors.info,
                  ),
                ),
                Expanded(
                  child: _QtyCell(
                    label: 'Adam-saat',
                    value: '${_fmt(line.ratePerAdamSaat!)} ${line.unit}/as',
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
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadii.xs,
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: AppColors.success.withValues(alpha: 0.15),
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '%${pct.toStringAsFixed(0)}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
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

/// Grafik tipi — alan / çizgi / çubuk.
enum _AsChartStyle {
  area('Alan', 'Çizgi + dolgu alanı'),
  line('Çizgi', 'Kapanış değerlerini birleştirir'),
  bar('Çubuk', 'Kapanış değerini çubuk olarak gösterir');

  const _AsChartStyle(this.label, this.subtitle);
  final String label;
  final String subtitle;

  bool get usesCompactSlots => this != bar;
}

/// Mum/çizgi periyodu — günlük · haftalık · aylık (OHLC agregasyon).
enum _AsInterval {
  day('1G', 'Günlük'),
  week('1H', 'Haftalık'),
  month('1A', 'Aylık');

  const _AsInterval(this.shortLabel, this.label);
  final String shortLabel;
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
  /// Standart: kapalı — kullanıcı gerektiğinde açar.
  bool _chartOpen = false;

  /// Standart görünüm: haftalık dönem · çubuk · 1G.
  _AsRange _range = _AsRange.week;
  _AsChartStyle _style = _AsChartStyle.bar;
  _AsInterval _interval = _AsInterval.day;

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    if (v.abs() >= 10) return v.toStringAsFixed(1);
    if (v.abs() >= 1) return v.toStringAsFixed(2);
    return v.toStringAsFixed(3);
  }

  List<_AsRatePoint> _filtered() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final DateTime start;
    final DateTime end;
    if (_range == _AsRange.week) {
      // Takvim haftası: Pazartesi → Pazar
      start = today.subtract(Duration(days: today.weekday - 1));
      end = start.add(const Duration(days: 6));
    } else {
      start = today.subtract(Duration(days: _range.days - 1));
      end = today;
    }
    final out = <_AsRatePoint>[];
    for (final p in widget.points) {
      try {
        final d = PuantajDate.parse(p.date);
        final day = DateTime(d.year, d.month, d.day);
        if (!day.isBefore(start) && !day.isAfter(end)) out.add(p);
      } catch (_) {
        // Geçersiz tarih — atla.
      }
    }
    return out;
  }

  /// Haftalık dönem + günlük periyot: Pazartesi–Pazar (7 gün, eksik günler 0).
  List<_AsOhlc> _weekSevenDaySeries(List<_AsRatePoint> points) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final ratesByDay = <String, List<double>>{};

    for (final p in points) {
      try {
        final d = PuantajDate.parse(p.date);
        final day = DateTime(d.year, d.month, d.day);
        if (day.isBefore(monday) || day.isAfter(sunday)) continue;
        final key = '${day.year}-${day.month}-${day.day}';
        ratesByDay.putIfAbsent(key, () => []).add(p.rate);
      } catch (_) {
        // Geçersiz tarih — atla.
      }
    }

    return [
      for (var i = 0; i < 7; i++)
        () {
          final d = monday.add(Duration(days: i));
          final key = '${d.year}-${d.month}-${d.day}';
          final rates = ratesByDay[key];
          final label = PuantajDate.format(d).substring(0, 5);
          if (rates == null || rates.isEmpty) {
            return _AsOhlc(
              label: label,
              open: 0,
              high: 0,
              low: 0,
              close: 0,
            );
          }
          var high = rates.first;
          var low = rates.first;
          for (final r in rates) {
            if (r > high) high = r;
            if (r < low) low = r;
          }
          return _AsOhlc(
            label: label,
            open: rates.first,
            high: high,
            low: low,
            close: rates.last,
          );
        }(),
    ];
  }

  /// Günlük noktaları seçilen periyotta OHLC mumlarına toplar.
  List<_AsOhlc> _aggregate(List<_AsRatePoint> points) {
    if (_range == _AsRange.week && _interval == _AsInterval.day) {
      return _weekSevenDaySeries(points);
    }
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

  Widget _optionSection({
    required ThemeData theme,
    required String title,
    required List<({Object value, String label, String? subtitle})> items,
    required Object selected,
    required ValueChanged<Object> onSelect,
  }) {
    final onSurface = theme.colorScheme.onSurface;
    final onVariant = theme.colorScheme.onSurfaceVariant;
    final selectedBg = AppColors.electricBlue.withValues(alpha: 0.12);
    final unselectedBg = theme.brightness == Brightness.dark
        ? theme.colorScheme.surface.withValues(alpha: 0.85)
        : AppColors.lightSurfaceHighlight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: onVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: selected == item.value ? selectedBg : unselectedBg,
              borderRadius: AppRadii.sm,
              child: InkWell(
                borderRadius: AppRadii.sm,
                onTap: () => onSelect(item.value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: selected == item.value
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected == item.value
                                    ? AppColors.electricBlue
                                    : onSurface,
                              ),
                            ),
                            if (item.subtitle != null)
                              Text(
                                item.subtitle!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: onVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        selected == item.value
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: selected == item.value
                            ? AppColors.electricBlue
                            : onVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openOptions() async {
    var draftRange = _range;
    var draftStyle = _style;
    var draftInterval = _interval;

    final applied = await SJModal.showSheet<bool>(
      context: context,
      title: 'Grafik ayarları',
      child: StatefulBuilder(
        builder: (context, setSheet) {
          final theme = Theme.of(context);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _optionSection(
                        theme: theme,
                        title: 'Dönem',
                        selected: draftRange,
                        onSelect: (v) =>
                            setSheet(() => draftRange = v as _AsRange),
                        items: [
                          for (final r in _AsRange.values)
                            (value: r, label: r.label, subtitle: null),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _optionSection(
                        theme: theme,
                        title: 'Grafik tipi',
                        selected: draftStyle,
                        onSelect: (v) =>
                            setSheet(() => draftStyle = v as _AsChartStyle),
                        items: [
                          for (final s in _AsChartStyle.values)
                            (
                              value: s,
                              label: s.label,
                              subtitle: s.subtitle,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _optionSection(
                        theme: theme,
                        title: 'Periyot',
                        selected: draftInterval,
                        onSelect: (v) => setSheet(
                          () => draftInterval = v as _AsInterval,
                        ),
                        items: [
                          for (final i in _AsInterval.values)
                            (
                              value: i,
                              label: '${i.label} (${i.shortLabel})',
                              subtitle: null,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SJButton(
                label: 'Uygula',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      ),
    );

    if (applied == true && mounted) {
      setState(() {
        _range = draftRange;
        _style = draftStyle;
        _interval = draftInterval;
      });
    }
  }

  String get _optionsSummary =>
      '${_range.label} · ${_style.label} · ${_interval.shortLabel}';

  bool _hasRate(_AsOhlc c) => c.close > 0 || c.high > 0 || c.open > 0;

  double _avgClose(List<_AsOhlc> candles) {
    final rates = [for (final c in candles) if (_hasRate(c)) c.close];
    if (rates.isEmpty) return 0;
    return rates.fold<double>(0, (s, r) => s + r) / rates.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.useDarkCards
        ? AppColors.electricBlueLight
        : AppColors.electricBlue;
    final candles = _chartOpen ? _aggregate(_filtered()) : const <_AsOhlc>[];
    final hasData = candles.any(_hasRate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadii.sm,
            onTap: () => setState(() => _chartOpen = !_chartOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    size: 18,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Grafik',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  Text(
                    _chartOpen ? 'Kapat' : 'Aç',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _chartOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_chartOpen) ...[
          const SizedBox(height: AppSpacing.xs),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.dividerColor.withValues(alpha: 0.45),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Verim · ${widget.unit}/as',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              if (hasData)
                Builder(
                  builder: (context) {
                    final avg = _avgClose(candles);
                    final latest = candles.lastWhere(_hasRate).close;
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
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: accent.withValues(alpha: 0.16),
              borderRadius: AppRadii.full,
              child: InkWell(
                borderRadius: AppRadii.full,
                onTap: _openOptions,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 16, color: accent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _optionsSummary,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!hasData)
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
                final avg = _avgClose(candles);
                final latest = candles.lastWhere(_hasRate).close;
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
            // Sabit yükseklik: kart/layout intrinsik ölçümünde grafik alanı
            // sıkışmasın; yatay kaydırma LayoutBuilder içinde kalsın.
            SizedBox(
              height: 170,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final avg = _avgClose(candles);
                  final minSlot = _style.usesCompactSlots ? 14.0 : 18.0;
                  final chartWidth = (candles.length * minSlot)
                      .clamp(constraints.maxWidth, double.infinity);
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: chartWidth.toDouble(),
                      height: constraints.maxHeight,
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
                                lineColor: accent,
                                averageColor: accent,
                                axisColor: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.35),
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
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
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
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
            ),
          ],
        ],
      ],
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

  Color _closeColor(_AsOhlc c) {
    if (average <= 0) return lineColor;
    final delta = (c.close - average) / average;
    if (delta >= 0.05) return bullish;
    if (delta <= -0.05) return bearish;
    return lineColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    var maxRate = average;
    var minRate = average > 0 ? average : candles.first.low;
    for (final c in candles) {
      if (c.high > maxRate) maxRate = c.high;
      if (c.low < minRate) minRate = c.low;
      // Çubuk/çizgi stillerinde yalnızca close kullanılır; yine de ölçek
      // OHLC aralığıyla tutarlı kalsın.
      if (c.close > maxRate) maxRate = c.close;
      if (c.close < minRate) minRate = c.close;
    }
    final span = (maxRate - minRate).abs();
    final top = maxRate <= 0
        ? 1.0
        : maxRate + (span <= 0 ? maxRate * 0.08 : span * 0.12);
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
    final barW = n <= 1
        ? (chartW * 0.28).clamp(8.0, 36.0)
        : (slotW * 0.55).clamp(3.0, 28.0);
    final baselineY = padT + chartH;

    double mapY(double v) {
      final t = top - floor;
      if (t <= 0) return padT + chartH / 2;
      return padT + chartH * (1 - ((v - floor) / t).clamp(0.0, 1.0));
    }

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(padL, baselineY),
      Offset(size.width - padR, baselineY),
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

    switch (style) {
      case _AsChartStyle.line:
      case _AsChartStyle.area:
        _paintLineSeries(
          canvas,
          mapY: mapY,
          padL: padL,
          slotW: slotW,
          baselineY: baselineY,
          fill: style == _AsChartStyle.area,
        );
      case _AsChartStyle.bar:
        _paintBars(
          canvas,
          mapY: mapY,
          padL: padL,
          slotW: slotW,
          barW: barW,
          baselineY: baselineY,
        );
    }
  }

  void _paintLineSeries(
    Canvas canvas, {
    required double Function(double) mapY,
    required double padL,
    required double slotW,
    required double baselineY,
    required bool fill,
  }) {
    final n = candles.length;
    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < n; i++) {
      final midX = padL + slotW * (i + 0.5);
      final y = mapY(candles[i].close);
      if (i == 0) {
        path.moveTo(midX, y);
        fillPath
          ..moveTo(midX, baselineY)
          ..lineTo(midX, y);
      } else {
        path.lineTo(midX, y);
        fillPath.lineTo(midX, y);
      }
    }
    if (fill && n > 0) {
      final lastX = padL + slotW * (n - 0.5);
      fillPath
        ..lineTo(lastX, baselineY)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..color = lineColor.withValues(alpha: 0.18)
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
      canvas.drawCircle(Offset(midX, y), 2.2, Paint()..color = lineColor);
    }
  }

  void _paintBars(
    Canvas canvas, {
    required double Function(double) mapY,
    required double padL,
    required double slotW,
    required double barW,
    required double baselineY,
  }) {
    for (var i = 0; i < candles.length; i++) {
      final c = candles[i];
      final midX = padL + slotW * (i + 0.5);
      final y = mapY(c.close);
      final topY = y < baselineY ? y : baselineY;
      final h = (baselineY - y).abs().clamp(2.0, double.infinity);
      final left = midX - barW / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, topY, barW, h),
          const Radius.circular(2),
        ),
        Paint()..color = _closeColor(c).withValues(alpha: 0.9),
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

class _DailyReportQuickActions extends StatelessWidget {
  const _DailyReportQuickActions({
    required this.busy,
    required this.onDun,
    required this.onBugun,
    required this.onOzel,
  });

  final bool busy;
  final VoidCallback onDun;
  final VoidCallback onBugun;
  final VoidCallback onOzel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _DailyReportPeriodButton(
                label: 'Dün',
                icon: Icons.history,
                busy: busy,
                onPressed: onDun,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _DailyReportPeriodButton(
                label: 'Bugün',
                icon: Icons.today_outlined,
                busy: busy,
                emphasized: true,
                onPressed: onBugun,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _DailyReportPeriodButton(
                label: 'Özel tarih',
                icon: Icons.calendar_month_outlined,
                busy: busy,
                onPressed: onOzel,
              ),
            ),
          ],
        ),
        if (busy) ...[
          const SizedBox(height: AppSpacing.sm),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ],
    );
  }
}

class _DailyReportPeriodButton extends StatelessWidget {
  const _DailyReportPeriodButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.busy = false,
    this.emphasized = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool busy;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = emphasized ? Colors.white : theme.colorScheme.primary;
    final bg = emphasized
        ? AppColors.electricBlue
        : AppColors.electricBlue.withValues(alpha: 0.08);
    final border = emphasized
        ? AppColors.electricBlue
        : AppColors.electricBlue.withValues(alpha: 0.35);

    return Material(
      color: bg,
      borderRadius: AppRadii.sm,
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: AppRadii.sm,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadii.sm,
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
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
