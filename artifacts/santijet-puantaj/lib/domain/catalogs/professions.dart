/// İnşaat sektörü meslek kataloğu — SGK / İŞKUR (ISCO-08) sınıflarına göre gruplu.
///
/// Kaynak gruplar: yönetim-teknik (şantiye), 711 kaba inşaat, 712 tamamlayıcı,
/// 713 boya/yüzey, elektrik-mekanik (74/72), iş makinesi (83), destek, 931 niteliksiz.
class ProfessionGroup {
  const ProfessionGroup({
    required this.name,
    required this.sgkHint,
    required this.professions,
  });

  final String name;

  /// Kısa SGK / ISCO referansı (UI alt başlık).
  final String sgkHint;

  final List<String> professions;
}

abstract final class ProfessionCatalog {
  static const List<ProfessionGroup> groups = [
    ProfessionGroup(
      name: 'Yönetim ve Teknik',
      sgkHint: 'Şantiye yönetim · mühendislik · İSG',
      professions: [
        'Proje Koordinatörü',
        'Proje Müdürü',
        'Şantiye Şefi',
        'İnşaat Mühendisi',
        'Saha Mühendisi',
        'Teknik Ofis Mühendisi',
        'Harita Mühendisi',
        'Jeoloji Mühendisi',
        'Mimar',
        'İSG Uzmanı',
        'İSG Teknikeri',
        'Puantör',
        'Şenör',
      ],
    ),
    ProfessionGroup(
      name: 'Kaba İnşaat',
      sgkHint: 'SGK 711',
      professions: [
        'İnşaat Ustası',
        'Saha Formeni',
        'Makine Formeni',
        'Formen',
        'Usta',
        'Kalfa',
        'Kalfa Yardımcısı',
        'Duvarcı',
        'Betonarmeci',
        'Betonarme Demircisi',
        'Kalıpçı',
        'Beton ve Betonarme Kalıpçısı',
        'Tünel Kalıpçı',
        'Şap İşçisi',
        'Mozaikçi',
      ],
    ),
    ProfessionGroup(
      name: 'İnşaatı Tamamlayıcı İşler',
      sgkHint: 'SGK 712',
      professions: [
        'Sıvacı',
        'Alçı Sıva Uygulayıcısı',
        'Alçıpan Ustası',
        'Asma Tavan Ustası',
        'Seramik / Fayans Döşeyicisi',
        'Mermer Döşeyici',
        'Parke Döşemecisi',
        'Çatı Ustası',
        'İzolasyoncu',
        'Su Yalıtımcısı',
        'Isı Yalıtımcısı',
        'Camcı',
        'Doğramacı',
        'Alüminyum Doğrama Ustası',
      ],
    ),
    ProfessionGroup(
      name: 'Boya ve Yüzey',
      sgkHint: 'SGK 713',
      professions: [
        'Boyacı',
        'Bina Boyacısı',
        'Badanacı',
      ],
    ),
    ProfessionGroup(
      name: 'Elektrik ve Mekanik',
      sgkHint: 'SGK 74 / 72',
      professions: [
        'Elektrikçi',
        'İnşaat Elektrikçisi',
        'Tesisatçı',
        'Su Tesisatçısı',
        'Kalorifer Tesisatçısı',
        'Havalandırma Tesisatçısı',
        'Kaynakçı',
        'Makine Bakımcısı',
      ],
    ),
    ProfessionGroup(
      name: 'İş Makinesi ve Ulaştırma',
      sgkHint: 'SGK 83',
      professions: [
        'İş Makinesi Operatörü',
        'Ekskavatör Operatörü',
        'JCB Operatörü',
        'Kule Vinç Operatörü',
        'Mobil Vinç Operatörü',
        'Forklift Operatörü',
        'Kamyon Şoförü',
      ],
    ),
    ProfessionGroup(
      name: 'Depo, Güvenlik ve Destek',
      sgkHint: 'Depo · kantarcı · güvenlik',
      professions: [
        'Depo & Ambar Personeli',
        'Kantar Personeli',
        'Güvenlik Görevlisi',
        'Gündüz Bekçisi',
        'Gece Bekçisi',
      ],
    ),
    ProfessionGroup(
      name: 'Nitelik Gerektirmeyen İşler',
      sgkHint: 'SGK 931',
      professions: [
        'İnşaat İşçisi',
        'Saha Düz İşçi',
        'Hafriyat İşçisi',
        'Beden İşçisi',
      ],
    ),
  ];

  /// Düz liste — grup sırası korunur (alfabetik sıralanmaz).
  static List<String> get defaultProfessions => [
        for (final g in groups) ...g.professions,
      ];

  /// Bilinen mesleğin SGK grubu; katalog dışı → null.
  static ProfessionGroup? groupOf(String profession) {
    final key = profession.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final g in groups) {
      for (final p in g.professions) {
        if (p.toLowerCase() == key) return g;
      }
    }
    return null;
  }

  /// Katalog + özel meslekleri grup sırasıyla döner.
  /// Özel / bilinmeyenler sonda «Diğer» altında.
  static List<({String groupName, String sgkHint, List<String> items})>
      groupItems(Iterable<String> items) {
    final remaining = <String, String>{};
    for (final raw in items) {
      final t = raw.trim();
      if (t.isEmpty) continue;
      remaining.putIfAbsent(t.toLowerCase(), () => t);
    }

    final out = <({String groupName, String sgkHint, List<String> items})>[];
    for (final g in groups) {
      final bucket = <String>[];
      for (final p in g.professions) {
        final hit = remaining.remove(p.toLowerCase());
        if (hit != null) bucket.add(hit);
      }
      if (bucket.isNotEmpty) {
        out.add((groupName: g.name, sgkHint: g.sgkHint, items: bucket));
      }
    }

    if (remaining.isNotEmpty) {
      final other = remaining.values.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      out.add((
        groupName: 'Diğer',
        sgkHint: 'Manuel eklenen meslekler',
        items: other,
      ));
    }
    return out;
  }

  /// Eski katalog adlarını SGK uyumlu ada taşır (boş = değişiklik yok).
  static const Map<String, String> legacyRename = {
    'demirci usta': 'Betonarme Demircisi',
    'demirci': 'Betonarme Demircisi',
    'kalıpçı usta': 'Kalıpçı',
    'elektrik usta': 'Elektrikçi',
    'mekanik usta': 'Havalandırma Tesisatçısı',
  };

  static String resolveLegacyName(String name) {
    final key = name.trim().toLowerCase();
    return legacyRename[key] ?? name.trim();
  }

  /// Ekip / meslek grubu (imalat ekipleri) — SGK meslek gruplarından ayrı.
  static const List<String> defaultTradeGroups = [
    'Hafriyat',
    'Kaba İnşaat',
    'Kalıp',
    'Demir',
    'Beton',
    'Duvar',
    'Çelik',
    'Sıva',
    'Şap',
    'İzolasyon',
    'Çatı',
    'Seramik / Fayans',
    'Boya',
    'Alçı Sıva',
    'Asma Tavan',
    'Alüminyum / Doğrama',
    'Su Tesisatı',
    'Elektrik',
    'Mekanik / Havalandırma',
    'Yangın Tesisatı',
    'Peyzaj',
    'Ofis',
    'Genel',
  ];
}
