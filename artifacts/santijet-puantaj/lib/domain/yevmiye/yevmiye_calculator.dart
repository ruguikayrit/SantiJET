import '../entities/attendance.dart';
import '../entities/person.dart';

/// Puantaj kayıtlarından ekip yevmiyesi (adam-gün, mesai dahil).
abstract final class YevmiyeCalculator {
  /// Tek kaydın adam-gün değeri: `(saat + mesai) / 8`.
  static double ofAttendance(Attendance a) => a.yevmiye;

  /// Aktif personelde tanımlı ekip adları (alfabetik).
  static List<String> teamNames(List<Person> people) {
    final set = <String>{};
    for (final p in people) {
      if (!p.active) continue;
      final t = p.team.trim();
      if (t.isNotEmpty) set.add(t);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Belirli proje + gün + ekip için toplam yevmiye (mesai dahil).
  static double forTeam({
    required String projectId,
    required String date,
    required String teamName,
    required List<Person> people,
    required List<Attendance> attendance,
  }) {
    final team = teamName.trim();
    if (team.isEmpty) return 0;

    final memberIds = <String>{
      for (final p in people)
        if (p.active && p.team.trim() == team) p.id,
    };
    if (memberIds.isEmpty) return 0;

    var sum = 0.0;
    for (final a in attendance) {
      if (a.projectId != projectId) continue;
      if (a.date != date) continue;
      if (!memberIds.contains(a.personId)) continue;
      sum += a.yevmiye;
    }
    return sum;
  }

  /// Ekipteki kişi sayısı (aktif personel).
  static int teamHeadcount(List<Person> people, String teamName) {
    final team = teamName.trim();
    return people
        .where((p) => p.active && p.team.trim() == team)
        .length;
  }
}
