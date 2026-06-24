import AsyncStorage from "@react-native-async-storage/async-storage";
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

import { PozAnaliz } from "@/constants/pozAnalizTypes";
import { sanitizeUserPozAnalizleri, toPersistedUserAnaliz } from "@/lib/pozAnalizCatalog";

const STORAGE_KEY = "imalat_poz_analizleri_v1";

export interface AppRole {
  id: string;
  isAdmin: boolean;
}

interface PozAnalizContextValue {
  loaded: boolean;
  pozAnalizleri: PozAnaliz[];
  currentRole: AppRole;
  addPozAnaliz: (
    analiz: Omit<PozAnaliz, "id" | "olusturmaTarihi" | "guncellemeTarihi">
  ) => string;
  updatePozAnaliz: (id: string, patch: Partial<PozAnaliz>) => void;
  deletePozAnaliz: (id: string) => void;
  clonePozAnaliz: (id: string, yeniAd: string, sourceOverride?: PozAnaliz) => PozAnaliz;
}

const PozAnalizContext = createContext<PozAnalizContextValue | undefined>(undefined);

function genId(): string {
  return "pa" + Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
}

const DEFAULT_ROLE: AppRole = { id: "proje-muduru", isAdmin: true };

export function PozAnalizProvider({ children }: { children: React.ReactNode }) {
  const [pozAnalizleri, setPozAnalizleri] = useState<PozAnaliz[]>([]);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY)
      .then((raw) => {
        if (!raw) return;
        try {
          setPozAnalizleri(sanitizeUserPozAnalizleri(JSON.parse(raw)));
        } catch {
          setPozAnalizleri([]);
        }
      })
      .finally(() => setLoaded(true));
  }, []);

  const persist = useCallback((next: PozAnaliz[]) => {
    const clean = sanitizeUserPozAnalizleri(next);
    setPozAnalizleri(clean);
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(clean)).catch(() => {});
  }, []);

  const value = useMemo<PozAnalizContextValue>(
    () => ({
      loaded,
      pozAnalizleri,
      currentRole: DEFAULT_ROLE,
      addPozAnaliz: (analiz) => {
        const id = genId();
        const now = new Date().toISOString();
        const yeni: PozAnaliz = { ...analiz, id, olusturmaTarihi: now, guncellemeTarihi: now };
        persist([...pozAnalizleri, yeni]);
        return id;
      },
      updatePozAnaliz: (id, patch) => {
        const now = new Date().toISOString();
        const exists = pozAnalizleri.some((a) => a.id === id);
        if (exists) {
          persist(
            pozAnalizleri.map((a) =>
              a.id === id
                ? toPersistedUserAnaliz({ ...a, ...patch, guncellemeTarihi: now } as PozAnaliz)
                : a
            )
          );
          return;
        }
        const yeni = toPersistedUserAnaliz({ ...patch, id, guncellemeTarihi: now } as PozAnaliz);
        persist([...pozAnalizleri, yeni]);
      },
      deletePozAnaliz: (id) => {
        persist(pozAnalizleri.filter((a) => a.id !== id));
      },
      clonePozAnaliz: (id, yeniAd, sourceOverride) => {
        const source = sourceOverride ?? pozAnalizleri.find((a) => a.id === id);
        if (!source) throw new Error("Analiz bulunamadı");
        const now = new Date().toISOString();
        const kopya: PozAnaliz = {
          ...source,
          id: genId(),
          analizAdi: yeniAd,
          kaynakTip: "kopya",
          olusturmaTarihi: now,
          guncellemeTarihi: now,
          kalemler: source.kalemler.map((k) => ({ ...k, id: genId() })),
        };
        persist([...pozAnalizleri, kopya]);
        return kopya;
      },
    }),
    [loaded, pozAnalizleri, persist]
  );

  return <PozAnalizContext.Provider value={value}>{children}</PozAnalizContext.Provider>;
}

export function usePozAnaliz(): PozAnalizContextValue {
  const ctx = useContext(PozAnalizContext);
  if (!ctx) throw new Error("usePozAnaliz must be used inside PozAnalizProvider");
  return ctx;
}
