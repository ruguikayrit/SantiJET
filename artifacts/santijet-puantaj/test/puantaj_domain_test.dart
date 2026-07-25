import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_puantaj/domain/enums/attendance_status.dart';
import 'package:santijet_puantaj/core/utils/puantaj_date.dart';

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
