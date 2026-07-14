# Staging önizleme (DEMİR)

Canlı siteyi riske atmadan DEMİR değişikliklerini önizlemek için `staging` branch kullanılır.

## URL'ler

| Ortam | URL |
|---|---|
| **Canlı (production)** | https://ruguikayrit.github.io/SantiJET/ |
| **Staging önizleme** | https://ruguikayrit.github.io/SantiJET/staging/ |
| **BFA** | https://ruguikayrit.github.io/SantiJET/bfa/ |

Staging sürümünde üstte turuncu **STAGING ÖNİZLEME** bandı görünür.

## Günlük akış

```bash
# 1) Geliştirme (en hızlı — deploy yok)
cd artifacts/santijet-demir
flutter run -d chrome

# 2) Staging'e gönder (önizleme deploy)
git checkout staging
git merge main          # veya doğrudan staging'de geliştir
# ... değişiklikler ...
git add .
git commit -m "..."
git push origin staging
# → 3-5 dk sonra /staging/ güncellenir

# 3) Canlıya al (hazır olunca)
git checkout main
git merge staging
git push origin main
# → canlı site güncellenir
```

## Ne zaman hangi branch?

| Branch | Ne zaman push? | Sonuç |
|---|---|---|
| `staging` | Geliştirme / test / önizleme | Yalnızca `/staging/` güncellenir; canlı kök URL `main`'deki kodu gösterir |
| `main` | Onaylanmış, saha için hazır sürüm | Canlı site + `/staging/` (staging branch'ten) + BFA yeniden yayınlanır |

## GitHub Actions

- `deploy-github-pages.yml` — `main` push → production + BFA + staging klasörü
- `deploy-santijet-demir-staging-preview.yml` — `staging` push → aynı paket, staging kodu güncel

Her iki workflow da tam site paketini üretir (production silinmez).

## Yerel geliştirme vs staging deploy

- **Yerel:** anlık hot reload, hiç deploy yok
- **Staging deploy:** gerçek cihazda (iPhone Safari vb.) test için
- **Main deploy:** kullanıcıların gördüğü canlı sürüm

`deploy-santijet-demir-web.yml` yalnızca manuel acil durum içindir; normal akışta kullanmayın (BFA ve staging'i ezebilir).
