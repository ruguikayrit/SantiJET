import { useEffect, useMemo, useState } from "react";

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
    [rawUser]
  );
  const [resmiAnalizler, setResmiAnalizler] = useState<PozAnaliz[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    loadResmiPozAnalizleri()
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
  }, []);

  const pozAnalizleri = useMemo(
    () => mergePozAnalizCatalog(resmiAnalizler, userAnalizleri),
    [resmiAnalizler, userAnalizleri]
  );

  return { pozAnalizleri, loading, error, resmiLoaded: !loading && !error };
}
