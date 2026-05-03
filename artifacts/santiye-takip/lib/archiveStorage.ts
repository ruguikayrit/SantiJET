import { Platform } from "react-native";

const DB_NAME = "santijet-archive";
const STORE = "files";
const DB_VERSION = 1;

function openDb(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    if (typeof indexedDB === "undefined") {
      reject(new Error("IndexedDB desteklenmiyor"));
      return;
    }
    const req = indexedDB.open(DB_NAME, DB_VERSION);
    req.onupgradeneeded = () => {
      const db = req.result;
      if (!db.objectStoreNames.contains(STORE)) db.createObjectStore(STORE);
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

async function idbPut(key: string, blob: Blob): Promise<void> {
  const db = await openDb();
  await new Promise<void>((resolve, reject) => {
    const tx = db.transaction(STORE, "readwrite");
    tx.objectStore(STORE).put(blob, key);
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
    tx.onabort = () => reject(tx.error);
  });
  db.close();
}

async function idbGet(key: string): Promise<Blob | null> {
  const db = await openDb();
  const result = await new Promise<Blob | null>((resolve, reject) => {
    const tx = db.transaction(STORE, "readonly");
    const r = tx.objectStore(STORE).get(key);
    r.onsuccess = () => resolve((r.result as Blob | undefined) ?? null);
    r.onerror = () => reject(r.error);
  });
  db.close();
  return result;
}

async function idbDelete(key: string): Promise<void> {
  const db = await openDb();
  await new Promise<void>((resolve, reject) => {
    const tx = db.transaction(STORE, "readwrite");
    tx.objectStore(STORE).delete(key);
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
    tx.onabort = () => reject(tx.error);
  });
  db.close();
}

export interface PersistedAsset {
  uri: string;
  name: string;
  mimeType?: string | null;
  size?: number | null;
}

export interface PersistResult {
  storageKey: string;
  size: number;
}

export async function saveAsset(
  id: string,
  asset: PersistedAsset,
  ext: string
): Promise<PersistResult> {
  if (Platform.OS === "web") {
    const r = await fetch(asset.uri);
    const blob = await r.blob();
    await idbPut(id, blob);
    return { storageKey: id, size: blob.size };
  }
  const FS: any = await import("expo-file-system/legacy");
  const dir = (FS.documentDirectory as string) + "santijet-archive/";
  try {
    await FS.makeDirectoryAsync(dir, { intermediates: true });
  } catch {}
  const dst = `${dir}${id}.${ext}`;
  await FS.copyAsync({ from: asset.uri, to: dst });
  let size = asset.size || 0;
  try {
    const info = await FS.getInfoAsync(dst);
    if (info && typeof info.size === "number") size = info.size;
  } catch {}
  return { storageKey: dst, size };
}

export async function deleteAsset(storageKey: string): Promise<void> {
  if (Platform.OS === "web") {
    try {
      await idbDelete(storageKey);
    } catch {}
    return;
  }
  try {
    const FS: any = await import("expo-file-system/legacy");
    await FS.deleteAsync(storageKey, { idempotent: true });
  } catch {}
}

export async function openAsset(
  storageKey: string,
  fileName: string,
  mime: string
): Promise<void> {
  if (Platform.OS === "web") {
    const blob = await idbGet(storageKey);
    if (!blob) throw new Error("Dosya bulunamadı");
    const url = URL.createObjectURL(
      blob.type ? blob : new Blob([blob], { type: mime })
    );
    const w = window.open(url, "_blank");
    if (!w) {
      const a = document.createElement("a");
      a.href = url;
      a.download = fileName;
      document.body.appendChild(a);
      a.click();
      a.remove();
    }
    setTimeout(() => URL.revokeObjectURL(url), 60_000);
    return;
  }
  const Sharing: any = await import("expo-sharing");
  if (await Sharing.isAvailableAsync()) {
    await Sharing.shareAsync(storageKey, { mimeType: mime, dialogTitle: fileName });
    return;
  }
  const Linking: any = await import("react-native");
  await Linking.Linking.openURL(storageKey);
}

export function formatBytes(n: number): string {
  if (!n || n < 0) return "0 B";
  const u = ["B", "KB", "MB", "GB"];
  let i = 0;
  let v = n;
  while (v >= 1024 && i < u.length - 1) {
    v /= 1024;
    i++;
  }
  return `${v.toFixed(v < 10 && i > 0 ? 1 : 0)} ${u[i]}`;
}
