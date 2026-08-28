import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_gen.dart';
import '../../core/utils/puantaj_date.dart';
import '../../domain/catalogs/task_categories.dart';
import '../../domain/catalogs/task_tags.dart';
import '../../domain/entities/company_info.dart';
import '../../domain/entities/daily_report.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/production.dart';
import '../../domain/entities/production_day_entry.dart';
import '../../domain/entities/project.dart';
import '../../domain/enums/attendance_status.dart';
import '../../domain/enums/photo_work_category.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/daily_report/attendance_snapshot_builder.dart';
import 'app_data_provider.dart';
import 'catalog_provider.dart';
import 'company_provider.dart';
import 'daily_report_provider.dart';
import 'plan_cloud_sync_provider.dart';
import 'production_provider.dart';
import 'tasks_provider.dart';
import 'uninsured_teams_provider.dart';
import 'yevmiyeli_is_provider.dart';

/// Ayarlar → Demo: puantaj, imalat, verim, görev, rapor ve yevmiyeli dahil
/// tüm modülleri test etmeye yetecek örnek veri.
class DemoSeedController {
  DemoSeedController(this._ref);

  final Ref _ref;

  static const demoProjectName = 'Demo Şantiye';
  static const demoProjectCode = 'DEMO-001';

  /// Mevcut demo projesini temizleyip baştan yükler.
  Future<Project> loadAll() async {
    final existing = _findDemoProject();
    if (existing != null) {
      _clearProjectData(existing.id);
    }

    final project = _ensureProject();
    _ref.read(activeProjectIdProvider.notifier).set(project.id);

    _seedCompanyInfo();
    _ensureTeams();
    final people = _replacePersonnel(project.id);
    _replaceAttendance(project: project, people: people);
    _replaceUninsuredTeams(projectId: project.id);
    _replaceProductions(projectId: project.id);
    _replaceDailyReports(projectId: project.id);
    _replaceYevmiyeli(projectId: project.id, people: people);
    _replaceTasks(projectId: project.id, people: people);
    _ref.read(productionProvider.notifier).seedYearlyChartDemo(project.id);
    await _ref.read(planCloudSyncControllerProvider).syncDemoForProject(
          projectId: project.id,
          projectName: project.name,
        );
    _seedTodayAttendanceShowcase(project: project, people: people);
    _syncReportSnapshots(projectId: project.id);
    return project;
  }

  /// 1×1 şeffaf PNG — rapor foto örneği (base64).
  static const demoPhotoBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  Project? _findDemoProject() {
    for (final p in _ref.read(projectsProvider)) {
      if (p.name == demoProjectName || p.code == demoProjectCode) return p;
    }
    return null;
  }

  void _clearProjectData(String projectId) {
    _ref.read(personnelProvider.notifier).deleteForProject(projectId);
    _ref.read(attendanceProvider.notifier).deleteForProject(projectId);
    _ref.read(productionProvider.notifier).deleteForProject(projectId);
    _ref.read(productionProvider.notifier).removeYearlyChartDemo(projectId);
    _ref.read(tasksProvider.notifier).deleteForProject(projectId);
    _ref.read(dailyReportsProvider.notifier).deleteForProject(projectId);
    _ref.read(yevmiyeliIsProvider.notifier).deleteForProject(projectId);
    _ref.read(uninsuredTeamsProvider.notifier).deleteForProject(projectId);
    _ref.read(planCloudSyncControllerProvider).clearProjectCaches(projectId);
  }

  Project _ensureProject() {
    final existing = _findDemoProject();
    if (existing != null) return existing;
    return _ref.read(projectsProvider.notifier).add(
          name: demoProjectName,
          code: demoProjectCode,
          company: 'Demo İnşaat A.Ş.',
        );
  }

  void _seedCompanyInfo() {
    _ref.read(companyInfoProvider.notifier).replace(
          const CompanyInfo(
            name: 'Demo İnşaat A.Ş.',
            taxNo: '1234567890',
            address: 'Maslak Mah. Demo Cad. No:1, Sarıyer / İstanbul',
            email: 'demo@santijet.app',
            phone: '+90 212 000 00 00',
          ),
        );
  }

  void _ensureTeams() {
    final teams = _ref.read(teamsProvider.notifier);
    for (final t in const [
      'Demir',
      'Demo Ekip',
      'Kalıp',
      'Mekanik',
      'Ofis',
    ]) {
      teams.add(t);
    }
    final categories = _ref.read(taskCategoriesProvider.notifier);
    for (final c in TaskCategoryCatalog.defaults) {
      categories.add(c);
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
        name: 'Uğur Tiryaki',
        profession: 'Şantiye Şefi',
        team: 'Ofis',
        company: 'Demo İnşaat A.Ş.',
      ),
      (
        name: 'Sinan Çakır',
        profession: 'Teknik Ofis Mühendisi',
        team: 'Ofis',
        company: 'Demo İnşaat A.Ş.',
      ),
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
      (
        name: 'Murat Elektrik',
        profession: 'Elektrik Usta',
        team: 'Mekanik',
        company: 'Elektrik Taşeron',
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

    final dates = _recentWeekdays(count: 20);
    for (var di = 0; di < dates.length; di++) {
      final date = dates[di];
      for (var pi = 0; pi < people.length; pi++) {
        final person = people[pi];
        final status = switch ((di + pi) % 12) {
          0 || 1 || 2 => AttendanceStatus.present,
          3 => AttendanceStatus.half,
          4 => AttendanceStatus.giris,
          5 => AttendanceStatus.cikis,
          6 => AttendanceStatus.izinli,
          7 => AttendanceStatus.raporlu,
          8 => AttendanceStatus.mazeret,
          9 => AttendanceStatus.haftaTatili,
          10 => AttendanceStatus.tatil,
          _ => AttendanceStatus.absent,
        };
        if (status == AttendanceStatus.absent) continue;
        attendance.setStatus(
          projectId: project.id,
          person: person,
          date: date,
          status: status,
        );
        if (status == AttendanceStatus.present && pi.isEven) {
          attendance.setOvertime(
            projectId: project.id,
            person: person,
            date: date,
            overtimeHours: 1.0 + (pi % 3) * 0.5,
          );
        }
      }
    }
  }

  void _replaceUninsuredTeams({required String projectId}) {
    final teams = _ref.read(uninsuredTeamsProvider.notifier);
    teams.deleteForProject(projectId);

    final dates = _recentWeekdays(count: 5);
    for (final date in dates) {
      teams.add(
        projectId: projectId,
        date: date,
        teamName: 'Dış Demir Ekibi',
        workerCount: 4 + dates.indexOf(date),
        company: 'Demo Taşeron',
      );
      if (dates.indexOf(date).isEven) {
        teams.add(
          projectId: projectId,
          date: date,
          teamName: 'Boyama Ekibi',
          workerCount: 3,
          company: 'Boya Taşeron',
        );
      }
    }
  }

  void _replaceProductions({required String projectId}) {
    final production = _ref.read(productionProvider.notifier);
    production.deleteForProject(projectId);

    ProductionDayEntry entry(
      int dayOffset, {
      required double qty,
      double usta = 3,
      double duz = 1,
    }) {
      return ProductionDayEntry(
        id: IdGen.make('prd'),
        date: _pastDay(dayOffset),
        ustaCount: usta,
        duzIsciCount: duz,
        completedQty: qty,
      );
    }

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
        plannedLabor: 6,
        note: '[DEMO] Kolon demiri',
        dailyEntries: [
          entry(12, qty: 4),
          entry(8, qty: 3.5),
          entry(3, qty: 5),
          entry(1, qty: 2),
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
        plannedLabor: 4,
        note: '[DEMO] Kiriş demiri',
        dailyEntries: [
          entry(10, qty: 2),
          entry(5, qty: 2.5),
          entry(2, qty: 1.5),
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
        plannedLabor: 8,
        note: '[DEMO] Temel demiri',
        dailyEntries: [
          entry(14, qty: 6),
          entry(7, qty: 8),
          entry(4, qty: 5),
          entry(0, qty: 6),
        ],
      ),
    );
    production.add(
      Production(
        id: '',
        projectId: projectId,
        name: 'Alçı Sıva',
        floor: 'Zemin Kat',
        section: 'Koridor',
        teamName: 'Kalıp',
        unit: 'm²',
        plannedQty: 850,
        plannedDays: 12,
        plannedLabor: 5,
        note: '[DEMO] Alçı sıva',
        dailyEntries: [
          entry(6, qty: 120, usta: 2, duz: 3),
          entry(2, qty: 95, usta: 2, duz: 2),
        ],
      ),
    );
    production.add(
      Production(
        id: '',
        projectId: projectId,
        name: 'Perde Betonu',
        floor: 'Bodrum Kat',
        section: 'Perde A',
        teamName: 'Demo Ekip',
        unit: 'm³',
        plannedQty: 180,
        plannedDays: 5,
        plannedLabor: 10,
        note: '[DEMO] Bekleyen — henüz günlük kayıt yok',
        dailyEntries: const [],
      ),
    );
    production.add(
      Production(
        id: '',
        projectId: projectId,
        name: 'Asansör Boşluğu Kalıbı',
        floor: 'Zemin Kat',
        section: 'Çekirdek',
        teamName: 'Kalıp',
        unit: 'm²',
        plannedQty: 120,
        plannedDays: 4,
        plannedLabor: 6,
        note: '[DEMO] Tamamlanan imalat',
        dailyEntries: [
          entry(8, qty: 40, usta: 3, duz: 2),
          entry(5, qty: 35, usta: 3, duz: 2),
          entry(2, qty: 45, usta: 2, duz: 3),
        ],
      ),
    );
  }

  void _replaceDailyReports({required String projectId}) {
    final reports = _ref.read(dailyReportsProvider.notifier);
    reports.deleteForProject(projectId);

    final dates = _recentWeekdays(count: 8);
    for (var i = 0; i < dates.length; i++) {
      final date = dates[i];
      final now = DateTime.now();
      final photoId = IdGen.make('pho');
      reports.upsert(
        DailyReport(
          id: IdGen.make('drp'),
          projectId: projectId,
          date: date,
          workConstruction: switch (i % 3) {
            0 =>
              'Temel perde betonu hazırlığı tamamlandı.\nKolon demiri montajı devam ediyor.',
            1 => 'Alçı sıva uygulaması koridor bölümünde sürüyor.',
            _ => 'Kiriş demiri bağlama işleri 2. kısımda tamamlandı.',
          },
          workElectrical:
              'Zemin kat aydınlatma kablo çekimi (${i + 1}. hat).',
          workMechanical: i.isEven ? 'Havalandırma kanalı montajına başlandı.' : '',
          planConstruction:
              'Demir ekibi kolon imalatına devam · Kalıp ekibi alçı sıva.',
          planElectrical: i.isOdd ? 'Zemin kat aydınlatma devam.' : '',
          planMechanical: i.isEven ? 'Mekanik kanal devam.' : '',
          incomingMaterials: [
            DailyReportMaterial(
              id: IdGen.make('mat'),
              name: 'Nervürlü demir Ø16',
              quantity: '${12 + i * 2}',
              unit: 'ton',
              supplierOrOrder: 'Tiryaki Demir',
              supplyDate: date,
            ),
            if (i.isEven)
              DailyReportMaterial(
                id: IdGen.make('mat'),
                name: 'Alçı sıva',
                quantity: '${40 + i * 5}',
                unit: 'torba',
                supplierOrOrder: 'Yapı Market',
                supplyDate: date,
              ),
          ],
          outgoingMaterials: [
            if (i >= 2)
              DailyReportMaterial(
                id: IdGen.make('out'),
                name: 'Kırık beton moloz',
                quantity: '${6 + i}',
                unit: 'm³',
                supplierOrOrder: 'Saha sevkiyat',
                supplyDate: date,
                note: 'Hafriyat alanına',
              ),
          ],
          orderedMaterials: [
            DailyReportMaterial(
              id: IdGen.make('ord'),
              name: 'Epoksi zemin kaplama',
              quantity: '120',
              unit: 'kg',
              supplierOrOrder: 'Boya Taşeron',
              supplyDate: _day(-2 + i),
              purchaseApproved: i.isOdd,
            ),
          ],
          machines: [
            DailyReportMachine(
              id: IdGen.make('mac'),
              name: 'Mini vinç',
              workDescription: 'Demir montaj desteği',
              hoursWorked: (6 + i).toDouble(),
              company: 'Demo Vinç',
              operatorName: 'Operatör A.',
            ),
          ],
          vehicles: [
            if (i.isEven)
              DailyReportMachine(
                id: IdGen.make('veh'),
                name: 'Kamyonet',
                type: 'Vasıta',
                plateOrId: '34 DEMO ${10 + i}',
                hoursWorked: 4 + i.toDouble(),
                workDescription: 'Malzeme sevkiyatı',
                operatorName: 'Sürücü B.',
              ),
          ],
          photos: i >= dates.length - 2
              ? [
                  DailyReportPhoto(
                    id: photoId,
                    dataBase64: demoPhotoBase64,
                    caption: 'Kolon demiri montaj görüntüsü',
                    workCategory: PhotoWorkCategory.construction,
                    createdAt: now,
                  ),
                  DailyReportPhoto(
                    id: IdGen.make('pho'),
                    dataBase64: demoPhotoBase64,
                    caption: 'Kablo hattı çekim alanı',
                    workCategory: PhotoWorkCategory.electrical,
                    createdAt: now,
                  ),
                ]
              : const [],
          weather: DailyReportWeather(
            temperatureC: 24 + i.toDouble(),
            nightTemperatureC: 16 + i.toDouble(),
            humidityPercent: (55 + i * 2).toDouble(),
            maxHumidityPercent: (70 + i).toDouble(),
            description: switch (i % 3) {
              0 => 'Az bulutlu',
              1 => 'Parçalı bulutlu',
              _ => 'Açık',
            },
            windKmh: (12 + i * 2).toDouble(),
            windGustKmh: (18 + i * 2).toDouble(),
            locationLabel: 'Demo Şantiye · İstanbul',
            fetchedAt: now,
            synced: true,
            isManual: false,
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  void _seedTodayAttendanceShowcase({
    required Project project,
    required List<Person> people,
  }) {
    if (people.isEmpty) return;
    final today = PuantajDate.today();
    final attendance = _ref.read(attendanceProvider.notifier);
    final statuses = [
      AttendanceStatus.present,
      AttendanceStatus.present,
      AttendanceStatus.half,
      AttendanceStatus.giris,
      AttendanceStatus.raporlu,
      AttendanceStatus.izinli,
      AttendanceStatus.mazeret,
      AttendanceStatus.present,
      AttendanceStatus.half,
      AttendanceStatus.cikis,
    ];
    for (var i = 0; i < people.length; i++) {
      attendance.setStatus(
        projectId: project.id,
        person: people[i],
        date: today,
        status: statuses[i % statuses.length],
      );
      if (statuses[i % statuses.length] == AttendanceStatus.present) {
        attendance.setOvertime(
          projectId: project.id,
          person: people[i],
          date: today,
          overtimeHours: 1.5,
        );
      }
    }
  }

  void _syncReportSnapshots({required String projectId}) {
    final reports = _ref
        .read(dailyReportsProvider)
        .where((r) => r.projectId == projectId)
        .toList();
    final people = _ref
        .read(personnelProvider)
        .where((p) => p.projectId == projectId)
        .toList();
    final attendance = _ref.read(attendanceProvider);
    final teams = _ref.read(uninsuredTeamsProvider);
    final notifier = _ref.read(dailyReportsProvider.notifier);

    for (final report in reports) {
      final snap = AttendanceSnapshotBuilder.build(
        projectId: projectId,
        date: report.date,
        attendance: attendance,
        activePeople:
            people.where((p) => p.isActiveOn(report.date)).toList(),
        teams: teams,
      );
      notifier.upsert(report.copyWith(attendanceSnapshot: snap));
    }
  }

  void _replaceYevmiyeli({
    required String projectId,
    required List<Person> people,
  }) {
    final yevmiyeli = _ref.read(yevmiyeliIsProvider.notifier);
    yevmiyeli.deleteForProject(projectId);

    Person? byName(String name) {
      for (final p in people) {
        if (p.name == name) return p;
      }
      return null;
    }

    final specs = [
      (
        person: byName('Can Demir'),
        day: 1,
        work: 'Dış cephe iskele kurulumu',
        yevmiye: 1.0,
      ),
      (
        person: byName('Burak Yılmaz'),
        day: 1,
        work: 'Kalıp söküm destek',
        yevmiye: 0.5,
      ),
      (
        person: byName('Emre Kaya'),
        day: 3,
        work: 'Zemin temizlik ve hazırlık',
        yevmiye: 1.0,
      ),
      (
        person: byName('Hasan Öz'),
        day: 0,
        work: 'Malzeme taşıma ve saha düzeni',
        yevmiye: 1.5,
      ),
    ];

    for (final s in specs) {
      final person = s.person;
      if (person == null) continue;
      yevmiyeli.addFromPerson(
        projectId: projectId,
        date: _pastDay(s.day),
        person: person,
        workDescription: s.work,
        yevmiyeCount: s.yevmiye,
        note: '[DEMO]',
      );
    }
  }

  void _replaceTasks({
    required String projectId,
    required List<Person> people,
  }) {
    final tasks = _ref.read(tasksProvider.notifier);
    tasks.deleteForProject(projectId);

    Person? byName(String name) {
      for (final p in people) {
        if (p.name == name) return p;
      }
      return null;
    }

    final assigner = byName('Uğur Tiryaki');
    if (assigner == null) return;

    const taskSpecs = <({
      String title,
      String category,
      String tag,
      String assigneeName,
      int dueOffset,
      TaskStatus status,
      String description,
    })>[
      (
        title: 'Epoksi malzemesi siparişi',
        category: 'Satın Alma',
        tag: TaskTagCatalog.insaat,
        assigneeName: 'Sinan Çakır',
        dueOffset: 2,
        status: TaskStatus.todo,
        description: 'Zemin kat epoksi için 120 kg set.',
      ),
      (
        title: 'Havalandırma kanalı tedarik',
        category: 'Satın Alma',
        tag: TaskTagCatalog.mekanik,
        assigneeName: 'Murat Elektrik',
        dueOffset: 5,
        status: TaskStatus.todo,
        description: 'Mekanik taşeron için SPIR kanal.',
      ),
      (
        title: 'Epoksi öncesi duvar hazırlık',
        category: 'Saha',
        tag: TaskTagCatalog.insaat,
        assigneeName: 'Can Demir',
        dueOffset: 0,
        status: TaskStatus.doing,
        description: 'Yüzey zımpara ve astar kontrolü.',
      ),
      (
        title: 'Liftlerin zımpara ve boyası',
        category: 'Saha',
        tag: TaskTagCatalog.insaat,
        assigneeName: 'Burak Yılmaz',
        dueOffset: -1,
        status: TaskStatus.todo,
        description: 'Asansör kabini yüzey hazırlığı.',
      ),
      (
        title: '25 cm rulo uygulama',
        category: 'Saha',
        tag: TaskTagCatalog.insaat,
        assigneeName: 'Emre Kaya',
        dueOffset: 1,
        status: TaskStatus.todo,
        description: 'Çatı izolasyon rulo serimi.',
      ),
      (
        title: 'Haftalık ilerleme raporu',
        category: 'Ofis',
        tag: '',
        assigneeName: 'Sinan Çakır',
        dueOffset: 4,
        status: TaskStatus.todo,
        description: 'İşverene haftalık PDF gönderimi.',
      ),
      (
        title: 'Alt yüklenici koordinasyon',
        category: 'Görüşme',
        tag: '',
        assigneeName: 'Uğur Tiryaki',
        dueOffset: 6,
        status: TaskStatus.todo,
        description: 'Demo Taşeron ile plan uyumu.',
      ),
      (
        title: 'Havalandırma tesisatı montaj',
        category: 'Saha',
        tag: TaskTagCatalog.mekanik,
        assigneeName: 'Murat Elektrik',
        dueOffset: 7,
        status: TaskStatus.todo,
        description: 'Bodrum kanal bağlantıları.',
      ),
      (
        title: 'Temel kalıp sökümü',
        category: 'Saha',
        tag: TaskTagCatalog.insaat,
        assigneeName: 'Can Demir',
        dueOffset: -3,
        status: TaskStatus.done,
        description: '[DEMO] Tamamlanan örnek görev.',
      ),
      (
        title: 'Zemin kat aydınlatma tesisatı',
        category: 'Saha',
        tag: TaskTagCatalog.elektrik,
        assigneeName: 'Murat Elektrik',
        dueOffset: 3,
        status: TaskStatus.todo,
        description: 'Bodrum koridor armatür ve hat çekimi.',
      ),
    ];

    for (final spec in taskSpecs) {
      final assignee = byName(spec.assigneeName);
      if (assignee == null) continue;
      tasks.add(
        projectId: projectId,
        title: spec.title,
        assigner: assigner,
        assignee: assignee,
        description: spec.description,
        category: spec.category,
        tag: spec.tag,
        dueDate: _day(spec.dueOffset),
        status: spec.status,
      );
    }
  }

  List<String> _recentWeekdays({required int count}) {
    final today = DateTime.now();
    final anchor = DateTime(today.year, today.month, today.day);
    final dates = <String>[];
    var cursor = anchor;
    while (dates.length < count) {
      if (cursor.weekday <= DateTime.friday) {
        dates.add(PuantajDate.format(cursor));
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return dates.reversed.toList();
  }

  /// [offsetFromToday]: 0 = bugün, -1 = dün, 2 = 2 gün sonra.
  String _day(int offsetFromToday) {
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day)
        .add(Duration(days: offsetFromToday));
    return PuantajDate.format(d);
  }

  /// Geçmiş gün — imalat kayıtları için (0 = bugün, 1 = dün).
  String _pastDay(int daysAgo) => _day(-daysAgo);
}

final demoSeedControllerProvider = Provider<DemoSeedController>((ref) {
  return DemoSeedController(ref);
});
