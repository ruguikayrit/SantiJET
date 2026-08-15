# ŞantiJET BETON

Şantiye beton yönetimi — keşif, sipariş, döküm ve laboratuvar basınç dayanımı (Test).

Hive-only offline; Türkçe UI; ŞantiJET Demir / Puantaj görsel dili.

## Kabuk (kilitli)

Bu düzen bilerek kilitlidir. Sohbet geçmişi olmadan da geri alınmamalıdır.

| Yer | Durum |
|-----|--------|
| Alt nav | Ana Sayfa · Keşif · Sipariş · Döküm · **Test** |
| Ayarlar | Navda **yok**. Sağ üst dişli (`SantijetHeader`) → `/ayarlar` (root navigator) |
| Bildirim zili | **Yok** (`showNotification: false`) |
| Test | `QualityScreen`, `/test` (`AppRoutes.kalite` aynı yol) |
| Kaydırma | Sekmeler arası yatay kaydırma kapalı |

Ayarlar listesi yalnızca: Projelerim, Tema, Demo veriyi yükle, Hakkında, Tüm Verileri Sil. **Basınç dayanım raporları** ve **Aktif proje özeti** bu listede durmaz.

Ana sayfa proje seçici: Puantaj gibi bottom sheet (Projelerim’e gitmez). Döküm kartı etiketi **Sipariş** (eski “Plan” değil). Sipariş listesinde tekrarlayan “Siparişler” başlığı yok.

## Test (basınç)

- Eleman grupları: temel / kolon / perde / döşeme (eski `kolon_perde` → kolon).
- Filtre: yapısal eleman + durum (Uygun / Uygunsuz / Sonuç bekleyen).
- Yeni/düzenle formunda **İptal**. PDF ve Excel dışa aktarma. Dışa aktarma filtrelenmiş listeyi kullanır.
- Anasayfa Beton Numune özeti: grup başına uygun + uygunsuz (+ bekliyor varsa).

## Geliştirme

```bash
pnpm dev:beton

# veya
cd artifacts/santijet-beton
flutter pub get
flutter run -d chrome
```

Yerel Flutter SDK (Windows): `C:\Users\Pc\flutter-sdk\bin\flutter.bat`.

## Pages

Staging önizleme: https://ruguikayrit.github.io/SantiJET/beton/

Kaynak `staging` dalından; deploy `.github/workflows/deploy-github-pages.yml` + `build-beton-pages.sh`. Push concurrency ile iptal olursa `gh workflow run deploy-github-pages.yml --ref staging`. Yalnızca `artifacts/santijet-beton` dosyalarını commit et; Demir / diğer ürün ağaçlarına dokunma.
