import AsyncStorage from "@react-native-async-storage/async-storage";
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
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
import { UserDataImportMode } from "@/lib/userDataBackup";

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
  importProjects: (projects: KesifProject[], mode: UserDataImportMode) => void;
}

const KesifContext = createContext<KesifContextValue | undefined>(undefined);

export function KesifProvider({ children }: { children: React.ReactNode }) {
  const [projects, setProjects] = useState<KesifProject[]>([]);
  const [loaded, setLoaded] = useState(false);
  const loadedRef = useRef(false);

  useEffect(() => {
    let active = true;
    AsyncStorage.getItem(STORAGE_KEY)
      .then((raw) => {
        if (!active) return;
        if (raw) {
          try {
            setProjects(sanitizeKesifProjects(JSON.parse(raw)));
          } catch {
            setProjects([]);
          }
        }
      })
      .finally(() => {
        if (active) {
          loadedRef.current = true;
          setLoaded(true);
        }
      });
    return () => {
      active = false;
    };
  }, []);

  const persist = useCallback((updater: (prev: KesifProject[]) => KesifProject[]) => {
    if (!loadedRef.current) return;
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
        if (!loadedRef.current) return "";
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
        if (!loadedRef.current) return;
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
        if (!loadedRef.current) return;
        persist((prev) => prev.filter((p) => p.id !== id));
      },
      addSatir: (projectId, analiz, miktar) => {
        if (!loadedRef.current) return;
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
        if (!loadedRef.current) return;
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
        if (!loadedRef.current) return;
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
        if (!loadedRef.current) return;
        const now = new Date().toISOString();
        persist((prev) =>
          prev.map((p) =>
            p.id === projectId ? { ...p, satirlar: [], guncellemeTarihi: now } : p,
          ),
        );
      },
      importProjects: (incoming, mode) => {
        if (!loadedRef.current) return;
        const now = new Date().toISOString();
        persist((prev) => {
          if (mode === "replace") {
            return incoming.map((p) => ({ ...p, guncellemeTarihi: p.guncellemeTarihi || now }));
          }
          const byId = new Map(prev.map((p) => [p.id, p]));
          for (const project of incoming) {
            byId.set(project.id, { ...project, guncellemeTarihi: project.guncellemeTarihi || now });
          }
          return Array.from(byId.values());
        });
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
