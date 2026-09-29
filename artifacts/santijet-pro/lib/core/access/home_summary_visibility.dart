/// Ana sayfa özet blokları. Rol tanımı gelince hangi rolün hangi başlığı
/// göreceği bu bölüm kimlikleri üzerinden seçilecek.
enum HomeSummarySection {
  finansalOzet,
  teknikOzet,
}

/// Ana sayfada finansal / teknik özet görünürlüğü.
class HomeSummaryVisibility {
  const HomeSummaryVisibility({
    this.finansalOzet = true,
    this.teknikOzet = true,
  });

  final bool finansalOzet;
  final bool teknikOzet;

  bool shows(HomeSummarySection section) => switch (section) {
        HomeSummarySection.finansalOzet => finansalOzet,
        HomeSummarySection.teknikOzet => teknikOzet,
      };

  /// Aktif rol atanana kadar tüm özetler görünür.
  /// Rol bağlandığında [rolId] ile politika buradan üretilecek.
  factory HomeSummaryVisibility.forRole(String? rolId) {
    if (rolId == null || rolId.isEmpty) {
      return const HomeSummaryVisibility();
    }
    // Rol matrisi tanımlanınca rolId → finansalOzet / teknikOzet eşlemesi buraya gelecek.
    return const HomeSummaryVisibility();
  }
}
