# ŞantiJET PRO — agent brief

Bu dosya sohbet geçmişinin yerine geçer. PRO işinde bağlayıcıdır.

Kapsam: yalnızca `artifacts/santijet-ana/**`. RN `santiye-takip` ve **Beton** dahil başka ürüne dokunma.

Staging: https://ruguikayrit.github.io/SantiJET/pro/

## Beton’a dokunma

PRO splash, staging otomatik oturum, onboarding atlama ve 16 modüllü hub Beton’a kopyalanmaz.
Beton kilitli: `artifacts/santijet-beton/AGENTS.md`.

## Staging oturum (kilitli)

`DEPLOY_CHANNEL=staging` (Pages build `--dart-define`):

- Constructor’da senkron `_loadSync` + `ensureStagingSession` (Hive await yok).
- Redirect içinde state mutate etme. Staging’de onboarding kapısı bypass.
- Boş/orphan `currentUserId` veya `none` izinli roller 16 modülü gizler; varsayılan `santiye-sefi` + `Role.defaultRoles()` zorunlu.
- Banner `flutter-view` `top` kaydırmaz (`pointer-events:none` overlay). Cache: `web/index.html` `APP_VERSION`.

## Kabuk

Splash → (prod) onboarding/login veya (staging) ana sayfa. Hub: izinli 16 modül + Asistan/Rapor/Ayarlar. RN `santiye-takip` dosyalarına dokunma.

## Git / deploy

Dal: `staging`. Mesaj: `feat(pro):` / `fix(pro):` / `docs(pro):`. Yalnızca `santijet-ana` (+ bu brief / `.cursor/rules/santijet-ana.mdc`).

Push concurrency iptal ederse: `gh workflow run deploy-github-pages.yml --ref staging`
