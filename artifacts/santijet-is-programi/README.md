# ŞantiJET İş Programı

Şantiye faaliyetlerini planlamak, sahadaki ilerlemeyi kaydetmek ve gecikmeleri
anında görmek için bağımsız Flutter uygulaması.

## V1
- Program: MS Project Giriş tablosu (Ad, Süre, Başlangıç, Bitiş, Öncüller)
- İzleme: % Tamamlanma, fiili/kalan süre ve iş
- Takvim: liste/Gantt görünümü, bugün çizgisi ve filtreler
- Özet: plan AG / gerçek AG / kalan AG, gecikenler
- Aktar: MS Project, Excel ve PDF alışverişi
- Ayarlar: Hesap, İş kodu, Projelerim, tema, yedek, tanıtım
- Yerel Hive veri deposu (`isprog_` kutuları)
- 10 faaliyetli iki şantiye demo programı
- Açık/koyu tema ve tek seferlik IAP lisans iskeleti

CPM, kritik yol hesabı, kaynak dengeleme, bulut, hesap ve abonelik yoktur.

## MS Project ile çalışma

Alışveriş dosya üzerinden yürür; canlı bağlantı yoktur.

| Biçim | Dışa | İçe |
| --- | --- | --- |
| MS Project XML (`.xml`) | var | var |
| Excel (`.xlsx`) | var | var |
| PDF | var | yok |

Dışa aktarılan XML, MS Project'in kendi alışveriş biçimi olan MSPDI'dir;
Project "Dosya → Aç" ile açar, tarihleri ve ilerlemeyi yeniden hesaplar.
Her şantiye bir özet görev olur, faaliyetler altına yazılır ve sorumlular
kaynak ataması olarak taşınır.

Excel dosyasının `Task_Table` sayfası Project alan adlarıyla
(`Name`, `Duration`, `Start`, `Finish`, `% Complete`, `Resource Names`, …)
yazılır; Project'in içe aktarım sihirbazı sütunları kendiliğinden eşler.
Şantiye adı `Text2` sütununda taşınır.

`.mpp` doğrudan okunmaz. Project içinde
**Dosya → Farklı Kaydet → MS Project XML (\*.xml)** ile kaydedip o dosya
seçilir.

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

Önizleme: https://ruguikayrit.github.io/SantiJET/is-programi/
