# ŞantiJET İş Programı

Şantiye faaliyetlerini planlamak, sahadaki ilerlemeyi kaydetmek ve gecikmeleri
anında görmek için bağımsız Flutter uygulaması.

## V1
- Program: şantiye seçimi, KPI'lar ve faaliyet listesi
- Takvim: liste/Gantt görünümü, bugün çizgisi ve filtreler
- Özet: durum kırılımı, gecikenler ve CSV dışa aktarımı
- Yerel Hive veri deposu (`isprog_` kutuları)
- 10 faaliyetli iki şantiye demo programı
- Açık/koyu tema ve tek seferlik IAP lisans iskeleti

CPM, kritik yol, bağımlılık, kaynak dengeleme, bulut, hesap ve abonelik yoktur.

## Çalıştırma

```bash
flutter pub get
flutter run -d chrome
```

## Doğrulama

```bash
flutter analyze
flutter test
```

Pages derlemesi:

```bash
.github/scripts/build-is-programi-pages.sh
```

Hedef taban yolu `/is-programi/` olur.
# santijet_is_programi

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
