/// İçe aktarım şablonu — Excel / JPG OCR için kabul edilen 9 sütun.
abstract final class KasaImportFormat {
  static const headers = <String>[
    'Tarih',
    'Tedarikçi',
    'Açıklama',
    'Gelir',
    'Gider',
    'Ödeme Şekli',
    'Belge Türü',
    'Şantiye',
    'Ek Açıklama',
  ];

  static const jpgAssetPath = 'assets/images/kasa_import_ornek.jpg';

  static const userHint =
      'Verilerinizi bu 9 sütunlu tabloda düzenleyin. '
      'JPG/PDF için ekran görüntüsü net ve düz olmalı; '
      'hatasız aktarım için Excel dosyası önerilir.';
}
