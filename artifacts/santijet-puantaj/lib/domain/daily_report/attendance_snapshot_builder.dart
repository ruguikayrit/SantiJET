import '../entities/attendance.dart';
import '../entities/daily_report.dart';
import '../entities/person.dart';
import '../enums/attendance_status.dart';
import '../permissions/role_degree.dart';

/// Proje + gün için canlı puantaj özeti üretir.
abstract final class AttendanceSnapshotBuilder {
  static DailyReportAttendanceSnapshot build({
    required String projectId,
    required String date,
    required List<Attendance> attendance,
    required List<Person> activePeople,
    DateTime? capturedAt,
  }) {
    final activeIds = {for (final p in activePeople) p.id};
    final day = attendance
        .where(
          (a) =>
              a.projectId == projectId &&
              a.date == date &&
              activeIds.contains(a.personId),
        )
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
        case AttendanceStatus.haftaTatili:
          leave++;
        case AttendanceStatus.absent:
          recordedAbsent++;
        case AttendanceStatus.giris:
        case AttendanceStatus.cikis:
          break;
      }
      adamSaat += a.hours + a.overtimeHours;
      yevmiye += a.yevmiye;
    }

    // Kaydı olmayan aktif personel → yok sayılır.
    final unrecorded =
        activePeople.where((p) => !byPerson.containsKey(p.id)).length;
    final absent = recordedAbsent + unrecorded;

    final metaById = {
      for (final p in activePeople)
        p.id: (team: p.team.trim(), profession: p.profession.trim()),
    };

    final people = [
      for (final a in day)
        DailyReportAttendancePerson(
          personId: a.personId,
          personName: a.personName,
          team: metaById[a.personId]?.team ?? '',
          profession: metaById[a.personId]?.profession ?? '',
          status: a.status.label,
          hours: a.hours,
          overtimeHours: a.overtimeHours,
          yevmiye: a.yevmiye,
        ),
    ]..sort(compareByRoleRank);

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
