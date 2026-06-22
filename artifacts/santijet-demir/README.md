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
dart run flutter_launcher_icons
dart run flutter_native_splash:create
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

## Production Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (macOS + Xcode gerekli)
flutter build ios --release
```

## Proje Yapısı

```
lib/
├── core/
│   ├── animations/     # Fade, stagger, tap scale
│   ├── crash/          # CrashReportingService
│   ├── responsive/     # Tablet layout
│   ├── routing/        # go_router + page transitions
│   ├── theme/          # Figma design tokens
│   └── widgets/        # Paylaşılan bileşenler
├── data/               # Mock data + export servisi
├── domain/             # Entity'ler
├── features/           # Modül ekranları
├── bootstrap.dart      # Hive + Crashlytics init
├── firebase_options.dart
├── app.dart
└── main.dart
```

## Mimari

- **Clean Architecture + MVVM**
- **Riverpod** — state yönetimi
- **go_router** — navigasyon (StatefulShellRoute ile alt tab bar)
- **Hive** — yerel depolama
- **Firebase Crashlytics** — hata raporlama (opsiyonel, bkz. docs/FIREBASE_SETUP.md)

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
| 6 | ✅ | Cila, Crashlytics, QA, app icon, native splash |

## Alt Navigasyon

Dashboard · Siparişler · Gelen Demir · Saha Sayım · Analiz

## QA

Detaylı test matrisi: [docs/QA_MATRIX.md](docs/QA_MATRIX.md)

## Firebase

Crashlytics kurulumu: [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)

## iPhone (Mac yok)

Mac olmadan iPhone'da kullanım: [docs/IPHONE_MACSIZ.md](docs/IPHONE_MACSIZ.md)

GitHub Pages (Safari + Ana Ekrana Ekle):

```
https://ruguikayrit.github.io/santijet/
```

Yerel ağ (aynı Wi‑Fi):

```bash
./scripts/serve_web_ios.sh
```

## iPhone / iOS (Mac varsa)

Native iOS kurulum: [docs/IOS_KURULUM.md](docs/IOS_KURULUM.md)

## Release Checklist

- [ ] `flutterfire configure` ile gerçek Firebase projesi bağla
- [ ] Android signing config (`android/app/build.gradle`)
- [ ] iOS provisioning profile ve App Store Connect
- [ ] `flutter analyze` ve `flutter test` yeşil
- [ ] QA matrisindeki tüm ekranlar manuel doğrulandı
