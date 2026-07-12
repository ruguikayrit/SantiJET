/// İmalat poz kategorileri ve ölçü birimleri — RN `pozAnalizleri.ts` ile hizalı.
abstract final class PozConstants {
  static const kategoriler = [
    'Hafriyat ve Toprak',
    'Beton ve Demir',
    'Kalıp',
    'Duvar',
    'Sıva ve Şap',
    'Yalıtım',
    'Çatı',
    'Kaplama',
    'Boya',
    'Doğrama',
    'Sıhhi Tesisat',
    'Elektrik',
    'Mekanik Tesisat',
    'Asansör',
    'Cephe',
    'Çevre Düzenleme',
    'Yıkım ve Söküm',
    'Çelik Yapı',
    'Altyapı',
    'Peyzaj',
    'Diğer',
  ];

  static const olcuBirimleri = [
    'Ad',
    'Adet',
    'm²',
    'm³',
    'm',
    'Ton',
    'Kg',
    'Sa',
    'lt',
    'Kwh',
    'Kt',
    'Tk',
    '100 m²',
    '1000 m²',
    '1000 Ad',
  ];

  static const defaultYukleniciKarOrani = 25.0;
}
