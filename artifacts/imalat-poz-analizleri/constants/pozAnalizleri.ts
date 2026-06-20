export const IMALAT_POZ_KATEGORILERI = [
  "Hafriyat ve Toprak",
  "Beton ve Demir",
  "Kalıp",
  "Duvar",
  "Sıva ve Şap",
  "Yalıtım",
  "Çatı",
  "Kaplama",
  "Boya",
  "Doğrama",
  "Sıhhi Tesisat",
  "Elektrik",
  "Mekanik Tesisat",
  "Asansör",
  "Cephe",
  "Çevre Düzenleme",
  "Yıkım ve Söküm",
  "Çelik Yapı",
  "Altyapı",
  "Peyzaj",
  "Diğer",
] as const;

export interface AnalizKalemi {
  id: string;
  tip: "malzeme" | "iscilik" | "ekipman";
  pozNo: string;
  tanim: string;
  olcuBirimi: string;
  miktar: number;
  birimFiyati: number;
  tutar: number;
}

export interface PozAnaliz {
  id: string;
  pozNo: string;
  analizAdi: string;
  olcuBirimi: string;
  kategori: string;
  kalemler: AnalizKalemi[];
  pozTarifi: string;
  yapimSartlari: string;
  olcusu: string;
  malzemeIscilikToplami: number;
  yukleniciKarOrani: number;
  yukleniciKarTutari: number;
  birimFiyati: number;
  olusturmaTarihi: string;
  guncellemeTarihi: string;
  kaynakTip: "sistem" | "kullanici" | "kopya";
  notlar?: string;
}

export function hesaplaAnalizToplam(
  analiz: Pick<PozAnaliz, "kalemler" | "yukleniciKarOrani">,
): {
  malzemeIscilikToplami: number;
  yukleniciKarTutari: number;
  birimFiyati: number;
} {
  const toplam = analiz.kalemler.reduce((s, k) => s + (k.tutar || 0), 0);
  const kar = Math.round(toplam * (analiz.yukleniciKarOrani / 100) * 100) / 100;
  return {
    malzemeIscilikToplami: Math.round(toplam * 100) / 100,
    yukleniciKarTutari: kar,
    birimFiyati: Math.round((toplam + kar) * 100) / 100,
  };
}
