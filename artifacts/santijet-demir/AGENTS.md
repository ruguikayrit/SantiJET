# ŞantiJET DEMİR — agent brief

Bu dosya sohbet geçmişinin yerine geçer. Demir işinde bağlayıcıdır.

Kapsam: yalnızca `artifacts/santijet-demir/**` (+ bu brief, `.cursor/rules/santijet-demir.mdc`, gerekirse `build-santijet-pages.sh`). Beton, Puantaj, Maliyet, Malzeme, Mühendis, **PRO (`santijet-ana`)** veya başka ürüne dokunma.

Staging (önizleme): https://ruguikayrit.github.io/SantiJET/demir/
Canlı kök (`main`): https://ruguikayrit.github.io/SantiJET/

## PRO / diğer üründen kopyalama yok

PRO splash skip, staging otomatik oturum, onboarding atlama, 16 modüllü hub **asla** Demir’e kopyalanmaz. Beton kabuğu da kopyalanmaz. Tersi de yok: Demir işi başka ürüne taşınmaz.

## Kabuk (kilitli — geri alma)

Alt nav: **Ana Sayfa · Sipariş · Gelen Demir · Saha Sayım · Analiz**

- Ayarlar alt navda yok. Sağ üst `SantijetHeader` **dişli** (`Icons.settings_outlined`) → `AppRoutes.settings`.
- Bildirim zili yok. `showNotification` varsayılan `false`; açma. Avatar / baş harf butonu yok (çark kullan).
- `PointerInterceptor` header çarkında yok (dokunuşu yutuyordu); alt navda web için kalır.
- Alt nav: Saha (`santijet-puantaj`) stil / kurgu — `AppColors.surface` + üst kenarlık, lift dışarıda, `electricBlue` / `textMuted`, klavyede gizle, `Router.neglect`. Tema `dividerColor` / `onSurfaceVariant` ile boyama yok.
- Ana sayfa proje seçici Saha ile aynı: logo kutusu + firma / iş adı / iş kodu; tıklanınca **İş seçin** alt sayfa (projeler listesine gitmez). Geri alma.
- Ana sayfa wordmark header; iç sayfalar bolt + DEMİR + sayfa adı.
- Shell body `SafeArea(bottom: false)` — üst inset status bar için.

Kaynak: `lib/core/widgets/santijet_header.dart`, `lib/features/shell/main_shell.dart`, `app_bottom_nav_bar.dart`.

## Giriş / Misafir (kilitli)

- Giriş ekranında **Misafir girişi · Demo ile dene** vardır. Misafir yerel oturum + Demo Şantiye yükler.
- Misafir **premium paket satın alamaz** (Abonelik ekranı + `setSubscriptionPlan` koruması). Üyelik açmadan satın alma yok.
- Misafir buluta yazılmaz; proje oluşturma yerelde kalır.

- **Günlük Brifing** ve **Demir Tahmin Motoru** kartı anasayfada yok. Geri koyma.
- **Proje İlerleme Durumu** altında formül satırı yok (`Proje ilerleme = planlanan kullanım toplamı / keşif miktarı`). Geri koyma.
- Ayarlar listesinde **Proje Bilgileri** ve **Dokunma Titreşimi** yok. Geri koyma.
- Ayarlar’da **Demo veriyi yükle** vardır (Yedekleme sonrası). Keşif / sipariş / teslimat / sayım / CAD metraj örneği; aktif proje **Demo Şantiye**. Kaldırma.

## Analiz / Rapor (kilitli)

- Analiz ekranında **Tahvil Hesaplayıcı** kartı / bölümü yok. Geri koyma.
- DWG analiz listesi kartının altında **İmalattan Veri Al** (mavi) sonra **Fire analizi yap** (yeşil). Üstte import butonu yok.
- Fire özeti paneli yalnız fire analizi tamamlandıktan sonra görünür; panel içinde **Fire analizi yap** yok.
- Analiz veri kaynağı: **İmalattan Veri Al** (CAD metrajı imalata gönderilmiş kayıtlar). **Ön İmalat** sekmesi / “Ön İmalattan Veri Al” yok; geri koyma.
- Keşif sekmeleri yalnız **İmalat · Otomatik Metraj** (çerçeveli başlık). Üçüncü **Ön İmalat** sekmesi yok.
- Fire analizi **tahvilsiz**: zayiatsız kesim + minimum fire (boy eşleştirme + stok kesim). Tahvil banner / `(tahvil ile fire analizi yap)` / tahvil zorunluluğu yok. Buton: **Fire analizi yap**. KPI: **Kesim Fire**.
- Raporlar listesinde turuncu **DEMO — 16 rapor…** bandı yok. Geri koyma. Demo PDF veri (`useDemoReports`) ayrı; bandı açmak demek değil.

## Web / ölü alan / dokunuş (kilitli)

- `AppMediaQuery`: `padding.bottom = 0`. Alt nav inset = yalnız `MediaQuery.viewPadding` (yapay iOS +34 yok).
- Turuncu **STAGING ÖNİZLEME** HTML şeridi yok (`#santijet-staging-banner`). 28px spacer ve `flutter-view` / `flt-glass-pane { top:28px }` kaydırması yok. `build-santijet-pages.sh` bunları enjekte etmez. Geri koyma — header dişli dokunuşunu bozar. `--dart-define=DEPLOY_CHANNEL=staging` kalır.
- `/demir/` yayınla. Eski `/staging/` yalnızca `/demir/` yönlendirmesi. Canlı kökü Demir önizleme ile değiştirme.
- Deploy’da `web/index.html` `APP_VERSION` bump.

Giriş: wordmark üstü bolt **108**. Küçültme.

Kaynak: `lib/core/responsive/app_safe_area.dart`, `web/index.html`, `.github/scripts/build-santijet-pages.sh`.

## Git / deploy

Dal: `staging`. Commit mesajı `feat(demir):` / `fix(demir):` / `docs(demir):`. Yalnızca demir dosyaları (+ bu brief / demir kuralı / pages betiği).

Push concurrency iptal ederse: `gh workflow run deploy-github-pages.yml --ref staging`
