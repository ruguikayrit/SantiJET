# ŞantiJET Mühendis — Agent Brief

## Ürün

**ŞantiJET Mühendis**, ŞantiJET ekosisteminin yapı mühendisliği hesap uygulamasıdır.
İlk odak: **TBDY-2018 Madde 9B** — tam penetrasyonlu küt kaynaklı kiriş–kolon birleşim hesabı.

Klasör: `artifacts/santijet-muhendis`  
Paket adı: `santijet_muhendis`  
Uygulama kimliği: `com.santijet.santijet_muhendis`

## Görev (bu brief)

1. TBDY-2018 birleşim hesabını tamamla (formüller, katalog, uygunluk kontrolleri, Excel doğrulama).
2. UI’yi ŞantiJET diline hizala (bolt + wordmark splash, electric blue `#0055FF`, Inter/Rajdhani, SJ kart/rozet bileşenleri, Türkçe saha dili).
3. Marka adı: **ŞantiJET Mühendis** — splash ürün satırı: **MÜHENDİS**.

## Hesap kapsamı

### Girdiler
- Çelik sınıfı: S235 / S275 / S355 / S450 (Fy, Fu, Ry, Rt — Tablo 2.1A + Tablo 9.2)
- Kolon profili: HEB / IPB (HE-B)
- Kiriş profili: IPE
- Yayılı yük `w` [kN/m]
- Açıklık `L` [m]

### Çıktılar
| Sembol | Açıklama |
|--------|----------|
| Cpr | `(Fy+Fu)/(2·Fy) ≤ 1.2` |
| Mpr | `Cpr · Ry · Fy · Wplx` |
| Lh | `L − d_kolon` |
| Vh | `2·Mpr/Lh + w·Lh/2` |
| Mf | `Mpr + Vh·Sh` (bu detayda Sh=0) |
| Vu | `Vh` |
| φVn | `0.6 · Fy · Aw · Cv1` |

### Uygunluk kontrolleri
- Tablo 9B.3 kiriş yüksekliği (`d ≤ 920 mm`)
- Tablo 9B.3 flanş kalınlığı (`tf ≤ 25 mm`)
- Açıklık/yükseklik oranı (`7 ≤ L/d ≤ 20`)
- Gövde narinliği (`h/tw ≤ 2.65√(E/(Ry·Fy))`)
- Kesme kapasitesi (`φVn ≥ Vu`)

### Doğrulama senaryosu (Excel)
S235 + IPB (HE-B) 260 + IPE 300 + w=9 + L=4.5  
→ `Mpr ≈ 248.1 kNm`, `Vh ≈ 136.1 kN`, `φVn ≈ 300.3 kN` → **UYGUN**

## UI / dil kuralları

- ŞantiJET Demir / BFA tasarım sistemi: `AppColors`, `AppTypography`, `SJStatusBadge`, `SJCard` desenleri.
- Açılış: bolt + wordmark + electric blue ürün satırı (Demir/BFA splash ile aynı kompozisyon).
- Sarı dolgulu düzenlenebilir alanlar (Excel sarı hücre metaforu).
- Canlı hesap — girdi değişince sonuç anında güncellenir.
- Durum rozetleri: **UYGUN** / **UYGUN DEĞİL**.
- Metinler Türkçe; yönetmelik referansları korunur (`TBDY-2018 · Madde 9B`).

## Çalıştırma

```bash
cd artifacts/santijet-muhendis
flutter pub get
flutter test
flutter run -d chrome   # veya: pnpm dev:muhendis
```

## Staging önizleme

https://ruguikayrit.github.io/SantiJET/muhendis/

Deploy: `.github/scripts/build-muhendis-pages.sh` → GitHub Pages (`deploy-github-pages.yml`).

## Bilinçli sınırlar (v1)

- Sh = 0 (tam penetrasyonlu küt kaynak, mafsal kolon yüzünde)
- Montaj cıvataları bilgi amaçlı (2×M16)
- Katalog: IPE + HEB; HEA/HEM sonraki faz
- PDF rapor / Demir entegrasyonu sonraki faz
