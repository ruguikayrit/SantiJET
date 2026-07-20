import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/entities/workforce.dart';

void main() {
  group('WorkforceCrewHours', () {
    test('manHours and adamGun for usta temel örnek bileşenleri', () {
      // 6 tam + 2 yarım + 4 kişi × 2 saat mesai
      const crew = WorkforceCrewHours(
        tam: 6,
        yarim: 2,
        mesaiKisi: 4,
        mesaiSaat: 2,
      );
      expect(crew.manHours, 6 * 8 + 2 * 4 + 2 * 4);
      expect(crew.adamGun, crew.manHours / 8);
    });

    test('kalfa hesabı dışı — yalnızca usta+düz toplanır', () {
      final entry = WorkforceEntry(
        id: 'wf-1',
        date: DateTime(2026, 7, 18),
        kalfa: 10,
        lines: const [
          WorkforceImalatLine(
            id: 'wil-1',
            imalatName: 'Temel',
            usta: WorkforceCrewHours(tam: 6, yarim: 2, mesaiKisi: 4, mesaiSaat: 2),
            duzIsci: WorkforceCrewHours(tam: 2, mesaiKisi: 1, mesaiSaat: 2),
          ),
          WorkforceImalatLine(
            id: 'wil-2',
            imalatName: 'Perde',
            usta: WorkforceCrewHours(tam: 3, mesaiKisi: 2, mesaiSaat: 1),
            duzIsci: WorkforceCrewHours(tam: 1, mesaiKisi: 1, mesaiSaat: 1),
          ),
        ],
      );

      expect(entry.workerDayUnits, entry.ustaAdamGun + entry.duzAdamGun);
      expect(entry.workerDayUnits, greaterThan(0));
      // kalfa 10 olsa da formüle eklenmez
      expect(entry.totalAdamGun, entry.workerDayUnits);
    });
  });

  group('WorkforceEntry.fromJson migration', () {
    test('classic steelWorkers/foremen/hours → Genel satırı', () {
      final entry = WorkforceEntry.fromJson({
        'id': 'old-1',
        'date': '2026-07-18T00:00:00.000',
        'steelWorkers': 5,
        'foremen': 8,
        'supervisors': 1,
        'hours': 8,
        'overtimeHours': 2,
      });

      expect(entry.kalfa, 5);
      expect(entry.lines, hasLength(1));
      expect(entry.lines.first.imalatName, 'Genel');
      expect(entry.lines.first.usta.tam, 8);
      expect(entry.lines.first.usta.yarim, 0);
      expect(entry.lines.first.usta.mesaiKisi, 8);
      expect(entry.lines.first.usta.mesaiSaat, 2);
      expect(entry.lines.first.duzIsci.isEmpty, isTrue);
      expect(entry.workerDayUnits, greaterThan(0));
    });

    test('schema v3 lines round-trip', () {
      final original = WorkforceEntry(
        id: 'wf-2',
        date: DateTime(2026, 7, 18),
        kalfa: 2,
        lines: const [
          WorkforceImalatLine(
            id: 'wil-a',
            imalatId: 'im-1',
            imalatName: 'Temel',
            usta: WorkforceCrewHours(tam: 6),
            duzIsci: WorkforceCrewHours(tam: 2),
          ),
        ],
      );
      final restored = WorkforceEntry.fromJson(original.toJson());
      expect(restored.kalfa, 2);
      expect(restored.lines, hasLength(1));
      expect(restored.lines.first.imalatName, 'Temel');
      expect(restored.lines.first.usta.tam, 6);
      expect(restored.workerDayUnits, closeTo(original.workerDayUnits, 1e-9));
    });
  });
}
