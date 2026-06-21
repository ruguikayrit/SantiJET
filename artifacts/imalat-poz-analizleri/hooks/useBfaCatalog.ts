import { useCallback, useEffect, useMemo, useState } from "react";

import {
  BfaCatalogStats,
  BfaDiscipline,
  BFA_DISCIPLINES,
  BfaModuleKey,
  resolveAnalizDiscipline,
} from "@/constants/bfaModules";
import { PozAnaliz } from "@/constants/pozAnalizleri";
import { useApp } from "@/context/AppContext";
import {
  loadAllResmiAnalizleri,
  mergePozAnalizCatalog,
  sanitizeUserPozAnalizleri,
} from "@/lib/pozAnalizCatalog";

const EMPTY_DISCIPLINE: Record<BfaDiscipline, PozAnaliz[]> = {
  insaat: [],
  mekanik: [],
  elektrik: [],
};

export function useBfaCatalog() {
  const { pozAnalizleri: rawUser, favoriteIds } = useApp();
  const userAnalizleri = useMemo(
    () => sanitizeUserPozAnalizleri(rawUser ?? []),
    [rawUser],
  );
  const [resmiByDiscipline, setResmiByDiscipline] =
    useState<Record<BfaDiscipline, PozAnaliz[]>>(EMPTY_DISCIPLINE);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    loadAllResmiAnalizleri()
      .then((data) => {
        if (!cancelled) {
          setResmiByDiscipline(data);
          setLoading(false);
        }
      })
      .catch(() => {
        if (!cancelled) {
          setError("Resmi analiz verisi yüklenemedi.");
          setLoading(false);
        }
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const byDiscipline = useMemo(() => {
    const result: Record<BfaDiscipline, PozAnaliz[]> = { ...EMPTY_DISCIPLINE };
    for (const discipline of BFA_DISCIPLINES) {
      result[discipline] = mergePozAnalizCatalog(
        resmiByDiscipline[discipline],
        userAnalizleri.filter((a) => resolveAnalizDiscipline(a) === discipline),
      );
    }
    return result;
  }, [resmiByDiscipline, userAnalizleri]);

  const all = useMemo(
    () => [...byDiscipline.insaat, ...byDiscipline.mekanik, ...byDiscipline.elektrik],
    [byDiscipline],
  );

  const favoriler = useMemo(
    () => all.filter((a) => favoriteIds.includes(a.id)),
    [all, favoriteIds],
  );

  const stats = useMemo<BfaCatalogStats>(
    () => ({
      insaat: byDiscipline.insaat,
      mekanik: byDiscipline.mekanik,
      elektrik: byDiscipline.elektrik,
      all,
      favoriler,
    }),
    [byDiscipline, all, favoriler],
  );

  const getModuleAnalizleri = useCallback(
    (modul: BfaModuleKey): PozAnaliz[] => {
      if (modul === "favoriler") return favoriler;
      return byDiscipline[modul];
    },
    [byDiscipline, favoriler],
  );

  return {
    loading,
    error,
    stats,
    all,
    getModuleAnalizleri,
    resmiLoaded: !loading && !error,
  };
}

/** Geriye dönük uyumluluk: yalnızca inşaat kataloğu */
export function useMergedPozAnalizleri() {
  const { getModuleAnalizleri, loading, error, resmiLoaded } = useBfaCatalog();
  return {
    pozAnalizleri: getModuleAnalizleri("insaat"),
    loading,
    error,
    resmiLoaded,
  };
}
