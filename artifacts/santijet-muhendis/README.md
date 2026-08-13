# ŞantiJET Mühendis

**TBDY-2018 çelik birleşim hesabı** — Tam penetrasyonlu küt kaynaklı kiriş–kolon birleşimi (Madde 9B).

Flutter uygulaması; ŞantiJET Demir / BFA tasarım sistemiyle hizalı.

## Ne hesaplar?

- Çelik sınıfı (S235 / S275 / S355 / S450) → Fy, Fu, Ry, Rt
- Kolon (HEB/IPB) + kiriş (IPE) kesit özellikleri
- `Cpr`, `Mpr`, `Lh`, `Vh`, `Mf`, `Vu`, `φVn`
- Tablo 9B.3 uygulama limitleri ve gövde narinlik / kesme kapasitesi kontrolleri

## Gereksinimler

- Flutter SDK 3.27+
- Dart 3.6+

## Kurulum

```bash
cd artifacts/santijet-muhendis
flutter pub get
```

## Çalıştırma

```bash
# Web
flutter run -d chrome

# veya monorepo kökünden
pnpm dev:muhendis
```

## Staging önizleme

| Ortam | URL |
|-------|-----|
| **Mühendis staging** | https://ruguikayrit.github.io/SantiJET/muhendis/ |
| DEMİR staging | https://ruguikayrit.github.io/SantiJET/staging/ |
| BFA | https://ruguikayrit.github.io/SantiJET/bfa/ |

Üstte turuncu **STAGING ÖNİZLEME** bandı görünür.

```bash
# staging branch'e push → /muhendis/ ~3–5 dk içinde güncellenir
git push origin staging
```

Manuel: Actions → **Deploy ŞantiJET GitHub Pages** → **Run workflow**.

## Test

```bash
flutter test
```

## Doğrulama örneği

Excel çıktısıyla aynı senaryo varsayılandır:

| Girdi | Değer |
|-------|-------|
| Çelik | S235 |
| Kolon | IPB (HE-B) 260 |
| Kiriş | IPE 300 |
| w | 9 kN/m |
| L | 4.5 m |

Beklenen: `Mpr ≈ 248.1 kNm`, `Vh ≈ 136.1 kN`, `φVn ≈ 300.3 kN` → **uygun**

## Agent brief

Ürün kapsamı ve UI kuralları: kök dizindeki [`AGENT_BRIEF.md`](../../AGENT_BRIEF.md).
