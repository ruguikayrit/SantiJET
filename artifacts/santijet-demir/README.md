# ŞantiJET DEMİR

**Çelik Takip Sistemi** — Demir keşfi, sipariş, teslimat, saha sayımı ve analiz modülleri.

Flutter ile geliştirilmiş, tamamen çevrimdışı çalışan profesyonel inşaat operasyon uygulaması.

## Gereksinimler

- Flutter SDK 3.27+
- Dart 3.6+
- Android Studio / Xcode (mobil build için)

## Kurulum

```bash
cd artifacts/santijet-demir
flutter pub get
```

## Çalıştırma

```bash
# Web (geliştirme önizleme)
flutter run -d chrome

# Android
flutter run -d android

# iOS (macOS gerekli)
flutter run -d ios
```

## Proje Yapısı

```
lib/
├── core/           # Tema, routing, ortak widget'lar
├── domain/         # Entity'ler, enum'lar
├── features/       # Modül bazlı ekranlar
│   ├── splash/
│   ├── shell/
│   ├── dashboard/
│   ├── orders/
│   ├── incoming_rebar/
│   ├── field_count/
│   └── analysis/
├── bootstrap.dart  # Hive init
├── app.dart
└── main.dart
```

## Mimari

- **Clean Architecture + MVVM**
- **Riverpod** — state yönetimi
- **go_router** — navigasyon (StatefulShellRoute ile alt tab bar)
- **Hive** — yerel depolama

## Figma Kaynağı

Tasarım: [Design System for ŞantiJET](https://www.figma.com/make/TXkpKrhhRK39WnswmlmLGg/Design-System-for-%C5%9EantiJET)

## Uygulama Aşamaları

| Faz | Durum | İçerik |
|-----|-------|--------|
| 1 | ✅ | Proje kurulumu, tema, splash, dashboard, alt nav |
| 2 | ✅ | Siparişler modülü + Keşif modülü |
| 3 | ✅ | Gelen Demir + Saha Sayım |
| 4 | ✅ | Analiz + Raporlar |
| 5 | ✅ | Ayarlar + PDF/Excel export + boş durumlar |
| 6 | ⏳ | Cila, Crashlytics, QA |

## Alt Navigasyon

Dashboard · Siparişler · Gelen Demir · Saha Sayım · Analiz
