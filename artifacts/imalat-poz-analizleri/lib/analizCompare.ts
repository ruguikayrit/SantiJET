import { AnalizKalemi, PozAnaliz, hesaplaAnalizToplam } from "@/constants/pozAnalizleri";

export interface AnalizCompareSummary {
  id: string;
  pozNo: string;
  analizAdi: string;
  olcuBirimi: string;
  malzemeIscilikToplami: number;
  yukleniciKarOrani: number;
  yukleniciKarTutari: number;
  birimFiyati: number;
}

export interface CompareKalemRow {
  key: string;
  pozNo: string;
  tanim: string;
  tip: AnalizKalemi["tip"];
  olcuBirimi: string;
  values: Record<string, { miktar: number; birimFiyati: number; tutar: number } | null>;
}

export interface AnalizCompareResult {
  analizler: AnalizCompareSummary[];
  kalemRows: CompareKalemRow[];
  minBirimFiyati: number;
  maxBirimFiyati: number;
}

function kalemKey(k: AnalizKalemi): string {
  return `${k.tip}|${k.pozNo.trim().toLowerCase()}|${k.tanim.trim().toLowerCase()}`;
}

export function buildAnalizCompare(analizler: PozAnaliz[]): AnalizCompareResult {
  const summaries: AnalizCompareSummary[] = analizler.map((a) => {
    const totals = hesaplaAnalizToplam(a);
    return {
      id: a.id,
      pozNo: a.pozNo,
      analizAdi: a.analizAdi,
      olcuBirimi: a.olcuBirimi,
      malzemeIscilikToplami: totals.malzemeIscilikToplami,
      yukleniciKarOrani: a.yukleniciKarOrani,
      yukleniciKarTutari: totals.yukleniciKarTutari,
      birimFiyati: totals.birimFiyati,
    };
  });

  const rowMap = new Map<string, CompareKalemRow>();

  for (const analiz of analizler) {
    for (const k of analiz.kalemler) {
      const key = kalemKey(k);
      let row = rowMap.get(key);
      if (!row) {
        row = {
          key,
          pozNo: k.pozNo,
          tanim: k.tanim,
          tip: k.tip,
          olcuBirimi: k.olcuBirimi,
          values: {},
        };
        rowMap.set(key, row);
      }
      row.values[analiz.id] = {
        miktar: k.miktar,
        birimFiyati: k.birimFiyati,
        tutar: k.tutar,
      };
    }
  }

  const tipOrder = { malzeme: 0, iscilik: 1, ekipman: 2 } as const;
  const kalemRows = [...rowMap.values()].sort((a, b) => {
    const tipDiff = tipOrder[a.tip] - tipOrder[b.tip];
    if (tipDiff !== 0) return tipDiff;
    return a.pozNo.localeCompare(b.pozNo, "tr") || a.tanim.localeCompare(b.tanim, "tr");
  });

  const birimFiyatlari = summaries.map((s) => s.birimFiyati);
  return {
    analizler: summaries,
    kalemRows,
    minBirimFiyati: Math.min(...birimFiyatlari),
    maxBirimFiyati: Math.max(...birimFiyatlari),
  };
}

export function trFmtCompare(n: number): string {
  return n.toLocaleString("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}
