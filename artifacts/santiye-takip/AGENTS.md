# ŞantiJET RN hub (Expo) — agent brief

Bu dosya sohbet geçmişinin yerine geçer. Expo ana uygulama işinde bağlayıcıdır.

Kapsam: yalnızca `artifacts/santiye-takip/**` (+ bu brief, `.cursor/rules/santijet-santiye.mdc`).
Flutter **ŞantiJET PRO** (`artifacts/santijet-ana`, Pages `/pro/`), Beton, DEMİR, SAHA ve başka ürüne dokunma.

Ürün etiketi (splash + ana sayfa wordmark altı): **PRO** (SAHA’daki `productLabel` gibi).
Flutter PRO ile aynı marka; kod ağacı ayrıdır.

## Kabuk (kilitli — geri alma)

- Açılış parolası yok. `PasswordGate` geri gelmez; kök `_layout` doğrudan `AppProvider`.
- Splash: SAHA/Demir düzeni — bolt + wordmark + **PRO**, koyu canvas `#05070A`, **ızgara/çizgi yok**. Asset: `splash_bolt.png` / `splash_wordmark.png`.
- Ana sayfa sol üst: ŞantiJET wordmark + alt satır **PRO** (`HomeBrandMark`, Demir/SAHA metrikleri). Ortada “OPERASYON YÖNETİMİ” + bolt logo yok.
- Sağ üst: zil, **en sonda** hamburger → `/ayarlar`. Baş harf avatarı header’da yok.
- Hesabım: Ayarlar listesinin **en başında**; `AccountSheet`.
- Native splash zemin `#05070A`.

## Temalar

`layout: "hivis"`: Hi-Vis İSG, Turuncu İSG, Lime İSG — sarı/turuncu/lime + siyah şerit kart.
`layout: "steel"`: Steel & Concrete, Bakır & Beton, Blueprint — koyu kart, renkli sol şerit.
Bu temaları ve layout alanını silme.

## Windows / Expo

`scripts/fix-expo-router-stub.js` entry import’u **posix göreli** yol olmalı (`\` Metro’da kaçar). Mutlak `C:\...` geri koyma.

Git: dal `staging`. Mesaj `feat(santiye):` / `fix(santiye):` / `docs(santiye):`. Yalnızca santiye-takip (+ bu brief / kural) dosyaları.
