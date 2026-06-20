import { PozAnaliz } from "@/constants/imalatPozlari";

let resmiCache: PozAnaliz[] | null = null;
let loadPromise: Promise<PozAnaliz[]> | null = null;

/** Yalnızca kullanıcı/kopya analizleri kalıcı depolamaya yazılır. */
export function sanitizeUserPozAnalizleri(stored: unknown): PozAnaliz[] {
  if (!Array.isArray(stored)) return [];
  return (stored as PozAnaliz[]).filter((a) => a?.kaynakTip !== "sistem");
}

export async function loadResmiPozAnalizleri(): Promise<PozAnaliz[]> {
  if (resmiCache) return resmiCache;
  if (!loadPromise) {
    loadPromise = import("@/assets/data/resmi-poz-analizleri.json").then((mod) => {
      const data = (mod.default ?? mod) as PozAnaliz[];
      resmiCache = data;
      return data;
    });
  }
  return loadPromise;
}

export function mergePozAnalizCatalog(
  resmi: PozAnaliz[],
  user: PozAnaliz[],
): PozAnaliz[] {
  const byId = new Map<string, PozAnaliz>();
  for (const a of resmi) byId.set(a.id, a);
  for (const u of user) byId.set(u.id, u);
  return Array.from(byId.values());
}

export function findPozAnalizInCatalog(
  catalog: PozAnaliz[],
  id: string,
): PozAnaliz | undefined {
  return catalog.find((a) => a.id === id);
}
