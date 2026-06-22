# QA Matrisi — ŞantiJET DEMİR v1.0.0

## Test Ortamları

| Ortam | Cihaz | Tema | Durum |
|-------|-------|------|-------|
| Android | Telefon (360×800) | Koyu | ✅ |
| Android | Telefon (360×800) | Açık | ✅ |
| Android | Tablet (768×1024) | Koyu | ✅ |
| iOS | iPhone 14 | Koyu | ⏳ macOS gerekli |
| Web | Chrome | Koyu | ✅ (geliştirme) |

## Ekran Matrisi

| Ekran | Navigasyon | Boş Durum | Export | Hive |
|-------|------------|-----------|--------|------|
| Splash | `/` | — | — | — |
| Dashboard | Tab 0 | — | — | — |
| Siparişler | Tab 1 | ✅ noSearchResult | — | — |
| Yeni Sipariş | `/orders/new` | — | — | — |
| Gelen Demir | Tab 2 | — | — | — |
| Teslimat Listesi | `/incoming-rebar/list` | — | — | — |
| Teslimat Detay | `/incoming-rebar/:id` | — | — | — |
| Yeni Teslimat | `/incoming-rebar/new` | — | — | — |
| Tedarikçi Performans | `/incoming-rebar/suppliers` | — | — | — |
| Saha Sayım | Tab 3 | — | — | — |
| Mutabakat | `/field-count/reconciliation` | — | ✅ PDF/Excel | — |
| Yeni Sayım | `/field-count/new` | — | — | — |
| Sayım Detay | `/field-count/:id` | — | — | — |
| Analiz | Tab 4 | — | — | — |
| Performans Analizi | `/analysis/performance` | — | — | — |
| Raporlar | `/reports` | — | — | — |
| Rapor Detay | `/reports/:id` | — | ✅ PDF/Excel | — |
| Keşif | `/survey` | — | ✅ PDF/Excel | — |
| Keşif Detay | `/survey/:id` | — | — | — |
| Ayarlar | `/settings` | — | — | ✅ |
| Firma Ayarları | `/settings/company` | — | — | ✅ |
| Proje Ayarları | `/settings/project` | — | — | ✅ |
| Bildirim Ayarları | `/settings/notifications` | — | — | ✅ |
| Boş Durum Önizleme | `/settings/empty-states` | ✅ 9 tip | — | — |

## Fonksiyonel Testler

| Test | Beklenen | Durum |
|------|----------|-------|
| Splash → Dashboard (2.8s) | Otomatik yönlendirme | ✅ |
| Alt nav 5 tab geçişi | Anında geçiş, state korunur | ✅ |
| Avatar → Ayarlar | `/settings` açılır | ✅ |
| Tema değiştirme | MaterialApp tema güncellenir | ✅ |
| Firma bilgisi kaydet | Hive'a yazılır, snackbar | ✅ |
| PDF export (rapor) | Paylaşım diyaloğu | ✅ |
| Excel export (keşif) | .xlsx dosyası | ✅ |
| CrashReporting init | Firebase yoksa fallback | ✅ |
| Tablet layout | KPI grid 4 sütun, max 720px | ✅ |

## Regresyon Komutları

```bash
cd artifacts/santijet-demir
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

## Bilinen Sınırlamalar

- Firebase Crashlytics placeholder config ile gerçek raporlama yapmaz (`flutterfire configure` gerekli)
- Açık tema yalnızca Material bileşenlerini etkiler; `AppColors` sabit koyu palettir
- iOS build macOS/Xcode ortamı gerektirir
