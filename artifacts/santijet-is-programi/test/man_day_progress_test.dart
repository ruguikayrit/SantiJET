import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_is_programi/domain/daily_crew_entry.dart';
import 'package:santijet_is_programi/domain/man_day_progress.dart';
import 'package:santijet_is_programi/domain/program_item.dart';

void main() {
  final start = DateTime(2026, 9, 1);
  final item = ProgramItem(
    id: 'kolon',
    santiyeId: 'Merkez',
    name: 'Kolon imalatı',
    startDate: start,
    endDate: DateTime(2026, 9, 10),
    plannedDays: 10,
    plannedCrew: 4,
    progress: 0,
    status: ProgramStatus.planned,
    responsible: 'Kalıp',
  );

  test('planlanan adam-gün süre × ekiptir', () {
    expect(item.plannedManDays, 40);
    expect(
      ProgramItem.endDateFromDuration(start, 10),
      DateTime(2026, 9, 10),
    );
  });

  test('kayıtlı yüzde fiili işi Project gibi üretir', () {
    final row = ManDayProgress.of(
      item.copyWith(progress: 30),
      const [],
      today: DateTime(2026, 9, 5),
    );
    expect(row.progress, 30);
    expect(row.realizedManDays, 12);
    expect(row.remainingManDays, 28);
  });

  test('günlük adam kayıtları gerçekleşen adam-günü ve ilerlemeyi üretir', () {
    final logs = [
      DailyCrewEntry(
        id: '1',
        itemId: 'kolon',
        date: DateTime(2026, 9, 1),
        workers: 4,
      ),
      DailyCrewEntry(
        id: '2',
        itemId: 'kolon',
        date: DateTime(2026, 9, 2),
        workers: 4,
      ),
      DailyCrewEntry(
        id: '3',
        itemId: 'kolon',
        date: DateTime(2026, 9, 3),
        workers: 2,
      ),
    ];
    final row = ManDayProgress.of(
      item,
      logs,
      today: DateTime(2026, 9, 3),
    );
    expect(row.realizedManDays, 10);
    expect(row.plannedToDate, 12);
    expect(row.varianceToDate, -2);
    expect(row.progress, 25);
    expect(row.effectiveStatus, ProgramStatus.inProgress);
  });

  test('süre doldu ve adam-gün tamamlanmadıysa gecikmiştir', () {
    final logs = [
      DailyCrewEntry(
        id: '1',
        itemId: 'kolon',
        date: DateTime(2026, 9, 1),
        workers: 4,
      ),
    ];
    final row = ManDayProgress.of(
      item,
      logs,
      today: DateTime(2026, 9, 12),
    );
    expect(row.effectiveStatus, ProgramStatus.delayed);
    expect(row.remainingManDays, 36);
  });

  test('planlanan adam-gün dolduysa tamamlanmıştır', () {
    final logs = [
      DailyCrewEntry(
        id: '1',
        itemId: 'kolon',
        date: DateTime(2026, 9, 1),
        workers: 40,
      ),
    ];
    final row = ManDayProgress.of(item, logs, today: DateTime(2026, 9, 2));
    expect(row.progress, 100);
    expect(row.effectiveStatus, ProgramStatus.completed);
  });
}
