import '../attendance/attendance_display.dart';
import '../entities/attendance.dart';
import '../entities/daily_report.dart';
import '../entities/person.dart';
import '../enums/attendance_status.dart';
import '../permissions/role_degree.dart';

/// Proje + gün için canlı puantaj özeti üretir (puantaj ekranı ile aynı durum kuralları).
abstract final class AttendanceSnapshotBuilder {
  static DailyReportAttendanceSnapshot build({
    required String projectId,
    required String date,
    required List<Attendance> attendance,
    required List<Person> activePeople,
    DateTime? capturedAt,
  }) {
    final byPerson = <String, Attendance>{};
    for (final a in attendance) {
      if (a.projectId == projectId && a.date == date) {
        byPerson[a.personId] = a;
      }
    }

    final counts = <AttendanceStatus, int>{
      for (final s in AttendanceStatus.values) s: 0,
    };
    var unrecorded = 0;
    var adamSaat = 0.0;
    var yevmiye = 0.0;
    final people = <DailyReportAttendancePerson>[];

    for (final p in activePeople) {
      final a = byPerson[p.id];
      final status = AttendanceDisplay.resolve(
        person: p,
        date: date,
        recorded: a?.status,
      );

      if (status == null) {
        unrecorded++;
        people.add(
          DailyReportAttendancePerson(
            personId: p.id,
            personName: p.name,
            team: p.team.trim(),
            profession: p.profession.trim(),
            status: 'Girilmedi',
            hours: 0,
          ),
        );
        continue;
      }

      counts[status] = (counts[status] ?? 0) + 1;
      final hours = a?.hours ?? status.hours;
      final overtime = a?.overtimeHours ?? 0.0;
      adamSaat += hours + overtime;
      yevmiye += (hours + overtime) / 8.0;

      people.add(
        DailyReportAttendancePerson(
          personId: p.id,
          personName: p.name,
          team: p.team.trim(),
          profession: p.profession.trim(),
          status: status.label,
          hours: hours,
          overtimeHours: overtime,
          yevmiye: (hours + overtime) / 8.0,
        ),
      );
    }

    people.sort(compareByRoleRank);

    final leave = (counts[AttendanceStatus.izinli] ?? 0) +
        (counts[AttendanceStatus.raporlu] ?? 0) +
        (counts[AttendanceStatus.mazeret] ?? 0) +
        (counts[AttendanceStatus.tatil] ?? 0) +
        (counts[AttendanceStatus.haftaTatili] ?? 0);

    return DailyReportAttendanceSnapshot(
      present: counts[AttendanceStatus.present] ?? 0,
      half: counts[AttendanceStatus.half] ?? 0,
      leave: leave,
      absent: counts[AttendanceStatus.absent] ?? 0,
      unrecorded: unrecorded,
      statusCounts: {
        for (final s in AttendanceStatus.values) s.jsonValue: counts[s] ?? 0,
      },
      totalAdamSaat: adamSaat,
      totalYevmiye: yevmiye,
      people: people,
      capturedAt: capturedAt ?? DateTime.now(),
    );
  }

  /// Meslek rütbesi → aynı rütbede meslek adı → ekip → personel adı.
  static int compareByRoleRank(
    DailyReportAttendancePerson a,
    DailyReportAttendancePerson b,
  ) {
    final byRank = RoleDegree.sortRank(a.profession)
        .compareTo(RoleDegree.sortRank(b.profession));
    if (byRank != 0) return byRank;
    final byProfession =
        _foldTr(a.profession).compareTo(_foldTr(b.profession));
    if (byProfession != 0) return byProfession;
    final byTeam = _foldTr(a.team).compareTo(_foldTr(b.team));
    if (byTeam != 0) return byTeam;
    return _foldTr(a.personName).compareTo(_foldTr(b.personName));
  }

  static String _foldTr(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
}
