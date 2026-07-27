import '../entities/attendance.dart';
import '../entities/person.dart';
import '../entities/production.dart';

/// Personel mesleğine göre usta / düz işçi (çırak) sınıflandırması.
enum LaborClass { usta, duzIsci }

abstract final class LaborClassifier {
  static const _ustaHints = [
    'usta',
    'kalfa',
    'formen',
    'operatör',
    'operator',
  ];

  static const _duzHints = [
    'düz',
    'duz',
    'çırak',
    'cirak',
    'yardımcı',
    'yardimci',
    'işçi',
    'isci',
  ];

  /// Ofis / yönetim — usta–düz havuzuna girmez.
  static const _excludeHints = [
    'mühendis',
    'muhendis',
    'müdür',
    'mudur',
    'koordinatör',
    'koordinator',
    'isg',
    'puantör',
    'puantor',
    'şenör',
    'senor',
    'bekçi',
    'bekci',
    'kantar',
    'depo',
    'ambar',
    'proje',
  ];

  static LaborClass? classify(String profession) {
    final p = profession.trim().toLowerCase();
    if (p.isEmpty) return LaborClass.duzIsci;
    for (final h in _excludeHints) {
      if (p.contains(h)) return null;
    }
    // Kalfa Yardımcısı → düz (önce yardımcı kontrolü)
    if (p.contains('yardımcı') || p.contains('yardimci')) {
      return LaborClass.duzIsci;
    }
    for (final h in _ustaHints) {
      if (p.contains(h)) return LaborClass.usta;
    }
    for (final h in _duzHints) {
      if (p.contains(h)) return LaborClass.duzIsci;
    }
    return LaborClass.duzIsci;
  }
}

/// Ekip × gün için puantajdan gelen ve imalatlara atanabilir iş gücü.
class CrewPool {
  const CrewPool({
    required this.ustaTotal,
    required this.duzTotal,
    this.ustaAllocated = 0,
    this.duzAllocated = 0,
  });

  /// Puantajdaki toplam usta adam-gün (mesai dahil).
  final double ustaTotal;

  /// Puantajdaki toplam düz işçi adam-gün (mesai dahil).
  final double duzTotal;

  /// Aynı gün/ekipteki diğer imalatlara atanmış.
  final double ustaAllocated;
  final double duzAllocated;

  double get ustaRemaining =>
      (ustaTotal - ustaAllocated).clamp(0, double.infinity);

  double get duzRemaining =>
      (duzTotal - duzAllocated).clamp(0, double.infinity);

  bool get isEmpty => ustaTotal <= 0 && duzTotal <= 0;
}

/// İmalat iş gücü dağılımı — puantaj havuzu − diğer imalat atamaları.
abstract final class ImalatCrewAllocator {
  /// Tek kişinin o günkü adam-gün katkısı (çalıştıysa).
  static double _personDay(Attendance a) {
    if (!a.status.isWorkedDay && a.overtimeHours <= 0) return 0;
    return a.yevmiye;
  }

  /// Ekibin o günkü puantajdan usta / düz işçi toplamları.
  static CrewPool poolFromPuantaj({
    required String projectId,
    required String date,
    required String teamName,
    required List<Person> people,
    required List<Attendance> attendance,
  }) {
    final team = teamName.trim();
    if (team.isEmpty) {
      return const CrewPool(ustaTotal: 0, duzTotal: 0);
    }

    final byId = <String, Person>{
      for (final p in people)
        if (p.active && p.team.trim() == team) p.id: p,
    };

    var usta = 0.0;
    var duz = 0.0;
    for (final a in attendance) {
      if (a.projectId != projectId || a.date != date) continue;
      final person = byId[a.personId];
      if (person == null) continue;
      final day = _personDay(a);
      if (day <= 0) continue;
      switch (LaborClassifier.classify(person.profession)) {
        case LaborClass.usta:
          usta += day;
          break;
        case LaborClass.duzIsci:
          duz += day;
          break;
        case null:
          break;
      }
    }
    return CrewPool(ustaTotal: usta, duzTotal: duz);
  }

  /// Aynı gün/ekipteki tüm günlük imalat kayıtlarının usta/düz toplamı.
  static ({double usta, double duz}) allocatedOnDay({
    required String projectId,
    required String date,
    required String teamName,
    required List<Production> productions,
    String? excludeDayEntryId,
  }) {
    final team = teamName.trim();
    var usta = 0.0;
    var duz = 0.0;
    for (final p in productions) {
      if (p.projectId != projectId) continue;
      if (p.teamName.trim() != team) continue;
      for (final e in p.dailyEntries) {
        if (e.date != date) continue;
        if (excludeDayEntryId != null && e.id == excludeDayEntryId) continue;
        usta += e.ustaCount;
        duz += e.duzIsciCount;
      }
    }
    return (usta: usta, duz: duz);
  }

  /// Puantaj toplamı − diğer imalatlar = bu imalat için kalan öneri.
  static CrewPool availableFor({
    required String projectId,
    required String date,
    required String teamName,
    required List<Person> people,
    required List<Attendance> attendance,
    required List<Production> productions,
    String? excludeDayEntryId,
  }) {
    final base = poolFromPuantaj(
      projectId: projectId,
      date: date,
      teamName: teamName,
      people: people,
      attendance: attendance,
    );
    final used = allocatedOnDay(
      projectId: projectId,
      date: date,
      teamName: teamName,
      productions: productions,
      excludeDayEntryId: excludeDayEntryId,
    );
    return CrewPool(
      ustaTotal: base.ustaTotal,
      duzTotal: base.duzTotal,
      ustaAllocated: used.usta,
      duzAllocated: used.duz,
    );
  }
}
