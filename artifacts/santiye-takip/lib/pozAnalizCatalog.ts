import { PozAnaliz } from "@/constants/imalatPozlari";

/** resmi-poz-analizleri.json güncellendiğinde artırın (Metro önbelleğini kırar). */
export const RESMI_POZ_CATALOG_VERSION = 2;

let resmiCache: { version: number; data: PozAnaliz[] } | null = null;
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

/**
 * Resmi (sistem) kayda yapılan düzenlemeler override olarak saklanır.
 * kaynakTip "sistem" kalırsa sanitize adımında silinir ve eski resmi veri geri gelir.
 */
export function toPersistedUserAnaliz(analiz: PozAnaliz): PozAnaliz {
  if (analiz.kaynakTip === "sistem") {
    return { ...analiz, kaynakTip: "kopya" };
  }
  return analiz;
}

export function clearResmiPozAnalizCache(): void {
  resmiCache = null;
  loadPromise = null;
}

export async function loadResmiPozAnalizleri(force = false): Promise<PozAnaliz[]> {
  if (force) clearResmiPozAnalizCache();
  if (resmiCache?.version === RESMI_POZ_CATALOG_VERSION) return resmiCache.data;
  clearResmiPozAnalizCache();
  if (!loadPromise) {
    loadPromise = import("@/assets/data/resmi-poz-analizleri.json").then((mod) => {
      const raw = (mod.default ?? mod) as unknown[];
      const data = Array.isArray(raw) ? raw.filter(isValidPozAnaliz) : [];
      resmiCache = { version: RESMI_POZ_CATALOG_VERSION, data };
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
