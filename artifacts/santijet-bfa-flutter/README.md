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

## Yerel kullanıcı verisi (Faz 9)

- **Özel analizler:** `userAnalizProvider` (Hive `user_analizleri`) — ekle,
  güncelle, sil, sistem kaydını kopyaya çevirme. `catalogProvider`, resmi
  katalogla kullanıcı/kopya analizlerini birleştirir.
- **Keşif:** `KesifProject` / `KesifSatiri` modelleri + `kesifProvider`
  (Hive `kesif_projects`) — proje oluştur/sil, satır ekle, miktar güncelle,
  satır sil, toplam hesaplama.
- **Ekranlar:** Keşif listesi ve detay ekranı gerçek Hive verisine bağlıdır.
  Poz ekleme modalı ve keşif Excel importu sonraki iterasyonlarda bu provider
  üzerine bağlanacaktır.

## PDF Export (Faz 10)

- `data/services/analiz_pdf_export_service.dart` — Flutter `pdf` + `printing`
  altyapısıyla A4 dikey analiz raporu üretir.
- Rapor yapısı RN `analizExport.ts` ile uyumludur: ŞantiJET başlığı, bilgi
  grid'i, poz tarifi, malzeme/işçilik/ekipman kalem tabloları, maliyet özeti,
  yapım şartları ve notlar.
- Türkçe karakter ve offline güvenilirlik için paketlenmiş Inter/Rajdhani
  fontları PDF içine gömülür.
- Analiz detay ekranındaki **PDF** butonu gerçek paylaşıma bağlandı.

## Excel Export (Faz 11)

- `data/services/analiz_excel_export_service.dart` — standart OpenXML `.xlsx`
  üretir (ZIP + XML).
- `excel` paketi güncel `pdf` paketiyle `xml` sürüm çakışması yarattığı için
  deprecated/uyumsuz paket kullanılmadı; `.xlsx` doğrudan üretildi.
- Analiz detay ekranındaki **Excel** butonu gerçek `.xlsx` paylaşımına bağlandı.
- Excel içeriği: ŞantiJET başlığı, poz bilgileri, kalem tablosu, maliyet özeti,
  poz tarifi, yapım şartları ve notlar.

## Ayarlar (Faz 12)

- Tema modu (`system` / `light` / `dark`) Hive `settings` kutusunda kalıcıdır.
- Ayarlar ekranı gerçek yerel verileri gösterir: özel analiz, favori, son
  görüntülenen, keşif sayıları.
- JSON yedek dışa/içe aktarma eklendi (`BackupService`):
  `userAnalizleri`, `favoriteIds`, `recentIds`, `kesifProjects`, `themeMode`.
- İçe aktarmada birleştir/değiştir akışı ile provider'lara uygulanır.
- Hukuki sayfa bağlantıları gerçek ekranlara bağlanmıştır.

## Hukuki Sayfalar (Faz 13)

- Gizlilik Politikası ve Kullanım Koşulları gerçek route/screen olarak eklendi.
- Kaynaklar ekranı, resmi YFK bağlantılarını listeler.
- Resmi kaynak açmadan önce onay modalı gösterilir; `url_launcher` ile sistem
  tarayıcısında açılır.
- Ayarlar ekranındaki hukuki bağlantılar gerçek ekranlara bağlandı.

## Performans (Faz 14)

- `CatalogData`, analiz listelerini poz numarasına göre tek sefer sıralar.
- Arama haystack'leri katalog yüklenirken önceden hesaplanır; her tuş vuruşunda
  13K kaydın metni tekrar birleştirilmez.
- `CatalogData.searchIn()` limit destekler ve sıralı kaynak listede tekrar sort
  yapmaz.
- Disiplin kategori listeleri cache'lenir.
- Analiz listesinde scroll cache + klavye-dismiss davranışı eklendi.
- Performans davranışları için `catalog_performance_test.dart` eklendi.

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
| **8** | **Analiz Detay Sayfası** | ✅ Tamamlandı |
| **9** | **Özel Analizler + Keşif (kalıcılık)** | ✅ Tamamlandı |
| **10** | **PDF Export** | ✅ Tamamlandı |
| **11** | **Excel Export** | ✅ Tamamlandı |
| **12** | **Ayarlar** | ✅ Tamamlandı |
| **13** | **Hukuki Sayfalar** | ✅ Tamamlandı |
| **14** | **Performans Optimizasyonu** | ✅ Tamamlandı |

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
