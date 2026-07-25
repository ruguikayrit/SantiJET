# ŞantiJET Puantaj

ŞantiJET ürün ailesinin **Puantaj** uygulaması (Flutter).

Personel bazlı günlük devam kaydı, haftalık/aylık cetvel. Görsel dil
**ŞantiJET Demir / BFA** ile ortaktır; iş kurgusu ana mobil uygulamadaki
(`artifacts/santiye-takip`) Puantaj modülünden alınmıştır.

> Demir’in “Günlük Puantaj” (imalat × ekip sayıları) özelliğinden farklıdır.
> Bu uygulama kişi-gün attendance modelini kullanır.

## Kurgu (santiye-takip paritesi)

| Durum | Kısa | Saat |
|-------|------|------|
| Mevcut | M | 8 |
| Yarım Gün | Y | 4 |
| İzinli / Raporlu / Mazeret / Res. Tatil / Yok | İ R Mz T X | 0 |

- Günlük giriş, toplu “Tümünü Mevcut/Yok”, “Dünden Kopyala”
- Haftalık / aylık cetvel (firma gruplu)
- Personel + proje yönetimi (Hive, cihaz içi)

## Mimari

Demir / BFA deseni: Riverpod + go_router + Hive + SJ design system.

```
lib/
  core/          tema, SJ bileşenleri, routing
  domain/        Attendance, Person, Project, status
  data/          Hive providers
  features/      home, puantaj, personnel, projects, settings
```

## Çalıştırma

```bash
cd artifacts/santijet-puantaj
flutter pub get
flutter run
```

## Staging önizleme (Safari / farklı ağlar)

| Ortam | URL |
|-------|-----|
| **Puantaj staging** | https://ruguikayrit.github.io/SantiJET/puantaj/ |
| DEMİR staging | https://ruguikayrit.github.io/SantiJET/staging/ |
| DEMİR canlı | https://ruguikayrit.github.io/SantiJET/ |
| BFA | https://ruguikayrit.github.io/SantiJET/bfa/ |

Üstte turuncu **STAGING ÖNİZLEME** bandı görünür. iPhone Safari’de açıp
**Paylaş → Ana Ekrana Ekle** ile PWA gibi kullanılabilir.

```bash
# staging branch'e push → /puantaj/ ~3–5 dk içinde güncellenir
git checkout staging
git add artifacts/santijet-puantaj .github/scripts/build-puantaj-pages.sh .github/workflows/deploy-github-pages.yml
git commit -m "..."
git push origin staging
```

Manuel: Actions → **Deploy ŞantiJET GitHub Pages** → **Run workflow**.

## Fazlar

| Faz | İçerik | Durum |
|-----|--------|-------|
| 1 | İskelet + tema + domain + günlük/haftalık/aylık puantaj | ✅ |
| 2 | PIN / rol yetkileri (view/edit) | ⬜ |
| 3 | Cetvel HTML/XLSX export | ⬜ |
| 4 | Günlük rapor entegrasyonu | ⬜ |
| 5 | Bulut senkron (opsiyonel) | ⬜ |
