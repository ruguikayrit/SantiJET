# Resmi Katalog Verisi

Bu klasör, ŞantiJET BFA resmi birim fiyat analizleri JSON dosyalarını barındıracaktır.

Faz 7 (Analiz Listeleri / Veri Katmanı) aşamasında, React Native referans
projesinden (`artifacts/imalat-poz-analizleri/assets/data/`) **salt-okunur** olarak
kopyalanacaktır:

| Dosya | İçerik | Kayıt |
|-------|--------|-------|
| `resmi-poz-analizleri.json` | İnşaat B.F.A. | 1.879 |
| `resmi-mekanik-analizleri.json` | Mekanik Tesisat B.F.A. | 5.646 |
| `resmi-elektrik-analizleri.json` | Elektrik Tesisat B.F.A. | 5.911 |

Toplam ~13.436 kayıt / ~19 MB. Performans nedeniyle veri katmanı tasarımı
(Isar/indeksli arama vb.) Faz 7 ve Faz 14'te ele alınacaktır.
