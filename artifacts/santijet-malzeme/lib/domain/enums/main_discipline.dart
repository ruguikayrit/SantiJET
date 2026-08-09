/// Ana disiplin — keşif / talep gruplama kökü.
enum MainDiscipline {
  insaat,
  elektrik,
  mekanik;

  String get label => switch (this) {
        MainDiscipline.insaat => 'İnşaat',
        MainDiscipline.elektrik => 'Elektrik',
        MainDiscipline.mekanik => 'Mekanik',
      };

  static MainDiscipline? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in MainDiscipline.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}
