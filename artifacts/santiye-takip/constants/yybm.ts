export interface YybmSinif {
  kod: string;
  grup: string;
  aciklama: string;
  ornekler: string[];
  fiyat: number;
}

export interface YybmYilData {
  yil: number;
  gazeteNo: string;
  gazeteKarariTarihi: string;
  siniflar: YybmSinif[];
  pdfMevcut: boolean;
}

const SINIFLAR_2026: YybmSinif[] = [
  {
    kod: "I-A",
    grup: "I. Sınıf (A) Grubu",
    aciklama: "Basit yapılar, çardaklar, seralar, ihata duvarları",
    ornekler: ["Basit hayvancılık ve tarım yapıları", "Çardaklar ve gölgelikler", "Plastik örtülü seralar", "İhata duvarları (3 m'ye kadar)"],
    fiyat: 2600,
  },
  {
    kod: "I-B",
    grup: "I. Sınıf (B) Grubu",
    aciklama: "Padok, cam seralar, depo amaçlı yapılar",
    ornekler: ["Basit padok ve küçükbaş hayvan ağılları", "Cam veya sert plastik örtülü seralar", "Depo amaçlı kayadan oyma yapılar", "Kalıcı kullanımı olan yardımcı yapılar"],
    fiyat: 3900,
  },
  {
    kod: "I-C",
    grup: "I. Sınıf (C) Grubu",
    aciklama: "Su depoları, ahırlar, istinat duvarları, EV şarj",
    ornekler: ["Betonarme ve kâgir su depoları", "Büyükbaş hayvan ahırları", "Elektrikli araç şarj istasyonları", "İstinat duvarları"],
    fiyat: 4200,
  },
  {
    kod: "I-D",
    grup: "I. Sınıf (D) Grubu",
    aciklama: "Güneş enerji santralleri",
    ornekler: ["Güneş enerji santralleri (GES)"],
    fiyat: 4800,
  },
  {
    kod: "II-A",
    grup: "II. Sınıf (A) Grubu",
    aciklama: "İskeleler, genel depolar, hayvan bakım yerleri",
    ornekler: ["Deniz iskeleleri", "Genel amaçlı depolar", "Hayvan bakımevi ve barınakları", "Tarımsal endüstri yapıları"],
    fiyat: 8100,
  },
  {
    kod: "II-B",
    grup: "II. Sınıf (B) Grubu",
    aciklama: "Tema parklar, halı sahalar, hangarlar",
    ornekler: ["Botanik, jeopark ve tema park yapıları", "Halı sahalar ve semt sahaları", "Hangar yapıları", "Kapalı pazar yerleri"],
    fiyat: 12500,
  },
  {
    kod: "II-C",
    grup: "II. Sınıf (C) Grubu",
    aciklama: "Kırsal konutlar, hal binaları, sanayi (0-500 kg/m²)",
    ornekler: ["Bağ/dağ/köy ve yayla evleri (200 m² altı)", "Bungalov evleri", "Hal binaları", "Sanayi tesisleri (0-500 kg/m²)"],
    fiyat: 15100,
  },
  {
    kod: "III-A",
    grup: "III. Sınıf (A) Grubu",
    aciklama: "Akaryakıt istasyonları, otoparklar, konutlar (3 kata kadar)",
    ornekler: ["Akaryakıt ve otogaz dolum istasyonları", "Garajlar ve kapalı otoparklar", "Konutlar (apartman tipi, 3 kata kadar)", "Kreşler ve okul öncesi merkezler"],
    fiyat: 19800,
  },
  {
    kod: "III-B",
    grup: "III. Sınıf (B) Grubu",
    aciklama: "Sağlık merkezleri, oteller, okullar, konutlar (21.5 m altı)",
    ornekler: ["112 acil sağlık istasyonları", "Aile sağlığı merkezleri", "İlkokul ve ortaokul yapıları", "Konutlar (21.50 m altı, 3 kat üzeri)"],
    fiyat: 21050,
  },
  {
    kod: "III-C",
    grup: "III. Sınıf (C) Grubu",
    aciklama: "Diş merkezleri, huzurevleri, liseler, konutlar (21.5-30.5 m)",
    ornekler: ["Ağız ve diş sağlığı merkezleri", "Huzurevi ve yaşlı bakım merkezleri", "Lise ve dengi okul yapıları", "Konutlar (21.50-30.50 m)"],
    fiyat: 23400,
  },
  {
    kod: "IV-A",
    grup: "IV. Sınıf (A) Grubu",
    aciklama: "AVM (25.000 m² altı), fakülteler, sanayi (3.001+ kg/m²)",
    ornekler: ["Alışveriş merkezleri (25.000 m² altı)", "Enstitüler, fakülteler ve yüksekokullar", "Konutlar (30.50-51.50 m)", "Sanayi tesisleri (3.001+ kg/m²)"],
    fiyat: 26450,
  },
  {
    kod: "IV-B",
    grup: "IV. Sınıf (B) Grubu",
    aciklama: "Bankalar, kapalı spor salonları (5.000+), üniversite",
    ornekler: ["Arşiv binaları", "Banka ve borsa binaları", "Kapalı spor salonları (5.000+ seyirci)", "Üniversite idari binaları"],
    fiyat: 33900,
  },
  {
    kod: "IV-C",
    grup: "IV. Sınıf (C) Grubu",
    aciklama: "Adalet sarayları, AVM (25.000+ m²), hastaneler (200 yatak altı)",
    ornekler: ["Adalet sarayları", "Alışveriş merkezleri (25.000 m² ve üzeri)", "Hastaneler (200 yatak altı)", "Olimpik spor tesisleri"],
    fiyat: 40500,
  },
  {
    kod: "V-A",
    grup: "V. Sınıf (A) Grubu",
    aciklama: "Büyükelçilikler, eğitim-araştırma hastaneleri, üniversite kampüsleri",
    ornekler: ["Büyükelçilik ve konsolosluk binaları", "Eğitim ve araştırma hastaneleri", "Stadyumlar ve hipodromlar", "Üniversite kampüsleri"],
    fiyat: 42350,
  },
  {
    kod: "V-B",
    grup: "V. Sınıf (B) Grubu",
    aciklama: "Askeri tesisler, hastaneler (200-400 yatak), 4 yıldızlı oteller",
    ornekler: ["Deniz, hava ve kara kuvvetleri tesisleri", "Hastaneler (200-400 yatak)", "İbadethaneler (1.500+ kişi)", "Oteller (4 yıldızlı)"],
    fiyat: 43850,
  },
  {
    kod: "V-C",
    grup: "V. Sınıf (C) Grubu",
    aciklama: "Opera/tiyatro, hastaneler (400+ yatak), müzeler",
    ornekler: ["Bale, opera ve tiyatro yapıları", "Hastaneler (400+ yatak)", "Kongre ve kültür merkezleri", "Müze yapıları"],
    fiyat: 48750,
  },
  {
    kod: "V-D",
    grup: "V. Sınıf (D) Grubu",
    aciklama: "Havalimanı terminalleri, metro istasyonları, 5 yıldızlı oteller",
    ornekler: ["Havalimanı terminal binaları", "Metro istasyonları", "Oteller (5 yıldızlı)", "Şehir hastaneleri"],
    fiyat: 53500,
  },
  {
    kod: "V-E",
    grup: "V. Sınıf (E) Grubu",
    aciklama: "Rüzgar enerji santralleri",
    ornekler: ["Rüzgâr enerji santralleri (RES)"],
    fiyat: 103500,
  },
];

const SINIFLAR_2025: YybmSinif[] = [
  {
    kod: "I-A",
    grup: "I. Sınıf (A) Grubu",
    aciklama: "Basit yapılar, çardaklar, seralar, ihata duvarları",
    ornekler: ["Basit hayvancılık ve tarım yapıları", "Çardaklar ve gölgelikler", "Plastik örtülü seralar", "İhata duvarları (3 m'ye kadar)"],
    fiyat: 2100,
  },
  {
    kod: "I-B",
    grup: "I. Sınıf (B) Grubu",
    aciklama: "Padok, cam seralar, depo amaçlı yapılar",
    ornekler: ["Basit padok ve küçükbaş hayvan ağılları", "Cam veya sert plastik örtülü seralar", "Depo amaçlı kayadan oyma yapılar"],
    fiyat: 3050,
  },
  {
    kod: "I-C",
    grup: "I. Sınıf (C) Grubu",
    aciklama: "Su depoları, ahırlar, istinat duvarları, EV şarj",
    ornekler: ["Betonarme ve kâgir su depoları", "Büyükbaş hayvan ahırları", "Elektrikli araç şarj istasyonları", "İstinat duvarları"],
    fiyat: 3300,
  },
  {
    kod: "I-D",
    grup: "I. Sınıf (D) Grubu",
    aciklama: "Güneş enerji santralleri",
    ornekler: ["Güneş enerji santralleri (GES)"],
    fiyat: 3900,
  },
  {
    kod: "II-A",
    grup: "II. Sınıf (A) Grubu",
    aciklama: "İskeleler, genel depolar, hayvan bakım yerleri",
    ornekler: ["Deniz iskeleleri", "Genel amaçlı depolar", "Hayvan bakımevi ve barınakları", "Tarımsal endüstri yapıları"],
    fiyat: 6600,
  },
  {
    kod: "II-B",
    grup: "II. Sınıf (B) Grubu",
    aciklama: "Tema parklar, halı sahalar, hangarlar",
    ornekler: ["Botanik, jeopark ve tema park yapıları", "Halı sahalar ve semt sahaları", "Hangar yapıları", "Kapalı pazar yerleri"],
    fiyat: 10200,
  },
  {
    kod: "II-C",
    grup: "II. Sınıf (C) Grubu",
    aciklama: "Kırsal konutlar, hal binaları, sanayi (0-500 kg/m²)",
    ornekler: ["Bağ/dağ/köy ve yayla evleri (200 m² altı)", "Bungalov evleri", "Hal binaları", "Sanayi tesisleri (0-500 kg/m²)"],
    fiyat: 12400,
  },
  {
    kod: "III-A",
    grup: "III. Sınıf (A) Grubu",
    aciklama: "Akaryakıt istasyonları, otoparklar, konutlar (3 kata kadar)",
    ornekler: ["Akaryakıt ve otogaz dolum istasyonları", "Garajlar ve kapalı otoparklar", "Konutlar (apartman tipi, 3 kata kadar)", "Kreşler ve okul öncesi merkezler"],
    fiyat: 17100,
  },
  {
    kod: "III-B",
    grup: "III. Sınıf (B) Grubu",
    aciklama: "Sağlık merkezleri, oteller, okullar, konutlar (21.5 m altı)",
    ornekler: ["112 acil sağlık istasyonları", "Aile sağlığı merkezleri", "İlkokul ve ortaokul yapıları", "Konutlar (21.50 m altı, 3 kat üzeri)"],
    fiyat: 18200,
  },
  {
    kod: "III-C",
    grup: "III. Sınıf (C) Grubu",
    aciklama: "Diş merkezleri, huzurevleri, liseler, konutlar (21.5-30.5 m)",
    ornekler: ["Ağız ve diş sağlığı merkezleri", "Huzurevi ve yaşlı bakım merkezleri", "Lise ve dengi okul yapıları", "Konutlar (21.50-30.50 m)"],
    fiyat: 19150,
  },
  {
    kod: "IV-A",
    grup: "IV. Sınıf (A) Grubu",
    aciklama: "AVM (25.000 m² altı), fakülteler, sanayi (3.001+ kg/m²)",
    ornekler: ["Alışveriş merkezleri (25.000 m² altı)", "Enstitüler, fakülteler ve yüksekokullar", "Konutlar (30.50-51.50 m)", "Sanayi tesisleri (3.001+ kg/m²)"],
    fiyat: 21500,
  },
  {
    kod: "IV-B",
    grup: "IV. Sınıf (B) Grubu",
    aciklama: "Bankalar, kapalı spor salonları (5.000+), üniversite",
    ornekler: ["Arşiv binaları", "Banka ve borsa binaları", "Kapalı spor salonları (5.000+ seyirci)", "Üniversite idari binaları"],
    fiyat: 27500,
  },
  {
    kod: "IV-C",
    grup: "IV. Sınıf (C) Grubu",
    aciklama: "Adalet sarayları, AVM (25.000+ m²), hastaneler (200 yatak altı)",
    ornekler: ["Adalet sarayları", "Alışveriş merkezleri (25.000 m² ve üzeri)", "Hastaneler (200 yatak altı)", "Olimpik spor tesisleri"],
    fiyat: 32600,
  },
  {
    kod: "V-A",
    grup: "V. Sınıf (A) Grubu",
    aciklama: "Büyükelçilikler, eğitim-araştırma hastaneleri, üniversite kampüsleri",
    ornekler: ["Büyükelçilik ve konsolosluk binaları", "Eğitim ve araştırma hastaneleri", "Stadyumlar ve hipodromlar", "Üniversite kampüsleri"],
    fiyat: 34400,
  },
  {
    kod: "V-B",
    grup: "V. Sınıf (B) Grubu",
    aciklama: "Askeri tesisler, hastaneler (200-400 yatak), 4 yıldızlı oteller",
    ornekler: ["Deniz, hava ve kara kuvvetleri tesisleri", "Hastaneler (200-400 yatak)", "İbadethaneler (1.500+ kişi)", "Oteller (4 yıldızlı)"],
    fiyat: 35600,
  },
  {
    kod: "V-C",
    grup: "V. Sınıf (C) Grubu",
    aciklama: "Opera/tiyatro, hastaneler (400+ yatak), müzeler",
    ornekler: ["Bale, opera ve tiyatro yapıları", "Hastaneler (400+ yatak)", "Kongre ve kültür merkezleri", "Müze yapıları"],
    fiyat: 39500,
  },
  {
    kod: "V-D",
    grup: "V. Sınıf (D) Grubu",
    aciklama: "Havalimanı terminalleri, metro istasyonları, 5 yıldızlı oteller",
    ornekler: ["Havalimanı terminal binaları", "Metro istasyonları", "Oteller (5 yıldızlı)", "Şehir hastaneleri"],
    fiyat: 43400,
  },
  {
    kod: "V-E",
    grup: "V. Sınıf (E) Grubu",
    aciklama: "Rüzgar enerji santralleri",
    ornekler: ["Rüzgâr enerji santralleri (RES)"],
    fiyat: 86250,
  },
];

export const YYBM_VERILER: Record<number, YybmYilData> = {
  2025: {
    yil: 2025,
    gazeteNo: "32799",
    gazeteKarariTarihi: "31 Ocak 2025",
    siniflar: SINIFLAR_2025,
    pdfMevcut: true,
  },
  2026: {
    yil: 2026,
    gazeteNo: "33157",
    gazeteKarariTarihi: "3 Şubat 2026",
    siniflar: SINIFLAR_2026,
    pdfMevcut: true,
  },
};

export const YYBM_PDF_URLS: Record<number, string> = {
  2025: "/api/pdfs/yybm-2025.pdf",
  2026: "/api/pdfs/yybm-2026.pdf",
};

export const MEVCUT_YILLAR = [2025, 2026];

export function formatFiyat(fiyat: number): string {
  return fiyat.toLocaleString("tr-TR") + " TL/m²";
}

export function artisOrani(eskiFiyat: number, yeniFiyat: number): number {
  return ((yeniFiyat - eskiFiyat) / eskiFiyat) * 100;
}
