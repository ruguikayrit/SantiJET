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
# Workspace kökünden
pnpm dev:ipa

# veya doğrudan
pnpm --filter @workspace/imalat-poz-analizleri run dev
```

Web önizleme:

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
