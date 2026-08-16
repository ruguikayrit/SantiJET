# ŞantiJET Tahvil

Saha için **demir tahvil** uygulaması. Tek fiyat, abonelik yok, hesap yok.
Hesap cihazınızda kalır.

Klasör: `artifacts/santijet-tahvil`  
Paket: `santijet_tahvil`  
Kimlik: `com.santijet.santijet_tahvil`

## Ne işe yarar

Projedeki donatıyı eldeki çapa / aralığa / adede **eşdeğer** çevirir:

- Aralık tahvili (As/m)
- Adet tahvili (kesit alanı)
- 2 çeşit donatı birlikte
- Uygun / fazla / hayır rozetleri
- Yerel kayıtlar

Kurallar DEMİR tahvil motoru ile aynıdır: ±4 mm çap, hedef As ≥ proje,
fazla kesit ≤ %5, aralık ≤ 25 cm.

## Çalıştırma

```bash
cd artifacts/santijet-tahvil
flutter pub get
flutter test
flutter run -d chrome   # veya: pnpm dev:tahvil
```

Staging: https://ruguikayrit.github.io/SantiJET/tahvil/
