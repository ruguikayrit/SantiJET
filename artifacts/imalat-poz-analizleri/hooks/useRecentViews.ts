import { useCallback, useEffect, useState } from "react";

import { loadRecentViews, RecentViewEntry, recordRecentView } from "@/lib/recentViews";

export function useRecentViews() {
  const [entries, setEntries] = useState<RecentViewEntry[]>([]);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    loadRecentViews()
      .then(setEntries)
      .finally(() => setLoaded(true));
  }, []);

  const recordView = useCallback(async (id: string) => {
    const next = await recordRecentView(id);
    setEntries(next);
  }, []);

  return { entries, loaded, recordView };
}
