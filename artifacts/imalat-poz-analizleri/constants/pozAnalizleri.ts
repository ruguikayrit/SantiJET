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

/** Türkçe arama/filtre için metin normalizasyonu */
export function normalizeTrSearch(text: string): string {
  return text.trim().toLocaleLowerCase("tr");
}

/** Katalogdaki gerçek kategori listesi (filtre çipleri için) */
export function buildPozKategoriFiltreleri(
  analizler: Pick<PozAnaliz, "kategori">[],
): string[] {
  const counts = new Map<string, number>();
  for (const a of analizler) {
    const k = (a.kategori || "").trim();
    if (!k) continue;
    counts.set(k, (counts.get(k) ?? 0) + 1);
  }
  return Array.from(counts.entries())
    .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0], "tr"))
    .map(([k]) => k);
}
