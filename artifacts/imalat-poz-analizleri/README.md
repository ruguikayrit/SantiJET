# ŞantiJET İPA

Bağımsız **İmalat Poz Analizleri** uygulaması. ŞantiJET ana uygulamasından (`artifacts/santiye-takip`) ayrıdır.

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

### Sabit QR / sabit link (tunnel kullanmayın)

`pnpm dev:ipa` artık **tunnel değil LAN modu** kullanır. QR kodu kod değişince veya sunucu yeniden başlayınca **değişmez**.

| Bağlantı | Adres |
|----------|--------|
| **Yer imi sayfası** (QR burada) | http://localhost:24917 |
| Web | http://localhost:24916 |
| Expo Go | `exp://<host>:24916` |

Host ilk çalıştırmada `.expo/ipa-dev-host` dosyasına kaydedilir.

Farklı ağdan (telefon mobil veri) erişim için host'u **bir kez** sabitleyin:

```bash
export IPA_EXPO_HOST=your-stable-hostname.example.com
pnpm dev:ipa
```

Tunnel (`dev:tunnel`) yalnızca geçici test içindir — her başlatmada yeni rastgele adres üretir.

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
