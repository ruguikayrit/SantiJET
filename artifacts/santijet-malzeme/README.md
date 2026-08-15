# ŞantiJET Malzeme

Keşif listesine göre malzeme talebi → teklif (PDF) → fiyat mukayesesi → teknik karar (TDS) → sipariş → teslim alma.

Hive-only offline (MVP); Türkçe UI; ŞantiJET Beton / Puantaj görsel diliyle birebir parity.

## Sekmeler

| Sekme | Rol |
|-------|-----|
| **Ana** | KPI (yan yana): Onay Bekleyen · Onaylandı · Teslim Edildi |
| **Keşif Malzeme** | Birim sarfiyatlar × keşif metrajı → malzeme ihtiyacı; talebe ekle |
| **Talep & Teklif** | Talep listesi, teklif PDF, firma teklifleri, fiyat mukayesesi |
| **Teslim** | İrsaliye / teslim alma; talep–poz bağlama; karşılama progress |
| **Kütüphane** | Teknik föyler (TDS); ekleme sağ alt FAB |

Ayarlar / projeler: header dişli ikonu (bottom tab değil).

## Kilitli UX (geri alma)

- **Keşif → Birim Sarfiyatlar:** İnşaat / Elektrik / Mekanik başlıkları açılır-kapanır; **varsayılan açık**.
- **Keşif → Keşif Listesi:** aynı disiplin başlıkları açılır-kapanır; **varsayılan kapalı**.
- **Kütüphane:** üstte Ekle yok; sağ alt **TDS Ekle** FAB (`SJFab`).
- **Tema:** hibrit chrome/kart mürekkebi ayır. Kart içi `cardText*` / `cardInsetSurface` / `statusInkOnCard`. Ayrıntı: `.cursor/rules/santijet-malzeme-theme-ink.mdc`.
- Ürün kuralı: `.cursor/rules/santijet-malzeme.mdc`.

## Domain özeti

| Entity | Not |
|--------|-----|
| `Project` | Proje bağlamı |
| `KesifSnapshot` / `KesifLine` | `pozNo`, metraj; `kesifProjectId` (ileride Maliyet bağ) |
| `UnitConsumption` | Birim sarfiyat (malzeme / 1 keşif birimi) |
| `MaterialItem` | Katalog kartı |
| `MaterialRequest` / `MaterialRequestLine` | Talep + durum: taslak \| teklifte \| siparis \| kismi \| kapandi |
| `QuoteRound` / `SupplierQuote` / `QuoteLine` | Teklif turu, firma, birim fiyat |
| `Delivery` / `DeliveryLine` | Teslim / irsaliye |
| `TechSheet` | TDS metadata (+ dosya path sonraki faz) |
| `MaterialDecision` | Opsiyonel teknik karar |

Hive kutuları (JSON-in-box): `settings`, `projects`, `kesif`, `unit_consumptions`, `requests`, `quotes`, `deliveries`, `library`.

## Sınırlar (çakışma yok)

| Bu app (Malzeme) | Başka app |
|------------------|-----------|
| Malzeme talebi, teslim, gruplama, teklif PDF, mukayese, TDS | **SAHA**: günlük gelen/sipariş **notu** (stok defteri değil) |
| Keşif satırlarından malzeme ihtiyacı | **Maliyet/BFA**: birim fiyat analizi + YM (fiyat motoru orada; burada satın alma fiyatı/teklif) |
| Genel malzeme | **DEMİR** gelen demir / **BETON** sipariş — branş app’lerinde kalır |

## Çalıştırma

```bash
cd artifacts/santijet-malzeme
flutter pub get && flutter run
```

Web: `flutter run -d chrome` · veya monorepo kökünden `pnpm dev:malzeme`.

İlk açılışta boşsa demo seed yüklenir (Ayarlar → Demo veriyi yükle ile yenilenebilir).

## Staging önizleme

https://ruguikayrit.github.io/SantiJET/malzeme/

`staging` (veya `main`) push → Actions `Deploy ŞantiJET GitHub Pages` → `/malzeme/`.

## Faz planı

- [x] **Faz 1:** iskelet + UI parity + seed + kabuk ekranlar ✅ (bu iş)
- [ ] **Faz 2:** talep↔teslim miktar motoru + mukayese tamamı
- [ ] **Faz 3:** TDS dosya deposu + arama
- [ ] **Faz 4:** Maliyet/BFA keşif import
- [x] **Faz 5:** staging Pages `/malzeme/`
