# ŞantiJET SAHA (Puantaj & Saha)

ŞantiJET ürün ailesinin **birleşik saha + puantaj** Flutter uygulaması.

Klasör/package adı şimdilik `santijet-puantaj` (rename Faz 2). Kullanıcıya görünen
ad: **ŞantiJET SAHA**.

Adam-gün devam kaydı, imalat/verim, günlük saha raporu. Görsel dil
**ŞantiJET Demir / BFA** ile ortaktır.

## Navigasyon

Kalıcı alt bar (**5 sekme**):

| Sekme | İçerik |
|-------|--------|
| Ana Sayfa | Bugünkü puantaj, imalat, **bugünün raporu**, verim özeti |
| Puantaj | Adam-gün devam; personel yönetimi buradan / Ayarlar’dan |
| İmalat | İçinde segment: **İmalat \| Verim** (ayrı bottom tab yok) |
| Görev | Atama + takvim (yeşil başlangıç / kırmızı teslimat); **atanan + atayan** görür |
| Rapor | Saha günlük formu |

Personel ayrı bottom tab değildir; `/personel` rotası ve Yönetim menüsü durur.

## Günlük Rapor (MVP)

Proje + takvim günü başına tek kayıt (Hive upsert):

- Fotoğraflar + açıklama (**açıklama önerilir**; boş izinli)
  - Saklama: **base64 → Hive** (mobil + web ortak; dosya yolu yok)
- Bölüm sırası: Hava → Puantaj → Fotoğraflar → Yapılan işler → Gelen / Giden / Sipariş malzeme → İş makinesi → Vasıta → Ertesi gün planı
- Gelen malzeme: **irsaliye fotoğrafı** + OCR (OCR.space) ile otomatik satır
  - Tedarik tarihi, firma, ürün adı, miktar, birim, fiyat (opsiyonel)
- Giden (gönderilen) malzeme satırları
- Yapılan işler: İnşaat / Elektrik / Mekanik + fotoğraf açıklamaları (otomatik)
- Sipariş verilen malzeme
- İş makinesi puantajı + **vasıta puantajı**
- PDF: hücreler ortalı; gelişmişte personel yanında **ekip** sütunu
- **Hava** listeden il seçimi (Open-Meteo; GPS/geocode yok; seçim hatırlanır)
  - Anlık sıcaklık, **gece sıcaklığı**, **nem**, açıklama, rüzgar
- **Puantaj snapshot** otomatik (aynı gün mevcut/yarım/izin/yok + adam-saat/yevmiye)
- **PDF dışa aktarma** — 3 stil: **Özet · Standart · Gelişmiş**
  - Standart = örnek “Günlük Şantiye Raporu” form düzeni (başlık, yüklenici, hava, puantaj, işler, malzeme, makine, imza; fotoğraflar ayrı sayfa)
  - Başlıkta **firma logosu** (Projelerim’de proje/firma logosundan)

Offline-first; bulut senkron bu fazda zorunlu değil.

## Puantaj durumları

Sıra kilitli: Giriş → Çıkış → Mevcut → Yarım → Yok → İzinli → Raporlu → Mazeret → Hafta Tatili → Resmi Tatil.

| Durum | Kısa | Saat |
|-------|------|------|
| Giriş | G | 0 |
| Çıkış | Ç | 0 |
| Mevcut | M | 8 |
| Yarım Gün | Y | 4 |
| Yok | X | 0 |
| İzinli | İ | 0 |
| Raporlu | R | 0 |
| Mazeret | Mz | 0 |
| Hafta Tatili | HT | 0 |
| Resmi Tatil | RT | 0 |

Kayıt yoksa pazar günü otomatik HT (manuel durum ezer).

## Puantajı dışa aktar

Personel ve Ekip listeleri **varsayılan kapalı**. Ekip başlığının altında **Ekip ara…** satırı durur.

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
