import 'daily_crew_entry.dart';
import 'program_item.dart';
import 'project_tracking.dart';

/// Planlanan iş ile fiili işi Project izleme hesabıyla karşılaştırır.
class ManDayProgress {
  const ManDayProgress({
    required this.item,
    required this.tracking,
    this.today,
  });

  final ProgramItem item;
  final ProjectTracking tracking;
  final DateTime? today;

  factory ManDayProgress.of(
    ProgramItem item,
    List<DailyCrewEntry> logs, {
    DateTime? today,
  }) {
    return ManDayProgress(
      item: item,
      tracking: ProjectTracking.fromItem(item, logs: logs),
      today: today,
    );
  }

  DateTime get _day => _dateOnly(today ?? DateTime.now());

  int get plannedManDays => tracking.work;
  int get realizedManDays => tracking.actualWork;
  int get remainingManDays => tracking.remainingWork;
  int get progress => tracking.percentComplete;
  bool get hasActuals =>
      tracking.percentComplete > 0 || tracking.actualWork > 0;

  /// Bugüne kadar planlanan iş. İş henüz başlamadıysa 0,
  /// süresi dolduysa tüm plandır.
  int get plannedToDate {
    if (plannedManDays <= 0) return 0;
    if (_day.isBefore(_dateOnly(item.startDate))) return 0;
    final elapsed = _day.difference(_dateOnly(item.startDate)).inDays + 1;
    final capped = elapsed.clamp(0, item.calculatedDays);
    return capped * item.plannedCrew;
  }

  int get varianceToDate => realizedManDays - plannedToDate;

  ProgramStatus get effectiveStatus => tracking.status(today: today);

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

/// Bir listedeki faaliyetlerin toplam iş / fiili / kalan kırılımı.
class SiteManDaySummary {
  const SiteManDaySummary({
    required this.planned,
    required this.realized,
    required this.plannedToDate,
  });

  final int planned;
  final int realized;
  final int plannedToDate;

  factory SiteManDaySummary.of(
    List<ProgramItem> items,
    List<DailyCrewEntry> logs, {
    DateTime? today,
  }) {
    var planned = 0;
    var realized = 0;
    var plannedToDate = 0;
    for (final item in items) {
      final row = ManDayProgress.of(item, logs, today: today);
      planned += row.plannedManDays;
      realized += row.realizedManDays;
      plannedToDate += row.plannedToDate;
    }
    return SiteManDaySummary(
      planned: planned,
      realized: realized,
      plannedToDate: plannedToDate,
    );
  }

  int get varianceToDate => realized - plannedToDate;
  int get remaining => (planned - realized).clamp(0, planned);
  int get progress =>
      planned == 0 ? 0 : ((realized / planned) * 100).round().clamp(0, 100);
}
