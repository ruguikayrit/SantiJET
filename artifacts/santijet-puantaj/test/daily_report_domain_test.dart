import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_puantaj/data/services/irsaliye_material_ocr.dart';
import 'package:santijet_puantaj/data/services/weather_service.dart';
import 'package:santijet_puantaj/domain/daily_report/attendance_snapshot_builder.dart';
import 'package:santijet_puantaj/domain/daily_report/daily_report_copy.dart';
import 'package:santijet_puantaj/domain/entities/attendance.dart';
import 'package:santijet_puantaj/domain/entities/daily_report.dart';
import 'package:santijet_puantaj/domain/entities/person.dart';
import 'package:santijet_puantaj/domain/enums/attendance_status.dart';
import 'package:santijet_puantaj/domain/enums/photo_work_category.dart';

void main() {
  group('AttendanceSnapshotBuilder', () {
    test('mevcut / yarım / izin / yok ve adam-saat', () {
      final people = [
        Person(id: 'u1', projectId: 'p', name: 'Ali', team: 'A Ekibi'),
        Person(id: 'u2', projectId: 'p', name: 'Veli', team: 'B Ekibi'),
        Person(id: 'u3', projectId: 'p', name: 'Ayşe'),
        Person(id: 'u4', projectId: 'p', name: 'Can'),
      ];
      final att = [
        Attendance(
          id: 'a1',
          projectId: 'p',
          personId: 'u1',
          personName: 'Ali',
          date: '04.08.2026',
          status: AttendanceStatus.present,
          hours: 8,
          overtimeHours: 2,
        ),
        Attendance(
          id: 'a2',
          projectId: 'p',
          personId: 'u2',
          personName: 'Veli',
          date: '04.08.2026',
          status: AttendanceStatus.half,
          hours: 4,
        ),
        Attendance(
          id: 'a3',
          projectId: 'p',
          personId: 'u3',
          personName: 'Ayşe',
          date: '04.08.2026',
          status: AttendanceStatus.izinli,
          hours: 0,
        ),
      ];

      final snap = AttendanceSnapshotBuilder.build(
        projectId: 'p',
        date: '04.08.2026',
        attendance: att,
        activePeople: people,
      );

      expect(snap.present, 1);
      expect(snap.half, 1);
      expect(snap.leave, 1);
      expect(snap.absent, 1); // Can kayıtsız
      expect(snap.totalAdamSaat, 14); // 8+2+4
      expect(snap.totalYevmiye, 1.75); // 1.25 + 0.5
      expect(snap.people.length, 3);
      expect(
        snap.people.firstWhere((p) => p.personId == 'u1').team,
        'A Ekibi',
      );
    });

    test('çıkış tarihinden sonra rapor gününde personel listelenmez', () {
      final activePeople = [
        Person(
          id: 'u1',
          projectId: 'p',
          name: 'Ali',
          hireDate: '2026-01-01',
          leaveDate: '2026-08-10',
        ),
        Person(
          id: 'u2',
          projectId: 'p',
          name: 'Veli',
          hireDate: '2026-01-01',
        ),
      ];
      final att = [
        Attendance(
          id: 'a1',
          projectId: 'p',
          personId: 'u1',
          personName: 'Ali',
          date: '11.08.2026',
          status: AttendanceStatus.present,
          hours: 8,
        ),
        Attendance(
          id: 'a2',
          projectId: 'p',
          personId: 'u2',
          personName: 'Veli',
          date: '11.08.2026',
          status: AttendanceStatus.present,
          hours: 8,
        ),
      ];

      final snap = AttendanceSnapshotBuilder.build(
        projectId: 'p',
        date: '11.08.2026',
        attendance: att,
        activePeople: activePeople
            .where((p) => p.isActiveOn('11.08.2026'))
            .toList(),
      );

      expect(snap.people.length, 1);
      expect(snap.people.single.personId, 'u2');
      expect(snap.present, 1);
      expect(snap.absent, 0);
    });
  });

  group('DailyReport JSON', () {
    test('round-trip foto + weather', () {
      final report = DailyReport(
        id: 'dr1',
        projectId: 'p',
        date: '04.08.2026',
        workConstruction: 'Kazı',
        workElectrical: 'Pano bağlantısı',
        workMechanical: 'Klima altyapı',
        photos: const [
          DailyReportPhoto(
            id: 'ph1',
            dataBase64: 'YWJj',
            caption: 'Batı cephe',
            workCategory: PhotoWorkCategory.construction,
          ),
        ],
        outgoingMaterials: const [
          DailyReportMaterial(id: 'om1', name: 'Kalıp', quantity: '10', unit: 'adet'),
        ],
        vehicles: const [
          DailyReportMachine(id: 'v1', name: 'Pickup', plateOrId: '34 ABC 01'),
        ],
        weather: const DailyReportWeather(
          temperatureC: 28,
          nightTemperatureC: 18,
          humidityPercent: 45,
          description: 'Açık / güneşli',
          windKmh: 12,
          locationLabel: 'Ankara',
          synced: true,
        ),
      );
      final restored = DailyReport.fromJson(report.toJson());
      expect(restored.workConstruction, 'Kazı');
      expect(restored.workElectrical, 'Pano bağlantısı');
      expect(restored.workMechanical, 'Klima altyapı');
      expect(restored.hasWorkEntries, isTrue);
      expect(restored.workDone, contains('İNŞAAT İŞLERİ'));
      expect(restored.workDone, contains('Batı cephe'));
      expect(restored.photos.single.caption, 'Batı cephe');
      expect(restored.outgoingMaterials.single.name, 'Kalıp');
      expect(restored.vehicles.single.plateOrId, '34 ABC 01');
      expect(restored.weather?.temperatureC, 28);
      expect(restored.weather?.nightTemperatureC, 18);
      expect(restored.weather?.humidityPercent, 45);
    });

    test('eski workDone alanı inşaata taşınır', () {
      final restored = DailyReport.fromJson({
        'id': 'dr2',
        'projectId': 'p',
        'date': '04.08.2026',
        'workDone': 'Eski tek satır iş',
      });
      expect(restored.workConstruction, 'Eski tek satır iş');
      expect(restored.workElectrical, '');
      expect(restored.workMechanical, '');
    });

    test('manuel alana sızmış foto açıklamaları temizlenir', () {
      final restored = DailyReport.fromJson({
        'id': 'dr3',
        'projectId': 'p',
        'date': '04.08.2026',
        'workConstruction': 'İNŞAAT İŞLERİ:\nKazı\nBatı cephe',
        'photos': [
          const DailyReportPhoto(
            id: 'ph1',
            dataBase64: 'YWJj',
            caption: 'Batı cephe',
            workCategory: PhotoWorkCategory.construction,
          ).toJson(),
        ],
      });
      expect(restored.workConstruction, 'Kazı');
      expect(
        restored.syncedCaptionsFor(PhotoWorkCategory.construction),
        ['Batı cephe'],
      );
      expect(restored.effectiveWorkConstruction, 'Kazı\nBatı cephe');
    });
  });

  group('WeatherService descriptions', () {
    test('MGM hadise kodları', () {
      expect(WeatherService.hadiseDescription('AB'), 'Az bulutlu');
      expect(WeatherService.hadiseDescription('GSY'), contains('Gökgürültülü'));
      expect(WeatherService.hadiseDescription(''), 'Değişken');
    });

    test('WMO yedek kodları', () {
      expect(WeatherService.wmoDescription(0), contains('güneşli'));
      expect(WeatherService.wmoDescription(61), contains('Yağmur'));
      expect(WeatherService.wmoDescription(999), 'Değişken');
    });
  });

  group('IrsaliyeMaterialOcr.parseText', () {
    test('etiketli alanları okur', () {
      const raw = '''
TEDARİK TARİHİ: 27.07.2026
TEDARİKÇİ: BSD İNŞAAT LTD. ŞTİ.
ÜRÜN ADI: Çimento CEM I 42.5
MİKTAR: 120
BİRİM: kg
BİRİM FİYAT: 4.5
''';
      final r = IrsaliyeMaterialOcr.parseText(raw);
      expect(r.supplyDate, '27.07.2026');
      expect(r.supplier.toLowerCase(), contains('bsd'));
      expect(r.lines, isNotEmpty);
      expect(r.lines.first.name.toLowerCase(), contains('imento'));
      expect(r.lines.first.quantity, '120');
      expect(r.lines.first.unit.toLowerCase(), 'kg');
      expect(r.lines.first.price, '4.5');
    });
  });

  group('applyDailyReportCopyFromPrevious', () {
    test('makine ve vasıtayı yeni id ile kopyalar; hava/foto dokunulmaz', () {
      var seq = 0;
      String makeId(String prefix) => '$prefix-${++seq}';

      const source = DailyReport(
        id: 'src',
        projectId: 'p',
        date: '07.08.2026',
        workConstruction: 'Kazı',
        nextDayPlan: 'Kalıp',
        machines: [
          DailyReportMachine(
            id: 'mch-old',
            name: 'Forklift',
            company: 'SARAL',
            hoursWorked: 2,
          ),
        ],
        vehicles: [
          DailyReportMachine(
            id: 'veh-old',
            name: 'Otomobil',
            plateOrId: '06 DCR 205',
          ),
        ],
        photos: [
          DailyReportPhoto(
            id: 'ph1',
            dataBase64: 'x',
            caption: 'eski',
          ),
        ],
        weather: DailyReportWeather(
          temperatureC: 30,
          description: 'Açık',
          synced: true,
        ),
      );
      const target = DailyReport(
        id: 'tgt',
        projectId: 'p',
        date: '08.08.2026',
        workConstruction: 'eski metin',
      );

      final outcome = applyDailyReportCopyFromPrevious(
        target: target,
        source: source,
        fields: {
          DailyReportCopyField.machines,
          DailyReportCopyField.vehicles,
          DailyReportCopyField.workTexts,
          DailyReportCopyField.nextDayPlan,
        },
        makeId: makeId,
      );

      expect(outcome.result.machines, 1);
      expect(outcome.result.vehicles, 1);
      expect(outcome.result.workTexts, isTrue);
      expect(outcome.result.nextDayPlan, isTrue);
      expect(outcome.report.machines.single.id, 'mch-1');
      expect(outcome.report.machines.single.name, 'Forklift');
      expect(outcome.report.vehicles.single.id, 'veh-2');
      expect(outcome.report.workConstruction, 'Kazı');
      expect(outcome.report.nextDayPlan, 'Kalıp');
      expect(outcome.report.photos, isEmpty);
      expect(outcome.report.weather, isNull);
    });

    test('kaynak boşsa hedef listeleri silmez', () {
      const source = DailyReport(
        id: 'src',
        projectId: 'p',
        date: '07.08.2026',
      );
      const target = DailyReport(
        id: 'tgt',
        projectId: 'p',
        date: '08.08.2026',
        machines: [
          DailyReportMachine(id: 'keep', name: 'Vinç'),
        ],
      );

      final outcome = applyDailyReportCopyFromPrevious(
        target: target,
        source: source,
        fields: {DailyReportCopyField.machines},
      );

      expect(outcome.result.isEmpty, isTrue);
      expect(outcome.report.machines.single.id, 'keep');
    });
  });
}
