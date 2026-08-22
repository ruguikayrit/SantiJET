import '../../core/utils/puantaj_date.dart';
import '../entities/daily_report.dart';

/// Tek günlük rapor özeti — haftalık/aylık türetmenin birimi.
class DailyReportDaySummary {
  const DailyReportDaySummary({
    required this.date,
    this.report,
  });

  final String date;
  final DailyReport? report;

  bool get hasReport => report != null;

  bool get hasContent {
    final r = report;
    if (r == null) return false;
    return r.hasWorkEntries ||
        r.photos.isNotEmpty ||
        r.incomingMaterials.isNotEmpty ||
        r.outgoingMaterials.isNotEmpty ||
        r.orderedMaterials.isNotEmpty ||
        r.machines.isNotEmpty ||
        r.vehicles.isNotEmpty ||
        r.nextDayPlan.trim().isNotEmpty ||
        r.weather != null ||
        (r.attendanceSnapshot?.people.isNotEmpty ?? false);
  }

  int get photoCount => report?.photos.length ?? 0;
  int get incomingCount => report?.incomingMaterials.length ?? 0;
  int get outgoingCount => report?.outgoingMaterials.length ?? 0;
  int get orderedCount => report?.orderedMaterials.length ?? 0;
  int get machineCount =>
      (report?.machines.length ?? 0) + (report?.vehicles.length ?? 0);

  double get machineHours {
    final r = report;
    if (r == null) return 0;
    var h = 0.0;
    for (final m in r.machines) {
      h += m.hoursWorked;
    }
    for (final v in r.vehicles) {
      h += v.hoursWorked;
    }
    return h;
  }

  double get adamSaat => report?.attendanceSnapshot?.totalAdamSaat ?? 0;
  double get yevmiye => report?.attendanceSnapshot?.totalYevmiye ?? 0;
  int get presentCount => report?.attendanceSnapshot?.present ?? 0;
}

/// Pazartesi–Pazar haftası — günlük özetlerden türetilir.
class WeeklyReportSummary {
  const WeeklyReportSummary({
    required this.anchorDate,
    required this.label,
    required this.days,
  });

  final String anchorDate;
  final String label;
  final List<DailyReportDaySummary> days;

  int get filledDayCount => days.where((d) => d.hasContent).length;

  int get totalPhotos =>
      days.fold<int>(0, (sum, d) => sum + d.photoCount);

  int get totalIncoming =>
      days.fold<int>(0, (sum, d) => sum + d.incomingCount);

  int get totalOutgoing =>
      days.fold<int>(0, (sum, d) => sum + d.outgoingCount);

  int get totalOrdered =>
      days.fold<int>(0, (sum, d) => sum + d.orderedCount);

  double get totalAdamSaat =>
      days.fold<double>(0, (sum, d) => sum + d.adamSaat);

  double get totalYevmiye =>
      days.fold<double>(0, (sum, d) => sum + d.yevmiye);

  double get totalMachineHours =>
      days.fold<double>(0, (sum, d) => sum + d.machineHours);
}

/// Ay içi haftalar — her hafta [WeeklyReportSummary]; ay toplamları ay günlerinden.
class MonthlyReportSummary {
  const MonthlyReportSummary({
    required this.anchorDate,
    required this.label,
    required this.weeks,
    required this.monthDays,
  });

  final String anchorDate;
  final String label;
  final List<WeeklyReportSummary> weeks;
  final List<DailyReportDaySummary> monthDays;

  int get filledDayCount => monthDays.where((d) => d.hasContent).length;

  int get totalDays => monthDays.length;

  int get totalPhotos =>
      monthDays.fold<int>(0, (sum, d) => sum + d.photoCount);

  int get totalIncoming =>
      monthDays.fold<int>(0, (sum, d) => sum + d.incomingCount);

  double get totalAdamSaat =>
      monthDays.fold<double>(0, (sum, d) => sum + d.adamSaat);

  double get totalYevmiye =>
      monthDays.fold<double>(0, (sum, d) => sum + d.yevmiye);

  double get totalMachineHours =>
      monthDays.fold<double>(0, (sum, d) => sum + d.machineHours);
}

/// Günlük kayıtlardan haftalık / aylık özet üretir.
abstract final class PeriodReportAggregator {
  static DailyReportDaySummary summarize({
    required String date,
    required List<DailyReport> reports,
    required String projectId,
  }) {
    DailyReport? found;
    for (final r in reports) {
      if (r.projectId == projectId && r.date == date) {
        found = r;
        break;
      }
    }
    return DailyReportDaySummary(date: date, report: found);
  }

  static WeeklyReportSummary buildWeekly({
    required String anchorDate,
    required List<DailyReport> reports,
    required String projectId,
  }) {
    final dayStrings = PuantajDate.weekDays(anchorDate);
    final days = [
      for (final d in dayStrings)
        summarize(date: d, reports: reports, projectId: projectId),
    ];
    return WeeklyReportSummary(
      anchorDate: dayStrings.first,
      label: PuantajDate.weekLabel(dayStrings),
      days: days,
    );
  }

  static MonthlyReportSummary buildMonthly({
    required String anchorDate,
    required List<DailyReport> reports,
    required String projectId,
  }) {
    final monthDayStrings = PuantajDate.monthDays(anchorDate);
    final monthDays = [
      for (final d in monthDayStrings)
        summarize(date: d, reports: reports, projectId: projectId),
    ];

    final weekStarts = <String>{};
    final weeks = <WeeklyReportSummary>[];
    for (final d in monthDayStrings) {
      final weekStart = PuantajDate.weekDays(d).first;
      if (weekStarts.add(weekStart)) {
        weeks.add(
          buildWeekly(
            anchorDate: weekStart,
            reports: reports,
            projectId: projectId,
          ),
        );
      }
    }

    return MonthlyReportSummary(
      anchorDate: anchorDate,
      label: PuantajDate.monthLabel(anchorDate),
      weeks: weeks,
      monthDays: monthDays,
    );
  }
}
