import 'program_item.dart';

/// Gantt zaman çizelgesi — yalnız takvim günü kullanır, saat/DST kaydırmaz.
class GanttLayout {
  const GanttLayout({
    required this.start,
    required this.end,
    required this.dayWidth,
  });

  /// İlk gün sütunu (gece yarısı, yerel).
  final DateTime start;

  /// Son gün sütunu (dahil).
  final DateTime end;

  final double dayWidth;

  static const nameWidth = 118.0;
  static const rowHeight = 36.0;
  static const scaleHeight = 28.0;

  factory GanttLayout.fromItems(List<ProgramItem> items) {
    final first = items
        .map((item) => dateOnly(item.startDate))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final last = items
        .map((item) => dateOnly(item.endDate))
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final start = addDays(first, -2);
    final end = addDays(last, 3);
    return GanttLayout(
      start: start,
      end: end,
      dayWidth: _dayWidth(end.difference(start).inDays + 1),
    );
  }

  int get slots => end.difference(start).inDays + 1;

  double get width => slots * dayWidth;

  int offset(DateTime date) =>
      dateOnly(date).difference(start).inDays.clamp(0, slots - 1);

  double xFor(DateTime date) => offset(date) * dayWidth;

  double barLeft(ProgramItem item) => xFor(item.startDate);

  double barWidth(ProgramItem item) {
    if (item.isMilestone) return 10;
    final days = item.calculatedDays < 1 ? 1 : item.calculatedDays;
    return days * dayWidth;
  }

  bool contains(DateTime date) {
    final day = dateOnly(date);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  List<DateTime> ticks() {
    final step = slots <= 21
        ? 1
        : slots <= 60
        ? 7
        : 14;
    return [for (var i = 0; i < slots; i += step) addDays(start, i)];
  }

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime addDays(DateTime value, int days) =>
      DateTime(value.year, value.month, value.day + days);

  static double _dayWidth(int slots) {
    if (slots <= 21) return 22;
    if (slots <= 60) return 14;
    return 10;
  }
}
