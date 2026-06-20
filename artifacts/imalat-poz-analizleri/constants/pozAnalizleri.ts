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

/** Arama ifadesini kelime tokenlarına ayırır */
export function tokenizeTrSearch(query: string): string[] {
  return normalizeTrSearch(query).split(/\s+/).filter(Boolean);
}

/** Analiz kaydının aranabilir metin alanlarını birleştirir */
export function buildPozAnalizHaystack(
  analiz: Pick<PozAnaliz, "pozNo" | "analizAdi" | "pozTarifi" | "kategori" | "kalemler">,
): string {
  const kalemMetni = analiz.kalemler.map((k) => `${k.pozNo} ${k.tanim}`).join(" ");
  return normalizeTrSearch(
    [analiz.pozNo, analiz.analizAdi, analiz.pozTarifi, analiz.kategori, kalemMetni]
      .filter(Boolean)
      .join(" "),
  );
}

/** Tüm kelime tokenları eşleşmeli (AND arama) */
export function matchesPozAnalizSearch(
  analiz: Pick<PozAnaliz, "pozNo" | "analizAdi" | "pozTarifi" | "kategori" | "kalemler">,
  query: string,
): boolean {
  const tokens = tokenizeTrSearch(query);
  if (!tokens.length) return true;
  const haystack = buildPozAnalizHaystack(analiz);
  return tokens.every((token) => haystack.includes(token));
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
