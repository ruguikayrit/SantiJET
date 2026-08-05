import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
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
    final theme = Theme.of(context);
    final people = [...snapshot.people]..sort((a, b) {
      final byProfession = a.profession
          .toLowerCase()
          .compareTo(b.profession.toLowerCase());
      if (byProfession != 0) return byProfession;
      final byTeam = a.team.toLowerCase().compareTo(b.team.toLowerCase());
      if (byTeam != 0) return byTeam;
      return a.personName.toLowerCase().compareTo(b.personName.toLowerCase());
    });
    final border = theme.dividerColor.withValues(alpha: 0.55);

    return Container(
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
            padding: EdgeInsets.fromLTRB(8, 8, 8, 6),
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
                  final meslek =
                      p.profession.isNotEmpty ? p.profession : '—';
                  final ekip = p.team.isNotEmpty ? p.team : '—';
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
                            p.personName,
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
    );
  }

  Color? _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('mevcut')) return AppColors.success;
    if (s.contains('yarım')) return AppColors.warning;
    if (s.contains('izin') || s.contains('rapor') || s.contains('mazeret')) {
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
    return SizedBox(
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.electricBlueLight,
          borderRadius: AppRadii.xs,
          border: Border.all(color: AppColors.electricBlue),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.2,
              height: 1.1,
            ),
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
    final theme = Theme.of(context);
    Widget chip(String label, String value) => Expanded(
          child: Column(
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(label, style: theme.textTheme.labelSmall),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            chip('Mevcut', '${snapshot.present}'),
            chip('Yarım', '${snapshot.half}'),
            chip('İzin', '${snapshot.leave}'),
            chip('Yok', '${snapshot.absent}'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AttendanceSummaryTable(snapshot: snapshot),
      ],
    );
  }
}
