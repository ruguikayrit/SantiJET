/// Kurumsal üyelik rolleri — sayfa ve işlem yetkileri buna göre ayrılır.
enum CorporateRole {
  employer,
  purchasing,
  projectManager,
  siteManager,
  accounting;

  String get label => switch (this) {
        CorporateRole.employer => 'İşveren',
        CorporateRole.purchasing => 'Satın Alma',
        CorporateRole.projectManager => 'Proje Müdürü',
        CorporateRole.siteManager => 'Şantiye Şefi',
        CorporateRole.accounting => 'Muhasebe',
      };

  String get description => switch (this) {
        CorporateRole.employer =>
          'Üst düzey onay ve tüm proje görünümü',
        CorporateRole.purchasing =>
          'Sipariş onayı ve gelen demir listesi görüntüleme',
        CorporateRole.projectManager =>
          'Sipariş, keşif, saha ve analiz yönetimi',
        CorporateRole.siteManager =>
          'Saha sayım, keşif ve teslimat işlemleri',
        CorporateRole.accounting =>
          'Gelen demir ve sipariş verilerine erişim',
      };

  static CorporateRole? fromStorage(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final role in CorporateRole.values) {
      if (role.name == raw) return role;
    }
    return null;
  }

  String get storageValue => name;
}
