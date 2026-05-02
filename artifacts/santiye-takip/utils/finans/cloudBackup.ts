import AsyncStorage from "@react-native-async-storage/async-storage";

const CLOUD_KEY_STORAGE = "@budget_cloud_key";
const CLOUD_LAST_SAVED_STORAGE = "@budget_cloud_last_saved";

const API_BASE =
  process.env.EXPO_PUBLIC_DOMAIN
    ? `https://${process.env.EXPO_PUBLIC_DOMAIN}:8080/api`
    : "http://localhost:8080/api";

function generateKey(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  return Array.from({ length: 6 }, () =>
    chars[Math.floor(Math.random() * chars.length)]
  ).join("");
}

export async function getOrCreateBackupKey(): Promise<string> {
  const existing = await AsyncStorage.getItem(CLOUD_KEY_STORAGE);
  if (existing) return existing;
  const key = generateKey();
  await AsyncStorage.setItem(CLOUD_KEY_STORAGE, key);
  return key;
}

export async function getBackupKey(): Promise<string | null> {
  return AsyncStorage.getItem(CLOUD_KEY_STORAGE);
}

export async function getLastSavedAt(): Promise<string | null> {
  return AsyncStorage.getItem(CLOUD_LAST_SAVED_STORAGE);
}

export async function saveToCloud(
  key: string,
  data: object
): Promise<{ key: string; savedAt: string }> {
  const res = await fetch(`${API_BASE}/backup/save`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ key, data }),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error((err as any).error ?? `Sunucu hatası: ${res.status}`);
  }
  const result = await res.json();
  await AsyncStorage.setItem(CLOUD_LAST_SAVED_STORAGE, result.savedAt);
  return result;
}

export async function restoreFromCloud(
  key: string
): Promise<{ data: any; updatedAt: string }> {
  const res = await fetch(`${API_BASE}/backup/restore`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ key: key.trim().toUpperCase() }),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error((err as any).error ?? `Sunucu hatası: ${res.status}`);
  }
  return res.json();
}

export async function setBackupKey(key: string): Promise<void> {
  await AsyncStorage.setItem(CLOUD_KEY_STORAGE, key.trim().toUpperCase());
}
