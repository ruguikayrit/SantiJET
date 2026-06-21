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

import { PozAnaliz } from "@/constants/pozAnalizleri";
import { sanitizeUserPozAnalizleri } from "@/lib/pozAnalizCatalog";
import { UserDataImportMode } from "@/lib/userDataBackup";

const STORAGE_KEY = "santijet_ipa_poz_analizleri_v1";
const FAVORITES_KEY = "santijet_ipa_favorites_v1";

function genId(): string {
  return "pa" + Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
}

function sanitizeFavoriteIds(stored: unknown): string[] {
  if (!Array.isArray(stored)) return [];
  return stored.filter((id): id is string => typeof id === "string" && id.length > 0);
}

interface AppContextValue {
  loaded: boolean;
  pozAnalizleri: PozAnaliz[];
  favoriteIds: string[];
  isFavorite: (id: string) => boolean;
  toggleFavorite: (id: string) => void;
  addPozAnaliz: (
    analiz: Omit<PozAnaliz, "id" | "olusturmaTarihi" | "guncellemeTarihi">,
  ) => string;
  updatePozAnaliz: (id: string, patch: Partial<PozAnaliz>) => void;
  deletePozAnaliz: (id: string) => void;
  clonePozAnaliz: (id: string, yeniAd: string, sourceOverride?: PozAnaliz) => PozAnaliz;
  importUserData: (
    data: { pozAnalizleri: PozAnaliz[]; favoriteIds: string[] },
    mode: UserDataImportMode,
  ) => void;
}

const AppContext = createContext<AppContextValue | undefined>(undefined);

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [pozAnalizleri, setPozAnalizleri] = useState<PozAnaliz[]>([]);
  const [favoriteIds, setFavoriteIds] = useState<string[]>([]);
  const [loaded, setLoaded] = useState(false);
  const loadedRef = useRef(false);

  useEffect(() => {
    let active = true;
    Promise.all([AsyncStorage.getItem(STORAGE_KEY), AsyncStorage.getItem(FAVORITES_KEY)])
      .then(([rawAnalizler, rawFavorites]) => {
        if (!active) return;
        if (rawAnalizler) {
          try {
            setPozAnalizleri(sanitizeUserPozAnalizleri(JSON.parse(rawAnalizler)));
          } catch {
            setPozAnalizleri([]);
          }
        }
        if (rawFavorites) {
          try {
            setFavoriteIds(sanitizeFavoriteIds(JSON.parse(rawFavorites)));
          } catch {
            setFavoriteIds([]);
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

  const persist = useCallback((updater: (prev: PozAnaliz[]) => PozAnaliz[]) => {
    if (!loadedRef.current) return;
    setPozAnalizleri((prev) => {
      const next = updater(prev);
      AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next)).catch(() => {});
      return next;
    });
  }, []);

  const persistFavorites = useCallback((updater: (prev: string[]) => string[]) => {
    if (!loadedRef.current) return;
    setFavoriteIds((prev) => {
      const next = updater(prev);
      AsyncStorage.setItem(FAVORITES_KEY, JSON.stringify(next)).catch(() => {});
      return next;
    });
  }, []);

  const value = useMemo<AppContextValue>(
    () => ({
      loaded,
      pozAnalizleri,
      favoriteIds,
      isFavorite: (id: string) => favoriteIds.includes(id),
      toggleFavorite: (id: string) => {
        if (!loadedRef.current) return;
        persistFavorites((prev) =>
          prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id],
        );
      },
      addPozAnaliz: (analiz) => {
        if (!loadedRef.current) return "";
        const id = genId();
        const now = new Date().toISOString();
        const yeni: PozAnaliz = { ...analiz, id, olusturmaTarihi: now, guncellemeTarihi: now };
        persist((prev) => [...prev, yeni]);
        return id;
      },
      updatePozAnaliz: (id, patch) => {
        if (!loadedRef.current) return;
        const now = new Date().toISOString();
        persist((prev) => {
          const existing = prev.find((a) => a.id === id);
          if (existing) {
            if (existing.kaynakTip === "sistem") return prev;
            return prev.map((a) =>
              a.id === id ? { ...a, ...patch, guncellemeTarihi: now } : a,
            );
          }
          if (patch.kaynakTip === "sistem") return prev;
          const yeni = { ...patch, id, guncellemeTarihi: now } as PozAnaliz;
          return [...prev, yeni];
        });
      },
      deletePozAnaliz: (id) => {
        if (!loadedRef.current) return;
        persist((prev) => prev.filter((a) => a.id !== id));
        persistFavorites((prev) => prev.filter((x) => x !== id));
      },
      clonePozAnaliz: (id, yeniAd, sourceOverride) => {
        if (!loadedRef.current) throw new Error("Veriler henüz yüklenmedi");
        let kopya!: PozAnaliz;
        persist((prev) => {
          const source = sourceOverride ?? prev.find((a) => a.id === id);
          if (!source) throw new Error("Analiz bulunamadı");
          const now = new Date().toISOString();
          kopya = {
            ...source,
            id: genId(),
            analizAdi: yeniAd,
            kaynakTip: "kopya",
            discipline: source.discipline,
            olusturmaTarihi: now,
            guncellemeTarihi: now,
            kalemler: source.kalemler.map((k) => ({ ...k, id: genId() })),
          };
          return [...prev, kopya];
        });
        return kopya;
      },
      importUserData: (data, mode) => {
        if (!loadedRef.current) return;
        if (mode === "replace") {
          persist(() => data.pozAnalizleri);
          persistFavorites(() => data.favoriteIds);
          return;
        }

        persist((prev) => {
          const byId = new Map(prev.map((a) => [a.id, a]));
          for (const analiz of data.pozAnalizleri) {
            byId.set(analiz.id, analiz);
          }
          return Array.from(byId.values());
        });
        persistFavorites((prev) => Array.from(new Set([...prev, ...data.favoriteIds])));
      },
    }),
    [loaded, persist, persistFavorites, pozAnalizleri, favoriteIds],
  );

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp(): AppContextValue {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error("useApp must be used inside AppProvider");
  return ctx;
}
