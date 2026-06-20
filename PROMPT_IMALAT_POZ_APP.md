# İmalat Poz Analizleri — Bağımsız Uygulama Geliştirme Promptu

---

## PROJE BAĞLAMI

**Uygulama:** İmalat Poz Analizleri (bağımsız Expo uygulaması)  
**Platform:** Expo / React Native (TypeScript)  
**Router:** expo-router  
**State:** `context/PozAnalizContext.tsx` (AsyncStorage)  
**Stil:** React Native StyleSheet + `useColors()` + `ThemeContext`  
**Dizin:** `artifacts/imalat-poz-analizleri/`

**Not:** ŞantiJET (`artifacts/santiye-takip`) içinde de imalat modülü vardır ve orada kalacaktır. Bu prompt yalnızca bağımsız uygulama içindir.

---

## ÇALIŞTIRMA

```bash
pnpm install
pnpm dev:imalat-poz:tunnel   # Telefon (Expo Go)
pnpm dev:imalat-poz          # Yerel ağ
pnpm dev:imalat-poz:web      # Web önizleme
```

Typecheck:

```bash
pnpm --filter @workspace/imalat-poz-analizleri run typecheck
```

---

## DOSYA YAPISI

```
artifacts/imalat-poz-analizleri/
├── app/
│   ├── _layout.tsx          # ThemeProvider + PozAnalizProvider
│   ├── index.tsx            # → /imalat-pozlari
│   └── imalat-pozlari.tsx   # Ana ekran
├── context/
│   ├── PozAnalizContext.tsx
│   └── ThemeContext.tsx
├── constants/
│   ├── pozAnalizTypes.ts
│   └── colors.ts
├── hooks/
│   ├── useMergedPozAnalizleri.ts
│   └── useColors.ts
├── lib/
│   └── pozAnalizCatalog.ts  # Lazy JSON yükleme
├── assets/data/
│   └── resmi-poz-analizleri.json
└── AGENTS.md
```

---

## VERİ MODELİ

Tipler: `constants/pozAnalizTypes.ts`

- `PozAnaliz` — analiz kaydı (sistem / kullanici / kopya)
- `AnalizKalemi` — malzeme / işçilik / ekipman kalemi
- `hesaplaAnalizToplam()` — birim fiyat hesabı

Resmi analizler uygulama açılışında değil, ekran yüklenirken JSON'dan okunur.

---

## GÖREV KURALLARI

1. Değişiklikleri `artifacts/imalat-poz-analizleri/` altında tut
2. ŞantiJET ana uygulamasını istek olmadan değiştirme
3. Resmi veriyi `santiye-takip/constants/resmiAnalizler.ts` → export script ile senkron tut
4. Giriş / workspace / onboarding ekleme — bağımsız uygulama doğrudan analiz ekranına açılır

---

## BAŞARI KRİTERLERİ

- [ ] `pnpm --filter @workspace/imalat-poz-analizleri run typecheck` geçer
- [ ] Expo tunnel ile telefonda açılır
- [ ] Resmi analizler yüklenir, arama/filtre çalışır
- [ ] Kullanıcı analizi ekleme/düzenleme/kopyalama kalıcıdır (AsyncStorage)
