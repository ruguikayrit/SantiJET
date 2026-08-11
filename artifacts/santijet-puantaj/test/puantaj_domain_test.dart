import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_puantaj/core/utils/puantaj_date.dart';
import 'package:santijet_puantaj/data/services/puantaj_backup_service.dart';
import 'package:santijet_puantaj/data/services/puantaj_report_builder.dart';
import 'package:santijet_puantaj/domain/attendance/attendance_display.dart';
import 'package:santijet_puantaj/domain/entities/attendance.dart';
import 'package:santijet_puantaj/domain/entities/person.dart';
import 'package:santijet_puantaj/domain/entities/production.dart';
import 'package:santijet_puantaj/domain/entities/production_day_entry.dart';
import 'package:santijet_puantaj/domain/enums/attendance_status.dart';
import 'package:santijet_puantaj/domain/yevmiye/yevmiye_calculator.dart';
import 'dart:convert';

void main() {
  group('Person.isActiveOn', () {
    const base = Person(
      id: '1',
      projectId: 'p1',
      name: 'Ali',
      hireDate: '2026-04-01',
      leaveDate: '2026-08-10',
      active: true,
    );

    test('çıkış günü dahil aktif', () {
      expect(base.isActiveOn('10.08.2026'), isTrue);
      expect(base.isActiveOn('2026-08-10'), isTrue);
    });

    test('çıkıştan sonraki gün pasif', () {
      expect(base.isActiveOn('11.08.2026'), isFalse);
      expect(base.isActiveOn('2026-08-11'), isFalse);
    });

    test('girişten önce pasif', () {
      expect(base.isActiveOn('31.03.2026'), isFalse);
    });

    test('manuel pasif her günü kapatır', () {
      expect(base.copyWith(active: false).isActiveOn('05.08.2026'), isFalse);
    });
  });

  group('AttendanceStatus', () {
    test('saat kuralları santiye-takip ile aynı', () {
      expect(AttendanceStatus.present.hours, 8);
      expect(AttendanceStatus.half.hours, 4);
      expect(AttendanceStatus.izinli.hours, 0);
      expect(AttendanceStatus.absent.hours, 0);
      expect(AttendanceStatus.giris.hours, 0);
      expect(AttendanceStatus.cikis.hours, 0);
      expect(AttendanceStatus.present.isWorkedDay, isTrue);
      expect(AttendanceStatus.half.isWorkedDay, isTrue);
      expect(AttendanceStatus.absent.isWorkedDay, isFalse);
      expect(AttendanceStatus.giris.isEmploymentMarker, isTrue);
      expect(AttendanceStatus.cikis.short, 'Ç');
      expect(AttendanceStatus.giris.short, 'G');
    });
  });

  group('AttendanceDisplay', () {
    test('işe giriş / çıkış gününde G ve Ç', () {
      const person = Person(
        id: '1',
        projectId: 'p',
        name: 'Ali',
        hireDate: '2026-08-01',
        leaveDate: '2026-08-10',
        active: true,
      );
      expect(
        AttendanceDisplay.resolve(
          person: person,
          date: '01.08.2026',
          recorded: AttendanceStatus.present,
        ),
        AttendanceStatus.giris,
      );
      expect(
        AttendanceDisplay.resolve(
          person: person,
          date: '10.08.2026',
          recorded: null,
        ),
        AttendanceStatus.cikis,
      );
      expect(
        AttendanceDisplay.resolve(
          person: person,
          date: '05.08.2026',
          recorded: AttendanceStatus.half,
        ),
        AttendanceStatus.half,
      );
      expect(
        AttendanceDisplay.employmentDatesLabel(person),
        'G:01.08.2026 · Ç:10.08.2026',
      );
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
        Person(id: 'u1', projectId: 'p', name: 'Ali', team: 'Demir'),
        Person(id: 'u2', projectId: 'p', name: 'Veli', team: 'Demir'),
        Person(id: 'u3', projectId: 'p', name: 'Ayşe', team: 'Kalıp'),
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

  group('Production', () {
    test('ilerleme günlük kayıtlardan hesaplanır', () {
      final job = Production(
        id: 'p1',
        projectId: 'pr',
        name: 'Kolon',
        plannedQty: 100,
        dailyEntries: [
          ProductionDayEntry(
            id: 'd1',
            date: '01.07.2026',
            ustaCount: 2,
            completedQty: 30,
          ),
          ProductionDayEntry(
            id: 'd2',
            date: '02.07.2026',
            ustaCount: 1,
            duzIsciCount: 2,
            completedQty: 70,
          ),
        ],
      );
      expect(job.completedQty, 100);
      expect(job.progressPct, 100);
      expect(job.isComplete, isTrue);
      expect(job.ustaCount, 3);
      expect(job.duzIsciCount, 2);
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

  group('PuantajReportBuilder', () {
    test('haftalık durum sütunlarını ve yok hariç genel toplamı üretir', () {
      const person = Person(
        id: 'u1',
        projectId: 'p',
        name: 'Ali',
        company: 'Firma',
      );
      final days = PuantajDate.weekDays('05.08.2026');
      final statuses = AttendanceStatus.values;
      final attendance = [
        for (var i = 0; i < statuses.length; i++)
          Attendance(
            id: 'a$i',
            projectId: 'p',
            personId: person.id,
            personName: person.name,
            date: days[i],
            status: statuses[i],
            hours: statuses[i].hours,
          ),
      ];

      final report = PuantajReportBuilder.build(
        projectName: 'Test',
        projectId: 'p',
        people: const [person],
        attendance: attendance,
        period: PuantajReportPeriod.weekly,
        anchorDate: '05.08.2026',
      );

      expect(
        report.headers.sublist(10),
        [
          'Mevcut',
          'Yarım Gün',
          'İzinli',
          'Raporlu',
          'Mazeret',
          'Res. Tatil',
          'Yok',
          'Genel Toplam',
        ],
      );
      expect(report.rows.single.sublist(10), [
        '1',
        '1',
        '1',
        '1',
        '1',
        '1',
        '1',
        '6',
      ]);
      expect(
        report.visual.companies.single.rows.single.statusCounts,
        [1, 1, 1, 1, 1, 1, 1],
      );
      expect(report.visual.companies.single.rows.single.totalLabel, '6');
    });
  });

  group('PuantajBackupPayload', () {
    test('parse geçerli yedek', () {
      final raw = jsonEncode({
        'format': puantajBackupFormatId,
        'version': 1,
        'exportedAt': '2026-07-27T12:00:00.000',
        'projects': [
          {'id': 'p1', 'name': 'Site A'},
        ],
        'personnel': [],
        'attendance': [],
        'productions': [],
        'professions': ['Usta'],
        'teams': ['Demir'],
      });
      final payload = PuantajBackupPayload.parse(raw);
      expect(payload.projects.length, 1);
      expect(payload.projects.first['name'], 'Site A');
      expect(payload.teams, ['Demir']);
    });

    test('yanlış format reddedilir', () {
      expect(
        () => PuantajBackupPayload.parse(
          jsonEncode({'format': 'other', 'version': 1}),
        ),
        throwsA(isA<PuantajBackupException>()),
      );
    });
  });
}
