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
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

/// Referans ana sayfa — açık zemin, sabit yerleşim.
class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  static const headerTop = Color(0xFF2A2A2A);
  static const headerBottom = Color(0xFF000000);
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
          if (!hasProject)
            SizedBox(
              height: 420,
              child: ModuleEmptyState(
                type: EmptyStateType.noProject,
                actionLabel: 'Proje Seç',
                onAction: () => context.push(AppRoutes.projects),
              ),
            )
          else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    icon: Icons.bar_chart_rounded,
                    label: 'Proje ilerlemesi',
                  ),
                  const SizedBox(height: 8),
                  _ProgressCard(snapshot: snapshot),
                  const SizedBox(height: 10),
                  _ScheduleCard(materialPercent: snapshot.consumedPercent),
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
    required this.lastCount,
    required this.diameters,
  });

  final double survey;
  final double delivered;
  final double consumed;
  final double stock;
  final double plannedUsage;
  final DateTime? lastCount;
  final List<_DiameterShare> diameters;

  double get gelenPercent => _ratio(delivered, survey);
  double get consumedPercent => _ratio(consumed, survey);
  double get netPercent => consumedPercent;
  double get usagePercent => _ratio(consumed, plannedUsage);

  static _HomeSnapshot from({
    required ReconciliationTotals totals,
    required List<ReconciliationRow> rows,
    required FieldCountRecord? latest,
  }) {
    final consumed = totals.actualUsage;
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
      lastCount: latest?.date,
      diameters: shares,
    );
  }
}

class _DiameterShare {
  const _DiameterShare({required this.diameter, required this.percent});

  final int diameter;
  final double percent;
}

double _ratio(double part, double whole) =>
    whole > 0 ? part / whole * 100 : 0;

String _pct(double value) => '%${value.round()}';

String _tons(double value) => '${AppFormat.tonnage(value)}';

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: HomeDashboard.blue),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: HomeDashboard.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

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

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.snapshot});

  final _HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final ratio = (snapshot.netPercent / 100).clamp(0.0, 1.0);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _pct(snapshot.netPercent),
                style: GoogleFonts.inter(
                  color: HomeDashboard.blue,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _tons(snapshot.survey),
                    style: GoogleFonts.inter(
                      color: HomeDashboard.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_tons(snapshot.consumed)} / ${_tons(snapshot.survey)}',
                    style: GoogleFonts.inter(
                      color: HomeDashboard.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFFE6EBF3),
              color: HomeDashboard.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends ConsumerWidget {
  const _ScheduleCard({required this.materialPercent});

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
      return _Card(
        child: InkWell(
          onTap: canEdit ? () => _pickDates(context, ref, project) : null,
          child: Row(
            children: [
              const Icon(Icons.event_outlined, size: 20, color: HomeDashboard.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  canEdit
                      ? 'Süre takibi için proje tarihlerini ekleyin'
                      : 'Proje tarihleri girilmemiş',
                  style: GoogleFonts.inter(
                    color: HomeDashboard.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canEdit)
                const Icon(Icons.chevron_right_rounded, color: HomeDashboard.blue),
            ],
          ),
        ),
      );
    }

    final today = DateUtils.dateOnly(DateTime.now());
    final totalDays = end.difference(start).inDays;
    final elapsedDays = today.difference(start).inDays.clamp(0, totalDays);
    final remainingDays = end.difference(today).inDays;
    final timePercent = totalDays > 0 ? elapsedDays / totalDays * 100 : 0.0;
    final gap = materialPercent - timePercent;

    final (statusText, statusColor) = gap < -_tolerance
        ? ('Plana göre ${_pct(-gap)} geride', _amber)
        : gap > _tolerance
            ? ('Plana göre ${_pct(gap)} ileride', HomeDashboard.blue)
            : ('Plana uygun', HomeDashboard.green);

    final dateFormat = DateFormat('dd.MM.yyyy', 'tr_TR');
    final remainingText = remainingDays > 0
        ? '$remainingDays gün kaldı'
        : remainingDays == 0
            ? 'Bugün bitiyor'
            : '${-remainingDays} gün gecikti';

    return _Card(
      child: InkWell(
        onTap: canEdit ? () => _pickDates(context, ref, project) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Süre / İlerleme',
                  style: GoogleFonts.inter(
                    color: HomeDashboard.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  statusText,
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ScheduleBar(
              label: 'Geçen süre',
              percent: timePercent,
              color: const Color(0xFF64748B),
            ),
            const SizedBox(height: 10),
            _ScheduleBar(
              label: 'Demir ilerlemesi',
              percent: materialPercent,
              color: HomeDashboard.blue,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: HomeDashboard.muted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${dateFormat.format(start)} – ${dateFormat.format(end)}',
                    style: GoogleFonts.inter(
                      color: HomeDashboard.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  remainingText,
                  style: GoogleFonts.inter(
                    color: remainingDays < 0 ? HomeDashboard.red : HomeDashboard.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
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

class _ScheduleBar extends StatelessWidget {
  const _ScheduleBar({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: HomeDashboard.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              _pct(percent),
              style: GoogleFonts.inter(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFE6EBF3),
            color: color,
          ),
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
    final date = snapshot.lastCount == null
        ? '—'
        : DateFormat('dd.MM.yyyy').format(snapshot.lastCount!);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            iconColor: HomeDashboard.red,
            iconBg: const Color(0xFFFDECEC),
            label: 'Tüketilen Demir',
            value: _tons(snapshot.consumed),
            footer: Text(
              _pct(snapshot.consumedPercent),
              style: GoogleFonts.inter(
                color: HomeDashboard.red,
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
            footer: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Son sayım',
                        style: GoogleFonts.inter(
                          color: HomeDashboard.muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: HomeDashboard.ink,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => context.go(AppRoutes.fieldCount),
          ),
        ),
      ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
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
    );
  }
}

class _DiameterCard extends StatelessWidget {
  const _DiameterCard({required this.shares});

  final List<_DiameterShare> shares;

  @override
  Widget build(BuildContext context) {
    final highlight = _lowest(shares);
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
            LayoutBuilder(
              builder: (context, constraints) {
                final cells = [
                  for (final share in shares)
                    _DiameterCell(
                      share: share,
                      color: HomeDashboard.diameterDot(share.diameter),
                      highlighted: share.diameter == highlight,
                    ),
                ];
                if (shares.length <= 5) {
                  return Row(
                    children: [
                      for (final cell in cells) Expanded(child: cell),
                    ],
                  );
                }
                final cellWidth = constraints.maxWidth / 5;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final cell in cells)
                        SizedBox(width: cellWidth, child: cell),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  static int? _lowest(List<_DiameterShare> shares) {
    if (shares.length < 2) return null;
    final min = shares.map((s) => s.percent).reduce((a, b) => a < b ? a : b);
    final max = shares.map((s) => s.percent).reduce((a, b) => a > b ? a : b);
    if (min == max) return null;
    return shares.firstWhere((s) => s.percent == min).diameter;
  }
}

class _DiameterCell extends StatelessWidget {
  const _DiameterCell({
    required this.share,
    required this.color,
    required this.highlighted,
  });

  final _DiameterShare share;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.diameterCalc(share.diameter)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: highlighted ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Ø${share.diameter}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: HomeDashboard.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _pct(share.percent),
            style: GoogleFonts.inter(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
            ),
          ),
        ),
      ),
    );
  }
}
