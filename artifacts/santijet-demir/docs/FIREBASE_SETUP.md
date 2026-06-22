# Firebase Crashlytics Kurulumu

ŞantiJET DEMİR, `CrashReportingService` ile hem yerel Hive log hem de Firebase Crashlytics destekler.

## Hızlı Başlangıç

1. [Firebase Console](https://console.firebase.google.com/) üzerinde proje oluşturun.
2. FlutterFire CLI kurun:

```bash
dart pub global activate flutterfire_cli
```

3. Proje dizininde yapılandırın:

```bash
cd artifacts/santijet-demir
flutterfire configure
```

4. Oluşan `lib/firebase_options.dart` dosyası placeholder dosyasının yerini alır.
5. `android/app/google-services.json` ve `ios/Runner/GoogleService-Info.plist` otomatik güncellenir.

## Davranış

| Ortam | Crashlytics | Yerel Log |
|-------|-------------|-----------|
| Debug | Kapalı | Aktif (Hive `crash_logs`) |
| Release | Aktif | Aktif |

Firebase yapılandırılmamışsa uygulama çalışmaya devam eder; hatalar yerel olarak kaydedilir.

## Manuel Test

Debug modda Crashlytics kapalıdır. Release build ile test edin:

```bash
flutter run --release -d android
```

## Yerel Logları Görüntüleme

`CrashReportingService.instance.getLocalLogs()` ile son 50 hata kaydına erişilebilir.
