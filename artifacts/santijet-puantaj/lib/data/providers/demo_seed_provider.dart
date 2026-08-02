import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_gen.dart';
import '../../core/utils/puantaj_date.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/production.dart';
import '../../domain/entities/production_day_entry.dart';
import '../../domain/entities/project.dart';
import '../../domain/enums/attendance_status.dart';
import 'app_data_provider.dart';
import 'catalog_provider.dart';
import 'production_provider.dart';
import 'verim_provider.dart';

/// Ayarlar → Demo: tüm özellikleri test etmeye yetecek örnek veri.
class DemoSeedController {
  DemoSeedController(this._ref);

  final Ref _ref;

  static const demoProjectName = 'Demo Şantiye';
  static const demoProjectCode = 'DEMO-001';

  Future<Project> loadAll() async {
    final project = _ensureProject();
    _ref.read(activeProjectIdProvider.notifier).set(project.id);

    _ensureTeams();
    final people = _replacePersonnel(project.id);
    _replaceAttendance(project: project, people: people);
    _replaceProductions(projectId: project.id);
    _ref.read(productionProvider.notifier).seedYearlyChartDemo(project.id);
    await _ref.read(verimProvider.notifier).syncFromCloud(demoFallback: true);
    return project;
  }

  Project _ensureProject() {
    final projects = _ref.read(projectsProvider);
    for (final p in projects) {
      if (p.name == demoProjectName || p.code == demoProjectCode) {
        return p;
      }
    }
    return _ref.read(projectsProvider.notifier).add(
          name: demoProjectName,
          code: demoProjectCode,
          company: 'Demo İnşaat A.Ş.',
        );
  }

  void _ensureTeams() {
    final teams = _ref.read(teamsProvider.notifier);
    for (final t in const ['Demir', 'Demo Ekip', 'Kalıp']) {
      teams.add(t);
    }
  }

  List<Person> _replacePersonnel(String projectId) {
    final personnel = _ref.read(personnelProvider.notifier);
    personnel.deleteForProject(projectId);

    const specs = <({
      String name,
      String profession,
      String team,
      String company,
    })>[
      (
        name: 'Ahmet Usta',
        profession: 'Demirci Usta',
        team: 'Demir',
        company: 'Tiryaki İnşaat',
      ),
      (
        name: 'Mehmet Çırak',
        profession: 'Demirci',
        team: 'Demir',
        company: 'Tiryaki İnşaat',
      ),
      (
        name: 'Ali İşçi',
        profession: 'Saha Düz İşçi',
        team: 'Demir',
        company: 'Tiryaki İnşaat',
      ),
      (
        name: 'Sinan Çakır',
        profession: 'Teknik Ofis Mühendisi',
        team: 'Demo Ekip',
        company: 'Tiryaki İnşaat',
      ),
      (
        name: 'Can Demir',
        profession: 'Kalıpçı Usta',
        team: 'Demo Ekip',
        company: 'Demo Taşeron',
      ),
      (
        name: 'Burak Yılmaz',
        profession: 'Kalıpçı',
        team: 'Demo Ekip',
        company: 'Demo Taşeron',
      ),
      (
        name: 'Emre Kaya',
        profession: 'Saha Düz İşçi',
        team: 'Kalıp',
        company: 'Demo Taşeron',
      ),
      (
        name: 'Hasan Öz',
        profession: 'Saha Düz İşçi',
        team: 'Kalıp',
        company: 'Demo Taşeron',
      ),
    ];

    final created = <Person>[];
    for (final s in specs) {
      created.add(
        personnel.add(
          Person(
            id: '',
            projectId: projectId,
            name: s.name,
            profession: s.profession,
            team: s.team,
            company: s.company,
          ),
        ),
      );
    }
    return created;
  }

  void _replaceAttendance({
    required Project project,
    required List<Person> people,
  }) {
    final attendance = _ref.read(attendanceProvider.notifier);
    attendance.deleteForProject(project.id);

    final today = DateTime.now();
    final dates = <String>[];
    for (var i = 13; i >= 0; i--) {
      final d = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      if (d.weekday > DateTime.friday) continue;
      dates.add(PuantajDate.format(d));
    }
    if (dates.isEmpty) dates.add(PuantajDate.today());

    for (var di = 0; di < dates.length; di++) {
      final date = dates[di];
      for (var pi = 0; pi < people.length; pi++) {
        final person = people[pi];
        final status = switch ((di + pi) % 7) {
          0 || 1 || 2 || 3 => AttendanceStatus.present,
          4 => AttendanceStatus.half,
          5 => AttendanceStatus.izinli,
          _ => AttendanceStatus.present,
        };
        attendance.setStatus(
          projectId: project.id,
          person: person,
          date: date,
          status: status,
        );
        if (status == AttendanceStatus.present && (pi % 3 == 0)) {
          attendance.setOvertime(
            projectId: project.id,
            person: person,
            date: date,
            overtimeHours: 1.0 + (pi % 2) * 0.5,
          );
        }
      }
    }
  }

  void _replaceProductions({required String projectId}) {
    final production = _ref.read(productionProvider.notifier);
    production.deleteForProject(projectId);

    final today = DateTime.now();
    String day(int offset) => PuantajDate.format(
          DateTime(today.year, today.month, today.day)
              .subtract(Duration(days: offset)),
        );

    production.add(
      Production(
        id: '',
        projectId: projectId,
        name: 'Kolon Demiri',
        floor: 'Bodrum Kat',
        section: '1. Kısım',
        teamName: 'Demir',
        unit: 'ton',
        plannedQty: 20,
        plannedDays: 7,
        note: '[DEMO] Kolon demiri',
        dailyEntries: [
          ProductionDayEntry(
            id: IdGen.make('prd'),
            date: day(2),
            ustaCount: 4,
            duzIsciCount: 0,
            completedQty: 5,
          ),
        ],
      ),
    );
    production.add(
      Production(
        id: '',
        projectId: projectId,
        name: 'Kiriş Demiri',
        floor: 'Bodrum Kat',
        section: '2. Kısım',
        teamName: 'Demir',
        unit: 'ton',
        plannedQty: 15,
        plannedDays: 10,
        note: '[DEMO] Kiriş demiri',
        dailyEntries: [
          ProductionDayEntry(
            id: IdGen.make('prd'),
            date: day(1),
            ustaCount: 3,
            duzIsciCount: 1,
            completedQty: 2.5,
          ),
        ],
      ),
    );
    production.add(
      Production(
        id: '',
        projectId: projectId,
        name: 'Temel Demiri',
        floor: 'Temel',
        section: 'A Blok',
        teamName: 'Demo Ekip',
        unit: 'ton',
        plannedQty: 40,
        plannedDays: 14,
        note: '[DEMO] Temel demiri',
        dailyEntries: [
          ProductionDayEntry(
            id: IdGen.make('prd'),
            date: day(3),
            ustaCount: 5,
            duzIsciCount: 2,
            completedQty: 8,
          ),
          ProductionDayEntry(
            id: IdGen.make('prd'),
            date: day(0),
            ustaCount: 4,
            duzIsciCount: 2,
            completedQty: 6,
          ),
        ],
      ),
    );
  }
}

final demoSeedControllerProvider = Provider<DemoSeedController>((ref) {
  return DemoSeedController(ref);
});
