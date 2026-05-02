import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Haptics from "expo-haptics";
import { useEffect, useState } from "react";

export function useListOrder(storageKey: string, ids: string[]) {
  const [orderedIds, setOrderedIds] = useState<string[]>(ids);

  useEffect(() => {
    AsyncStorage.getItem(storageKey).then((val) => {
      if (!val) { setOrderedIds(ids); return; }
      try {
        const saved = JSON.parse(val) as string[];
        const reconciled = [
          ...saved.filter((id) => ids.includes(id)),
          ...ids.filter((id) => !saved.includes(id)),
        ];
        setOrderedIds(reconciled);
      } catch {
        setOrderedIds(ids);
      }
    });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [storageKey]);

  const idsKey = ids.join(",");
  useEffect(() => {
    setOrderedIds((prev) => {
      const reconciled = [
        ...prev.filter((id) => ids.includes(id)),
        ...ids.filter((id) => !prev.includes(id)),
      ];
      return reconciled;
    });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [idsKey]);

  const moveItem = (id: string, dir: "up" | "down") => {
    Haptics.selectionAsync();
    setOrderedIds((prev) => {
      const idx = prev.indexOf(id);
      const next = dir === "up" ? idx - 1 : idx + 1;
      if (next < 0 || next >= prev.length) return prev;
      const arr = [...prev];
      [arr[idx], arr[next]] = [arr[next], arr[idx]];
      AsyncStorage.setItem(storageKey, JSON.stringify(arr));
      return arr;
    });
  };

  const sortedByOrder = <T extends { id: string }>(items: T[]): T[] =>
    [...items].sort((a, b) => {
      const ia = orderedIds.indexOf(a.id);
      const ib = orderedIds.indexOf(b.id);
      if (ia === -1 && ib === -1) return 0;
      if (ia === -1) return 1;
      if (ib === -1) return -1;
      return ia - ib;
    });

  const positionOf = (id: string) => orderedIds.indexOf(id);
  const totalCount = orderedIds.length;

  return { orderedIds, setOrderedIds, moveItem, sortedByOrder, positionOf, totalCount };
}
