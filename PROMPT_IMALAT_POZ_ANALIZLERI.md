# ŞantiJET — İmalat Poz Analizleri Modülü: Geliştirme Promptu

---

## PROJE BAĞLAMI

**Uygulama:** ŞantiJET — Türkçe inşaat şantiye yönetim uygulaması  
**Platform:** Expo / React Native (TypeScript)  
**Router:** expo-router (file-based routing, `app/` dizini)  
**State:** React Context (`context/AppContext.tsx`)  
**Stil:** React Native StyleSheet + `useColors()` hook (tema sistemi)  
**Dizin:** `artifacts/santiye-takip/`

### Mevcut Yapı (Değiştirilecek)

- `app/imalat-pozlari.tsx` — Temel poz listesi ekranı (KALDIRIP YENİDEN YAZILACAK)  
- `constants/imalatPozlari.ts` — Mevcut `ImalatPoz` arayüzü ve kategori verileri  
- `app/ayarlar.tsx` satır 57-58: `"İnşaat imalat pozlarını ve tariflerini yönetin"` → route: `"/imalat-pozlari"`

### Mevcut ImalatPoz Arayüzü

```typescript
export interface ImalatPoz {
  code: string;       // Poz No (ör. "15.250.1114")
  category: string;   // Kategori
  name: string;       // Analizin Adı
  unit: string;       // Ölçü Birimi
  description?: string; // Poz Tarifi
}
```

Bu arayüz `PozAnaliz` yapısıyla GENIŞLETILECEK — aşağıda tanımlanmıştır.

---

## GÖREV TANIMI

`app/imalat-pozlari.tsx` ekranını tamamen yeniden yaz.

Mevcut basit poz listesi yerine; Türkiye Çevre ve Şehircilik Bakanlığı resmi **İmalat Analiz Tabloları** formatında, tam işlevli bir **İmalat Poz Analizleri** yönetim sistemi oluştur.

---

## VERİ MODELİ

### Yeni Tip Tanımları (`constants/imalatPozlari.ts` içine ekle)

```typescript
export interface AnalazKalemi {
  id: string;
  tip: "malzeme" | "iscilik" | "ekipman";
  pozNo: string;
  tanim: string;
  olcuBirimi: string;
  miktar: number;
  birimFiyati: number;
  tutar: number; // miktar × birimFiyati (otomatik)
}

export interface PozAnaliz {
  id: string;                    // uuid
  pozNo: string;                 // ör. "15.250.1114"
  analizAdi: string;             // ör. "Makina ile ortalama 2,5 cm kalınlıkta alçı esaslı şap yapılması"
  olcuBirimi: string;            // ör. "m²"
  kategori: string;              // IMALAT_POZ_KATEGORILERI içinden
  kalemler: AnalazKalemi[];      // Malzeme + İşçilik + Ekipman kalemleri
  pozTarifi: string;             // Uzun açıklama metni
  yapimSartlari: string;         // Yapım koşulları
  olcusu: string;                // Ölçü açıklaması
  malzemeIscilikToplami: number; // Otomatik hesap
  yukleniciKarOrani: number;     // Varsayılan: 25
  yukleniciKarTutari: number;    // Otomatik hesap
  birimFiyati: number;           // Nihai 1 m² (veya birim) fiyatı
  olusturmaTarihi: string;       // ISO string
  guncellemeTarihi: string;      // ISO string
  kaynakTip: "sistem" | "kullanici" | "kopya"; // Kaynak türü
  notlar?: string;
}
```

### AppContext Güncellemesi

`context/AppContext.tsx` içine şunları ekle:

```typescript
// State
const [pozAnalizleri, setPozAnalizleri] = useState<PozAnaliz[]>(DEFAULT_POZ_ANALIZLERI);

// Actions
addPozAnaliz(analiz: Omit<PozAnaliz, "id" | "olusturmaTarihi" | "guncellemeTarihi">): void
updatePozAnaliz(id: string, updates: Partial<PozAnaliz>): void
deletePozAnaliz(id: string): void
clonePozAnaliz(id: string, yeniAd: string): PozAnaliz
```

---

## EKRAN YAPISI

`app/imalat-pozlari.tsx` ekranı 2 görünümden oluşur:

```
ImalatPozlariScreen
├── [liste görünümü]  ← Varsayılan
│   ├── Sticky arama çubuğu
│   ├── Kategori filtre şeridi
│   └── FlatList (tıklanabilir satırlar)
│
└── [detay görünümü]  ← Satıra tıklayınca
    ├── Üst bilgi alanı (Poz No, Ad, Birim, Tarih)
    ├── Malzeme tablosu
    ├── İşçilik tablosu
    ├── Ekipman tablosu (varsa)
    ├── Hesap özeti satırı
    ├── Poz Tarifi bölümü
    ├── Yapım Şartları bölümü
    ├── Ölçüsü bölümü
    └── Aksiyon butonları
```

---

## LİSTE GÖRÜNÜMÜ

### Arama Çubuğu

```
Placeholder: "Poz No veya analiz adı ara..."
```

Anlık filtreleme; büyük/küçük harf duyarsız:
- `pozNo` (ör. "15.250")
- `analizAdi`
- `pozTarifi` içeriği

### Kategori Filtresi

Yatay kaydırılabilir chip şeridi. Seçenekler: tüm `IMALAT_POZ_KATEGORILERI` + "Tümü".

### Tablo Sütunları

| Stn. | Alan | Genişlik |
|------|------|---------|
| 1 | Sıra No | Sabit küçük |
| 2 | Poz No | Orta |
| 3 | Analizin Adı | Esnek |
| 4 | Birim | Sabit küçük |

Her satır tıklanabilir. Hover/press efekti (`activeOpacity`).

### Performans

`FlatList` + `keyExtractor` + `initialNumToRender={20}` + `windowSize={10}`.  
Binlerce kayıt için optimize edilecek.

---

## DETAY GÖRÜNÜMÜ

### Üst Bilgi Alanı (sabit, kaydırılmaz)

```
┌─────────────────────────────────────────────────────────┐
│  Poz No: 15.250.1114              Ölçü Birimi: m²       │
│  Makina ile ortalama 2,5 cm kalınlıkta alçı esaslı şap  │
│  yapılması                                              │
│  Son Güncelleme: 15.01.2026                             │
└─────────────────────────────────────────────────────────┘
```

### Analiz Tablosu Yapısı

Resmi Çevre ve Şehircilik Bakanlığı formatını taklit et:

```
┌─────────────┬──────────────────────────────┬──────────┬─────────┬───────────┬────────────┐
│  Poz No     │  Tanımı                      │  Ölçü   │ Miktarı │ Birim Fyt │  Tutarı    │
│             │                              │ Birimi   │         │   (TL)    │   (TL)     │
├─────────────┴──────────────────────────────┴──────────┴─────────┴───────────┴────────────┤
│  Malzeme                                                                                 │
├─────────────┬──────────────────────────────┬──────────┬─────────┬───────────┬────────────┤
│ 19.100.1100 │ Sıva Makinası                │   Sa     │   0,1   │    749,85 │     74,99  │
│ 10.240.5518 │ Alçı Esaslı Hazır Karışım... │   Kg     │  45     │      2,18 │     98,10  │
│ 10.130.9991 │ Su                           │   m³     │   0,025 │     55,00 │      1,38  │
├─────────────┴──────────────────────────────┴──────────┴─────────┴───────────┴────────────┤
│  İşçilik                                                                                 │
├─────────────┬──────────────────────────────┬──────────┬─────────┬───────────┬────────────┤
│ 10.100.1068 │ Birinci sınıf usta           │   Sa     │   0,3   │    310,00 │     93,00  │
│ 10.100.1062 │ Düz işçi                     │   Sa     │   0,2   │    205,00 │     41,00  │
├─────────────┴──────────────────────────────┴──────────┴─────────┴───────────┴────────────┤
│                          Malzeme + İşçilik Tutarı                    │        308,47     │
│                          %25 Yüklenici Karı ve Genel Giderler        │         77,12     │
│                          1 m² Fiyatı                                 │        385,59     │
└──────────────────────────────────────────────────────────────────────┴───────────────────┘
```

### Düzenleme Modu

"Düzenle" butonuna basınca tüm hücreler `TextInput`'a dönüşür:
- Poz No, Tanım, Ölçü Birimi, Miktar, Birim Fiyatı alanları düzenlenebilir
- Tutar = `Miktar × Birim Fiyatı` anlık hesaplanır (düzenlenemez, gösterim)

### Hesap Mantığı

```typescript
// Her kalem için:
kalem.tutar = kalem.miktar * kalem.birimFiyati;

// Özet:
const malzemeToplam = kalemler.filter(k => k.tip === "malzeme").reduce((s, k) => s + k.tutar, 0);
const iscilikToplam = kalemler.filter(k => k.tip === "iscilik").reduce((s, k) => s + k.tutar, 0);
const ekipmanToplam = kalemler.filter(k => k.tip === "ekipman").reduce((s, k) => s + k.tutar, 0);
const malzemeIscilikToplami = malzemeToplam + iscilikToplam + ekipmanToplam;
const yukleniciKarTutari = malzemeIscilikToplami * (analiz.yukleniciKarOrani / 100);
const birimFiyati = malzemeIscilikToplami + yukleniciKarTutari;
```

Para birimi formatı: Türk lirası, nokta binlik ayraç, virgül ondalık:  
`308,47 TL` → `Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2 })`

---

## AKSİYON BUTONLARI

Detay ekranının altında sabit bir buton şeridi:

| Buton | İkon | İşlev |
|-------|------|-------|
| Düzenle / Kaydet | edit / save | Düzenleme modunu aç/kapat, kaydet |
| Kopyala | copy | Analizi klonla, yeni ad sor, listeye ekle |
| Sil | trash | Onay sonrası sil (sistem kayıtları silinmez) |
| Yazdır | printer | React Native Print veya paylaş |
| PDF Aktar | file-pdf | PDF oluştur, `expo-sharing` ile paylaş |
| Excel Aktar | file-spreadsheet | CSV/XLSX oluştur, paylaş |

---

## KOPYALAMA (CLONE) SİSTEMİ

"Kopyala" butonuna basınca:
1. Modal aç: "Yeni analiz adı girin"
2. Ön doldur: `"Kopya — {orijinalAd}"`
3. Kullanıcı adı değiştirir ve onaylar
4. Yeni `PozAnaliz` oluşturulur: `kaynakTip: "kopya"`, yeni `id`, yeni tarihler
5. Tüm `kalemler` array kopyalanır (derin kopya)
6. Liste görünümüne dön, yeni kayıt seçili görünsün

Örnek:  
- Orijinal: `"Makina ile ortalama 2,5 cm kalınlıkta alçı esaslı şap yapılması"`  
- Kopya: `"Makina ile ortalama 4 cm kalınlıkta alçı esaslı şap yapılması"`

---

## POZ TARİFİ / YAPIM ŞARTLARI / ÖLÇÜSÜ

Detay ekranında, analiz tablosunun altında 3 bölüm:

```
[Poz Tarifi]
Proje ve detay projesine göre, dolgusu yapılacak yüzeyin temizlenmesi, yıkanması, 
kot alınması, makine ile elde edilen harcın, alınan kota göre zemine ortalama 2,5 cm 
kalınlıkta uygulanması için gerekli her türlü malzeme ve zayiatı, işçilik, inşaat 
yerindeki yatay ve düşey taşıma, boşaltma, yüklenici genel giderleri ve kârı dahil, 
1 m² fiyatı:

[Yapım Şartları]
(Varsa özel şartlar)

[Ölçüsü]
Şap yapılan yerin alanı projesi üzerinden hesaplanır.
```

Düzenleme modunda bu üç alan `TextInput multiline` olur.

---

## AYARLAR EKRANI DEĞİŞİKLİĞİ

`app/ayarlar.tsx` içinde:

**Mevcut:**
```
"İnşaat imalat pozlarını ve tariflerini yönetin"
route: "/imalat-pozlari"
```

**Değiştirilecek başlık:**
```
başlık: "İmalat Poz Analizleri"
alt: "Resmi analiz tabloları, fiyat hesaplamaları ve özel analizler"
route: "/imalat-pozlari"
```

Route değişmez — aynı ekran dosyası kullanılır.

---

## ÖRNEK VERİ (DEFAULT_POZ_ANALIZLERI)

`constants/imalatPozlari.ts` içine minimum 5 gerçek analiz ekle. Aşağıdaki analizi kesinlikle dahil et:

```typescript
{
  id: "sys-15-250-1114",
  pozNo: "15.250.1114",
  analizAdi: "Makina ile ortalama 2,5 cm kalınlıkta alçı esaslı şap yapılması",
  olcuBirimi: "m²",
  kategori: "Sıva ve Şap",
  kaynakTip: "sistem",
  yukleniciKarOrani: 25,
  kalemler: [
    { id: "k1", tip: "malzeme", pozNo: "19.100.1100", tanim: "Sıva Makinası (İmalatta kullanılan makina karşılığı)", olcuBirimi: "Sa", miktar: 0.1, birimFiyati: 749.85, tutar: 74.99 },
    { id: "k2", tip: "malzeme", pozNo: "10.240.5518", tanim: "Alçı Esaslı Hazır Karışım Zemin Harcı (TS EN 13813)", olcuBirimi: "Kg", miktar: 45, birimFiyati: 2.18, tutar: 98.10 },
    { id: "k3", tip: "malzeme", pozNo: "10.130.9991", tanim: "Su", olcuBirimi: "m³", miktar: 0.025, birimFiyati: 55.00, tutar: 1.38 },
    { id: "k4", tip: "iscilik", pozNo: "10.100.1068", tanim: "Birinci sınıf usta", olcuBirimi: "Sa", miktar: 0.3, birimFiyati: 310.00, tutar: 93.00 },
    { id: "k5", tip: "iscilik", pozNo: "10.100.1062", tanim: "Düz işçi (İnşaat yerinde yükleme, yatay ve düşey taşıma, boşaltma dahil)", olcuBirimi: "Sa", miktar: 0.2, birimFiyati: 205.00, tutar: 41.00 },
  ],
  malzemeIscilikToplami: 308.47,
  yukleniciKarTutari: 77.12,
  birimFiyati: 385.59,
  pozTarifi: "Proje ve detay projesine göre, dolgusu yapılacak yüzeyin temizlenmesi, yıkanması, kot alınması, makine ile elde edilen harcın, alınan kota göre zemine ortalama 2,5 cm kalınlıkta uygulanması için gerekli her türlü malzeme ve zayiatı, işçilik, inşaat yerindeki yatay ve düşey taşıma, boşaltma, yüklenici genel giderleri ve kârı dahil, 1 m² fiyatı:",
  yapimSartlari: "",
  olcusu: "Şap yapılan yerin alanı projesi üzerinden hesaplanır.",
  olusturmaTarihi: "2026-01-15T00:00:00.000Z",
  guncellemeTarihi: "2026-01-20T00:00:00.000Z",
}
```

---

## EK ÖZELLİKLER

### Satır İşlemleri (Düzenleme Modunda)

- Yeni kalem satırı ekle (+ butonu, tip seç: Malzeme / İşçilik / Ekipman)
- Satır sil (sola kaydır veya çöp kutusu ikonu)
- Satır sırası değiştir (sürükle-bırak, isteğe bağlı)

### Yüklenici Karı Oranı

Varsayılan %25. Detay ekranında kullanıcı bu oranı değiştirebilir (TextInput).  
Değişince tüm hesaplar anında güncellenir.

### Otomatik Kayıt (Draft)

Düzenleme modunda 3 saniye hareketsizlik sonrası `AsyncStorage`'a taslak kaydet.  
Ekrandan çıkarken kaydedilmemiş değişiklik varsa uyarı göster.

---

## GÖRSEL TASARIM KURALLARI

**Tema:** `useColors()` hook'undan gelen renkleri kullan (mevcut tema sistemi).

```typescript
const colors = useColors();
// colors.background, colors.card, colors.text, colors.border, colors.primary vb.
```

**Tablo Stili:**
- Sınır: `1px solid colors.border` (koyu gri, resmi belge görünümü)
- Başlık satırı: `colors.card` arka plan, kalın font
- Tip grupları (Malzeme / İşçilik): `colors.card` arka plan, italic, birleşik hücre
- Tutar sütunu: sağa hizalı, `JetBrains Mono` veya sistem monospace font
- Toplam satırları: `colors.primary` ile vurgulu, kalın

**Mobil Optimizasyon:**
- Yatay kaydırmalı tablo (`ScrollView horizontal`)
- Minimum sütun genişlikleri koru
- Alt aksiyon şeridi `SafeAreaView` içinde sabit

---

## DOSYA DÜZENİ

```
artifacts/santiye-takip/
├── app/
│   └── imalat-pozlari.tsx          ← TAM YENİDEN YAZ
├── constants/
│   └── imalatPozlari.ts            ← PozAnaliz tipi + DEFAULT_POZ_ANALIZLERI ekle
├── context/
│   └── AppContext.tsx              ← pozAnalizleri state + CRUD actions ekle
└── components/
    └── pozAnaliz/
        ├── PozAnalizListesi.tsx    ← Liste bileşeni (isteğe bağlı ayır)
        ├── PozAnalizDetay.tsx      ← Detay + tablo bileşeni (isteğe bağlı ayır)
        └── AnalizTablosu.tsx       ← Tablo render bileşeni (isteğe bağlı ayır)
```

---

## KRİTİK KURALLAR

1. Tüm UI metinleri Türkçe olacak.
2. Mevcut `ImalatPoz` arayüzü korunacak, `PozAnaliz` arayüzü EKLENECEk (değiştirilmeyecek).
3. Mevcut `DEFAULT_IMALAT_POZLARI` verileri bozulmayacak.
4. `useColors()` hook'u mutlaka kullanılacak — hardcoded renk yok.
5. `currentRole?.isAdmin` kontrolü: sadece adminler oluşturabilir/düzenleyebilir/silebilir; diğerleri sadece görüntüleyebilir.
6. Sistem kayıtları (`kaynakTip: "sistem"`) silinemez, sadece kopyalanabilir.
7. Hesaplamalar her zaman client-side, anlık, state-driven olacak.
8. Emoji kullanılmayacak.

---

## BAŞARI KRİTERLERİ

- [ ] Analiz listesi arama ile anlık filtreler
- [ ] Satıra tıklayınca tam analiz tablosu açılır
- [ ] Analiz tablosu resmi belge formatına görsel olarak uyar
- [ ] Tüm hücreler düzenleme modunda düzenlenebilir
- [ ] Tutar = Miktar × Birim Fiyatı anlık hesaplanır
- [ ] %25 yüklenici karı anlık hesaplanır
- [ ] Kopyalama çalışır, yeni isim alınır
- [ ] Poz Tarifi / Yapım Şartları / Ölçüsü alanları düzenlenebilir
- [ ] Admin kontrolü çalışır
- [ ] Tema sistemine uyumlu (açık/koyu tema)
- [ ] Yatay kaydırmalı tablo mobilde çalışır
