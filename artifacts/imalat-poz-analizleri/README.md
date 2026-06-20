# ŞantiJET B.F.A.

Bağımsız **Birim Fiyat Analizleri** uygulaması. ŞantiJET ana uygulamasından (`artifacts/santiye-takip`) ayrıdır.

## Modüller

| # | Modül | Veri dosyası |
|---|--------|----------------|
| 01 | İnşaat B.F.A. | `assets/data/resmi-poz-analizleri.json` (1.879 analiz) |
| 02 | Mekanik Tesisat B.F.A. | `assets/data/resmi-mekanik-analizleri.json` (5.646 analiz — Cilt 1-3) |
| 03 | Elektrik Tesisat B.F.A. | `assets/data/resmi-elektrik-analizleri.json` (5.911 analiz — Cilt 1-3) |
| 04 | Favoriler | AsyncStorage (`santijet_ipa_favorites_v1`) |

Elektrik katalog ÇŞB YFK 2026 Cilt 1-3 PDF'lerinden üretilmiştir (5.911 kayıt).

## Özellikler

- 1.879 resmi inşaat + 5.646 mekanik + 5.911 elektrik tesisat analizi (lazy JSON yükleme)
- Arama, kategori filtresi, detay görünümü
- Düzenleme, kopyalama, silme (sistem kayıtları korunur)
- Kullanıcı analizleri AsyncStorage ile kalıcı
- Dışa aktarma (metin paylaşımı)

## Geliştirme

```bash
pnpm dev:ipa
```

### Telefon bağlantısı

**Bulut / farklı ağ:** `pnpm dev:ipa` otomatik **tunnel** moduna geçer (Cursor Agent ortamında).

**Yerel bilgisayar + aynı Wi‑Fi:** LAN modu için:
```bash
IPA_NETWORK_MODE=lan pnpm dev:ipa
```

### Sabit yer imi (QR burada)

| Bağlantı | Adres |
|----------|--------|
| **Yer imi sayfası** | http://localhost:24917 |
| Metro web | http://localhost:24916 |

Bu sayfa adresi **hiç değişmez**. QR tunnel modunda sayfa açıkken otomatik güncellenir — yeni QR aramanıza gerek kalmaz.

LAN modunda host `.expo/ipa-dev-host` dosyasına kaydedilir.

Web-only:

```bash
pnpm dev:ipa:web
```

## Yapı

```
artifacts/imalat-poz-analizleri/
├── app/index.tsx          # Ana ekran
├── assets/data/           # resmi-poz-analizleri.json
├── constants/             # Tipler ve tema
├── context/               # AppContext + ThemeContext
└── lib/pozAnalizCatalog.ts
```
