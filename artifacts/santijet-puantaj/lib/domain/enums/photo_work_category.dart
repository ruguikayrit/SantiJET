/// Fotoğraf açıklamasının senkronize edileceği yapılan iş kategorisi.
enum PhotoWorkCategory {
  none,
  construction,
  electrical,
  mechanical;

  String get label => switch (this) {
        none => 'Seçilmedi',
        construction => 'İnşaat',
        electrical => 'Elektrik',
        mechanical => 'Mekanik',
      };

  String get workSectionTitle => switch (this) {
        none => '',
        construction => 'İnşaat işleri',
        electrical => 'Elektrik işleri',
        mechanical => 'Mekanik işler',
      };

  String get storage => name;

  static PhotoWorkCategory fromStorage(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    return PhotoWorkCategory.values.firstWhere(
      (e) => e.name == s,
      orElse: () => PhotoWorkCategory.none,
    );
  }
}
