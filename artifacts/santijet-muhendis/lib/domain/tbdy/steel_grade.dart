/// Çelik sınıfı — Tablo 2.1A (t ≤ 40 mm) + Tablo 9.2 katsayıları.
class SteelGrade {
  const SteelGrade({
    required this.id,
    required this.label,
    required this.fy,
    required this.fu,
    required this.ry,
    required this.rt,
  });

  final String id;
  final String label;

  /// Akma dayanımı [N/mm²] — t ≤ 40 mm.
  final double fy;

  /// Çekme dayanımı [N/mm²] — t ≤ 40 mm.
  final double fu;

  /// Beklenen akma katsayısı Ry (Tablo 9.2).
  final double ry;

  /// Beklenen çekme katsayısı Rt (Tablo 9.2).
  final double rt;
}

/// Hot-rolled structural steel grades used in TBDY-2018 connection checks.
abstract final class SteelGrades {
  static const s235 = SteelGrade(
    id: 'S235',
    label: 'S235',
    fy: 235,
    fu: 360,
    ry: 1.4,
    rt: 1.1,
  );

  static const s275 = SteelGrade(
    id: 'S275',
    label: 'S275',
    fy: 275,
    fu: 430,
    ry: 1.3,
    rt: 1.1,
  );

  static const s355 = SteelGrade(
    id: 'S355',
    label: 'S355',
    fy: 355,
    fu: 510,
    ry: 1.25,
    rt: 1.1,
  );

  static const s450 = SteelGrade(
    id: 'S450',
    label: 'S450',
    fy: 440,
    fu: 550,
    ry: 1.15,
    rt: 1.1,
  );

  static const List<SteelGrade> all = [s235, s275, s355, s450];

  static SteelGrade byId(String id) =>
      all.firstWhere((g) => g.id == id, orElse: () => s235);
}
