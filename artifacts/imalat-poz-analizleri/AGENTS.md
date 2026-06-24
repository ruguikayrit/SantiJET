# İmalat Poz Analizleri — Agent Talimatları

Bağımsız Expo uygulaması. ŞantiJET ana uygulamasından ayrıdır; varsayılan çalışma alanı `artifacts/imalat-poz-analizleri/` olmalıdır.

## Kapsam

- **Bu uygulama:** `artifacts/imalat-poz-analizleri/`
- **Dokunma (istek olmadan):** `artifacts/santiye-takip/` — ŞantiJET içindeki imalat modülü ayrı kalır
- **Paylaşılan lib:** Yalnızca gerçekten gerekirse `lib/` altına bakın

## Geliştirme

Proje kökünden:

```bash
pnpm install
pnpm dev:imalat-poz          # Yerel ağ (port 24916)
pnpm dev:imalat-poz:tunnel   # Telefon / Expo Go tunnel
pnpm dev:imalat-poz:web      # Tarayıcı önizleme (port 24917)
```

Doğrudan paket:

```bash
pnpm --filter @workspace/imalat-poz-analizleri run typecheck
```

## Stack

- Expo 54, expo-router, React Native, TypeScript
- State: `context/PozAnalizContext.tsx` (AsyncStorage)
- Resmi analizler: `assets/data/resmi-poz-analizleri.json` (lazy load)
- Postinstall: `scripts/fix-expo-router-stub.js`

## QR sayfası

Tunnel çalışırken QR HTML:

```bash
cd artifacts/imalat-poz-analizleri
python3 -m http.server 24920 --bind 0.0.0.0
# http://localhost:24920/expo-qr.html
```

## Cloud Agent notları

- Kurulum her zaman monorepo kökünden: `pnpm install`
- Değişiklikler `cursor/imalat-poz-app-090b` veya `main` üzerinde PR ile
- `.expo/` ve `expo-qr.*` commit edilmez
