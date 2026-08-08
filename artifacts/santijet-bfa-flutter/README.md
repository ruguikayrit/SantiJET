# ŞantiJET Maliyet — Flutter

ŞantiJET ürün ailesinin **ŞantiJET Maliyet** uygulaması (eski ad: ŞantiJET BFA /
Birim Fiyat Analizleri). Klasör adı şimdilik `santijet-bfa-flutter` (rename Faz 2).

**Ürün kapsamı:** birim fiyat analizi · keşif · metraj · yaklaşık maliyet  
**Pages path:** `/bfa/` (deploy path rename ayrı iş)

React Native sürümünden (`artifacts/imalat-poz-analizleri/`) **bağımsız** olarak,
ŞantiJET Design System ve Flutter mimarisiyle geliştirilmektedir.

## Kabuk (4 yüzey)

| Tab | İçerik |
|-----|--------|
| Ana Sayfa | Özet kartları, son analizler, açık keşifler, YM, hızlı aksiyonlar |
| Analiz | Özel analiz, karşılaştırma, katalog girişleri |
| Birim Fiyat | Poz arama, katalog fiyatı, keşife uygula |
| Keşif | Satırlar + **Metraj** + **YM** (ayrı tab değil) |

Ayarlar bottom tab değildir (header / Ana Sayfa).

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
