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

- `deploy-github-pages.yml` — `main` veya `staging` push → production + `/staging/` + BFA (BFA hata verirse yine de DEMİR deploy edilir)

### Staging URL 404 alırsanız

1. **Actions** sekmesinde son `Deploy ŞantiJET GitHub Pages` çalışmasının **yeşil** olduğunu kontrol edin.
2. Kırmızıysa genelde BFA `analyze/test` değil artık; logda `staging preview missing` veya environment hatasına bakın.
3. **Settings → Environments → github-pages → Deployment branches** bölümünde `staging` branch'ine izin verin (veya kısıtlamayı kaldırın). Aksi halde `staging` push deploy'u anında reddedilir.
4. Alternatif: Actions → `Deploy ŞantiJET GitHub Pages` → **Run workflow** (manuel, `main` üzerinden çalışır; en güncel `staging` branch'ini okur).

`deploy-santijet-demir-web.yml` yalnızca manuel acil durum içindir; normal akışta kullanmayın (BFA ve `/staging/` klasörünü ezebilir).

## Yerel geliştirme vs staging deploy

- **Yerel:** anlık hot reload, hiç deploy yok
- **Staging deploy:** gerçek cihazda (iPhone Safari vb.) test için
- **Main deploy:** kullanıcıların gördüğü canlı sürüm

`deploy-santijet-demir-web.yml` yalnızca manuel acil durum içindir; normal akışta kullanmayın (BFA ve staging'i ezebilir).
