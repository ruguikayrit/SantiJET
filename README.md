# ŞantiJET

Türkçe inşaat şantiye yönetim uygulaması. pnpm monorepo yapısında birden fazla modülden oluşur.

## Modüller

| Modül | Klasör | Açıklama |
|-------|--------|----------|
| **SAHA (Flutter)** | `artifacts/santijet-puantaj` | **Aktif** — ŞantiJET SAHA / puantaj (`/puantaj/`) |
| **Maliyet (Flutter)** | `artifacts/santijet-bfa-flutter` | **Aktif** — ŞantiJET Maliyet (`/maliyet/`) |
| **BETON (Flutter)** | `artifacts/santijet-beton` | **Aktif** — Mevcut beton uygulaması (`/beton/`) |
| **Mühendis (Flutter)** | `artifacts/santijet-muhendis` | **Aktif** — TBDY-2018 çelik birleşim hesabı |
| B.F.A. (RN arşiv) | `artifacts/imalat-poz-analizleri` | Emekli — yalnızca referans |
| Mobil uygulama (RN) | `artifacts/santiye-takip` | Expo — ana şantiye takip, splash **PRO** (korunur) |
| **Ana / PRO (Flutter)** | `artifacts/santijet-ana` | **Aktif Flutter hub** — RN ile aynı kurgu, 16 modül |
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

### Maliyet — ŞantiJET Maliyet (Flutter — aktif; eski BFA)

```bash
pnpm dev:bfa
```

Tarayıcıda Flutter web oturumu açılır. Pages path: `/maliyet/`.

### SAHA — Puantaj & saha (Flutter)

```bash
cd artifacts/santijet-puantaj
flutter pub get
flutter run
```

Staging: https://ruguikayrit.github.io/SantiJET/puantaj/

### BETON — Mevcut beton uygulaması (Flutter)

```bash
pnpm dev:beton
```

Pages: `/beton/`.

### Mühendis — TBDY-2018 birleşim hesabı (Flutter)

```bash
pnpm dev:muhendis
```

Agent brief: [`AGENT_BRIEF.md`](./AGENT_BRIEF.md).

### B.F.A. — RN arşiv (emekli, yalnızca referans)

```bash
pnpm dev:ipa:archive
```

### Ana / PRO — Flutter hub (aktif)

```bash
pnpm dev:ana
```

RN `santiye-takip` bozulmadan durur; Flutter karşılığı `artifacts/santijet-ana`.

Staging: https://ruguikayrit.github.io/SantiJET/pro/

### Mobil uygulama (Expo web — RN, korunur)

```bash
pnpm dev:mobile-web
```

Tarayıcıda: http://localhost:24915

### Mobil uygulama (Expo — telefon, tunnel)

```bash
pnpm dev:mobile:tunnel
```

Expo Go ile QR kodu tarayın.

Yeni agent: [`artifacts/santiye-takip/AGENTS.md`](./artifacts/santiye-takip/AGENTS.md) bağlayıcıdır. Flutter PRO (`santijet-ana`) ayrıdır.

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
│   ├── santijet-puantaj/      # SAHA Flutter (/puantaj/)
│   ├── santijet-bfa-flutter/  # B.F.A. Flutter (aktif)
│   ├── santijet-beton/        # BETON Flutter (/beton/)
│   ├── santijet-muhendis/     # Mühendis — TBDY-2018 birleşim
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
