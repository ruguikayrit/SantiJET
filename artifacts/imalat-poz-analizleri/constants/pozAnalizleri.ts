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
  /** insaat | mekanik | elektrik — kullanıcı/kopya kayıtları için */
  discipline?: "insaat" | "mekanik" | "elektrik";
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

const POZ_SEARCH_MEASURE_UNITS =
  "cm|mm|m²|m³|m2|m3|kg|ton|adet|lt|gr";

const POZ_SEARCH_WORD_CHAR = "a-z0-9ğüşıöç";

function escapeRegExp(text: string): string {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/** "19cm" gibi bitişik ölçü yazımlarını "19 cm" biçimine çevirir */
function expandPozSearchQuery(query: string): string {
  return normalizeTrSearch(query).replace(
    new RegExp(`(\\d+(?:[.,]\\d+)?)\\s*(${POZ_SEARCH_MEASURE_UNITS})\\b`, "gi"),
    "$1 $2",
  );
}

/** Arama ifadesini kelime tokenlarına ayırır; sayı+birim çiftlerini birleştirir */
export function tokenizeTrSearch(query: string): string[] {
  const parts = expandPozSearchQuery(query).split(/\s+/).filter(Boolean);
  const unitRe = new RegExp(`^(${POZ_SEARCH_MEASURE_UNITS})$`, "i");
  const tokens: string[] = [];

  for (let i = 0; i < parts.length; i++) {
    const part = parts[i];
    const next = parts[i + 1];
    if (/^\d+(?:[.,]\d+)?$/.test(part) && next && unitRe.test(next)) {
      tokens.push(`${part} ${next}`);
      i++;
    } else {
      tokens.push(part);
    }
  }
  return tokens;
}

/** Kelime sınırında eşleşme; poz no içindeki 1901 gibi yanlış eşleşmeleri engeller */
function tokenMatchesHaystack(token: string, haystack: string): boolean {
  const measureMatch = token.match(
    new RegExp(`^(\\d+(?:[.,]\\d+)?)\\s+(${POZ_SEARCH_MEASURE_UNITS})$`, "i"),
  );
  if (measureMatch) {
    const [, num, unit] = measureMatch;
    const re = new RegExp(
      `(^|[^${POZ_SEARCH_WORD_CHAR}])${escapeRegExp(num)}\\s*${escapeRegExp(unit)}($|[^${POZ_SEARCH_WORD_CHAR}])`,
      "i",
    );
    return re.test(haystack);
  }

  const re = new RegExp(
    `(^|[^${POZ_SEARCH_WORD_CHAR}])${escapeRegExp(token)}($|[^${POZ_SEARCH_WORD_CHAR}])`,
    "i",
  );
  return re.test(haystack);
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
  return tokens.every((token) => tokenMatchesHaystack(token, haystack));
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
