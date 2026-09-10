import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_is_programi/domain/program_item.dart';
import 'package:santijet_is_programi/domain/project_tracking.dart';

void main() {
  final item = ProgramItem(
    id: 't1',
    santiyeId: 'Merkez',
    name: 'Kalıp',
    startDate: DateTime(2026, 3, 1),
    endDate: DateTime(2026, 3, 10),
    plannedDays: 10,
    plannedCrew: 4,
    progress: 0,
    status: ProgramStatus.planned,
    responsible: 'Kalıp Ekibi',
  );

  test('% Tamamlanma fiili süre ve işi birlikte günceller', () {
    final row = ProjectTracking.fromItem(item).applyPercentComplete(50);
    expect(row.duration, 10);
    expect(row.work, 40);
    expect(row.actualDuration, 5);
    expect(row.remainingDuration, 5);
    expect(row.actualWork, 20);
    expect(row.remainingWork, 20);
    expect(row.actualStart, DateTime(2026, 3, 1));
    expect(row.actualFinish, isNull);
  });

  test('% 100 fiili bitişi yazar', () {
    final row = ProjectTracking.fromItem(item).applyPercentComplete(100);
    expect(row.actualFinish, DateTime(2026, 3, 10));
    expect(row.remainingDuration, 0);
    expect(row.remainingWork, 0);
    expect(row.status(today: DateTime(2026, 3, 5)), ProgramStatus.completed);
  });

  test('fiili süre planı aşarsa süre uzar', () {
    final row = ProjectTracking.fromItem(item).applyActualDuration(12);
    expect(row.duration, 12);
    expect(row.finish, DateTime(2026, 3, 12));
    expect(row.percentComplete, 100);
    expect(row.work, 48);
  });

  test('kalan süre yazılınca süre fiili + kalan olur', () {
    final row = ProjectTracking.fromItem(
      item,
    ).applyPercentComplete(40).applyRemainingDuration(3);
    expect(row.actualDuration, 4);
    expect(row.remainingDuration, 3);
    expect(row.duration, 7);
    expect(row.percentComplete, ((4 / 7) * 100).round());
  });

  test('bitiş değişince süre yeniden hesaplanır', () {
    final row = ProjectTracking.fromItem(
      item,
    ).applyFinish(DateTime(2026, 3, 5));
    expect(row.duration, 5);
    expect(row.work, 20);
  });

  test('kayıtlı yüzde izleme alanlarını doldurur', () {
    final row = ProjectTracking.fromItem(item.copyWith(progress: 25));
    expect(row.percentComplete, 25);
    expect(row.actualWork, 10);
    expect(row.actualDuration, 3);
  });
}
