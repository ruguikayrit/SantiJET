import { useCallback, useEffect, useMemo, useState } from "react";

import { PozAnaliz } from "@/constants/pozAnalizTypes";
import { usePozAnaliz } from "@/context/PozAnalizContext";
import {
  loadResmiPozAnalizleri,
  mergePozAnalizCatalog,
  sanitizeUserPozAnalizleri,
} from "@/lib/pozAnalizCatalog";

export function useMergedPozAnalizleri() {
  const { pozAnalizleri: rawUser } = usePozAnaliz();
  const userAnalizleri = useMemo(
    () => sanitizeUserPozAnalizleri(rawUser ?? []),
    [rawUser],
  );
  const [resmiAnalizler, setResmiAnalizler] = useState<PozAnaliz[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  const reload = useCallback(() => {
    setLoading(true);
    setError(null);
    setReloadKey((k) => k + 1);
  }, []);

  useEffect(() => {
    let cancelled = false;
    loadResmiPozAnalizleri(reloadKey > 0)
      .then((data) => {
        if (!cancelled) {
          setResmiAnalizler(data);
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
  }, [reloadKey]);

  const pozAnalizleri = useMemo(
    () => mergePozAnalizCatalog(resmiAnalizler, userAnalizleri),
    [resmiAnalizler, userAnalizleri],
  );

  return { pozAnalizleri, loading, error, resmiLoaded: !loading && !error, reload };
}
