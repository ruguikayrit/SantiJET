# ŞantiJET BFA — Flutter

ŞantiJET ürün ailesinin **Birim Fiyat Analizleri** uygulamasının Flutter sürümü.
React Native sürümünden (`artifacts/imalat-poz-analizleri/`) **bağımsız** olarak,
ŞantiJET Design System ve Flutter mimarisiyle yeniden geliştirilmektedir.

> React Native projesi salt-okunur referans ve arşiv olarak korunur. Bu proje
> tamamen ayrı bir uygulamadır.

## Teknoloji

- **Flutter 3.44.3 / Dart 3.12.2**
- **Riverpod** (riverpod_generator ile codegen)
- **go_router** — yönlendirme
- **freezed + json_serializable** — immutable veri modelleri
- **google_fonts** (Inter) — tipografi
- **Material 3**

## Mimari (feature-first)

```
lib/
├── main.dart                 # ProviderScope kökü
├── app/app.dart              # MaterialApp.router + tema/router bağlama
├── core/
│   ├── theme/                # SJColors, SJTypography, SJTheme, theme_provider
│   ├── router/               # app_router (go_router), routes
│   ├── constants/            # app_info, BfaDiscipline
│   ├── utils/                # (ileride) tr_search, formatters, id_gen
│   └── widgets/              # paylaşılan iskelet widget'ları
├── data/
│   ├── models/               # PozAnaliz, AnalizKalemi (freezed)
│   ├── repositories/         # (ileride) katalog, kullanıcı verisi, keşif, yedek
│   └── datasources/          # (ileride) asset JSON / yerel DB
└── features/
    ├── home/                 # ana sayfa (Faz 6)
    ├── analiz_list/          # analiz listesi (Faz 7)
    ├── analiz_detail/        # analiz detayı (Faz 8)
    ├── ozel_analiz/          # özel analizler (Faz 9)
    ├── karsilastir/          # karşılaştırma
    ├── kesif/                # keşif listesi + detayı (Faz 9)
    ├── export/               # PDF + Excel (Faz 10–11)
    ├── settings/             # ayarlar (Faz 12)
    └── legal/                # hukuki sayfalar (Faz 13)
```

## Migration Durumu

| Faz | Konu | Durum |
|-----|------|-------|
| **1** | **Proje Mimarisi** | ✅ Tamamlandı |
| 2 | Tema Sistemi | ⏳ ŞantiJET Demir'e hizalanacak |
| 3 | Design System | ⏳ |
| 4 | Reusable Components | ⏳ |
| 5 | Navigasyon | ⏳ (iskelet hazır) |
| 6–13 | Ekranlar & özellikler | ⏳ |
| 14 | Performans | ⏳ |

## Geliştirme

```bash
# Bağımlılıklar
flutter pub get

# Kod üretimi (freezed / json / riverpod)
dart run build_runner build

# Sürekli üretim (geliştirme sırasında)
dart run build_runner watch

# Analiz & test
flutter analyze
flutter test

# Çalıştırma
flutter run            # cihaz/emülatör
flutter run -d chrome  # web
```

## Notlar

- Resmi katalog JSON'ları Faz 7'de `assets/data/` altına kopyalanacaktır
  (~13.436 kayıt / ~19 MB). Bkz. `assets/data/README.md`.
- ŞantiJET Demir Flutter referans projesi erişime açıldığında tema ve design
  system token'ları (Faz 2–4) Demir ile birebir hizalanacaktır.
