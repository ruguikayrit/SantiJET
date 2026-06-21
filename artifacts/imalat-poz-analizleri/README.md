# ŞantiJET B.F.A.

Bağımsız **Birim Fiyat Analizleri** uygulaması. ŞantiJET ana uygulamasından (`artifacts/santiye-takip`) ayrıdır.

## Modüller

| # | Modül | Veri dosyası |
|---|--------|----------------|
| 01 | İnşaat B.F.A. | `assets/data/resmi-poz-analizleri.json` |
| 02 | Mekanik Tesisat B.F.A. | `assets/data/resmi-mekanik-analizleri.json` |
| 03 | Elektrik Tesisat B.F.A. | `assets/data/resmi-elektrik-analizleri.json` |
| 04 | Favoriler | AsyncStorage (`santijet_ipa_favorites_v1`) |

Mekanik ve elektrik katalogları PDF içe aktarımı için hazır; JSON doldurulunca modül 1 ile aynı listeleme/detay akışı çalışır.

## Özellikler

- 960+ resmi Çevre ve Şehircilik Bakanlığı imalat analiz tablosu (lazy JSON yükleme)
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
