# ŞantiJET BETON — agent brief

Bu dosya sohbet geçmişinin yerine geçer. Beton işinde bağlayıcıdır.

Kapsam: yalnızca `artifacts/santijet-beton/**`. Demir, Puantaj, Maliyet, Malzeme, Mühendis, **PRO (`santijet-ana`)** veya başka ürüne dokunma.

## PRO’dan kopyalama yok

ŞantiJET PRO (`artifacts/santijet-ana`, `/pro/`) işi Beton’a taşınmaz:

- Staging otomatik oturum, onboarding atlama, splash skip
- 16 modüllü hub, “Hızlı Başla”
- PRO splash / bildirim zili / Ayarlar alt nav

## Kabuk (kilitli — geri alma)

Alt nav: **Ana Sayfa · Keşif · Sipariş · Döküm · Test**

- Ayarlar alt navda yok. Sağ üst `SantijetHeader` dişli → `/ayarlar` (root navigator).
- Bildirim zili yok. `SantijetHeader.showNotification` varsayılan `false`; açma.
- Test = `QualityScreen`, `/test` (`AppRoutes.kalite` aynı yol).
- Ayarlar listesi: Projelerim, Tema, Demo veriyi yükle, Hakkında, Tüm Verileri Sil.
- Listeden çıkarılmış: Basınç dayanım raporları, Aktif proje özeti.
- Sekmeler arası yatay kaydırma kapalı (`popGestureEnabled: false`, `Router.neglect`, `PopScope`).
- Ana sayfa proje seçici: bottom sheet. Projelerim’e yönlendirme.
- Döküm kartı hacim kutuları: Planlanan döküm / Gerçekleşen döküm (eski “Sipariş” / “Dökülen” değil; “Plan” da değil).
- Ana sayfa özet kutuları aynı satırda eşit yükseklik (en yükseğe göre). Üçüncü kart başlığı: Planlanan ve Gerçekleşen; kutusu: Fark (eski “Sipariş · Gerçekleşen” / “Sipariş farkı” değil).
- Sipariş listesinde tekrarlayan “Siparişler” başlığı yok.
- Sipariş paylaşımı: projede birden fazla WhatsApp alıcısı; paylaşınca aynı metin hepsine. Kişi seçici yok. Eski tek numara listeye taşınır.

Kaynak: `lib/core/routing/app_router.dart`, `app_routes.dart`, `lib/features/shell/main_shell.dart`, `lib/core/widgets/santijet_header.dart`.

## Test (basınç)

Eleman: temel / kolon / perde / döşeme (eski `kolon_perde` → kolon).
Filtreler: Yapısal eleman / Durum / Zaman — açılır liste (`PopupMenuButton`).
**Rapor Al** sağ üstte ayarlar dişlisinin solunda (`SantijetHeaderDownloadButton`, Saha Puantaj AL ile aynı slot). **Rapor Ekle** diğer sayfalar gibi sağ alt `floatingActionButton`. PDF/Excel sheet.
Anasayfa numune özeti: uygun + uygunsuz.

## Tema

`SJCard` içinde chrome `AppTypography` / `textPrimary` kullanma. Kart mürekkebi: `cardText*` / `cardTitle*`. Kural: `.cursor/rules/santijet-beton-theme.mdc`.

## Git / deploy

Dal: `staging`. Commit mesajı `feat(beton):` / `fix(beton):` / `docs(beton):`. Yalnızca beton dosyaları.

Staging: https://ruguikayrit.github.io/SantiJET/beton/  
Push concurrency iptal ederse: `gh workflow run deploy-github-pages.yml --ref staging`
