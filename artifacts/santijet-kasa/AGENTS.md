# ŞantiJET Kasa — agent brief

Bu dosya sohbet geçmişinin yerine geçer. Kasa işinde bağlayıcıdır.

Kapsam: yalnızca `artifacts/santijet-kasa/**` (+ bu brief, `.cursor/rules/santijet-kasa.mdc`, gerekirse `build-kasa-pages.sh`). DEMİR, Beton, PRO, RN hub, SAHA, Malzeme, Maliyet, Mühendis veya Tahvil’e dokunma. Tersi de yok: Kasa işi başka ürüne taşınmaz.

Staging: https://ruguikayrit.github.io/SantiJET/kasa/

Turuncu **STAGING ÖNİZLEME** şeridi yok: `build-kasa-pages.sh` `#santijet-staging-banner`, 28px spacer veya `flutter-view { top:28px }` basmaz. `--dart-define=DEPLOY_CHANNEL=staging` kalır. Geri koyma.

## Ürün

Şantiye **iş avansı ve harcama** defteri. Excel “İŞ AVANSI VE HARCAMA TABLOSU” kurgusunun mobil/web karşılığı.

- Tek fiyat (IAP one-time). **Abonelik yok.** Hesap / bulut / login yok.
- Veri cihazda kalır. Hive kutuları `kasa_` önekli (`KasaHive`). Çıplak `settings` açma.
- Alt nav: **Kasa · Hareketler · Rapor**. Ayarlar navda yok (sağ üst dişli).
- Bildirim zili ve avatar yok.
- Üst özet: TOPLAM GELİR · TOPLAM GİDER · GÜNCEL KASA (= gelir − gider; negatif kırmızı).

Kaynak: `lib/features/shell/main_shell.dart`, `lib/core/widgets/santijet_header.dart`.

## Hareket modeli (kilitli)

Satır alanları: tarih, tedarikçi, açıklama, gelir, gider, ödeme şekli, belge türü, şantiye, ek açıklama.

- Bir satırda gelir **veya** gider (ikisi birden dolu olmasın).
- Para TR formatı: `₺1.234,56`
- Filtre: tarih aralığı, şantiye, tedarikçi, ödeme şekli, belge türü, gelir/gider.
- Arama: tedarikçi + açıklama + ek açıklama.

## Bilinçli sınırlar (v1)

- Çoklu kullanıcı / bulut senkron yok
- Fiş OCR / kamera yok
- Banka entegrasyonu yok
- Abonelik yok
- PRO hub / DEMİR sipariş kabuğu kopyalama yok

## Git / deploy

Dal: `staging`. Commit mesajı `feat(kasa):` / `fix(kasa):` / `docs(kasa):`.
Yalnızca kasa dosyaları (+ bu brief / kural / pages betiği).
