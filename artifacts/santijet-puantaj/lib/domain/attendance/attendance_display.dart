import '../entities/person.dart';
import '../enums/attendance_status.dart';

/// Kayıtlı puantaj + personel giriş/çıkış tarihinden görünen durum.
abstract final class AttendanceDisplay {
  /// İşten çıkış günü → Ç, işe giriş günü → G; aksi halde kayıtlı durum.
  static AttendanceStatus? resolve({
    required Person? person,
    required String date,
    AttendanceStatus? recorded,
  }) {
    if (person != null) {
      final day = Person.parseEmploymentDate(date);
      if (day != null) {
        final leave = Person.parseEmploymentDate(person.leaveDate);
        if (leave != null &&
            leave.year == day.year &&
            leave.month == day.month &&
            leave.day == day.day) {
          return AttendanceStatus.cikis;
        }
        final hire = Person.parseEmploymentDate(person.hireDate);
        if (hire != null &&
            hire.year == day.year &&
            hire.month == day.month &&
            hire.day == day.day) {
          return AttendanceStatus.giris;
        }
      }
    }
    return recorded;
  }

  /// PDF / ekran için `G:dd.MM.yyyy · Ç:dd.MM.yyyy` (boş alanlar atlanır).
  static String employmentDatesLabel(Person person) {
    final hire = Person.parseEmploymentDate(person.hireDate);
    final leave = Person.parseEmploymentDate(person.leaveDate);
    final parts = <String>[];
    if (hire != null) {
      parts.add('G:${_fmt(hire)}');
    }
    if (leave != null) {
      parts.add('Ç:${_fmt(leave)}');
    }
    return parts.join(' · ');
  }

  static String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }
}
