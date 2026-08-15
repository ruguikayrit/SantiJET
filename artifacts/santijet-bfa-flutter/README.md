# ŞantiJET Maliyet — Flutter

ŞantiJET ürün ailesinin **ŞantiJET Maliyet** uygulaması (eski ad: ŞantiJET BFA /
Birim Fiyat Analizleri). Klasör adı şimdilik `santijet-bfa-flutter` (rename Faz 2).

**Ürün kapsamı:** birim fiyat analizi · keşif · metraj · yaklaşık maliyet  
**Pages path:** `/maliyet/` (eski `/bfa/` yönlendirilir)

React Native sürümünden (`artifacts/imalat-poz-analizleri/`) **bağımsız** olarak,
ŞantiJET Design System ve Flutter mimarisiyle geliştirilmektedir.

## Kabuk (5 yüzey)

Ayarlar bottom tab değildir (`SantijetHeader` dişli).

| Tab | İçerik |
|-----|--------|
| Ana Sayfa | Şantiye seçici (`ProjectSwitcher`); özet ızgarası / Yeni Analiz FAB yok |
| Analiz | Katalog / disiplin / karşılaştır / favori girişleri (hub katalogu beklemez) |
| Metraj | Cetvel; poz metrajsız eklenir; disiplin başlıkları varsayılan kapalı |
| Keşif | Poz · tanım · metraj; kaydırarak sil; PDF’de fiyat sütunu yok |
| Y.Maliyet | Sayfa başlığı **Yaklaşık Maliyet**; B.F. düzenlenir; PDF’de fiyat var |

Kilitli UX (geri alma): `.cursor/rules/santijet-maliyet.mdc`

### Metraj / Keşif / YM

- Poz Ekle miktar adımı yok (miktar 0). Metrajsız poz uyarısı sayfa başında.
- Poz satırı sağdan sola kaydırılarak silinir.
- Cetvel satırında X yok; silme düzenleme sheet’inde Kaydet yanında.
- PDF grupları: İnşaat İşleri · Elektrik İşleri · Mekanik İşler.
- Keşif PDF başlığı `METRAJ / KEŞİF CETVELİ`; YM `YAKLAŞIK MALİYET CETVELİ`.

## Deploy

`staging` dalına yalnız bu klasör (+ kural / bu README). Canlı:
https://ruguikayrit.github.io/SantiJET/maliyet/  
Deploy’da `web/index.html` içindeki `APP_VERSION` artırılır.

## Yedek / migration

- Hive kutuları değişmedi (`favorites`, `recent`, `settings`, `user_analizleri`, `kesif_projects`).
- Yeni yedek `app`: `santijet-maliyet`
- Eski yedekler okunur: `santijet-bfa-flutter`, `santijet-bfa`

## Teknoloji (ŞantiJET Demir referansıyla hizalı)

- **Flutter / Dart**
- **flutter_riverpod** — düz sağlayıcılar
- **go_router** — StatefulShellRoute
- **hive / hive_flutter** — yerel kalıcılık
- **Inter + Rajdhani** — paketlenmiş fontlar

## Geliştirme

```bash
flutter pub get
flutter run -d chrome --web-port=5173
# veya monorepo kökünden: pnpm dev:bfa
```

```bash
flutter analyze
flutter test
```
