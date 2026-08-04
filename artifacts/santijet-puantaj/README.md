# ŞantiJET SAHA (Puantaj & Saha)

ŞantiJET ürün ailesinin **birleşik saha + puantaj** Flutter uygulaması.

Klasör/package adı şimdilik `santijet-puantaj` (rename Faz 2). Kullanıcıya görünen
ad: **ŞantiJET SAHA**.

Adam-gün devam kaydı, imalat/verim, günlük saha raporu. Görsel dil
**ŞantiJET Demir / BFA** ile ortaktır.

## Navigasyon

Kalıcı alt bar (**4 sekme**):

| Sekme | İçerik |
|-------|--------|
| Ana Sayfa | Bugünkü puantaj, imalat, **bugünün raporu**, verim özeti |
| Puantaj | Adam-gün devam; personel yönetimi buradan / Ayarlar’dan |
| İmalat | İçinde segment: **İmalat \| Verim** (ayrı bottom tab yok) |
| Günlük Rapor | Saha günlük formu |

Personel ayrı bottom tab değildir; `/personel` rotası ve Yönetim menüsü durur.

## Günlük Rapor (MVP)

Proje + takvim günü başına tek kayıt (Hive upsert):

- Fotoğraflar + açıklama (**açıklama önerilir**; boş izinli)
  - Saklama: **base64 → Hive** (mobil + web ortak; dosya yolu yok)
- Yapılan işler (serbest metin)
- Gelen malzeme / sipariş malzeme satırları
- İş makinesi puantajı
- **Hava** otomatik (Open-Meteo; proje firma/şehir → geocode; yoksa İstanbul)
- **Puantaj snapshot** otomatik (aynı gün mevcut/yarım/izin/yok + adam-saat/yevmiye)

Offline-first; bulut senkron bu fazda zorunlu değil.

## Puantaj durumları

| Durum | Kısa | Saat |
|-------|------|------|
| Mevcut | M | 8 |
| Yarım Gün | Y | 4 |
| İzinli / Raporlu / Mazeret / Res. Tatil / Yok | İ R Mz T X | 0 |

## Mimari

Riverpod + go_router + Hive + SJ design system.

```
lib/
  core/          tema, SJ bileşenleri, routing
  domain/        Attendance, DailyReport, Person, Project…
  data/          Hive providers, weather, export
  features/      home, puantaj, imalat (+verim hub), daily_report, …
```

## Çalıştırma

```bash
cd artifacts/santijet-puantaj
flutter pub get
flutter run
```

## Staging

| Ortam | URL |
|-------|-----|
| **SAHA / Puantaj staging** | https://ruguikayrit.github.io/SantiJET/puantaj/ |

```bash
git checkout staging
# …commit sonrası
git push origin staging
```

## Fazlar

| Faz | İçerik | Durum |
|-----|--------|-------|
| 1 | Puantaj iskelet + imalat/verim | ✅ |
| 1b | 4 sekme + Günlük Rapor MVP (hava + snapshot + foto) | ✅ |
| 2 | Klasör rename + PIN / roller | ⬜ |
| 3 | Cetvel / rapor export genişletme | ⬜ |
| 4 | Bulut senkron (opsiyonel) | ⬜ |
