import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/sj_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/puantaj_date.dart';
import '../../data/providers/company_provider.dart';
import '../../data/providers/daily_report_export_sections_provider.dart';
import '../../data/providers/daily_report_provider.dart';
import '../../data/services/daily_report_export_sections.dart';
import '../../data/services/daily_report_pdf_service.dart';
import '../../domain/entities/daily_report.dart';
import '../../domain/entities/project.dart';
import '../daily_report/widgets/daily_report_export_sections_sheet.dart';

/// Seçili gün(ler) için PDF üret (anasayfa Dün/Bugün ve takvim sheet ortak).
Future<void> exportHomeDailyReportPdf(
  WidgetRef ref, {
  required Project project,
  required List<String> dates,
  required DailyReportExportSections sections,
}) async {
  if (dates.isEmpty) {
    throw ArgumentError('En az bir gün seçin');
  }
  final sorted = List<String>.from(dates)
    ..sort((a, b) {
      final da = PuantajDate.tryParse(a);
      final db = PuantajDate.tryParse(b);
      if (da == null || db == null) return a.compareTo(b);
      return da.compareTo(db);
    });

  final notifier = ref.read(dailyReportsProvider.notifier);
  final reports = <DailyReport>[];
  final snaps = <DailyReportAttendanceSnapshot?>[];

  for (final date in sorted) {
    var report = notifier.ensureDraft(
      projectId: project.id,
      date: date,
    );
    report = syncAttendanceIntoReport(ref, report);
    reports.add(report);
    snaps.add(report.attendanceSnapshot);
  }

  final company = ref.read(companyInfoProvider);
  await dailyReportPdfService.exportMany(
    reports: reports,
    project: project,
    company: company,
    sections: sections,
    liveSnapshots: snaps,
  );
}

/// Ana sayfa — günlük rapor PDF için hızlı filtre + çoklu gün takvimi.
Future<void> showHomeDailyReportPdfSheet(
  BuildContext context,
  WidgetRef ref, {
  required Project project,
  List<String>? initialDates,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (_, scrollController) => HomeDailyReportPdfSheet(
        project: project,
        scrollController: scrollController,
        initialDates: initialDates,
      ),
    ),
  );
}

class HomeDailyReportPdfSheet extends ConsumerStatefulWidget {
  const HomeDailyReportPdfSheet({
    required this.project,
    this.scrollController,
    this.initialDates,
    super.key,
  });

  final Project project;
  final ScrollController? scrollController;
  final List<String>? initialDates;

  @override
  ConsumerState<HomeDailyReportPdfSheet> createState() =>
      _HomeDailyReportPdfSheetState();
}

class _HomeDailyReportPdfSheetState
    extends ConsumerState<HomeDailyReportPdfSheet> {
  late DateTime _month;
  final Set<String> _selected = {};
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialDates?.isNotEmpty == true
        ? widget.initialDates!
        : [PuantajDate.today()];
    _selected.addAll(seed);
    final first = PuantajDate.tryParse(seed.first) ?? DateTime.now();
    _month = DateTime(first.year, first.month);
  }

  void _applyQuick(List<String> dates) {
    setState(() {
      _selected
        ..clear()
        ..addAll(dates);
      final first = PuantajDate.tryParse(dates.first);
      if (first != null) {
        _month = DateTime(first.year, first.month);
      }
      _error = null;
    });
  }

  void _toggleDay(DateTime day) {
    final key = PuantajDate.format(day);
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else {
        _selected.add(key);
      }
      _error = null;
    });
  }

  List<String> _sortedSelected() {
    final list = _selected.toList();
    list.sort((a, b) {
      final da = PuantajDate.tryParse(a);
      final db = PuantajDate.tryParse(b);
      if (da == null || db == null) return a.compareTo(b);
      return da.compareTo(db);
    });
    return list;
  }

  Future<void> _exportPdf() async {
    if (_busy) return;
    final dates = _sortedSelected();
    if (dates.isEmpty) {
      setState(() => _error = 'En az bir gün seçin.');
      return;
    }

    final sections = await showDailyReportExportSectionsPicker(
      context,
      ref,
      title: 'Çıktıda yer alacak başlıklar',
      subtitle: dates.length == 1
          ? '${widget.project.name} · ${dates.first}'
          : '${widget.project.name} · ${dates.length} gün',
    );
    if (sections == null || !mounted) return;

    ref.read(dailyReportExportSectionsProvider.notifier).save(sections);

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await exportHomeDailyReportPdf(
        ref,
        project: widget.project,
        dates: dates,
        sections: sections,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dates.length == 1
                ? 'PDF rapor dışa aktarıldı'
                : '${dates.length} günlük PDF rapor dışa aktarıldı',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = PuantajDate.today();
    final sorted = _sortedSelected();
    final thisMonthDays = PuantajDate.monthDaysThrough(today, through: today);
    final lastMonthDays = PuantajDate.previousMonthDays(today);
    final weekDays = PuantajDate.weekDays(today);
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          bottomPad > 0 ? AppSpacing.sm : AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                children: [
                  Text(
                    'Günlük rapor',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Takvimden gün seçin. Haftalık filtre Pzt–Paz 7 günü tek PDF’te birleştirir.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickChip(
                        label: 'Dün',
                        selected: _selected.length == 1 &&
                            _selected.contains(PuantajDate.shift(today, -1)),
                        onTap: () =>
                            _applyQuick([PuantajDate.shift(today, -1)]),
                      ),
                      _QuickChip(
                        label: 'Bugün',
                        selected: _selected.length == 1 &&
                            _selected.contains(today),
                        onTap: () => _applyQuick([today]),
                      ),
                      _QuickChip(
                        label: 'Bu hafta (7 gün)',
                        selected: _isSameSet(weekDays),
                        onTap: () => _applyQuick(weekDays),
                      ),
                      _QuickChip(
                        label: 'Bu ay',
                        selected: _isSameSet(thisMonthDays),
                        onTap: () => _applyQuick(thisMonthDays),
                      ),
                      _QuickChip(
                        label: 'Geçen ay',
                        selected: _isSameSet(lastMonthDays),
                        onTap: () => _applyQuick(lastMonthDays),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _MonthHeader(
                    month: _month,
                    onPrev: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1),
                    ),
                    onNext: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _MultiDayCalendar(
                    month: _month,
                    selected: _selected,
                    onToggle: _toggleDay,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    sorted.isEmpty
                        ? 'Seçili gün yok'
                        : sorted.length == 1
                            ? 'Seçili: ${sorted.first}'
                            : 'Seçili: ${sorted.length} gün · ${sorted.first} – ${sorted.last}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.critical,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SJButton(
              label: sorted.length <= 1
                  ? 'PDF Rapor Oluştur'
                  : '${sorted.length} Günlük PDF Oluştur',
              icon: Icons.picture_as_pdf_outlined,
              loading: _busy,
              expanded: true,
              onPressed: _busy ? null : _exportPdf,
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameSet(List<String> dates) {
    if (_selected.length != dates.length) return false;
    for (final d in dates) {
      if (!_selected.contains(d)) return false;
    }
    return true;
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppColors.electricBlue.withValues(alpha: 0.18),
      side: BorderSide(
        color: selected
            ? AppColors.electricBlue
            : Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const _months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            '${_months[month.month - 1]} ${month.year}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _MultiDayCalendar extends StatelessWidget {
  const _MultiDayCalendar({
    required this.month,
    required this.selected,
    required this.onToggle,
  });

  final DateTime month;
  final Set<String> selected;
  final ValueChanged<DateTime> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday-based: weekday 1=Mon … 7=Sun → leading blanks
    final leading = first.weekday - 1;
    final totalCells = leading + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastAllowed = today.add(const Duration(days: 1));

    return Column(
      children: [
        Row(
          children: [
            for (final d in const ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'])
              Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < rows; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final idx = r * 7 + c;
                        final dayNum = idx - leading + 1;
                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return const SizedBox(height: 40);
                        }
                        final day = DateTime(month.year, month.month, dayNum);
                        final key = PuantajDate.format(day);
                        final isSelected = selected.contains(key);
                        final enabled = !day.isAfter(lastAllowed) &&
                            !day.isBefore(DateTime(2020));
                        final isToday = day == today;

                        return Padding(
                          padding: const EdgeInsets.all(2),
                          child: Material(
                            color: isSelected
                                ? AppColors.electricBlue
                                : isToday
                                    ? AppColors.electricBlue
                                        .withValues(alpha: 0.12)
                                    : Colors.transparent,
                            borderRadius: AppRadii.sm,
                            child: InkWell(
                              borderRadius: AppRadii.sm,
                              onTap: enabled ? () => onToggle(day) : null,
                              child: SizedBox(
                                height: 40,
                                child: Center(
                                  child: Text(
                                    '$dayNum',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: !enabled
                                          ? theme.disabledColor
                                          : isSelected
                                              ? Colors.white
                                              : null,
                                      fontWeight: isSelected || isToday
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
