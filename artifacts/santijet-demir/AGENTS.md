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
- `PointerInterceptor` header çarkında yok (dokunuşu yutuyordu).
- Ana sayfa wordmark header; iç sayfalar bolt + DEMİR + sayfa adı.
- Shell body `SafeArea(bottom: false)` — üst inset status bar / staging bandı için.

Kaynak: `lib/core/widgets/santijet_header.dart`, `lib/features/shell/main_shell.dart`, `app_bottom_nav_bar.dart`.

## Ana sayfa / Ayarlar (kilitli)

- **Günlük Brifing** ve **Demir Tahmin Motoru** kartı anasayfada yok. Geri koyma.
- **Proje İlerleme Durumu** altında formül satırı yok (`Proje ilerleme = planlanan kullanım toplamı / keşif miktarı`). Geri koyma.
- Ayarlar listesinde **Proje Bilgileri** ve **Dokunma Titreşimi** yok. Geri koyma.

## Analiz / Rapor (kilitli)

- Fire özeti buton metni: `(tahvil ile fire analizi yap)`. Eski “Fire Analizi Yap”e dönme.
- Raporlar listesinde turuncu **DEMO — 16 rapor…** bandı yok. Geri koyma. Demo PDF veri (`useDemoReports`) ayrı; bandı açmak demek değil.

## Web / ölü alan / dokunuş (kilitli)

- `AppMediaQuery`: `padding.bottom = 0`. Alt nav inset = yalnız `MediaQuery.viewPadding` (yapay iOS +34 yok).
- Staging HTML bandı: `pointer-events:none`. DEMİR’de `flutter-view` / `flt-glass-pane` `top:28px` + yükseklik kısaltma **kalır** (header çarkının tıklanması için). PRO’daki “flutter-view kaydırma yok” kuralını Demir’e uygulama.
- `/demir/` yayınla. Eski `/staging/` yalnızca `/demir/` yönlendirmesi. Canlı kökü Demir önizleme ile değiştirme.
- Deploy’da `web/index.html` `APP_VERSION` bump.

Giriş: wordmark üstü bolt **108**. Küçültme.

Kaynak: `lib/core/responsive/app_safe_area.dart`, `web/index.html`, `.github/scripts/build-santijet-pages.sh`.

## Git / deploy

Dal: `staging`. Commit mesajı `feat(demir):` / `fix(demir):` / `docs(demir):`. Yalnızca demir dosyaları (+ bu brief / demir kuralı / pages betiği).

Push concurrency iptal ederse: `gh workflow run deploy-github-pages.yml --ref staging`
