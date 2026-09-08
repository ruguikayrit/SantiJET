# ŞantiJET Kasa

Şantiye **iş avansı ve harcama** defteri. Tek fiyat, abonelik yok, hesap yok.
Veri cihazınızda kalır.

Klasör: `artifacts/santijet-kasa`  
Paket: `santijet_kasa`  
Kimlik: `com.santijet.santijet_kasa`

## Ne işe yarar

Excel “İŞ AVANSI VE HARCAMA TABLOSU” kurgusunun mobil/web karşılığı:

- Üst özet: toplam gelir · toplam gider · güncel kasa
- Hareket satırları (tarih, tedarikçi, açıklama, gelir/gider, ödeme, belge, şantiye…)
- Filtre, arama, şantiye bazlı rapor
- PDF / Excel / JPG dışa aktarım (Rapor sayfası altı)
- JPG / PDF OCR (ön işleme + tablo hizalama) + Excel içe aktarım; onay önizlemesi

## Çalıştırma

```bash
cd artifacts/santijet-kasa
flutter pub get
flutter test
flutter analyze
flutter run -d chrome
```

Staging hedefi: `/kasa/` (turuncu STAGING şeridi yok).
