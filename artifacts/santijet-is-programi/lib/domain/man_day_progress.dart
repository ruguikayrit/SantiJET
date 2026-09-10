import 'daily_crew_entry.dart';
import 'program_item.dart';

/// Planlanan imalat ile sahadaki gerçekleşeni adam-gün üzerinden karşılaştırır.
/// İlerleme yüzdesi kaydırıcıdan değil, günlük adam kayıtlarından doğar.
class ManDayProgress {
  const ManDayProgress({
    required this.item,
    required this.realizedManDays,
    required this.hasLogs,
    this.today,
  });

  final ProgramItem item;
  final int realizedManDays;
  final bool hasLogs;
  final DateTime? today;

  factory ManDayProgress.of(
    ProgramItem item,
    List<DailyCrewEntry> logs, {
    DateTime? today,
  }) {
    var realized = 0;
    var hasLogs = false;
    for (final log in logs) {
      if (log.itemId != item.id) continue;
      hasLogs = true;
      realized += log.workers;
    }
    return ManDayProgress(
      item: item,
      realizedManDays: realized,
      hasLogs: hasLogs,
      today: today,
    );
  }

  DateTime get _day => _dateOnly(today ?? DateTime.now());

  /// Süre × ekip. İşin plan birimi.
  int get plannedManDays => item.plannedManDays;

  /// Bugüne kadar planlanan adam-gün. İş henüz başlamadıysa 0,
  /// süresi dolduysa tüm plandır.
  int get plannedToDate {
    if (plannedManDays <= 0) return 0;
    if (_day.isBefore(_dateOnly(item.startDate))) return 0;
    final elapsed = _day.difference(_dateOnly(item.startDate)).inDays + 1;
    final capped = elapsed.clamp(0, item.calculatedDays);
    return capped * item.plannedCrew;
  }

  /// Gerçek − bugüne kadar plan. Eksi değer planın gerisinde demektir.
  int get varianceToDate => realizedManDays - plannedToDate;

  /// Saha kaydı varsa adam-günden, yoksa dosyadan/elle girilen yüzdeden.
  int get progress {
    if (hasLogs) {
      if (plannedManDays <= 0) return realizedManDays > 0 ? 100 : 0;
      return ((realizedManDays / plannedManDays) * 100).round().clamp(0, 100);
    }
    return item.progress.clamp(0, 100);
  }

  ProgramStatus get effectiveStatus {
    if (item.isStatusManual) return item.status;
    if (progress >= 100) return ProgramStatus.completed;
    if (_day.isAfter(_dateOnly(item.endDate))) return ProgramStatus.delayed;
    if (progress > 0 || !_day.isBefore(_dateOnly(item.startDate))) {
      return ProgramStatus.inProgress;
    }
    return ProgramStatus.planned;
  }

  /// Malzeme alımı ve işçilik hakedişi için kalan işçilik.
  int get remainingManDays =>
      (plannedManDays - realizedManDays).clamp(0, plannedManDays);

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

/// Bir listedeki faaliyetlerin toplam plan / gerçekleşen kırılımı.
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
