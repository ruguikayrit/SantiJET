# ŞantiJET

Türkçe inşaat şantiye yönetim uygulaması. pnpm monorepo yapısında birden fazla modülden oluşur.

## Modüller

| Modül | Klasör | Açıklama |
|-------|--------|----------|
| **B.F.A. (Flutter)** | `artifacts/santijet-bfa-flutter` | **Aktif** — Birim Fiyat Analizleri (Flutter) |
| **BETON (Flutter)** | `artifacts/santijet-beton` | **Aktif** — Mevcut beton uygulaması (`/beton/`) |
| **BETON R1 (Flutter)** | `artifacts/santijet-beton-r1` | **Aktif** — R1 MVP: plan / döküm / sipariş / kalite (`/beton-r1/`) |
| B.F.A. (RN arşiv) | `artifacts/imalat-poz-analizleri` | Emekli — yalnızca referans |
| Mobil uygulama | `artifacts/santiye-takip` | Expo / React Native — ana şantiye takip uygulaması |
| Neon HUD | `artifacts/santijet-neon` | Vite web dashboard — neon temalı yönetici paneli |
| Web sitesi | `artifacts/santijet-website` | Tanıtım / SaaS landing page |
| API sunucusu | `artifacts/api-server` | Express API (AI asistan, workspace yönetimi) |
| Mockup sandbox | `artifacts/mockup-sandbox` | UI bileşen önizleme ortamı |

## Gereksinimler

- Node.js 22+
- pnpm 10+
- PostgreSQL (yalnızca API sunucusu için)

## Kurulum

```bash
pnpm install
```

## Geliştirme

Tüm komutlar proje kök dizininden çalıştırılır.

### Neon HUD (web dashboard)

```bash
pnpm dev:neon
```

Tarayıcıda: http://localhost:23301/neon/

### B.F.A. — Birim Fiyat Analizleri (Flutter — aktif)

```bash
pnpm dev:bfa
```

Tarayıcıda Flutter web oturumu açılır.

### BETON — Mevcut beton uygulaması (Flutter)

```bash
pnpm dev:beton
```

Pages: `/beton/`.

### BETON R1 — Yeni MVP (Flutter — mevcut BETON'dan ayrı)

```bash
pnpm dev:beton-r1
```

Pages: `/beton-r1/`.

### B.F.A. — RN arşiv (emekli, yalnızca referans)

```bash
pnpm dev:ipa:archive
```

### Mobil uygulama (Expo web)

```bash
pnpm dev:mobile-web
```

Tarayıcıda: http://localhost:24915

### Mobil uygulama (Expo — telefon, tunnel)

```bash
pnpm dev:mobile:tunnel
```

Expo Go ile QR kodu tarayın.

### Mobil uygulama (Expo — yerel ağ)

```bash
pnpm dev:mobile
```

### API sunucusu

```bash
export DATABASE_URL="postgresql://user:pass@localhost:5432/santijet"
pnpm dev:api
```

API: http://localhost:8080

### Web sitesi

```bash
pnpm dev:website
```

### Tüm modülleri derleme kontrolü

```bash
pnpm typecheck
pnpm build
```

### B.F.A. kalite kapısı (Flutter)

```bash
cd artifacts/santijet-bfa-flutter
flutter pub get
flutter analyze
flutter test
```

CI: `.github/workflows/bfa-ci.yml` (push/PR) ve Pages deploy öncesi otomatik çalışır.

## Ortam değişkenleri

| Değişken | Gerekli | Açıklama |
|----------|---------|----------|
| `PORT` | Evet (dev) | Her modül kendi portunu kullanır |
| `BASE_PATH` | Hayır | Vite uygulamaları için base path (örn. `/neon/`) |
| `DATABASE_URL` | API için | PostgreSQL bağlantı dizesi |
| `EXPO_PUBLIC_API_BASE` | Hayır | API sunucusu (AI asistan vb.; YYBM PDF'leri uygulama içinde) |
| `OPENAI_API_KEY` | API için | AI asistan özelliği |

`.env.example` dosyasına bakın.

## Proje yapısı

```
├── artifacts/          # Uygulama modülleri
│   ├── santijet-bfa-flutter/  # B.F.A. Flutter (aktif)
│   ├── santijet-beton/        # BETON Flutter (/beton/)
│   ├── santijet-beton-r1/     # BETON R1 Flutter (/beton-r1/)
│   ├── imalat-poz-analizleri/ # B.F.A. RN (arşiv)
│   ├── santiye-takip/  # Expo mobil uygulama
│   ├── santijet-neon/  # Neon HUD web paneli
│   ├── santijet-website/
│   ├── api-server/
│   └── mockup-sandbox/
├── lib/                # Paylaşılan kütüphaneler
│   ├── api-client-react/
│   ├── api-spec/
│   ├── api-zod/
│   └── db/
└── attached_assets/    # Logo ve görsel dosyalar
```
