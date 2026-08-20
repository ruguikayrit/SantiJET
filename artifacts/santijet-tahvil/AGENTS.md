# ŞantiJET Tahvil — agent brief

Bu dosya sohbet geçmişinin yerine geçer. Tahvil işinde bağlayıcıdır.

Kapsam: yalnızca `artifacts/santijet-tahvil/**` (+ bu brief, `.cursor/rules/santijet-tahvil.mdc`, gerekirse `build-tahvil-pages.sh`). DEMİR, Beton, PRO, Malzeme, SAHA, Maliyet veya Mühendis’e dokunma. Tersi de yok: Tahvil işi başka ürüne taşınmaz.

Staging: https://ruguikayrit.github.io/SantiJET/tahvil/

Turuncu **STAGING ÖNİZLEME** şeridi yok: `build-tahvil-pages.sh` `#santijet-staging-banner`, 28px spacer veya `flutter-view { top:28px }` basmaz. `--dart-define=DEPLOY_CHANNEL=staging` kalır. Geri koyma.

## Ürün

Demir tahvilini **sade, hızlı, profesyonel** hesaplayan ayrı uygulama.

- Tek fiyat. **Abonelik yok.** Hesap / bulut oturumu yok.
- Hive kutuları `tahvil_` önekli (`TahvilHive`). Çıplak `settings` açma.
- Alt nav: **Hesap · Teknik · Kayıtlar**. Ayarlar navda yok (sağ üst dişli).
- Teknik: demir birim ağırlık tablosu (kg/m = d² / 162) ve
  100 cm’de donatı alanı As (cm²) tablosu.
- Bildirim zili ve avatar yok.

Kaynak: `lib/features/shell/main_shell.dart`, `lib/core/widgets/santijet_header.dart`.

## Hesap kuralları (kilitli formül)

DEMİR tahvil motoru ile aynı saha kuralları; kopyala-yapıştır başka ürüne dönüş değil.

- Çap farkı ±4 mm
- Hedef As ≥ proje As
- Fazla kesit ≤ %5
- Aralık ≤ 25 cm
- Standart çap: 8, 10, 12, 14, 16, 18, 20, 22, 25, 28, 32, 36, 40, 50

## Git / deploy

Dal: `staging`. Commit mesajı `feat(tahvil):` / `fix(tahvil):` / `docs(tahvil):`.
Yalnızca tahvil dosyaları (+ bu brief / kural / pages betiği).
