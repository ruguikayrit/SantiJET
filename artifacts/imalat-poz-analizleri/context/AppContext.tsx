import AsyncStorage from "@react-native-async-storage/async-storage";
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

import { PozAnaliz } from "@/constants/pozAnalizleri";
import { sanitizeUserPozAnalizleri } from "@/lib/pozAnalizCatalog";

const STORAGE_KEY = "santijet_ipa_poz_analizleri_v1";

function genId(): string {
  return "pa" + Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
}

interface AppContextValue {
  loaded: boolean;
  pozAnalizleri: PozAnaliz[];
  addPozAnaliz: (
    analiz: Omit<PozAnaliz, "id" | "olusturmaTarihi" | "guncellemeTarihi">,
  ) => string;
  updatePozAnaliz: (id: string, patch: Partial<PozAnaliz>) => void;
  deletePozAnaliz: (id: string) => void;
  clonePozAnaliz: (id: string, yeniAd: string, sourceOverride?: PozAnaliz) => PozAnaliz;
}

const AppContext = createContext<AppContextValue | undefined>(undefined);

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [pozAnalizleri, setPozAnalizleri] = useState<PozAnaliz[]>([]);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY)
      .then((raw) => {
        if (raw) {
          try {
            setPozAnalizleri(sanitizeUserPozAnalizleri(JSON.parse(raw)));
          } catch {
            setPozAnalizleri([]);
          }
        }
      })
      .finally(() => setLoaded(true));
  }, []);

  const persist = useCallback((updater: (prev: PozAnaliz[]) => PozAnaliz[]) => {
    setPozAnalizleri((prev) => {
      const next = updater(prev);
      AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next)).catch(() => {});
      return next;
    });
  }, []);

  const value = useMemo<AppContextValue>(
    () => ({
      loaded,
      pozAnalizleri,
      addPozAnaliz: (analiz) => {
        const id = genId();
        const now = new Date().toISOString();
        const yeni: PozAnaliz = { ...analiz, id, olusturmaTarihi: now, guncellemeTarihi: now };
        persist((prev) => [...prev, yeni]);
        return id;
      },
      updatePozAnaliz: (id, patch) => {
        const now = new Date().toISOString();
        persist((prev) => {
          const exists = prev.some((a) => a.id === id);
          if (exists) {
            return prev.map((a) =>
              a.id === id ? { ...a, ...patch, guncellemeTarihi: now } : a,
            );
          }
          const yeni = { ...patch, id, guncellemeTarihi: now } as PozAnaliz;
          return [...prev, yeni];
        });
      },
      deletePozAnaliz: (id) => {
        persist((prev) => prev.filter((a) => a.id !== id));
      },
      clonePozAnaliz: (id, yeniAd, sourceOverride) => {
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
            olusturmaTarihi: now,
            guncellemeTarihi: now,
            kalemler: source.kalemler.map((k) => ({ ...k, id: genId() })),
          };
          return [...prev, kopya];
        });
        return kopya;
      },
    }),
    [loaded, persist, pozAnalizleri],
  );

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp(): AppContextValue {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error("useApp must be used inside AppProvider");
  return ctx;
}
