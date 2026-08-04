import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_puantaj/data/services/irsaliye_material_ocr.dart';
import 'package:santijet_puantaj/data/services/weather_service.dart';
import 'package:santijet_puantaj/domain/daily_report/attendance_snapshot_builder.dart';
import 'package:santijet_puantaj/domain/entities/attendance.dart';
import 'package:santijet_puantaj/domain/entities/daily_report.dart';
import 'package:santijet_puantaj/domain/entities/person.dart';
import 'package:santijet_puantaj/domain/enums/attendance_status.dart';

void main() {
  group('AttendanceSnapshotBuilder', () {
    test('mevcut / yarım / izin / yok ve adam-saat', () {
      const people = [
        Person(id: 'u1', projectId: 'p', name: 'Ali'),
        Person(id: 'u2', projectId: 'p', name: 'Veli'),
        Person(id: 'u3', projectId: 'p', name: 'Ayşe'),
        Person(id: 'u4', projectId: 'p', name: 'Can'),
      ];
      const att = [
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
          ),
        ],
        weather: const DailyReportWeather(
          temperatureC: 28,
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
      expect(restored.photos.single.caption, 'Batı cephe');
      expect(restored.weather?.temperatureC, 28);
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
  });

  group('WeatherService.wmoDescription', () {
    test('bilinen kodlar', () {
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
}
