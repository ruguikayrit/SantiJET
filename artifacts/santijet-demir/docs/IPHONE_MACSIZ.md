# iPhone'da Mac Olmadan ŞantiJET DEMİR

Mac ve Xcode olmadan iPhone'da uygulamayı kullanmanın en pratik yolu: **Safari + web sürümü (PWA)**.

---

## Yöntem 1 — GitHub Pages (önerilen, her yerden erişim)

Depo GitHub Pages'e deploy edildikten sonra iPhone Safari'den açılır.

### Tek seferlik ayar (GitHub'da)

1. GitHub repo → **Settings** → **Pages**
2. **Build and deployment** → Source: **GitHub Actions**
3. `main` branch'e merge edin (veya Actions'tan workflow'u manuel çalıştırın)

### iPhone'da açma

1. Safari'de şu adresi açın (repo adına göre):

```
https://ruguikayrit.github.io/santijet/
```

> Repo adı `SantiJET` ise: `https://ruguikayrit.github.io/SantiJET/`

2. **Paylaş** (kare + ok) → **Ana Ekrana Ekle**
3. Ana ekrandaki **ŞantiJET DEMİR** ikonuna dokunun — uygulama gibi tam ekran açılır

### Deploy durumunu kontrol

GitHub → **Actions** → **Deploy ŞantiJET DEMİR Web** → yeşil tik

---

## Yöntem 2 — Aynı Wi‑Fi (bilgisayar yanınızdayken)

Windows veya Linux bilgisayarda:

```bash
cd artifacts/santijet-demir
./scripts/serve_web_ios.sh
```

Terminalde çıkan `http://192.168.x.x:8080` adresini iPhone Safari'de açın.

---

## Yöntem 3 — Android telefon (varsa)

Mac gerekmez; APK doğrudan yüklenebilir:

```bash
cd artifacts/santijet-demir
flutter build apk --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`  
Telefona kopyalayıp yükleyin (bilinmeyen kaynaklara izin verin).

---

## Ne beklemeli?

| Özellik | Web (Safari) | Native iOS |
|---------|--------------|------------|
| Tüm ekranlar | ✅ | ✅ |
| Ana ekrana ekleme | ✅ | ✅ |
| PDF paylaşım | ⚠️ sınırlı | ✅ |
| App Store | ❌ | ✅ (Mac + hesap gerekir) |
| Expo Go | ❌ kullanılmaz | ❌ |

---

## Sorun giderme

| Sorun | Çözüm |
|-------|--------|
| Sayfa boş / 404 | GitHub Pages Actions deploy'un tamamlanmasını bekleyin |
| Yavaş açılıyor | İlk yükleme normal; sonraki açılışlar daha hızlı |
| Expo Go açılmıyor | ŞantiJET DEMİR Flutter'dır, Expo değil |
