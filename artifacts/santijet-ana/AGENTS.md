# ŞantiJET PRO — agent brief

Bu dosya sohbet geçmişinin yerine geçer. PRO işinde bağlayıcıdır.

Kapsam: yalnızca `artifacts/santijet-ana/**` (+ bu brief, `.cursor/rules/santijet-ana.mdc`, gerekirse `build-pro-pages.sh`).
RN `artifacts/santiye-takip` ve **Beton** dahil başka ürüne dokunma.

Staging: https://ruguikayrit.github.io/SantiJET/pro/

## Geri alma (kilitli — sohbet gerekmez)

Aşağıdakileri “basitleştirme” diye geri çekme. Belirti: splash/`#/onboarding` takılması, Hızlı Başla’nın tıklanmaması, ana sayfada 16 modülün kaybolması.

| Konu | Kilit |
|------|--------|
| Yükleme | Constructor **senkron** `_loadSync`. Async `_load` + `await startLocalSession` / Hive timeout **yok**. |
| Staging oturum | `ensureStagingSession` → `santiye-sefi` + `Role.defaultRoles()`. Orphan `currentUserId` veya `none` izinler yetmez; `applyLocalSessionSync` çağır. Hive `put` fire-and-forget. |
| Router | Redirect içinde **state yazma**. Staging’de `needsOnboarding = false` (onboarding kapısı bypass). `refreshListenable` yalnız `(loaded, currentUserId, workspaceInfo?.id)`. |
| Splash | Staging: `ensureStagingSession` + `context.go(home)`. Prod: workspace/user yoksa onboarding. |
| Onboarding | **Hızlı Başla** → `applyLocalSessionSync` (await Hive yok). Staging’de post-frame otomatik `_quickStartLocal`. |
| Modüller | Hub `getPermission != none`. Hive’daki boş `santiye-sefi` izinleri `fromJson` içinde `Role.defaultRoles()`. |
| Web hit-test | Staging banner overlay, `pointer-events:none`. **`flutter-view { top:28px }` yok** (CanvasKit tıklamayı kaçırır). |
| Cache | `web/index.html` `APP_VERSION` her davranış/deploy değişiminde artır. |

Kaynak: `lib/data/providers/app_state_provider.dart`, `lib/core/routing/app_router.dart`, `lib/features/splash/splash_screen.dart`, `lib/features/onboarding/onboarding_screen.dart`, `lib/features/home/home_screen.dart`, `web/index.html`, `.github/scripts/build-pro-pages.sh`.

## Staging build

Pages: `--dart-define=DEPLOY_CHANNEL=staging`, `--base-href /SantiJET/pro/`.
Script banner ekler; flutter-view kaydırmaz.

## Kabuk

Splash → (prod) onboarding/login veya (staging) ana sayfa.
Hub: izinli 16 modül + Asistan / Rapor / Ayarlar (dişli). RN görünümüne uy; RN dosyasına dokunma.

## Git / deploy

Dal: `staging`. Mesaj: `feat(pro):` / `fix(pro):` / `docs(pro):`.

Push concurrency iptal ederse: `gh workflow run deploy-github-pages.yml --ref staging`
