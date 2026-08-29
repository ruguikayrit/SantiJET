import 'package:flutter/material.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/text_format.dart';
import '../../../data/services/period_site_report_builder.dart';
import '../../../data/services/puantaj_report_builder.dart';
import '../../../domain/daily_report/attendance_snapshot_builder.dart';
import '../../../domain/entities/daily_report.dart';
import '../../../domain/enums/attendance_status.dart';

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
    for (final s in AttendanceStatus.values) {
      if (s.label.toLowerCase() == status.toLowerCase()) return s.color;
    }
    final s = status.toLowerCase();
    if (s.contains('girilmedi')) return AppColors.inkSecondary;
    if (s.contains('mevcut')) return AppColors.success;
    if (s.contains('yarım')) return AppColors.warning;
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
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.inkPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 9,
            letterSpacing: 0.1,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}

/// Özet chip satırı — tablonun üstünde (puantaj durumlarının tamamı).
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
      return Container(
        constraints: const BoxConstraints(minWidth: 52),
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
                fontSize: 16,
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
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.1,
                color: ink.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in AttendanceStatus.values)
                chip(
                  label: s.short,
                  value: '${snapshot.countOf(s)}',
                  accent: s.color,
                ),
              chip(
                label: 'Per',
                value: '${snapshot.people.length}',
                accent: AppColors.inkSecondary,
              ),
              chip(
                label: 'Ekip',
                value: '${snapshot.totalTeamWorkers}',
                accent: AppColors.electricBlue,
              ),
              if (snapshot.unrecorded > 0)
                chip(
                  label: '–',
                  value: '${snapshot.unrecorded}',
                  accent: AppColors.inkSecondary,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Personel',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AttendanceSummaryTable(snapshot: snapshot),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Ekip',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _TeamSummaryTable(snapshot: snapshot),
      ],
    );
  }
}

/// Firma adı + ekip adı + günlük çalışan tablosu.
class _TeamSummaryTable extends StatelessWidget {
  const _TeamSummaryTable({required this.snapshot});

  final DailyReportAttendanceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final theme = AppColors.useDarkCards
        ? SJCard.darkContrastTheme(base)
        : AppColors.isSantijetPro
            ? SJCard.lightContrastTheme(base)
            : base;
    final teams = [...snapshot.teams]
      ..sort((a, b) {
        final byCompany =
            a.company.toLowerCase().compareTo(b.company.toLowerCase());
        if (byCompany != 0) return byCompany;
        return a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase());
      });
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
                  _HeaderCell('FİRMA ADI', flex: 3),
                  _HeaderCell('EKİP ADI', flex: 3),
                  _HeaderCell('GÜNLÜK\nÇALIŞAN', flex: 2),
                ],
              ),
            ),
            if (teams.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Text(
                  'Bu gün için ekip kaydı yok',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              for (final t in teams)
                Container(
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
                          t.company.isNotEmpty
                              ? titleCaseTr(t.company)
                              : '—',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          titleCaseTr(t.teamName),
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
                          '${t.workerCount}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: SizedBox.shrink()),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Toplam',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${snapshot.totalTeamWorkers}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _summaryNum(double v, {int maxFrac = 2}) {
  if (v <= 0) return '—';
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  final s = v.toStringAsFixed(maxFrac);
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Haftalık / aylık personel özeti — günlük tablo formatı, DURUM yok (4 sütun).
class PeriodPersonnelSummaryTable extends StatelessWidget {
  const PeriodPersonnelSummaryTable({super.key, required this.summary});

  final PeriodPersonelSummary summary;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final theme = AppColors.useDarkCards
        ? SJCard.darkContrastTheme(base)
        : AppColors.isSantijetPro
            ? SJCard.lightContrastTheme(base)
            : base;
    final rows = summary.rows;
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
                  _HeaderCell('YV', flex: 1),
                ],
              ),
            ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Text(
                  'Bu dönemde personel satırı yok',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final p = rows[index];
                    final meslek = p.profession.isNotEmpty
                        ? titleCaseTr(p.profession)
                        : '—';
                    final ekip =
                        p.team.isNotEmpty ? titleCaseTr(p.team) : '—';
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
                            flex: 1,
                            child: Text(
                              _summaryNum(p.yevmiye),
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
                      '${rows.length} kişi',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${_summaryNum(summary.totalAdamSaat, maxFrac: 1)} as',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      _summaryNum(summary.totalYevmiye),
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
}

/// Haftalık / aylık ekip ve yevmiyeli özet tablosu.
class PeriodTeamSummaryTable extends StatelessWidget {
  const PeriodTeamSummaryTable({
    super.key,
    required this.headers,
    required this.rows,
    this.emptyMessage = 'Bu dönemde ekip puantaj kaydı yok',
    this.sumColumnIndexes = const {},
    this.totalLabel = 'Toplam',
  });

  final List<String> headers;
  final List<List<String>> rows;
  final String emptyMessage;

  /// Bu sütun indekslerinin sayısal toplamı alt satırda gösterilir.
  final Set<int> sumColumnIndexes;
  final String totalLabel;

  static List<int> _flexesFor(List<String> headers) {
    final n = headers.length;
    if (n == 0) return const [];
    // Ekip puantajı (5): isim sütunları geniş, sayılar dengeli.
    if (n == 5) return const [3, 3, 2, 2, 2];
    // Yevmiyeli (6–8): kimlik geniş, kısa kodlar dar.
    return [
      for (var i = 0; i < n; i++)
        if (i == 0 && headers[i].replaceAll('\n', '').trim() == '#')
          1
        else if (headers[i].toUpperCase().contains('YV') ||
            headers[i].toUpperCase().contains('YEVMİYE'))
          1
        else if (headers[i].toUpperCase().contains('TARİH') ||
            headers[i].toUpperCase().contains('EKİP') ||
            headers[i].toUpperCase().contains('MESLEK'))
          2
        else
          3,
    ];
  }

  static String _displayHeader(String raw) {
    return raw
        .split('\n')
        .map((line) => line.trim().toUpperCase())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final theme = AppColors.useDarkCards
        ? SJCard.darkContrastTheme(base)
        : AppColors.isSantijetPro
            ? SJCard.lightContrastTheme(base)
            : base;
    final border = theme.dividerColor.withValues(alpha: 0.55);
    final flexes = _flexesFor(headers);
    final labelHeaders = [for (final h in headers) _displayHeader(h)];
    final needsScroll = headers.length >= 6;
    final minTableWidth = needsScroll ? headers.length * 76.0 : 0.0;

    return Theme(
      data: theme,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: AppRadii.md,
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: needsScroll
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth > minTableWidth
                      ? constraints.maxWidth
                      : minTableWidth;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _PeriodTableBody(
                      width: w,
                      headers: labelHeaders,
                      flexes: flexes,
                      rows: rows,
                      emptyMessage: emptyMessage,
                      sumColumnIndexes: sumColumnIndexes,
                      totalLabel: totalLabel,
                      border: border,
                      theme: theme,
                    ),
                  );
                },
              )
            : _PeriodTableBody(
                width: null,
                headers: labelHeaders,
                flexes: flexes,
                rows: rows,
                emptyMessage: emptyMessage,
                sumColumnIndexes: sumColumnIndexes,
                totalLabel: totalLabel,
                border: border,
                theme: theme,
              ),
      ),
    );
  }

  static String _totalCell({
    required int columnIndex,
    required List<List<String>> rows,
    required Set<int> sumColumnIndexes,
    required String totalLabel,
  }) {
    if (columnIndex == 0) return totalLabel;
    if (!sumColumnIndexes.contains(columnIndex)) return '';
    return formatNumericColumnSum(rows, columnIndex);
  }
}

/// Dönem tablosu gövdesi — başlık bandı + satırlar.
class _PeriodTableBody extends StatelessWidget {
  const _PeriodTableBody({
    required this.width,
    required this.headers,
    required this.flexes,
    required this.rows,
    required this.emptyMessage,
    required this.sumColumnIndexes,
    required this.totalLabel,
    required this.border,
    required this.theme,
  });

  final double? width;
  final List<String> headers;
  final List<int> flexes;
  final List<List<String>> rows;
  final String emptyMessage;
  final Set<int> sumColumnIndexes;
  final String totalLabel;
  final Color border;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          decoration: BoxDecoration(
            color: AppColors.electricBlue.withValues(alpha: 0.08),
            border: Border(bottom: BorderSide(color: border)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < headers.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    flex: flexes[i],
                    child: _PeriodHeaderBadge(label: headers[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          for (final row in rows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < headers.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      flex: flexes[i],
                      child: Text(
                        i < row.length ? row[i] : '—',
                        textAlign: i < 2 ? TextAlign.start : TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: i < 2 ? FontWeight.w600 : FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (sumColumnIndexes.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              color: AppColors.success.withValues(alpha: 0.08),
              child: Row(
                children: [
                  for (var i = 0; i < headers.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      flex: flexes[i],
                      child: Text(
                        PeriodTeamSummaryTable._totalCell(
                          columnIndex: i,
                          rows: rows,
                          sumColumnIndexes: sumColumnIndexes,
                          totalLabel: totalLabel,
                        ),
                        textAlign: i < 2 ? TextAlign.start : TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: sumColumnIndexes.contains(i)
                              ? AppColors.success
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ],
    );

    if (width == null) return body;
    return SizedBox(width: width, child: body);
  }
}

/// Dönem tablosu başlık rozeti — çok satırlı, eşit yükseklik.
class _PeriodHeaderBadge extends StatelessWidget {
  const _PeriodHeaderBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.electricBlueLight,
        borderRadius: AppRadii.xs,
        border: Border.all(color: AppColors.electricBlue),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.inkPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.15,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
