import { PozAnaliz, hesaplaAnalizToplam } from "@/constants/pozAnalizleri";

export interface KesifSatiri {
  id: string;
  analizId: string;
  pozNo: string;
  analizAdi: string;
  olcuBirimi: string;
  birimFiyati: number;
  miktar: number;
  tutar: number;
}

export interface KesifProject {
  id: string;
  ad: string;
  aciklama: string;
  satirlar: KesifSatiri[];
  olusturmaTarihi: string;
  guncellemeTarihi: string;
}

export function genKesifId(prefix: string): string {
  return prefix + Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
}

export function hesaplaSatirTutar(miktar: number, birimFiyati: number): number {
  return Math.round(miktar * birimFiyati * 100) / 100;
}

export function buildKesifSatiri(analiz: PozAnaliz, miktar: number): KesifSatiri {
  const birimFiyati = hesaplaAnalizToplam(analiz).birimFiyati;
  const qty = Number.isFinite(miktar) ? miktar : 0;
  return {
    id: genKesifId("ks"),
    analizId: analiz.id,
    pozNo: analiz.pozNo,
    analizAdi: analiz.analizAdi,
    olcuBirimi: analiz.olcuBirimi,
    birimFiyati,
    miktar: qty,
    tutar: hesaplaSatirTutar(qty, birimFiyati),
  };
}

export function hesaplaKesifToplam(satirlar: KesifSatiri[]): number {
  return Math.round(satirlar.reduce((s, r) => s + r.tutar, 0) * 100) / 100;
}

export function trFmtKesif(n: number): string {
  return n.toLocaleString("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

export function sanitizeKesifProjects(stored: unknown): KesifProject[] {
  if (!Array.isArray(stored)) return [];
  const result: KesifProject[] = [];
  for (const raw of stored) {
    if (!raw || typeof raw !== "object") continue;
    const p = raw as Partial<KesifProject>;
    if (typeof p.id !== "string" || typeof p.ad !== "string") continue;
    const satirlar: KesifSatiri[] = [];
    if (Array.isArray(p.satirlar)) {
      for (const s of p.satirlar) {
        if (!s || typeof s !== "object") continue;
        const row = s as Partial<KesifSatiri>;
        if (typeof row.id !== "string" || typeof row.analizId !== "string") continue;
        const miktar = Number(row.miktar) || 0;
        const birimFiyati = Number(row.birimFiyati) || 0;
        satirlar.push({
          id: row.id,
          analizId: row.analizId,
          pozNo: String(row.pozNo ?? ""),
          analizAdi: String(row.analizAdi ?? ""),
          olcuBirimi: String(row.olcuBirimi ?? ""),
          birimFiyati,
          miktar,
          tutar: hesaplaSatirTutar(miktar, birimFiyati),
        });
      }
    }
    result.push({
      id: p.id,
      ad: p.ad.trim() || "Keşif",
      aciklama: typeof p.aciklama === "string" ? p.aciklama : "",
      satirlar,
      olusturmaTarihi:
        typeof p.olusturmaTarihi === "string" ? p.olusturmaTarihi : new Date().toISOString(),
      guncellemeTarihi:
        typeof p.guncellemeTarihi === "string" ? p.guncellemeTarihi : new Date().toISOString(),
    });
  }
  return result.sort(
    (a, b) => new Date(b.guncellemeTarihi).getTime() - new Date(a.guncellemeTarihi).getTime(),
  );
}
