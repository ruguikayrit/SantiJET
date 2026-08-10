# ŞantiJET PRO (Flutter)

Ana şantiye takip hub’ı — React Native `artifacts/santiye-takip` ile aynı kurgu ve görünüm.

**RN sürümü dokunulmadan kalır.** Bu klasör bağımsız Flutter uygulamasıdır.

## Özellikler

- Splash (bolt + wordmark + PRO), onboarding, PIN, bireysel/ekip workspace
- 12 tema (klasik, lacivert-pro, hi-vis, steel…) + dil (tr/en/ar/ru/de)
- Ana sayfa: 16 modüllü ızgara, izin filtresi, sıra/renk özelleştirme
- Modüller: Proje, Günlük Rapor, Puantaj, Görev, İmalat, İlerleme, Malzeme, Kantar, Keşif, İş Programı, Satın Alma, Hakediş, Yaklaşık Maliyet, Taşeron, Personel, Dosyalar
- Rapor (PDF/Excel), AI Asistan (bulut), veri yedekleme, kataloglar, YYBM
- Hive kalıcılık + api-server workspace sync

## Çalıştırma

```bash
# kökten
pnpm dev:ana

# veya
cd artifacts/santijet-ana
flutter pub get
flutter run -d chrome
```

Flutter SDK: `C:\Users\Pc\flutter-sdk` (PATH’e ekli değilse tam yol kullanın).

## Staging (GitHub Pages)

https://ruguikayrit.github.io/SantiJET/pro/
