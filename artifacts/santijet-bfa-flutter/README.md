# ŞantiJET BFA — Flutter

ŞantiJET ürün ailesinin **Birim Fiyat Analizleri** uygulamasının Flutter sürümü.
React Native sürümünden (`artifacts/imalat-poz-analizleri/`) **bağımsız** olarak,
ŞantiJET Design System ve Flutter mimarisiyle yeniden geliştirilmektedir.

> React Native projesi salt-okunur referans ve arşiv olarak korunur. Bu proje
> tamamen ayrı bir uygulamadır.

## Teknoloji (ŞantiJET Demir referansıyla hizalı)

- **Flutter 3.44.3 / Dart 3.12.2**
- **flutter_riverpod ^2.6.1** — düz sağlayıcılar (codegen kullanılmaz, Demir gibi)
- **go_router ^14.6.2** — yönlendirme
- **equatable** — elle yazılmış değişmez varlık sınıfları (freezed kullanılmaz)
- **hive / hive_flutter** — yerel kalıcılık (favoriler, son görüntülenenler)
- **Inter + Rajdhani** — paketlenmiş fontlar (offline; `assets/fonts/`)
- **intl** — biçimlendirme
- **Material 3**

> Stack ve tasarım token'ları, `artifacts/santijet-demir` referans projesinden
> **birebir** hizalanmıştır.

## Mimari (Demir konvansiyonu)

```
lib/
├── main.dart                 # bootstrap() çağrısı
├── bootstrap.dart            # WidgetsFlutterBinding + runApp(ProviderScope)
├── app.dart                  # SantijetBfaApp (MaterialApp.router)
├── core/
│   ├── theme/                # app_colors, app_typography, app_spacing,
│   │                         #   app_radii, app_shadows, app_theme, theme_mode_provider
│   ├── animations/           # app_animations (süre/eğri + StaggeredFadeIn)
│   ├── routing/              # app_router (StatefulShellRoute), app_routes, page_transitions
│   ├── constants/            # app_info
│   ├── utils/                # (ileride) tr_search, formatters, id_gen
│   └── widgets/              # paylaşılan widget'lar
├── domain/
│   ├── entities/             # PozAnaliz, AnalizKalemi (equatable + copyWith + JSON)
│   └── enums/                # KaynakTip, AnalizDiscipline, AnalizKalemTip
├── data/
│   ├── datasources/          # catalog_local_datasource (assets JSON → PozAnaliz)
│   ├── providers/            # catalog (FutureProvider), favorites + recent (Hive)
│   └── repositories/         # (ileride) kullanıcı verisi, keşif, yedek
└── features/
    ├── shell/                # MainShell — kalıcı alt navigasyon kabuğu
    ├── home/                 # ana sayfa (Faz 6)
    ├── analiz_list/          # analiz listesi (Faz 7)
    ├── analiz_detail/        # analiz detayı (Faz 8)
    ├── ozel_analiz/          # özel analizler (Faz 9)
    ├── karsilastir/          # karşılaştırma
    ├── kesif/                # keşif listesi + detayı (Faz 9)
    ├── export/               # PDF + Excel (Faz 10–11)
    ├── settings/             # ayarlar (Faz 12)
    └── legal/                # hukuki sayfalar (Faz 13)
```

## Tasarım Sistemi (Demir'den birebir)

**Token'lar (`core/theme/`):**
- **Renkler:** `AppColors` — canvas `#05070A`, electric blue `#0055FF`, koyu yüzeyler,
  durum renkleri + BFA modül vurguları (inşaat/mekanik/elektrik/keşif).
- **Tipografi:** `AppTypography` — Rajdhani (başlık/KPI) + Inter (gövde/etiket), 9 adımlı ölçek.
- **Boşluk/Yarıçap/Gölge:** `AppSpacing` (8pt), `AppRadii` (xs–full), `AppShadows` (5 seviye + glow).
- **Tema:** `AppTheme.light` / `AppTheme.dark` (Material 3).

**Bileşen kütüphanesi (`core/design_system/`)** — tek import: `design_system.dart`:
`SJCard`, `SJButton` (primary/secondary/ghost/destructive + loading), `SJInput`,
`SJSearchBar`, `SJModal` (sheet + confirm), `SJBottomNavigation`, `SJStatCard`,
`SJListItem`, `SJEmptyState`, `SJStatusBadge`, `SJFilterChips`.
Demir desenlerine dayanır; yapısal renkler `Theme`'den, marka/durum renkleri
`AppColors`'tan gelir (açık + koyu temada doğru görünüm). Görsel doğrulama:
`/tasarim-sistemi` galeri ekranı.

**BFA'ya özel bileşenler (`core/widgets/`)** — tek import: `app_widgets.dart`:
`ModuleTile`, `AnalizListItem`, `KalemRow`, `CostSummaryCard`, `MetrajInput`,
`DisciplineBadge`, `FavoriteButton`. SJ bileşenleri üzerine kuruludur.
İş mantığı: `domain/calc/analiz_hesap.dart` (RN `hesaplaAnalizToplam`),
biçimlendirme: `core/utils/app_format.dart` (TR para/sayı).

## Migration Durumu

| Faz | Konu | Durum |
|-----|------|-------|
| **1** | **Proje Mimarisi** | ✅ Tamamlandı |
| **2** | **Tema Sistemi (Demir hizalama)** | ✅ Tamamlandı |
| **3** | **Design System (SJ bileşenleri)** | ✅ Tamamlandı |
| **4** | **Reusable Components (BFA)** | ✅ Tamamlandı |
| **5** | **Navigasyon (bottom nav + geçişler)** | ✅ Tamamlandı |
| **6** | **Ana Sayfa + Veri Katmanı** | ✅ Tamamlandı |
| **7** | **Analiz Listeleri** | ✅ Tamamlandı |
| 8–13 | Ekranlar & özellikler | ⏳ |
| 14 | Performans | ⏳ |

## Geliştirme

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome   # web
```

> Kod üretimi (build_runner) **kullanılmaz** — Demir gibi düz Riverpod sağlayıcıları
> ve elle yazılmış varlık sınıfları tercih edilir.

## Notlar

- Resmi katalog JSON'ları Faz 7'de `assets/data/` altına kopyalanacaktır
  (~13.436 kayıt / ~19 MB). Bkz. `assets/data/README.md`.
- Referans proje: `artifacts/santijet-demir` (salt-okunur).
