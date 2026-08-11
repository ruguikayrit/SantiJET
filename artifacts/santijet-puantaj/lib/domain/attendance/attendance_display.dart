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

  /// İşe giriş satırı — örn. `Giriş: 07.04.2026` (yoksa boş).
  static String hireDateLine(Person person) {
    final hire = Person.parseEmploymentDate(person.hireDate);
    return hire == null ? '' : 'Giriş: ${_fmt(hire)}';
  }

  /// İşten çıkış satırı — örn. `Çıkış: 20.07.2026` (yoksa boş).
  static String leaveDateLine(Person person) {
    final leave = Person.parseEmploymentDate(person.leaveDate);
    return leave == null ? '' : 'Çıkış: ${_fmt(leave)}';
  }

  /// İsim altı satırlar: giriş, ardından çıkış (boş olanlar atlanır).
  static List<String> employmentDateLines(Person person) {
    return [
      for (final line in [hireDateLine(person), leaveDateLine(person)])
        if (line.isNotEmpty) line,
    ];
  }

  static String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }
}
