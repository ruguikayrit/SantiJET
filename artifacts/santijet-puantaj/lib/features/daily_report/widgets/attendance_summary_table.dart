import 'package:flutter/material.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/text_format.dart';
import '../../../domain/daily_report/attendance_snapshot_builder.dart';
import '../../../domain/entities/daily_report.dart';

/// Demir çap/ton tablosu düzeninde puantaj personel özeti.
class AttendanceSummaryTable extends StatelessWidget {
  const AttendanceSummaryTable({super.key, required this.snapshot});

  final DailyReportAttendanceSnapshot snapshot;

  static String _num(double v, {int maxFrac = 2}) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    final s = v.toStringAsFixed(maxFrac);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    // Kart yüzeyi her zaman cardSurface; mürekkep hibrit temalarda
    // chrome Theme'den değil kart kontrastından alınır.
    final theme = AppColors.useDarkCards
        ? SJCard.darkContrastTheme(base)
        : AppColors.isSantijetPro
            ? SJCard.lightContrastTheme(base)
            : base;
    final people = [...snapshot.people]
      ..sort(AttendanceSnapshotBuilder.compareByRoleRank);
    final border = theme.dividerColor.withValues(alpha: 0.55);

    return Theme(
      data: theme,
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.md,
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: _HeaderRow(
              cells: [
                _HeaderCell('PERSONEL', flex: 3),
                _HeaderCell('MESLEK', flex: 2),
                _HeaderCell('EKİP', flex: 2),
                _HeaderCell('DURUM', flex: 2),
                _HeaderCell('YV', flex: 1),
              ],
            ),
          ),
          if (people.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Text(
                'Bu gün için personel satırı yok',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: people.length,
                itemBuilder: (context, index) {
                  final p = people[index];
                  final meslek = p.profession.isNotEmpty
                      ? titleCaseTr(p.profession)
                      : '—';
                  final ekip =
                      p.team.isNotEmpty ? titleCaseTr(p.team) : '—';
                  final yv = p.yevmiye > 0 ? _num(p.yevmiye) : '—';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            titleCaseTr(p.personName),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            meslek,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            ekip,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            p.status,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _statusColor(p.status),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            yv,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            color: AppColors.success.withValues(alpha: 0.08),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'TOPLAM',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${people.length} kişi',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                const Expanded(flex: 2, child: SizedBox.shrink()),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${_num(snapshot.totalAdamSaat, maxFrac: 1)} as',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    _num(snapshot.totalYevmiye),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
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
  }

  Color? _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('mevcut')) return AppColors.success;
    if (s.contains('yarım')) return AppColors.warning;
    if (s.contains('izin') ||
        s.contains('rapor') ||
        s.contains('mazeret') ||
        s.contains('tatil')) {
      return AppColors.info;
    }
    if (s.contains('yok')) return AppColors.critical;
    return null;
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.cells});

  final List<_HeaderCell> cells;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(flex: cells[i].flex, child: cells[i]),
        ],
      ],
    );
  }
}

/// Demir [AppTableHeaderBadge] ile aynı dil — mavi çerçeveli başlık.
class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {this.flex = 1});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.electricBlueLight,
        borderRadius: AppRadii.xs,
        border: Border.all(color: AppColors.electricBlue),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.inkPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.15,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

/// Özet chip satırı — tablonun üstünde.
class AttendanceSummaryChips extends StatelessWidget {
  const AttendanceSummaryChips({super.key, required this.snapshot});

  final DailyReportAttendanceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    Widget chip({
      required String label,
      required String value,
      required Color accent,
    }) {
      final ink = AppColors.statusInkOnCard(accent);
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: AppRadii.sm,
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  color: ink.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            chip(
              label: 'Mevcut',
              value: '${snapshot.present}',
              accent: AppColors.success,
            ),
            chip(
              label: 'Yarım',
              value: '${snapshot.half}',
              accent: AppColors.warning,
            ),
            chip(
              label: 'İzin',
              value: '${snapshot.leave}',
              accent: AppColors.info,
            ),
            chip(
              label: 'Yok',
              value: '${snapshot.absent}',
              accent: AppColors.critical,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AttendanceSummaryTable(snapshot: snapshot),
      ],
    );
  }
}
