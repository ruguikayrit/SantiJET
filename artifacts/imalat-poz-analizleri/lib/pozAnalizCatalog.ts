import {
  BfaDiscipline,
  BFA_DISCIPLINES,
  resolveAnalizDiscipline,
} from "@/constants/bfaModules";
import { PozAnaliz } from "@/constants/pozAnalizleri";

const resmiCache: Partial<Record<BfaDiscipline, PozAnaliz[]>> = {};
const loadPromises: Partial<Record<BfaDiscipline, Promise<PozAnaliz[]>>> = {};

const RESMI_JSON: Record<BfaDiscipline, () => Promise<{ default?: unknown }>> = {
  insaat: () => import("@/assets/data/resmi-poz-analizleri.json"),
  mekanik: () => import("@/assets/data/resmi-mekanik-analizleri.json"),
  elektrik: () => import("@/assets/data/resmi-elektrik-analizleri.json"),
};

export function isValidPozAnaliz(a: unknown): a is PozAnaliz {
  return (
    a != null &&
    typeof a === "object" &&
    typeof (a as PozAnaliz).id === "string" &&
    (a as PozAnaliz).id.length > 0
  );
}

function tagDiscipline(analizler: PozAnaliz[], discipline: BfaDiscipline): PozAnaliz[] {
  return analizler.map((a) => ({
    ...a,
    discipline: a.discipline ?? discipline,
  }));
}

/** Yalnızca kullanıcı/kopya analizleri kalıcı depolamaya yazılır. */
export function sanitizeUserPozAnalizleri(stored: unknown): PozAnaliz[] {
  if (!Array.isArray(stored)) return [];
  return (stored as unknown[])
    .filter(isValidPozAnaliz)
    .filter((a) => a.kaynakTip !== "sistem")
    .map((a) => ({
      ...a,
      discipline: resolveAnalizDiscipline(a),
    }));
}

export async function loadResmiPozAnalizleri(
  discipline: BfaDiscipline = "insaat",
): Promise<PozAnaliz[]> {
  if (resmiCache[discipline]) return resmiCache[discipline]!;
  if (!loadPromises[discipline]) {
    loadPromises[discipline] = RESMI_JSON[discipline]().then((mod) => {
      const raw = (mod.default ?? mod) as unknown[];
      const data = tagDiscipline(
        Array.isArray(raw) ? raw.filter(isValidPozAnaliz) : [],
        discipline,
      );
      resmiCache[discipline] = data;
      return data;
    });
  }
  return loadPromises[discipline]!;
}

export async function loadAllResmiAnalizleri(): Promise<Record<BfaDiscipline, PozAnaliz[]>> {
  const entries = await Promise.all(
    BFA_DISCIPLINES.map(async (discipline) => [
      discipline,
      await loadResmiPozAnalizleri(discipline),
    ] as const),
  );
  return Object.fromEntries(entries) as Record<BfaDiscipline, PozAnaliz[]>;
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
