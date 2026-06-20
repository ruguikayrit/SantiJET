import AsyncStorage from "@react-native-async-storage/async-storage";

const STORAGE_KEY = "santijet_ipa_recent_v1";
const MAX_RECENT = 20;

export interface RecentViewEntry {
  id: string;
  viewedAt: string;
}

export async function loadRecentViews(): Promise<RecentViewEntry[]> {
  try {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.filter(
      (e): e is RecentViewEntry =>
        e != null &&
        typeof e === "object" &&
        typeof e.id === "string" &&
        e.id.length > 0 &&
        typeof e.viewedAt === "string",
    );
  } catch {
    return [];
  }
}

export async function recordRecentView(id: string): Promise<RecentViewEntry[]> {
  const now = new Date().toISOString();
  const prev = await loadRecentViews();
  const next: RecentViewEntry[] = [
    { id, viewedAt: now },
    ...prev.filter((e) => e.id !== id),
  ].slice(0, MAX_RECENT);
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next)).catch(() => {});
  return next;
}

export async function clearRecentViews(): Promise<void> {
  await AsyncStorage.removeItem(STORAGE_KEY).catch(() => {});
}
