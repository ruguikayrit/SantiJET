import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_puantaj/core/utils/puantaj_date.dart';
import 'package:santijet_puantaj/domain/entities/attendance.dart';
import 'package:santijet_puantaj/domain/entities/person.dart';
import 'package:santijet_puantaj/domain/entities/production.dart';
import 'package:santijet_puantaj/domain/enums/attendance_status.dart';
import 'package:santijet_puantaj/domain/yevmiye/imalat_crew_allocator.dart';
import 'package:santijet_puantaj/domain/yevmiye/yevmiye_calculator.dart';

void main() {
  group('AttendanceStatus', () {
    test('saat kuralları santiye-takip ile aynı', () {
      expect(AttendanceStatus.present.hours, 8);
      expect(AttendanceStatus.half.hours, 4);
      expect(AttendanceStatus.izinli.hours, 0);
      expect(AttendanceStatus.absent.hours, 0);
      expect(AttendanceStatus.present.isWorkedDay, isTrue);
      expect(AttendanceStatus.half.isWorkedDay, isTrue);
      expect(AttendanceStatus.absent.isWorkedDay, isFalse);
    });
  });

  group('YevmiyeCalculator', () {
    test('mesai dahil adam-gün', () {
      const a = Attendance(
        id: '1',
        projectId: 'p',
        personId: 'u1',
        personName: 'Ali',
        date: '25.07.2026',
        status: AttendanceStatus.present,
        hours: 8,
        overtimeHours: 2,
      );
      expect(a.yevmiye, 1.25);
      expect(YevmiyeCalculator.ofAttendance(a), 1.25);
    });

    test('ekip toplamı yalnızca ekip üyelerinden', () {
      const people = [
        Person(id: 'u1', name: 'Ali', team: 'Demir'),
        Person(id: 'u2', name: 'Veli', team: 'Demir'),
        Person(id: 'u3', name: 'Ayşe', team: 'Kalıp'),
      ];
      const att = [
        Attendance(
          id: 'a1',
          projectId: 'p',
          personId: 'u1',
          personName: 'Ali',
          date: '25.07.2026',
          status: AttendanceStatus.present,
          hours: 8,
          overtimeHours: 0,
        ),
        Attendance(
          id: 'a2',
          projectId: 'p',
          personId: 'u2',
          personName: 'Veli',
          date: '25.07.2026',
          status: AttendanceStatus.half,
          hours: 4,
          overtimeHours: 2,
        ),
        Attendance(
          id: 'a3',
          projectId: 'p',
          personId: 'u3',
          personName: 'Ayşe',
          date: '25.07.2026',
          status: AttendanceStatus.present,
          hours: 8,
        ),
      ];
      // u1: 8/8=1, u2: (4+2)/8=0.75 → 1.75
      expect(
        YevmiyeCalculator.forTeam(
          projectId: 'p',
          date: '25.07.2026',
          teamName: 'Demir',
          people: people,
          attendance: att,
        ),
        1.75,
      );
    });
  });

  group('ImalatCrewAllocator', () {
    test('ikinci imalat için kalan usta/düz düşülür', () {
      const people = [
        Person(id: 'u1', name: 'A', team: 'Demir', profession: 'Usta'),
        Person(id: 'u2', name: 'B', team: 'Demir', profession: 'Usta'),
        Person(id: 'u3', name: 'C', team: 'Demir', profession: 'Saha Düz İşçi'),
      ];
      const att = [
        Attendance(
          id: 'a1',
          projectId: 'p',
          personId: 'u1',
          personName: 'A',
          date: '25.07.2026',
          status: AttendanceStatus.present,
          hours: 8,
        ),
        Attendance(
          id: 'a2',
          projectId: 'p',
          personId: 'u2',
          personName: 'B',
          date: '25.07.2026',
          status: AttendanceStatus.present,
          hours: 8,
        ),
        Attendance(
          id: 'a3',
          projectId: 'p',
          personId: 'u3',
          personName: 'C',
          date: '25.07.2026',
          status: AttendanceStatus.present,
          hours: 8,
        ),
      ];
      const first = Production(
        id: 'pr1',
        projectId: 'p',
        name: 'Temel',
        date: '25.07.2026',
        teamName: 'Demir',
        ustaCount: 1,
        duzIsciCount: 1,
      );
      final pool = ImalatCrewAllocator.availableFor(
        projectId: 'p',
        date: '25.07.2026',
        teamName: 'Demir',
        people: people,
        attendance: att,
        productions: [first],
      );
      expect(pool.ustaTotal, 2);
      expect(pool.duzTotal, 1);
      expect(pool.ustaRemaining, 1);
      expect(pool.duzRemaining, 0);
    });
  });

  group('PuantajDate', () {
    test('format / parse roundtrip', () {
      final d = DateTime(2026, 7, 25);
      final s = PuantajDate.format(d);
      expect(s, '25.07.2026');
      expect(PuantajDate.parse(s), d);
    });

    test('hafta pazartesiden başlar', () {
      // Cumartesi 25.07.2026 → hafta 20–26
      final days = PuantajDate.weekDays('25.07.2026');
      expect(days.length, 7);
      expect(days.first, '20.07.2026');
      expect(days.last, '26.07.2026');
    });
  });
}
