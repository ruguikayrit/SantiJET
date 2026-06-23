import { PozAnaliz } from "@/constants/pozAnalizTypes";

let resmiCache: PozAnaliz[] | null = null;
let loadPromise: Promise<PozAnaliz[]> | null = null;

export function isValidPozAnaliz(a: unknown): a is PozAnaliz {
  return (
    a != null &&
    typeof a === "object" &&
    typeof (a as PozAnaliz).id === "string" &&
    (a as PozAnaliz).id.length > 0
  );
}

/** Yalnızca kullanıcı/kopya analizleri kalıcı depolamaya yazılır. */
export function sanitizeUserPozAnalizleri(stored: unknown): PozAnaliz[] {
  if (!Array.isArray(stored)) return [];
  return (stored as unknown[])
    .filter(isValidPozAnaliz)
    .filter((a) => a.kaynakTip !== "sistem");
}

export async function loadResmiPozAnalizleri(): Promise<PozAnaliz[]> {
  if (resmiCache) return resmiCache;
  if (!loadPromise) {
    loadPromise = import("@/assets/data/resmi-poz-analizleri.json").then((mod) => {
      const raw = (mod.default ?? mod) as unknown[];
      const data = Array.isArray(raw) ? raw.filter(isValidPozAnaliz) : [];
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
  for (const a of resmi) {
    if (isValidPozAnaliz(a)) byId.set(a.id, a);
  }
  for (const u of user) {
    if (isValidPozAnaliz(u)) byId.set(u.id, u);
  }
  return Array.from(byId.values());
}

export function findPozAnalizInCatalog(
  catalog: PozAnaliz[],
  id: string,
): PozAnaliz | undefined {
  return catalog.find((a) => a.id === id);
}
