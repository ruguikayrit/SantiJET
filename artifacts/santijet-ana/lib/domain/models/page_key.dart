// Sayfa izin anahtarları ve varsayılan roller — RN AppContext birebir.

enum Permission { none, view, edit }

extension PermissionX on Permission {
  String get wire {
    switch (this) {
      case Permission.none:
        return 'none';
      case Permission.view:
        return 'view';
      case Permission.edit:
        return 'edit';
    }
  }

  static Permission fromWire(Object? raw) {
    switch (raw?.toString()) {
      case 'view':
        return Permission.view;
      case 'edit':
        return Permission.edit;
      default:
        return Permission.none;
    }
  }
}

const List<String> allPageKeys = [
  'proje',
  'dosyalar',
  'kesif',
  'is-programi',
  'puantaj',
  'gunluk-rapor',
  'imalat',
  'gorev',
  'malzeme',
  'taseron',
  'satin-alma',
  'kantar',
  'butce',
  'hakedis',
  'ilerleme',
  'kullanicilar',
];

typedef PageKey = String;

const Map<String, String> pageLabels = {
  'proje': 'Proje',
  'dosyalar': 'Dosyalar',
  'kesif': 'Keşif',
  'is-programi': 'İş Programı',
  'puantaj': 'Puantaj',
  'gunluk-rapor': 'Günlük Rapor',
  'imalat': 'İmalat',
  'gorev': 'Görev',
  'malzeme': 'Malzeme',
  'taseron': 'Taşeron',
  'satin-alma': 'Satın Alma',
  'kantar': 'Kantar',
  'butce': 'Bütçe',
  'hakedis': 'Hakediş',
  'ilerleme': 'İlerleme',
  'kullanicilar': 'Kullanıcılar',
};

const List<String> defaultProfessions = [
  'Proje Koordinatörü',
  'Proje Müdürü',
  'Şantiye Şefi',
  'Saha Mühendisi',
  'Teknik Ofis Mühendisi',
  'Harita Mühendisi',
  'Jeoloji Mühendisi',
  'İSG Uzmanı',
  'Şenör',
  'Puantör',
  'Saha Formeni',
  'Makine Formeni',
  'Usta',
  'Ekskavatör Operatörü',
  'JCB Operatörü',
  'Kamyon Şoförü',
  'Kule Vinç Operatörü',
  'Mobil Vinç Operatörü',
  'Kantar Personeli',
  'Depo & Ambar Personeli',
  'Kalfa',
  'Kalfa Yardımcısı',
  'Saha Düz İşçi',
  'Gündüz Bekçisi',
  'Gece Bekçisi',
];

const List<String> defaultTradeGroups = [
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
  'Alçı / Asma Tavan',
  'Alüminyum / Doğrama',
  'Su Tesisatı',
  'Elektrik',
  'Mekanik / Havalandırma',
  'Yangın Tesisatı',
  'Asansör',
  'Peyzaj',
  'Altyapı',
  'İnce İşler',
];

Map<String, Permission> get _allEdit => {
      for (final k in allPageKeys) k: Permission.edit,
    };

Map<String, Permission> _perms(Map<String, Permission> map) =>
    {for (final k in allPageKeys) k: map[k] ?? Permission.none};

/// Varsayılan roller — RN DEFAULT_ROLES.
List<Map<String, dynamic>> get defaultRolesRaw => [
      {
        'id': 'isveren',
        'name': 'İşveren',
        'isAdmin': false,
        'permissions': _perms({
          for (final k in allPageKeys) k: Permission.view,
        }),
      },
      {
        'id': 'proje-muduru',
        'name': 'Proje Müdürü',
        'isAdmin': true,
        'permissions': _allEdit,
      },
      {
        'id': 'santiye-sefi',
        'name': 'Şantiye Şefi',
        'isAdmin': true,
        'permissions': _allEdit,
      },
      {
        'id': 'saha-muhendisi',
        'name': 'Saha Mühendisi',
        'isAdmin': false,
        'permissions': _perms({
          'proje': Permission.view,
          'dosyalar': Permission.edit,
          'kesif': Permission.none,
          'is-programi': Permission.edit,
          'puantaj': Permission.edit,
          'gunluk-rapor': Permission.edit,
          'imalat': Permission.edit,
          'gorev': Permission.edit,
          'malzeme': Permission.view,
          'taseron': Permission.view,
          'satin-alma': Permission.view,
          'kantar': Permission.edit,
          'butce': Permission.none,
          'hakedis': Permission.none,
          'ilerleme': Permission.view,
          'kullanicilar': Permission.none,
        }),
      },
      {
        'id': 'teknik-ofis-muhendisi',
        'name': 'Teknik Ofis Mühendisi',
        'isAdmin': false,
        'permissions': _perms({
          'proje': Permission.view,
          'dosyalar': Permission.edit,
          'kesif': Permission.edit,
          'is-programi': Permission.view,
          'puantaj': Permission.none,
          'gunluk-rapor': Permission.view,
          'imalat': Permission.edit,
          'gorev': Permission.view,
          'malzeme': Permission.view,
          'taseron': Permission.view,
          'satin-alma': Permission.view,
          'kantar': Permission.view,
          'butce': Permission.view,
          'hakedis': Permission.edit,
          'ilerleme': Permission.edit,
          'kullanicilar': Permission.none,
        }),
      },
      {
        'id': 'isg-birimi',
        'name': 'İSG Birimi',
        'isAdmin': false,
        'permissions': _perms({
          'proje': Permission.view,
          'dosyalar': Permission.view,
          'gunluk-rapor': Permission.edit,
          'imalat': Permission.view,
          'gorev': Permission.edit,
          'is-programi': Permission.view,
          'ilerleme': Permission.view,
        }),
      },
      {
        'id': 'taseron',
        'name': 'Taşeron',
        'isAdmin': false,
        'permissions': _perms({
          'proje': Permission.view,
          'dosyalar': Permission.view,
          'is-programi': Permission.view,
          'gunluk-rapor': Permission.edit,
          'imalat': Permission.view,
          'gorev': Permission.view,
          'hakedis': Permission.view,
          'ilerleme': Permission.view,
        }),
      },
      {
        'id': 'satin-alma-birimi',
        'name': 'Satın Alma Birimi',
        'isAdmin': false,
        'permissions': _perms({
          'proje': Permission.view,
          'dosyalar': Permission.view,
          'malzeme': Permission.edit,
          'taseron': Permission.view,
          'satin-alma': Permission.edit,
          'kantar': Permission.edit,
          'butce': Permission.view,
        }),
      },
      {
        'id': 'muhasebe-birimi',
        'name': 'Muhasebe Birimi',
        'isAdmin': false,
        'permissions': _perms({
          'proje': Permission.view,
          'dosyalar': Permission.view,
          'satin-alma': Permission.view,
          'kantar': Permission.view,
          'butce': Permission.view,
          'hakedis': Permission.view,
        }),
      },
      {
        'id': 'ik-birimi',
        'name': 'İK Birimi',
        'isAdmin': false,
        'permissions': _perms({
          'proje': Permission.view,
          'dosyalar': Permission.view,
          'puantaj': Permission.edit,
          'kullanicilar': Permission.edit,
        }),
      },
      {
        'id': 'diger-kullanicilar',
        'name': 'Diğer Kullanıcılar',
        'isAdmin': false,
        'permissions': _perms({
          'proje': Permission.view,
          'dosyalar': Permission.view,
          'gunluk-rapor': Permission.view,
          'gorev': Permission.view,
        }),
      },
    ];
