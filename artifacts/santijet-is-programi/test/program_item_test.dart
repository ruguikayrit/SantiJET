import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_is_programi/domain/program_item.dart';

void main() {
  group('ProgramItem', () {
    final today = DateTime(2026, 9, 10);

    test('plannedDays yoksa iki tarih dahil gün sayısını hesaplar', () {
      final item = _item(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 5),
      );
      expect(item.calculatedDays, 5);
    });

    test('bitişi geçen ve tamamlanmayan faaliyeti gecikmiş sayar', () {
      final item = _item(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 9),
        progress: 90,
        status: ProgramStatus.inProgress,
      );
      expect(item.effectiveStatus(today: today), ProgramStatus.delayed);
    });

    test('yüzde yüz ilerlemeyi tamamlandı sayar', () {
      final item = _item(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 20),
        progress: 100,
        status: ProgramStatus.inProgress,
      );
      expect(item.effectiveStatus(today: today), ProgramStatus.completed);
    });

    test('manuel durum otomatik gecikmeyi ezer', () {
      final item = _item(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 5),
        progress: 70,
        status: ProgramStatus.inProgress,
        isStatusManual: true,
      );
      expect(item.effectiveStatus(today: today), ProgramStatus.inProgress);
    });

    test('JSON turunda alanları korur', () {
      final item = _item(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 5),
        progress: 35,
        status: ProgramStatus.inProgress,
      ).copyWith(
        wbs: '1.2',
        outlineLevel: 2,
        isMilestone: false,
        msProjectUid: 14,
        predecessors: '3FS+2 gün',
      );
      final restored = ProgramItem.fromJson(item.toJson());
      expect(restored.id, item.id);
      expect(restored.status, ProgramStatus.inProgress);
      expect(restored.progress, 35);
      expect(restored.startDate, DateTime(2026, 9, 1));
      expect(restored.wbs, '1.2');
      expect(restored.outlineLevel, 2);
      expect(restored.msProjectUid, 14);
      expect(restored.predecessors, '3FS+2 gün');
    });
  });

  group('ProgramItemValidator', () {
    test('boş adı reddeder', () {
      expect(ProgramItemValidator.name('  '), isNotNull);
    });

    test('bitiş başlangıçtan önce olamaz', () {
      expect(
        ProgramItemValidator.dates(DateTime(2026, 9, 10), DateTime(2026, 9, 9)),
        isNotNull,
      );
    });

    test('ilerleme 0–100 aralığında olmalıdır', () {
      expect(ProgramItemValidator.progress(-1), isNotNull);
      expect(ProgramItemValidator.progress(101), isNotNull);
      expect(ProgramItemValidator.progress(40), isNull);
    });

    test('süre ve ekip en az 1 olmalıdır', () {
      expect(ProgramItemValidator.duration(0), isNotNull);
      expect(ProgramItemValidator.crew(0), isNotNull);
      expect(ProgramItemValidator.duration(5), isNull);
      expect(ProgramItemValidator.crew(3), isNull);
    });
  });
}

ProgramItem _item({
  required DateTime start,
  required DateTime end,
  int progress = 0,
  ProgramStatus status = ProgramStatus.planned,
  bool isStatusManual = false,
}) => ProgramItem(
  id: 'test',
  santiyeId: 'Test Şantiyesi',
  name: 'Test faaliyeti',
  startDate: start,
  endDate: end,
  progress: progress,
  status: status,
  responsible: 'Test',
  isStatusManual: isStatusManual,
);
