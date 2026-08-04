import '../entities/attendance.dart';
import '../entities/daily_report.dart';
import '../entities/person.dart';
import '../enums/attendance_status.dart';

/// Proje + gün için canlı puantaj özeti üretir.
abstract final class AttendanceSnapshotBuilder {
  static DailyReportAttendanceSnapshot build({
    required String projectId,
    required String date,
    required List<Attendance> attendance,
    required List<Person> activePeople,
    DateTime? capturedAt,
  }) {
    final day = attendance
        .where((a) => a.projectId == projectId && a.date == date)
        .toList();

    var present = 0;
    var half = 0;
    var leave = 0;
    var recordedAbsent = 0;
    var adamSaat = 0.0;
    var yevmiye = 0.0;

    final byPerson = <String, Attendance>{};
    for (final a in day) {
      byPerson[a.personId] = a;
      switch (a.status) {
        case AttendanceStatus.present:
          present++;
        case AttendanceStatus.half:
          half++;
        case AttendanceStatus.izinli:
        case AttendanceStatus.raporlu:
        case AttendanceStatus.mazeret:
        case AttendanceStatus.tatil:
          leave++;
        case AttendanceStatus.absent:
          recordedAbsent++;
      }
      adamSaat += a.hours + a.overtimeHours;
      yevmiye += a.yevmiye;
    }

    // Kaydı olmayan aktif personel → yok sayılır.
    final unrecorded = activePeople.where((p) => !byPerson.containsKey(p.id)).length;
    final absent = recordedAbsent + unrecorded;

    final teamById = {
      for (final p in activePeople) p.id: p.team.trim(),
    };

    final people = [
      for (final a in day)
        DailyReportAttendancePerson(
          personId: a.personId,
          personName: a.personName,
          team: teamById[a.personId] ?? '',
          status: a.status.label,
          hours: a.hours,
          overtimeHours: a.overtimeHours,
          yevmiye: a.yevmiye,
        ),
    ]..sort((a, b) => a.personName.compareTo(b.personName));

    return DailyReportAttendanceSnapshot(
      present: present,
      half: half,
      leave: leave,
      absent: absent,
      totalAdamSaat: adamSaat,
      totalYevmiye: yevmiye,
      people: people,
      capturedAt: capturedAt ?? DateTime.now(),
    );
  }
}
