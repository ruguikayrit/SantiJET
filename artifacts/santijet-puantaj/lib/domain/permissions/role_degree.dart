import '../entities/person.dart';

/// Meslek → rol derecesi.
///
/// 1. derece: görev oluşturup atayabilir; atadığı görevleri görür.
/// 2. derece (ve altı): yalnızca kendisine atanan görevleri görür
/// (ör. Formen, Saha Mühendisi’ne atanan görevi görmez).
abstract final class RoleDegree {
  static const first = 1;
  static const field = 2;

  /// Açık 1. derece meslekler.
  static const firstDegreeProfessions = <String>{
    'Proje Koordinatörü',
    'Proje Müdürü',
    'Şantiye Şefi',
    'Saha Mühendisi',
    'Teknik Ofis Mühendisi',
    'Harita Mühendisi',
    'Jeoloji Mühendisi',
    'İSG Uzmanı',
  };

  static String _fold(String raw) => raw
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  static int forProfession(String profession) {
    final raw = profession.trim();
    if (raw.isEmpty) return field;

    for (final known in firstDegreeProfessions) {
      if (known == raw) return first;
    }

    final p = _fold(raw);
    // Formen / usta / operatör / işçi → saha (2+)
    if (p.contains('formen') ||
        p.contains('usta') ||
        p.contains('kalfa') ||
        p.contains('operator') ||
        p.contains('sofor') ||
        p.contains('isci') ||
        p.contains('bekci') ||
        p.contains('puantor') ||
        p.contains('senor') ||
        p.contains('depo') ||
        p.contains('ambar') ||
        p.contains('kantar')) {
      return field;
    }

    // Mühendis / müdür / şef / koordinatör → 1. derece
    if (p.contains('muhendis') ||
        p.contains('mudur') ||
        p.contains('sefi') ||
        p.contains('sef ') ||
        p.endsWith('sef') ||
        p.contains('koordinator') ||
        p.contains('isg')) {
      return first;
    }

    return field;
  }

  static int forPerson(Person person) => forProfession(person.profession);

  static bool canAssignTasks(Person person) => forPerson(person) == first;

  static bool isFirstDegree(Person person) => forPerson(person) == first;
}
