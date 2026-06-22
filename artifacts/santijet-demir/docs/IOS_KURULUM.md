# iPhone / iOS'ta ŞantiJET DEMİR Açma Rehberi

**ŞantiJET DEMİR bir Flutter uygulamasıdır.** Expo Go ile açılmaz.

---

## Seçenek A — Mac varsa (gerçek iOS uygulaması) ✅ Önerilen

### Gereksinimler
- Mac bilgisayar
- Xcode (App Store'dan ücretsiz)
- iPhone + USB kablo (veya aynı Wi‑Fi)
- Flutter SDK kurulu

### Adımlar

```bash
# 1. Repoyu klonla
git clone https://github.com/ruguikayrit/SantiJET.git
cd SantiJET/artifacts/santijet-demir

# 2. Bağımlılıklar
flutter pub get

# 3. iOS pod'ları (ilk seferde)
cd ios && pod install && cd ..

# 4. iPhone'u Mac'e bağla, güvene al

# 5. Cihazları listele
flutter devices

# 6. iPhone'a yükle ve çalıştır
flutter run -d ios
```

**Simulator ile (fiziksel telefon yoksa):**
```bash
open -a Simulator
flutter run -d ios
```

**İlk kez fiziksel cihazda:** Xcode → `ios/Runner.xcworkspace` aç → Signing & Capabilities → Team seç (Apple ID yeterli, ücretsiz hesap olur).

---

## Seçenek B — Mac yoksa: iPhone Safari (web önizleme)

Tam native değil ama tüm ekranları test edebilirsiniz.

### Bilgisayarınızda (Mac veya Windows/Linux):

```bash
cd artifacts/santijet-demir
flutter pub get
flutter build web
cd build/web
python3 -m http.server 8080 --bind 0.0.0.0
```

### iPhone'da:
1. iPhone ve bilgisayar **aynı Wi‑Fi** ağında olsun
2. Bilgisayarın yerel IP'sini bulun:
   - Mac: Sistem Ayarları → Ağ → IP (ör. `192.168.1.42`)
   - Windows: `ipconfig`
3. iPhone **Safari**'de açın: `http://192.168.1.42:8080`
4. (İsteğe bağlı) Paylaş → **Ana Ekrana Ekle** → uygulama gibi açılır

---

## Seçenek C — TestFlight (App Store dışı dağıtım)

Mac + Apple Developer Program ($99/yıl) gerekir.

```bash
cd artifacts/santijet-demir
flutter build ipa
```

Ardından Xcode Organizer veya Transporter ile App Store Connect'e yükleyip TestFlight davetiyesi gönderin.

---

## Sık karşılaşılan hatalar

| Hata | Çözüm |
|------|--------|
| Expo Go açılmıyor | Normal — bu uygulama Expo değil, Flutter |
| `No devices found` | iPhone kablosu, güven onayı, Xcode kurulu mu kontrol edin |
| Signing hatası | Xcode'da Team / Bundle ID ayarlayın |
| Web'de yavaş | İlk yükleme büyük; release build kullanın: `flutter build web` |

---

## Hızlı kontrol

```bash
flutter doctor -v
```

iOS satırında ✓ görmelisiniz (Mac'te).
