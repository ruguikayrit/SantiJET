import AsyncStorage from "@react-native-async-storage/async-storage";
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

import {
  KesifProject,
  buildKesifSatiri,
  genKesifId,
  hesaplaSatirTutar,
  sanitizeKesifProjects,
} from "@/constants/kesif";
import { PozAnaliz } from "@/constants/pozAnalizleri";

const STORAGE_KEY = "santijet_ipa_kesif_v1";

interface KesifContextValue {
  loaded: boolean;
  projects: KesifProject[];
  getProject: (id: string) => KesifProject | undefined;
  createProject: (ad: string, aciklama?: string) => string;
  updateProject: (id: string, patch: Partial<Pick<KesifProject, "ad" | "aciklama">>) => void;
  deleteProject: (id: string) => void;
  addSatir: (projectId: string, analiz: PozAnaliz, miktar: number) => void;
  updateSatirMiktar: (projectId: string, satirId: string, miktar: number) => void;
  removeSatir: (projectId: string, satirId: string) => void;
  clearAllSatirlar: (projectId: string) => void;
}

const KesifContext = createContext<KesifContextValue | undefined>(undefined);

export function KesifProvider({ children }: { children: React.ReactNode }) {
  const [projects, setProjects] = useState<KesifProject[]>([]);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY)
      .then((raw) => {
        if (raw) {
          try {
            setProjects(sanitizeKesifProjects(JSON.parse(raw)));
          } catch {
            setProjects([]);
          }
        }
      })
      .finally(() => setLoaded(true));
  }, []);

  const persist = useCallback((updater: (prev: KesifProject[]) => KesifProject[]) => {
    setProjects((prev) => {
      const next = updater(prev);
      AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next)).catch(() => {});
      return next;
    });
  }, []);

  const value = useMemo<KesifContextValue>(
    () => ({
      loaded,
      projects,
      getProject: (id) => projects.find((p) => p.id === id),
      createProject: (ad, aciklama = "") => {
        const id = genKesifId("kp");
        const now = new Date().toISOString();
        const project: KesifProject = {
          id,
          ad: ad.trim() || "Yeni Keşif",
          aciklama: aciklama.trim(),
          satirlar: [],
          olusturmaTarihi: now,
          guncellemeTarihi: now,
        };
        persist((prev) => [project, ...prev]);
        return id;
      },
      updateProject: (id, patch) => {
        const now = new Date().toISOString();
        persist((prev) =>
          prev.map((p) =>
            p.id === id
              ? {
                  ...p,
                  ...patch,
                  ad: patch.ad !== undefined ? patch.ad.trim() || p.ad : p.ad,
                  aciklama: patch.aciklama !== undefined ? patch.aciklama : p.aciklama,
                  guncellemeTarihi: now,
                }
              : p,
          ),
        );
      },
      deleteProject: (id) => {
        persist((prev) => prev.filter((p) => p.id !== id));
      },
      addSatir: (projectId, analiz, miktar) => {
        const satir = buildKesifSatiri(analiz, miktar);
        const now = new Date().toISOString();
        persist((prev) =>
          prev.map((p) =>
            p.id === projectId
              ? { ...p, satirlar: [...p.satirlar, satir], guncellemeTarihi: now }
              : p,
          ),
        );
      },
      updateSatirMiktar: (projectId, satirId, miktar) => {
        const qty = Number.isFinite(miktar) ? miktar : 0;
        const now = new Date().toISOString();
        persist((prev) =>
          prev.map((p) => {
            if (p.id !== projectId) return p;
            return {
              ...p,
              guncellemeTarihi: now,
              satirlar: p.satirlar.map((s) =>
                s.id === satirId
                  ? {
                      ...s,
                      miktar: qty,
                      tutar: hesaplaSatirTutar(qty, s.birimFiyati),
                    }
                  : s,
              ),
            };
          }),
        );
      },
      removeSatir: (projectId, satirId) => {
        const now = new Date().toISOString();
        persist((prev) =>
          prev.map((p) =>
            p.id === projectId
              ? {
                  ...p,
                  satirlar: p.satirlar.filter((s) => s.id !== satirId),
                  guncellemeTarihi: now,
                }
              : p,
          ),
        );
      },
      clearAllSatirlar: (projectId) => {
        const now = new Date().toISOString();
        persist((prev) =>
          prev.map((p) =>
            p.id === projectId ? { ...p, satirlar: [], guncellemeTarihi: now } : p,
          ),
        );
      },
    }),
    [loaded, persist, projects],
  );

  return <KesifContext.Provider value={value}>{children}</KesifContext.Provider>;
}

export function useKesif(): KesifContextValue {
  const ctx = useContext(KesifContext);
  if (!ctx) throw new Error("useKesif must be used inside KesifProvider");
  return ctx;
}
