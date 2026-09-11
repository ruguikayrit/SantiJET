import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_is_programi/domain/gantt_layout.dart';
import 'package:santijet_is_programi/domain/program_item.dart';

ProgramItem _item({
  required DateTime start,
  required DateTime end,
  int days = 1,
  bool milestone = false,
}) => ProgramItem(
  id: 't-${start.day}',
  santiyeId: 'Merkez',
  name: 'İş',
  startDate: start,
  endDate: end,
  plannedDays: days,
  progress: 0,
  status: ProgramStatus.planned,
  responsible: '',
  isMilestone: milestone,
);

void main() {
  test('sütunlar ilk ve son günü kapsar, saat kaydırmaz', () {
    final layout = GanttLayout.fromItems([
      _item(
        start: DateTime(2026, 8, 11, 15, 30),
        end: DateTime(2026, 8, 20, 9),
        days: 10,
      ),
    ]);

    expect(layout.start, DateTime(2026, 8, 9));
    expect(layout.end, DateTime(2026, 8, 23));
    expect(layout.slots, 15);
    expect(layout.offset(DateTime(2026, 8, 11, 23, 59)), 2);
    expect(layout.xFor(DateTime(2026, 8, 11)), 2 * layout.dayWidth);
  });

  test('çubuk süresi gün sütunuyla çarpılır, taşmaz', () {
    final item = _item(
      start: DateTime(2026, 3, 10),
      end: DateTime(2026, 3, 12),
      days: 3,
    );
    final layout = GanttLayout.fromItems([item]);

    expect(layout.barLeft(item), layout.xFor(DateTime(2026, 3, 10)));
    expect(layout.barWidth(item), 3 * layout.dayWidth);
    expect(
      layout.barLeft(item) + layout.barWidth(item),
      lessThan(layout.width),
    );
  });

  test('ölçek işaretleri son sütunun dışına çıkmaz', () {
    final layout = GanttLayout.fromItems([
      _item(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 20), days: 20),
    ]);
    for (final tick in layout.ticks()) {
      expect(layout.xFor(tick), lessThan(layout.width));
    }
  });
}
