import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/domain/entities/project.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/features/field_count/field_count_calculator.dart';
import 'package:santijet_demir/core/widgets/diameter_status_cells.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/shell/widgets/home_welcome_card.dart';

/// Referans ana sayfa — açık zemin, sabit yerleşim.
class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  static const page = Color(0xFFF3F6FB);
  static const ink = Color(0xFF0F2744);
  static const muted = Color(0xFF8B97A8);
  static const blue = Color(0xFF2563EB);
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFEF4444);

  static Color diameterDot(int diameter) {
    return switch (diameter) {
      8 => const Color(0xFF3B82F6),
      10 => const Color(0xFFA855F7),
      12 => const Color(0xFFEF4444),
      14 => const Color(0xFFF97316),
      16 => const Color(0xFFEAB308),
      20 => const Color(0xFF8B5CF6),
      22 => const Color(0xFFDC2626),
      28 => const Color(0xFF0EA5E9),
      _ => blue,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasProject = ref.watch(activeProjectProvider) != null;
    final rows = ref.watch(reconciliationRowsProvider);
    final totals = computeReconciliationTotals(rows);
    final counts = ref.watch(fieldCountsProvider);
    final latest = counts.isEmpty ? null : counts.first;
    final snapshot = _HomeSnapshot.from(totals: totals, rows: rows, latest: latest);

    return ColoredBox(
      color: page,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DemirBrandHeader(showWordmark: true),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: HomeWelcomeCard(),
          ),
          if (!hasProject)
            SizedBox(
              height: 380,
              child: ModuleEmptyState(
                type: EmptyStateType.noProject,
                actionLabel: 'Proje Seç',
                onAction: () => context.push(AppRoutes.projects),
              ),
            )
          else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScheduleCard(
                    consumed: snapshot.consumed,
                    survey: snapshot.survey,
                    materialPercent: snapshot.consumedPercent,
                  ),
                  const SizedBox(height: 10),
                  _KpiRow(snapshot: snapshot),
                  const SizedBox(height: 10),
                  _DiameterCard(shares: snapshot.diameters),
                ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSnapshot {
  const _HomeSnapshot({
    required this.survey,
    required this.delivered,
    required this.consumed,
    required this.stock,
    required this.plannedUsage,
    required this.diameters,
  });

  final double survey;
  final double delivered;
  final double consumed;
  final double stock;
  final double plannedUsage;
  final List<_DiameterShare> diameters;

  double get gelenPercent => _ratio(delivered, survey);
  double get consumedPercent => _ratio(consumed, survey);
  double get stockPercent => _ratio(stock, survey);
  double get usagePercent => _ratio(consumed, plannedUsage);

  static _HomeSnapshot from({
    required ReconciliationTotals totals,
    required List<ReconciliationRow> rows,
    required FieldCountRecord? latest,
  }) {
    final consumed = totals.actualUsage < 0 ? 0.0 : totals.actualUsage;
    final hasUsage = consumed > 0.05;
    final shares = [
      for (final row in rows)
        _DiameterShare(
          diameter: row.diameter,
          percent: _ratio(hasUsage ? row.used : row.plannedUsage, row.survey),
        ),
    ];
    return _HomeSnapshot(
      survey: totals.survey,
      delivered: totals.delivered,
      consumed: consumed,
      stock: latest == null
          ? (totals.delivered - consumed).clamp(0, double.infinity).toDouble()
          : totals.fieldCount.clamp(0, double.infinity).toDouble(),
      plannedUsage: totals.plannedUsage,
      diameters: shares,
    );
  }
}

class _DiameterShare {
  const _DiameterShare({required this.diameter, required this.percent});

  final int diameter;
  final double percent;
}

double _ratio(double part, double whole) {
  if (whole <= 0 || part <= 0) return 0;
  return part / whole * 100;
}

String _pct(double value) => '%${value.round()}';

String _tons(double value) => '${AppFormat.tonnage(value)}';

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F2744),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RhythmTons extends StatelessWidget {
  const _RhythmTons({
    required this.consumed,
    required this.survey,
    required this.percent,
  });

  final double consumed;
  final double survey;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            '${_tons(consumed)} / ${_tons(survey)}',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _pct(percent),
          style: GoogleFonts.inter(
            color: const Color(0xFF60A5FA),
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _ScheduleCard extends ConsumerWidget {
  const _ScheduleCard({
    required this.consumed,
    required this.survey,
    required this.materialPercent,
  });

  final double consumed;
  final double survey;
  final double materialPercent;

  static const _amber = Color(0xFFD97706);
  static const _tolerance = 5.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    if (project == null) return const SizedBox.shrink();
    final canEdit = ref.watch(canEditActiveProjectProvider);
    final start = project.startDate;
    final end = project.endDate;

    if (start == null || end == null || !end.isAfter(start)) {
      return _RhythmShell(
        onTap: canEdit ? () => _pickDates(context, ref, project) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _RhythmTitle(),
            const SizedBox(height: 12),
            _RhythmTons(
              consumed: consumed,
              survey: survey,
              percent: materialPercent,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 18, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    canEdit
                        ? 'Takvim yok. Başlangıç ve bitiş tarihini seçin.'
                        : 'Tarih bilgisi henüz girilmemiş',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFCBD5E1),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
                if (canEdit)
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
              ],
            ),
          ],
        ),
      );
    }

    final today = DateUtils.dateOnly(DateTime.now());
    final totalDays = end.difference(start).inDays;
    final elapsedDays = today.difference(start).inDays.clamp(0, totalDays);
    final remainingDays = end.difference(today).inDays;
    final timePercent = totalDays > 0 ? elapsedDays / totalDays * 100 : 0.0;
    final gap = materialPercent - timePercent;

    final (statusText, statusColor, statusIcon) = gap < -_tolerance
        ? ('Geride', _amber, Icons.trending_down_rounded)
        : gap > _tolerance
            ? ('İleride', HomeDashboard.blue, Icons.trending_up_rounded)
            : ('Plana uygun', HomeDashboard.green, Icons.check_circle_rounded);

    final dateFormat = DateFormat('dd.MM.yyyy', 'tr_TR');
    final remainingText = remainingDays > 0
        ? '$remainingDays gün kaldı'
        : remainingDays == 0
            ? 'Bugün bitiyor'
            : '${-remainingDays} gün gecikti';
    final overdue = remainingDays < 0;

    final gapPoints = gap.abs().round();
    final interpretation = gap < -_tolerance
        ? 'Montaj sürenin $gapPoints puan gerisinde.'
        : gap > _tolerance
            ? 'Montaj sürenin $gapPoints puan önünde.'
            : 'Süre ve montaj dengeli ilerliyor.';

    final todayFraction = totalDays > 0 ? elapsedDays / totalDays : 0.0;

    return _RhythmShell(
      onTap: canEdit ? () => _pickDates(context, ref, project) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: _RhythmTitle()),
              _ScheduleDarkStatus(
                label: statusText,
                color: statusColor,
                icon: statusIcon,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RhythmTons(
            consumed: consumed,
            survey: survey,
            percent: materialPercent,
          ),
          const SizedBox(height: 14),
          _RhythmChart(
                  timePercent: timePercent,
                  materialPercent: materialPercent,
                  elapsedDays: elapsedDays,
                  totalDays: totalDays,
                ),
                const SizedBox(height: 14),
                Text(
                  interpretation,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      overdue ? Icons.warning_amber_rounded : Icons.timer_outlined,
                      size: 15,
                      color: overdue
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      remainingText,
                      style: GoogleFonts.inter(
                        color: overdue
                            ? const Color(0xFFFCA5A5)
                            : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (canEdit)
                      const Icon(
                        Icons.edit_calendar_outlined,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
          const SizedBox(height: 12),
          _TodayAxis(
            start: dateFormat.format(start),
            end: dateFormat.format(end),
            fraction: todayFraction,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDates(BuildContext context, WidgetRef ref, Project project) async {
    final now = DateTime.now();
    final start = project.startDate;
    final end = project.endDate;
    final range = await showDateRangePicker(
      context: context,
      locale: const Locale('tr', 'TR'),
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      initialDateRange: start != null && end != null && end.isAfter(start)
          ? DateTimeRange(start: start, end: end)
          : null,
      helpText: 'Proje başlangıç ve bitiş tarihi',
      saveText: 'Kaydet',
      cancelText: 'İptal',
      confirmText: 'Tamam',
      fieldStartLabelText: 'Başlangıç',
      fieldEndLabelText: 'Bitiş',
    );
    if (range == null) return;
    try {
      await ref.read(projectsControllerProvider).updateProject(
            project.copyWith(startDate: range.start, endDate: range.end),
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Proje tarihleri kaydedilemedi: $e')),
      );
    }
  }
}

class _RhythmShell extends StatelessWidget {
  const _RhythmShell({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2744), Color(0xFF071526)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2B0F2744),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RhythmTitle extends StatelessWidget {
  const _RhythmTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _RhythmMark(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Proje ritmi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayAxis extends StatelessWidget {
  const _TodayAxis({
    required this.start,
    required this.end,
    required this.fraction,
  });

  final String start;
  final String end;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final marker = width * fraction.clamp(0.0, 1.0);
        const labelWidth = 44.0;
        final maxLeft = width > labelWidth ? width - labelWidth : 0.0;
        final labelLeft = (marker - labelWidth / 2).clamp(0.0, maxLeft);
        final dotLeft = (marker - 4).clamp(0.0, (width - 8).clamp(0.0, width));
        return Column(
          children: [
            SizedBox(
              height: 22,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 3,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Positioned(
                    left: labelLeft,
                    top: 0,
                    width: labelWidth,
                    child: Text(
                      'BUGÜN',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF60A5FA),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Positioned(
                    left: dotLeft,
                    bottom: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF60A5FA),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0F2744), width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ScheduleDatePoint(
                  label: 'BAŞLANGIÇ',
                  value: start,
                  alignment: CrossAxisAlignment.start,
                ),
                const Spacer(),
                _ScheduleDatePoint(
                  label: 'BİTİŞ',
                  value: end,
                  alignment: CrossAxisAlignment.end,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _RhythmMark extends StatelessWidget {
  const _RhythmMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 28,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0x1AFFFFFF),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(5, 7, 5, 7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RhythmMarkBar(fraction: 0.72, color: Color(0xFFCBD5E1)),
              _RhythmMarkBar(fraction: 0.46, color: Color(0xFF60A5FA)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RhythmMarkBar extends StatelessWidget {
  const _RhythmMarkBar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 4,
        width: double.infinity,
        child: LinearProgressIndicator(
          value: fraction,
          minHeight: 4,
          backgroundColor: const Color(0x33FFFFFF),
          color: color,
        ),
      ),
    );
  }
}

class _RhythmChart extends StatelessWidget {
  const _RhythmChart({
    required this.timePercent,
    required this.materialPercent,
    required this.elapsedDays,
    required this.totalDays,
  });

  final double timePercent;
  final double materialPercent;
  final int elapsedDays;
  final int totalDays;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RhythmSeries(
          label: 'Süre',
          percent: timePercent,
          color: const Color(0xFFCBD5E1),
        ),
        const SizedBox(height: 10),
        _RhythmSeries(
          label: 'Montaj',
          percent: materialPercent,
          color: const Color(0xFF60A5FA),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 58, right: 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _RhythmScale(),
              const SizedBox(height: 2),
              Text(
                '$elapsedDays / $totalDays gün',
                style: GoogleFonts.inter(
                  color: const Color(0xFF70849A),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RhythmSeries extends StatelessWidget {
  const _RhythmSeries({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = (percent / 100).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFFB8C6D8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 22,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                const Positioned.fill(child: _RhythmGrid()),
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 7,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0x14FFFFFF),
                      borderRadius: BorderRadius.all(Radius.circular(99)),
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: constraints.maxWidth * fraction,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 46,
          child: Text(
            _pct(percent),
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _RhythmGrid extends StatelessWidget {
  const _RhythmGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.white.withValues(alpha: i == 0 ? 0.18 : 0.10),
                  ),
                  right: i == 3
                      ? BorderSide(
                          color: Colors.white.withValues(alpha: 0.18),
                        )
                      : BorderSide.none,
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );
  }
}

class _RhythmScale extends StatelessWidget {
  const _RhythmScale();

  @override
  Widget build(BuildContext context) {
    const marks = [0, 25, 50, 75, 100];
    return SizedBox(
      height: 14,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final mark in marks)
                Positioned(
                  left: (width * mark / 100 - (mark == 0 ? 0 : 10))
                      .clamp(0.0, (width - 16).clamp(0.0, width)),
                  child: Text(
                    '$mark',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF70849A),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ScheduleDarkStatus extends StatelessWidget {
  const _ScheduleDarkStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleDatePoint extends StatelessWidget {
  const _ScheduleDatePoint({
    required this.label,
    required this.value,
    required this.alignment,
  });

  final String label;
  final String value;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF70849A),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// Kept for backwards-compatible card variants.
// ignore: unused_element
class _ScheduleStatusPill extends StatelessWidget {
  const _ScheduleStatusPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _ScheduleDeadlineChip extends StatelessWidget {
  const _ScheduleDeadlineChip({required this.label, required this.overdue});

  final String label;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final color = overdue ? HomeDashboard.red : HomeDashboard.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: overdue ? HomeDashboard.red : HomeDashboard.muted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _ScheduleMetricTile extends StatelessWidget {
  const _ScheduleMetricTile({
    required this.label,
    required this.percent,
    required this.color,
    required this.caption,
  });

  final String label;
  final double percent;
  final Color color;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final value = (percent / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            style: GoogleFonts.inter(
              color: HomeDashboard.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _pct(percent),
            style: GoogleFonts.inter(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: const Color(0xFFE6EBF3),
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: HomeDashboard.muted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _ScheduleDualTrack extends StatelessWidget {
  const _ScheduleDualTrack({
    required this.timePercent,
    required this.materialPercent,
  });

  final double timePercent;
  final double materialPercent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Karşılaştırma',
          style: GoogleFonts.inter(
            color: HomeDashboard.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final timeX = width * (timePercent / 100).clamp(0.0, 1.0);
            final materialX = width * (materialPercent / 100).clamp(0.0, 1.0);
            return SizedBox(
              height: 36,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 14,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6EBF3),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 14,
                    width: materialX,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: HomeDashboard.blue.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (timeX - 1).clamp(0.0, width - 2),
                    top: 10,
                    child: Container(
                      width: 2,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF64748B),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _ScheduleLegendDot(color: HomeDashboard.blue, label: 'Demir'),
            const SizedBox(width: 14),
            _ScheduleLegendDot(color: const Color(0xFF64748B), label: 'Süre işareti'),
          ],
        ),
      ],
    );
  }
}

class _ScheduleLegendDot extends StatelessWidget {
  const _ScheduleLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            color: HomeDashboard.muted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _ScheduleTimeline extends StatelessWidget {
  const _ScheduleTimeline({
    required this.start,
    required this.end,
    required this.progress,
    required this.dateFormat,
  });

  final DateTime start;
  final DateTime end;
  final double progress;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final dotLeft = (constraints.maxWidth - 10) * progress.clamp(0.0, 1.0);
            return SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 4,
                    child: Container(
                      height: 2,
                      color: const Color(0xFFE6EBF3),
                    ),
                  ),
                  Positioned(
                    left: dotLeft,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: HomeDashboard.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x332563EB),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                dateFormat.format(start),
                style: GoogleFonts.inter(
                  color: HomeDashboard.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              'Bugün',
              style: GoogleFonts.inter(
                color: HomeDashboard.blue,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            Expanded(
              child: Text(
                dateFormat.format(end),
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(
                  color: HomeDashboard.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.snapshot});

  final _HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _KpiCard(
            icon: Icons.local_shipping_rounded,
            iconColor: HomeDashboard.green,
            iconBg: const Color(0xFFE7F8EE),
            label: 'Gelen Demir',
            value: _tons(snapshot.delivered),
            footer: Text(
              _pct(snapshot.gelenPercent),
              style: GoogleFonts.inter(
                color: HomeDashboard.green,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            onTap: () => context.go(AppRoutes.incomingRebar),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiCard(
            icon: Icons.person_rounded,
            iconColor: HomeDashboard.ink,
            iconBg: const Color(0xFFF1F5F9),
            label: 'Tüketilen Demir',
            value: _tons(snapshot.consumed),
            footer: Text(
              _pct(snapshot.consumedPercent),
              style: GoogleFonts.inter(
                color: HomeDashboard.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            onTap: () => context.go(AppRoutes.fieldCount),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiCard(
            icon: Icons.inventory_2_rounded,
            iconColor: HomeDashboard.blue,
            iconBg: const Color(0xFFE8F1FE),
            label: 'Mevcut Stok',
            value: _tons(snapshot.stock),
            footer: Text(
              _pct(snapshot.stockPercent),
              style: GoogleFonts.inter(
                color: HomeDashboard.blue,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            onTap: () => context.go(AppRoutes.fieldCount),
          ),
        ),
      ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.footer,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final Widget footer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: HomeDashboard.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  value,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: HomeDashboard.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}

class _DiameterCard extends StatelessWidget {
  const _DiameterCard({required this.shares});

  final List<_DiameterShare> shares;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Çap Bazlı Durum',
                style: GoogleFonts.inter(
                  color: HomeDashboard.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => context.push(AppRoutes.diameterStatus),
                child: Row(
                  children: [
                    Text(
                      'Detay',
                      style: GoogleFonts.inter(
                        color: HomeDashboard.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: HomeDashboard.blue),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (shares.isEmpty)
            Text(
              'Keşifte çap satırı yok',
              style: GoogleFonts.inter(color: HomeDashboard.muted, fontSize: 12),
            )
          else
            DiameterStatusCells(
              items: [
                for (final share in shares)
                  DiameterStatusCellItem(
                    diameter: share.diameter,
                    bottomLabel: _pct(share.percent),
                    sortValue: share.percent,
                  ),
              ],
              onDiameterTap: (diameter) =>
                  context.push(AppRoutes.diameterCalc(diameter)),
            ),
        ],
      ),
    );
  }
}
