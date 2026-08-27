import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_puantaj/core/utils/puantaj_date.dart';
import 'package:santijet_puantaj/data/services/puantaj_backup_service.dart';
import 'package:santijet_puantaj/data/services/puantaj_report_builder.dart';
import 'package:santijet_puantaj/domain/attendance/attendance_display.dart';
import 'package:santijet_puantaj/domain/entities/attendance.dart';
import 'package:santijet_puantaj/domain/entities/person.dart';
import 'package:santijet_puantaj/domain/entities/production.dart';
import 'package:santijet_puantaj/domain/entities/production_day_entry.dart';
import 'package:santijet_puantaj/domain/entities/uninsured_team_entry.dart';
import 'package:santijet_puantaj/domain/enums/attendance_status.dart';
import 'package:santijet_puantaj/domain/yevmiye/yevmiye_calculator.dart';
import 'dart:convert';

void main() {
  group('Person.isActiveOn', () {
    final base = Person(
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

    test('manuel active bayrağı istihdamı etkilemez', () {
      expect(base.copyWith(active: false).isActiveOn('05.08.2026'), isTrue);
    });

    test('örnek: 20 Temmuz çıkış — günlük/haftalık/aylık görünürlük', () {
      final person = Person(
        id: '1',
        projectId: 'p',
        name: 'Ali',
        hireDate: '2026-07-01',
        leaveDate: '2026-07-20',
        active: true,
      );

      // Günlük: çıkış gününe kadar
      expect(person.isActiveOn('20.07.2026'), isTrue);
      expect(person.isActiveOn('21.07.2026'), isFalse);

      // Haftalık: çıkış gününü içeren hafta evet; tamamen sonrası hayır
      final weekWithLeave = PuantajDate.weekDays('20.07.2026');
      expect(person.wasEmployedInPeriod(weekWithLeave), isTrue);
      final weekAfter = PuantajDate.weekDays('27.07.2026');
      expect(person.wasEmployedInPeriod(weekAfter), isFalse);

      // Aylık: çıkış yaptığı ay (Temmuz) evet; Ağustos hayır
      expect(
        person.wasEmployedInPeriod(PuantajDate.monthDays('15.07.2026')),
        isTrue,
      );
      expect(
        person.wasEmployedInPeriod(PuantajDate.monthDays('01.08.2026')),
        isFalse,
      );
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
      expect(AttendanceStatus.giris.countsInTeamHeadcount, isTrue);
      expect(AttendanceStatus.cikis.countsInTeamHeadcount, isTrue);
      expect(AttendanceStatus.present.countsInTeamHeadcount, isTrue);
      expect(AttendanceStatus.half.countsInTeamHeadcount, isTrue);
      expect(AttendanceStatus.absent.countsInTeamHeadcount, isFalse);
      expect(AttendanceStatus.giris.isEmploymentMarker, isTrue);
      expect(AttendanceStatus.cikis.short, 'Ç');
      expect(AttendanceStatus.giris.short, 'G');
    });
  });

  group('AttendanceDisplay', () {
    test('işe giriş / çıkış gününde G ve Ç', () {
      final person = Person(
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
        AttendanceDisplay.hireDateLine(person),
        'Giriş: 01.08.2026',
      );
      expect(
        AttendanceDisplay.leaveDateLine(person),
        'Çıkış: 10.08.2026',
      );
      expect(
        AttendanceDisplay.employmentDateLines(person),
        ['Giriş: 01.08.2026', 'Çıkış: 10.08.2026'],
      );
    });

    test('kayıtsız Pazar günü otomatik HT; manuel kayıt öncelikli', () {
      final person = Person(
        id: '1',
        projectId: 'p',
        name: 'Ali',
        hireDate: '2026-01-01',
      );
      // 02.08.2026 ve 09.08.2026 Pazar
      expect(
        AttendanceDisplay.resolve(
          person: person,
          date: '02.08.2026',
          recorded: null,
        ),
        AttendanceStatus.haftaTatili,
      );
      expect(
        AttendanceDisplay.resolve(
          person: person,
          date: '09.08.2026',
          recorded: null,
        ),
        AttendanceStatus.haftaTatili,
      );
      expect(
        AttendanceDisplay.resolve(
          person: person,
          date: '02.08.2026',
          recorded: AttendanceStatus.present,
        ),
        AttendanceStatus.present,
      );
      // 05.08.2026 Çarşamba — kayıt yoksa boş
      expect(
        AttendanceDisplay.resolve(
          person: person,
          date: '05.08.2026',
          recorded: null,
        ),
        isNull,
      );
    });
  });

  group('YevmiyeCalculator', () {
    test('mesai dahil adam-gün', () {
      final a = Attendance(
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
      final people = [
        Person(id: 'u1', projectId: 'p', name: 'Ali', team: 'Demir'),
        Person(id: 'u2', projectId: 'p', name: 'Veli', team: 'Demir'),
        Person(id: 'u3', projectId: 'p', name: 'Ayşe', team: 'Kalıp'),
      ];
      final att = [
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
      final person = Person(
        id: 'u1',
        projectId: 'p',
        name: 'Ali',
        company: 'Firma',
      );
      final days = PuantajDate.weekDays('05.08.2026');
      final statuses = [
        AttendanceStatus.present,
        AttendanceStatus.half,
        AttendanceStatus.izinli,
        AttendanceStatus.raporlu,
        AttendanceStatus.mazeret,
        AttendanceStatus.tatil,
        AttendanceStatus.absent,
      ];
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
        people: [person],
        attendance: attendance,
        period: PuantajReportPeriod.weekly,
        anchorDate: '05.08.2026',
      );

      expect(
        report.headers.sublist(12),
        [
          'Giriş',
          'Çıkış',
          'Mevcut',
          'Yarım Gün',
          'Yok',
          'İzinli',
          'Raporlu',
          'Mazeret',
          'Hafta Tatili',
          'Resmi Tatil',
          'Genel Toplam',
        ],
      );
      expect(report.rows.single.sublist(12), [
        '0',
        '0',
        '1',
        '1',
        '1',
        '1',
        '1',
        '1',
        '0',
        '1',
        '6',
      ]);
      expect(
        report.visual.companies.single.rows.single.statusCounts,
        [0, 0, 1, 1, 1, 1, 1, 1, 0, 1],
      );
      expect(report.visual.companies.single.rows.single.totalLabel, '6');
    });

    test('ekip günlük: Firma Adı + Ekip Adı + toplam; M/Y/G/Ç sayılır', () {
      final a = Person(
        id: '1',
        projectId: 'p',
        name: 'Burhan Alkan',
        company: 'Bsd İnşaat',
        team: 'Alçısıva',
      );
      final b = Person(
        id: '2',
        projectId: 'p',
        name: 'Ali',
        company: 'Bsd İnşaat',
        team: 'Alçısıva',
      );
      final c = Person(
        id: '3',
        projectId: 'p',
        name: 'Veli',
        company: 'Bsd İnşaat',
        team: 'Alçısıva',
      );
      final attendance = [
        Attendance(
          id: 'a1',
          projectId: 'p',
          personId: a.id,
          personName: a.name,
          date: '16.08.2026',
          status: AttendanceStatus.present,
          hours: 8,
        ),
        Attendance(
          id: 'a2',
          projectId: 'p',
          personId: b.id,
          personName: b.name,
          date: '16.08.2026',
          status: AttendanceStatus.giris,
          hours: 0,
        ),
        Attendance(
          id: 'a3',
          projectId: 'p',
          personId: c.id,
          personName: c.name,
          date: '16.08.2026',
          status: AttendanceStatus.absent,
          hours: 0,
        ),
      ];
      final report = PuantajReportBuilder.build(
        projectName: 'MOA',
        projectId: 'p',
        people: [a, b, c],
        attendance: attendance,
        period: PuantajReportPeriod.daily,
        anchorDate: '16.08.2026',
        layout: PuantajExportLayout.ekip,
        uninsuredTeams: [
          UninsuredTeamEntry(
            id: 's1',
            projectId: 'p',
            date: '16.08.2026',
            teamName: 'Kalıp',
            workerCount: 4,
            company: 'Demo Taşeron',
          ),
        ],
      );

      expect(report.plainTable, isTrue);
      expect(report.headers, [
        'Firma\nAdı',
        'Ekip\nAdı',
        'Adam.gün\n/gün',
        'Çalışılan\ngün',
        'Ortalama\nçalışan',
      ]);
      expect(report.rows, [
        ['Bsd İnşaat', 'Alçısıva', '2', '1', '2'],
        ['Demo Taşeron', 'Kalıp', '4', '1', '4'],
      ]);
    });
  });

  group('PuantajBackupPayload', () {
    test('parse geçerli yedek v1', () {
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
      expect(payload.tasks, isEmpty);
    });

    test('parse geçerli yedek v2 — tüm alanlar', () {
      final raw = jsonEncode({
        'format': puantajBackupFormatId,
        'version': 2,
        'exportedAt': '2026-07-27T12:00:00.000',
        'projects': [
          {'id': 'p1', 'name': 'Site A'},
        ],
        'personnel': [],
        'attendance': [],
        'productions': [],
        'professions': ['Usta'],
        'teams': ['Demir'],
        'tasks': [
          {'id': 't1', 'projectId': 'p1', 'title': 'Görev'},
        ],
        'dailyReports': [],
        'yevmiyeliIs': [],
        'uninsuredTeams': [],
        'taskCategories': ['Saha'],
      });
      final payload = PuantajBackupPayload.parse(raw);
      expect(payload.version, 2);
      expect(payload.tasks.length, 1);
      expect(payload.taskCategories, ['Saha']);
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
