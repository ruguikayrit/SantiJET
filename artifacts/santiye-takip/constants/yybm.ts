export interface YybmSinif {
  kod: string;
  grup: string;
  aciklama: string;
  ornekler: string[];
  fiyat: number;
}

export interface YybmDonem {
  id: string;
  yil: number;
  altDonem?: number;
  etiket: string;
  gazeteNo: string;
  gazeteKarariTarihi: string;
  siniflar: YybmSinif[];
  pdfMevcut: boolean;
  pdfUrl: string;
  yapiSinifiTipi: "eski" | "yeni";
}

// ─── ESKİ YAPI SINIFI AÇIKLAMALARI (2020–2024) ─────────────────────────────
const ESKI_SINIF_META: Record<string, { grup: string; aciklama: string; ornekler: string[] }> = {
  "I-A":   { grup: "I. Sınıf (A) Grubu",   aciklama: "Çardak, basit baraka, kümes, küçükbaş ağıl", ornekler: ["Geçici baraka", "Basit kümes ve küçükbaş ağıl", "Çardak ve gölgelik", "Basit depo"] },
  "I-B":   { grup: "I. Sınıf (B) Grubu",   aciklama: "Basit sera, ihata duvarı, tarım yapıları", ornekler: ["Plastik örtülü sera", "İhata duvarı (3 m'ye kadar)", "Basit tarım yapıları", "Yükleme rampaları"] },
  "II-A":  { grup: "II. Sınıf (A) Grubu",  aciklama: "Depo, garaj, hangar, iskele", ornekler: ["Genel amaçlı depo", "Garaj", "Hangar", "Deniz iskelesi"] },
  "II-B":  { grup: "II. Sınıf (B) Grubu",  aciklama: "Sanayi, akaryakıt istasyonu, kapalı spor tesisi", ornekler: ["Sanayi tesisi", "Akaryakıt istasyonu", "Kapalı spor salonu", "Kır lokantası"] },
  "II-C":  { grup: "II. Sınıf (C) Grubu",  aciklama: "Konut, işyeri, okul, sağlık tesisi", ornekler: ["Konut (küçük)", "İşyeri", "Okul binaları", "Küçük sağlık tesisi"] },
  "III-A": { grup: "III. Sınıf (A) Grubu", aciklama: "Büro, iş merkezi, konut (4-6 kat)", ornekler: ["Büro binası", "İş merkezi", "Konut (4-6 katlı)", "Küçük otel"] },
  "III-B": { grup: "III. Sınıf (B) Grubu", aciklama: "Otel, yurt, hastane, AVM", ornekler: ["Otel", "Öğrenci yurdu", "Hastane", "Alışveriş merkezi"] },
  "IV-A":  { grup: "IV. Sınıf (A) Grubu",  aciklama: "Havalimanı, kongre merkezi, yüksek katlı konut", ornekler: ["Havalimanı terminal", "Kongre merkezi", "Yüksek katlı konut", "AVM (büyük)"] },
  "IV-B":  { grup: "IV. Sınıf (B) Grubu",  aciklama: "Özel ve üst kaliteli bina", ornekler: ["Özel nitelikli bina", "Yüksek standartta ofis", "Prestij konut", "Büyükelçilik"] },
  "IV-C":  { grup: "IV. Sınıf (C) Grubu",  aciklama: "Lüks bina, premium konut", ornekler: ["Lüks konut projesi", "Premium ofis binası", "5 yıldızlı otel", "Şehir hastanesi"] },
  "V-A":   { grup: "V. Sınıf (A) Grubu",   aciklama: "Akıllı ve yeşil bina", ornekler: ["Akıllı bina sistemi", "Çevre dostu yeşil bina", "LEED sertifikalı yapı", "Enerji verimli ofis"] },
  "V-B":   { grup: "V. Sınıf (B) Grubu",   aciklama: "Yüksek güvenlik gerektiren bina", ornekler: ["Güvenlik binası", "Data center", "Araştırma merkezi", "Askeri tesis"] },
  "V-C":   { grup: "V. Sınıf (C) Grubu",   aciklama: "Anıt ve kültür yapısı", ornekler: ["Opera binası", "Tiyatro", "Müze", "Anıt yapı"] },
  "V-D":   { grup: "V. Sınıf (D) Grubu",   aciklama: "Olimpik tesis, stadyum, büyükelçilik", ornekler: ["Olimpik tesis", "Stadyum", "Hipodrom", "Büyükelçilik kompleksi"] },
};

function eskiSinif(kod: string, fiyat: number): YybmSinif {
  const meta = ESKI_SINIF_META[kod]!;
  return { kod, ...meta, fiyat };
}

// ─── DÖNEM VERİLERİ ──────────────────────────────────────────────────────────

const SINIFLAR_2020: YybmSinif[] = [
  eskiSinif("I-A", 210), eskiSinif("I-B", 310),
  eskiSinif("II-A", 510), eskiSinif("II-B", 750), eskiSinif("II-C", 820),
  eskiSinif("III-A", 1100), eskiSinif("III-B", 1450),
  eskiSinif("IV-A", 1550), eskiSinif("IV-B", 1850), eskiSinif("IV-C", 2000),
  eskiSinif("V-A", 2400), eskiSinif("V-B", 2900), eskiSinif("V-C", 3250), eskiSinif("V-D", 3800),
];

const SINIFLAR_2021: YybmSinif[] = [
  eskiSinif("I-A", 255), eskiSinif("I-B", 390),
  eskiSinif("II-A", 640), eskiSinif("II-B", 940), eskiSinif("II-C", 1030),
  eskiSinif("III-A", 1360), eskiSinif("III-B", 1800),
  eskiSinif("IV-A", 1920), eskiSinif("IV-B", 2300), eskiSinif("IV-C", 2480),
  eskiSinif("V-A", 2970), eskiSinif("V-B", 3600), eskiSinif("V-C", 4000), eskiSinif("V-D", 4700),
];

const SINIFLAR_2022_1: YybmSinif[] = [
  eskiSinif("I-A", 425), eskiSinif("I-B", 640),
  eskiSinif("II-A", 1050), eskiSinif("II-B", 1550), eskiSinif("II-C", 1700),
  eskiSinif("III-A", 2250), eskiSinif("III-B", 3000),
  eskiSinif("IV-A", 3200), eskiSinif("IV-B", 3800), eskiSinif("IV-C", 4100),
  eskiSinif("V-A", 4950), eskiSinif("V-B", 6000), eskiSinif("V-C", 6650), eskiSinif("V-D", 7800),
];

const SINIFLAR_2022_2: YybmSinif[] = [
  eskiSinif("I-A", 605), eskiSinif("I-B", 910),
  eskiSinif("II-A", 1500), eskiSinif("II-B", 2210), eskiSinif("II-C", 2425),
  eskiSinif("III-A", 3200), eskiSinif("III-B", 4275),
  eskiSinif("IV-A", 4580), eskiSinif("IV-B", 5440), eskiSinif("IV-C", 5875),
  eskiSinif("V-A", 7090), eskiSinif("V-B", 8595), eskiSinif("V-C", 9525), eskiSinif("V-D", 11175),
];

const SINIFLAR_2022_3: YybmSinif[] = [
  eskiSinif("I-A", 650), eskiSinif("I-B", 990),
  eskiSinif("II-A", 1650), eskiSinif("II-B", 2400), eskiSinif("II-C", 2685),
  eskiSinif("III-A", 3450), eskiSinif("III-B", 4650),
  eskiSinif("IV-A", 4950), eskiSinif("IV-B", 5900), eskiSinif("IV-C", 6400),
  eskiSinif("V-A", 7700), eskiSinif("V-B", 9350), eskiSinif("V-C", 10300), eskiSinif("V-D", 12150),
];

const SINIFLAR_2023_1: YybmSinif[] = [
  eskiSinif("I-A", 865), eskiSinif("I-B", 1320),
  eskiSinif("II-A", 2195), eskiSinif("II-B", 3200), eskiSinif("II-C", 3575),
  eskiSinif("III-A", 4600), eskiSinif("III-B", 6350),
  eskiSinif("IV-A", 6825), eskiSinif("IV-B", 8100), eskiSinif("IV-C", 8825),
  eskiSinif("V-A", 10650), eskiSinif("V-B", 12950), eskiSinif("V-C", 14350), eskiSinif("V-D", 16950),
];

const SINIFLAR_2023_2: YybmSinif[] = [
  eskiSinif("I-A", 1050), eskiSinif("I-B", 1550),
  eskiSinif("II-A", 2600), eskiSinif("II-B", 3800), eskiSinif("II-C", 5350),
  eskiSinif("III-A", 7500), eskiSinif("III-B", 9000),
  eskiSinif("IV-A", 10200), eskiSinif("IV-B", 12050), eskiSinif("IV-C", 12450),
  eskiSinif("V-A", 13800), eskiSinif("V-B", 16250), eskiSinif("V-C", 18100), eskiSinif("V-D", 21400),
];

const SINIFLAR_2024: YybmSinif[] = [
  eskiSinif("I-A", 1450), eskiSinif("I-B", 2100),
  eskiSinif("II-A", 3500), eskiSinif("II-B", 5250), eskiSinif("II-C", 7750),
  eskiSinif("III-A", 12250), eskiSinif("III-B", 14400),
  eskiSinif("IV-A", 15300), eskiSinif("IV-B", 17400), eskiSinif("IV-C", 18700),
  eskiSinif("V-A", 21300), eskiSinif("V-B", 22250), eskiSinif("V-C", 24300), eskiSinif("V-D", 26800),
];

const SINIFLAR_2025: YybmSinif[] = [
  {
    kod: "I-A", grup: "I. Sınıf (A) Grubu",
    aciklama: "Basit yapılar, çardaklar, seralar, ihata duvarları",
    ornekler: ["Basit hayvancılık ve tarım yapıları", "Çardaklar ve gölgelikler", "Plastik örtülü seralar", "İhata duvarları (3 m'ye kadar)"],
    fiyat: 2100,
  },
  {
    kod: "I-B", grup: "I. Sınıf (B) Grubu",
    aciklama: "Padok, cam seralar, depo amaçlı yapılar",
    ornekler: ["Basit padok ve küçükbaş hayvan ağılları", "Cam veya sert plastik örtülü seralar", "Depo amaçlı kayadan oyma yapılar"],
    fiyat: 3050,
  },
  {
    kod: "I-C", grup: "I. Sınıf (C) Grubu",
    aciklama: "Su depoları, ahırlar, istinat duvarları, EV şarj",
    ornekler: ["Betonarme ve kâgir su depoları", "Büyükbaş hayvan ahırları", "Elektrikli araç şarj istasyonları", "İstinat duvarları"],
    fiyat: 3300,
  },
  {
    kod: "I-D", grup: "I. Sınıf (D) Grubu",
    aciklama: "Güneş enerji santralleri",
    ornekler: ["Güneş enerji santralleri (GES)"],
    fiyat: 3900,
  },
  {
    kod: "II-A", grup: "II. Sınıf (A) Grubu",
    aciklama: "İskeleler, genel depolar, hayvan bakım yerleri",
    ornekler: ["Deniz iskeleleri", "Genel amaçlı depolar", "Hayvan bakımevi ve barınakları", "Tarımsal endüstri yapıları"],
    fiyat: 6600,
  },
  {
    kod: "II-B", grup: "II. Sınıf (B) Grubu",
    aciklama: "Tema parklar, halı sahalar, hangarlar",
    ornekler: ["Botanik, jeopark ve tema park yapıları", "Halı sahalar ve semt sahaları", "Hangar yapıları", "Kapalı pazar yerleri"],
    fiyat: 10200,
  },
  {
    kod: "II-C", grup: "II. Sınıf (C) Grubu",
    aciklama: "Kırsal konutlar, hal binaları, sanayi (0-500 kg/m²)",
    ornekler: ["Bağ/dağ/köy ve yayla evleri (200 m² altı)", "Bungalov evleri", "Hal binaları", "Sanayi tesisleri (0-500 kg/m²)"],
    fiyat: 12400,
  },
  {
    kod: "III-A", grup: "III. Sınıf (A) Grubu",
    aciklama: "Akaryakıt istasyonları, otoparklar, konutlar (3 kata kadar)",
    ornekler: ["Akaryakıt ve otogaz dolum istasyonları", "Garajlar ve kapalı otoparklar", "Konutlar (apartman tipi, 3 kata kadar)", "Kreşler ve okul öncesi merkezler"],
    fiyat: 17100,
  },
  {
    kod: "III-B", grup: "III. Sınıf (B) Grubu",
    aciklama: "Sağlık merkezleri, oteller, okullar, konutlar (21.5 m altı)",
    ornekler: ["112 acil sağlık istasyonları", "Aile sağlığı merkezleri", "İlkokul ve ortaokul yapıları", "Konutlar (21.50 m altı, 3 kat üzeri)"],
    fiyat: 18200,
  },
  {
    kod: "III-C", grup: "III. Sınıf (C) Grubu",
    aciklama: "Diş merkezleri, huzurevleri, liseler, konutlar (21.5-30.5 m)",
    ornekler: ["Ağız ve diş sağlığı merkezleri", "Huzurevi ve yaşlı bakım merkezleri", "Lise ve dengi okul yapıları", "Konutlar (21.50-30.50 m)"],
    fiyat: 19150,
  },
  {
    kod: "IV-A", grup: "IV. Sınıf (A) Grubu",
    aciklama: "AVM (25.000 m² altı), fakülteler, sanayi (3.001+ kg/m²)",
    ornekler: ["Alışveriş merkezleri (25.000 m² altı)", "Enstitüler, fakülteler ve yüksekokullar", "Konutlar (30.50-51.50 m)", "Sanayi tesisleri (3.001+ kg/m²)"],
    fiyat: 21500,
  },
  {
    kod: "IV-B", grup: "IV. Sınıf (B) Grubu",
    aciklama: "Bankalar, kapalı spor salonları (5.000+), üniversite",
    ornekler: ["Arşiv binaları", "Banka ve borsa binaları", "Kapalı spor salonları (5.000+ seyirci)", "Üniversite idari binaları"],
    fiyat: 27500,
  },
  {
    kod: "IV-C", grup: "IV. Sınıf (C) Grubu",
    aciklama: "Adalet sarayları, AVM (25.000+ m²), hastaneler (200 yatak altı)",
    ornekler: ["Adalet sarayları", "Alışveriş merkezleri (25.000 m² ve üzeri)", "Hastaneler (200 yatak altı)", "Olimpik spor tesisleri"],
    fiyat: 32600,
  },
  {
    kod: "V-A", grup: "V. Sınıf (A) Grubu",
    aciklama: "Büyükelçilikler, eğitim-araştırma hastaneleri, üniversite kampüsleri",
    ornekler: ["Büyükelçilik ve konsolosluk binaları", "Eğitim ve araştırma hastaneleri", "Stadyumlar ve hipodromlar", "Üniversite kampüsleri"],
    fiyat: 34400,
  },
  {
    kod: "V-B", grup: "V. Sınıf (B) Grubu",
    aciklama: "Askeri tesisler, hastaneler (200-400 yatak), 4 yıldızlı oteller",
    ornekler: ["Deniz, hava ve kara kuvvetleri tesisleri", "Hastaneler (200-400 yatak)", "İbadethaneler (1.500+ kişi)", "Oteller (4 yıldızlı)"],
    fiyat: 35600,
  },
  {
    kod: "V-C", grup: "V. Sınıf (C) Grubu",
    aciklama: "Opera/tiyatro, hastaneler (400+ yatak), müzeler",
    ornekler: ["Bale, opera ve tiyatro yapıları", "Hastaneler (400+ yatak)", "Kongre ve kültür merkezleri", "Müze yapıları"],
    fiyat: 39500,
  },
  {
    kod: "V-D", grup: "V. Sınıf (D) Grubu",
    aciklama: "Havalimanı terminalleri, metro istasyonları, 5 yıldızlı oteller",
    ornekler: ["Havalimanı terminal binaları", "Metro istasyonları", "Oteller (5 yıldızlı)", "Şehir hastaneleri"],
    fiyat: 43400,
  },
  {
    kod: "V-E", grup: "V. Sınıf (E) Grubu",
    aciklama: "Rüzgar enerji santralleri",
    ornekler: ["Rüzgâr enerji santralleri (RES)"],
    fiyat: 86250,
  },
];

const SINIFLAR_2026: YybmSinif[] = [
  {
    kod: "I-A", grup: "I. Sınıf (A) Grubu",
    aciklama: "Basit yapılar, çardaklar, seralar, ihata duvarları",
    ornekler: ["Basit hayvancılık ve tarım yapıları", "Çardaklar ve gölgelikler", "Plastik örtülü seralar", "İhata duvarları (3 m'ye kadar)"],
    fiyat: 2600,
  },
  {
    kod: "I-B", grup: "I. Sınıf (B) Grubu",
    aciklama: "Padok, cam seralar, depo amaçlı yapılar",
    ornekler: ["Basit padok ve küçükbaş hayvan ağılları", "Cam veya sert plastik örtülü seralar", "Depo amaçlı kayadan oyma yapılar", "Kalıcı kullanımı olan yardımcı yapılar"],
    fiyat: 3900,
  },
  {
    kod: "I-C", grup: "I. Sınıf (C) Grubu",
    aciklama: "Su depoları, ahırlar, istinat duvarları, EV şarj",
    ornekler: ["Betonarme ve kâgir su depoları", "Büyükbaş hayvan ahırları", "Elektrikli araç şarj istasyonları", "İstinat duvarları"],
    fiyat: 4200,
  },
  {
    kod: "I-D", grup: "I. Sınıf (D) Grubu",
    aciklama: "Güneş enerji santralleri",
    ornekler: ["Güneş enerji santralleri (GES)"],
    fiyat: 4800,
  },
  {
    kod: "II-A", grup: "II. Sınıf (A) Grubu",
    aciklama: "İskeleler, genel depolar, hayvan bakım yerleri",
    ornekler: ["Deniz iskeleleri", "Genel amaçlı depolar", "Hayvan bakımevi ve barınakları", "Tarımsal endüstri yapıları"],
    fiyat: 8100,
  },
  {
    kod: "II-B", grup: "II. Sınıf (B) Grubu",
    aciklama: "Tema parklar, halı sahalar, hangarlar",
    ornekler: ["Botanik, jeopark ve tema park yapıları", "Halı sahalar ve semt sahaları", "Hangar yapıları", "Kapalı pazar yerleri"],
    fiyat: 12500,
  },
  {
    kod: "II-C", grup: "II. Sınıf (C) Grubu",
    aciklama: "Kırsal konutlar, hal binaları, sanayi (0-500 kg/m²)",
    ornekler: ["Bağ/dağ/köy ve yayla evleri (200 m² altı)", "Bungalov evleri", "Hal binaları", "Sanayi tesisleri (0-500 kg/m²)"],
    fiyat: 15100,
  },
  {
    kod: "III-A", grup: "III. Sınıf (A) Grubu",
    aciklama: "Akaryakıt istasyonları, otoparklar, konutlar (3 kata kadar)",
    ornekler: ["Akaryakıt ve otogaz dolum istasyonları", "Garajlar ve kapalı otoparklar", "Konutlar (apartman tipi, 3 kata kadar)", "Kreşler ve okul öncesi merkezler"],
    fiyat: 19800,
  },
  {
    kod: "III-B", grup: "III. Sınıf (B) Grubu",
    aciklama: "Sağlık merkezleri, oteller, okullar, konutlar (21.5 m altı)",
    ornekler: ["112 acil sağlık istasyonları", "Aile sağlığı merkezleri", "İlkokul ve ortaokul yapıları", "Konutlar (21.50 m altı, 3 kat üzeri)"],
    fiyat: 21050,
  },
  {
    kod: "III-C", grup: "III. Sınıf (C) Grubu",
    aciklama: "Diş merkezleri, huzurevleri, liseler, konutlar (21.5-30.5 m)",
    ornekler: ["Ağız ve diş sağlığı merkezleri", "Huzurevi ve yaşlı bakım merkezleri", "Lise ve dengi okul yapıları", "Konutlar (21.50-30.50 m)"],
    fiyat: 23400,
  },
  {
    kod: "IV-A", grup: "IV. Sınıf (A) Grubu",
    aciklama: "AVM (25.000 m² altı), fakülteler, sanayi (3.001+ kg/m²)",
    ornekler: ["Alışveriş merkezleri (25.000 m² altı)", "Enstitüler, fakülteler ve yüksekokullar", "Konutlar (30.50-51.50 m)", "Sanayi tesisleri (3.001+ kg/m²)"],
    fiyat: 26450,
  },
  {
    kod: "IV-B", grup: "IV. Sınıf (B) Grubu",
    aciklama: "Bankalar, kapalı spor salonları (5.000+), üniversite",
    ornekler: ["Arşiv binaları", "Banka ve borsa binaları", "Kapalı spor salonları (5.000+ seyirci)", "Üniversite idari binaları"],
    fiyat: 33900,
  },
  {
    kod: "IV-C", grup: "IV. Sınıf (C) Grubu",
    aciklama: "Adalet sarayları, AVM (25.000+ m²), hastaneler (200 yatak altı)",
    ornekler: ["Adalet sarayları", "Alışveriş merkezleri (25.000 m² ve üzeri)", "Hastaneler (200 yatak altı)", "Olimpik spor tesisleri"],
    fiyat: 40500,
  },
  {
    kod: "V-A", grup: "V. Sınıf (A) Grubu",
    aciklama: "Büyükelçilikler, eğitim-araştırma hastaneleri, üniversite kampüsleri",
    ornekler: ["Büyükelçilik ve konsolosluk binaları", "Eğitim ve araştırma hastaneleri", "Stadyumlar ve hipodromlar", "Üniversite kampüsleri"],
    fiyat: 42350,
  },
  {
    kod: "V-B", grup: "V. Sınıf (B) Grubu",
    aciklama: "Askeri tesisler, hastaneler (200-400 yatak), 4 yıldızlı oteller",
    ornekler: ["Deniz, hava ve kara kuvvetleri tesisleri", "Hastaneler (200-400 yatak)", "İbadethaneler (1.500+ kişi)", "Oteller (4 yıldızlı)"],
    fiyat: 43850,
  },
  {
    kod: "V-C", grup: "V. Sınıf (C) Grubu",
    aciklama: "Opera/tiyatro, hastaneler (400+ yatak), müzeler",
    ornekler: ["Bale, opera ve tiyatro yapıları", "Hastaneler (400+ yatak)", "Kongre ve kültür merkezleri", "Müze yapıları"],
    fiyat: 48750,
  },
  {
    kod: "V-D", grup: "V. Sınıf (D) Grubu",
    aciklama: "Havalimanı terminalleri, metro istasyonları, 5 yıldızlı oteller",
    ornekler: ["Havalimanı terminal binaları", "Metro istasyonları", "Oteller (5 yıldızlı)", "Şehir hastaneleri"],
    fiyat: 53500,
  },
  {
    kod: "V-E", grup: "V. Sınıf (E) Grubu",
    aciklama: "Rüzgar enerji santralleri",
    ornekler: ["Rüzgâr enerji santralleri (RES)"],
    fiyat: 103500,
  },
];

// ─── TÜM DÖNEMLER (kronolojik sıra) ─────────────────────────────────────────
export const YYBM_DONEMLER: YybmDonem[] = [
  {
    id: "2020",
    yil: 2020,
    etiket: "2020",
    gazeteNo: "31044",
    gazeteKarariTarihi: "15 Şubat 2020",
    siniflar: SINIFLAR_2020,
    pdfMevcut: true,
    pdfUrl: "/api/pdfs/yybm-2020.pdf",
    yapiSinifiTipi: "eski",
  },
  {
    id: "2021",
    yil: 2021,
    etiket: "2021",
    gazeteNo: "31389",
    gazeteKarariTarihi: "27 Şubat 2021",
    siniflar: SINIFLAR_2021,
    pdfMevcut: true,
    pdfUrl: "/api/pdfs/yybm-2021.pdf",
    yapiSinifiTipi: "eski",
  },
  {
    id: "2022/1",
    yil: 2022,
    altDonem: 1,
    etiket: "2022/1",
    gazeteNo: "31755",
    gazeteKarariTarihi: "18 Şubat 2022",
    siniflar: SINIFLAR_2022_1,
    pdfMevcut: true,
    pdfUrl: "/api/pdfs/yybm-2022-1.pdf",
    yapiSinifiTipi: "eski",
  },
  {
    id: "2022/2",
    yil: 2022,
    altDonem: 2,
    etiket: "2022/2",
    gazeteNo: "31874",
    gazeteKarariTarihi: "21 Haziran 2022",
    siniflar: SINIFLAR_2022_2,
    pdfMevcut: true,
    pdfUrl: "/api/pdfs/yybm-2022-2.pdf",
    yapiSinifiTipi: "eski",
  },
  {
    id: "2022/3",
    yil: 2022,
    altDonem: 3,
    etiket: "2022/3",
    gazeteNo: "31952",
    gazeteKarariTarihi: "13 Eylül 2022",
    siniflar: SINIFLAR_2022_3,
    pdfMevcut: true,
    pdfUrl: "/api/pdfs/yybm-2022-3.pdf",
    yapiSinifiTipi: "eski",
  },
  {
    id: "2023/1",
    yil: 2023,
    altDonem: 1,
    etiket: "2023/1",
    gazeteNo: "32106",
    gazeteKarariTarihi: "11 Şubat 2023",
    siniflar: SINIFLAR_2023_1,
    pdfMevcut: true,
    pdfUrl: "/api/pdfs/yybm-2023-1.pdf",
    yapiSinifiTipi: "eski",
  },
  {
    id: "2023/2",
    yil: 2023,
    altDonem: 2,
    etiket: "2023/2",
    gazeteNo: "32277",
    gazeteKarariTarihi: "12 Ağustos 2023",
    siniflar: SINIFLAR_2023_2,
    pdfMevcut: true,
    pdfUrl: "/api/pdfs/yybm-2023-2.pdf",
    yapiSinifiTipi: "eski",
  },
  {
    id: "2024",
    yil: 2024,
    etiket: "2024",
    gazeteNo: "32465",
    gazeteKarariTarihi: "20 Şubat 2024",
    siniflar: SINIFLAR_2024,
    pdfMevcut: true,
    pdfUrl: "/api/pdfs/yybm-2024.pdf",
    yapiSinifiTipi: "eski",
  },
  {
    id: "2025",
    yil: 2025,
    etiket: "2025",
    gazeteNo: "32799",
    gazeteKarariTarihi: "31 Ocak 2025",
    siniflar: SINIFLAR_2025,
    pdfMevcut: true,
    pdfUrl: "/api/pdfs/yybm-2025.pdf",
    yapiSinifiTipi: "yeni",
  },
  {
    id: "2026",
    yil: 2026,
    etiket: "2026",
    gazeteNo: "33157",
    gazeteKarariTarihi: "3 Şubat 2026",
    siniflar: SINIFLAR_2026,
    pdfMevcut: true,
    pdfUrl: "/api/pdfs/yybm-2026.pdf",
    yapiSinifiTipi: "yeni",
  },
];

export const YYBM_DONEM_MAP: Record<string, YybmDonem> = Object.fromEntries(
  YYBM_DONEMLER.map((d) => [d.id, d])
);

export function formatFiyat(fiyat: number): string {
  return fiyat.toLocaleString("tr-TR") + " TL/m²";
}

export function artisOrani(eskiFiyat: number, yeniFiyat: number): number {
  return ((yeniFiyat - eskiFiyat) / eskiFiyat) * 100;
}
