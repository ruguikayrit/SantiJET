import * as FileSystem from "expo-file-system/legacy";
import * as Sharing from "expo-sharing";
import { Alert, Platform } from "react-native";

import { PozAnaliz } from "@/constants/pozAnalizleri";
import { sanitizeUserPozAnalizleri } from "@/lib/pozAnalizCatalog";

export const BACKUP_VERSION = 1;

export interface UserDataBackup {
  version: typeof BACKUP_VERSION;
  app: "santijet-bfa";
  exportedAt: string;
  pozAnalizleri: PozAnaliz[];
  favoriteIds: string[];
  themeId?: string;
}

export type UserDataImportMode = "merge" | "replace";

function sanitizeFavoriteIds(stored: unknown): string[] {
  if (!Array.isArray(stored)) return [];
  return stored.filter((id): id is string => typeof id === "string" && id.length > 0);
}

export function buildUserDataBackup(
  pozAnalizleri: PozAnaliz[],
  favoriteIds: string[],
  themeId?: string,
): UserDataBackup {
  return {
    version: BACKUP_VERSION,
    app: "santijet-bfa",
    exportedAt: new Date().toISOString(),
    pozAnalizleri,
    favoriteIds,
    ...(themeId ? { themeId } : {}),
  };
}

export function parseUserDataBackup(raw: unknown): UserDataBackup | null {
  if (!raw || typeof raw !== "object") return null;
  const obj = raw as Partial<UserDataBackup>;
  if (obj.app !== "santijet-bfa") return null;
  if (typeof obj.version !== "number" || obj.version < 1) return null;

  const pozAnalizleri = sanitizeUserPozAnalizleri(obj.pozAnalizleri);
  const favoriteIds = sanitizeFavoriteIds(obj.favoriteIds);

  return {
    version: BACKUP_VERSION,
    app: "santijet-bfa",
    exportedAt: typeof obj.exportedAt === "string" ? obj.exportedAt : new Date().toISOString(),
    pozAnalizleri,
    favoriteIds,
    ...(typeof obj.themeId === "string" && obj.themeId.length > 0 ? { themeId: obj.themeId } : {}),
  };
}

function backupFilename(): string {
  const stamp = new Date().toISOString().slice(0, 10);
  return `santijet_bfa_yedek_${stamp}.json`;
}

async function downloadBackupOnWeb(json: string, filename: string): Promise<void> {
  const blob = new Blob([json], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  URL.revokeObjectURL(url);
}

export async function shareUserDataBackup(backup: UserDataBackup): Promise<boolean> {
  const json = JSON.stringify(backup, null, 2);
  const filename = backupFilename();

  try {
    if (Platform.OS === "web") {
      await downloadBackupOnWeb(json, filename);
      return true;
    }

    const uri = `${FileSystem.cacheDirectory}${filename}`;
    await FileSystem.writeAsStringAsync(uri, json, { encoding: FileSystem.EncodingType.UTF8 });

    if (await Sharing.isAvailableAsync()) {
      await Sharing.shareAsync(uri, {
        mimeType: "application/json",
        dialogTitle: "Verileri Dışa Aktar",
      });
      return true;
    }

    Alert.alert(
      "Dışa Aktarma",
      `${backup.pozAnalizleri.length} özel analiz ve ${backup.favoriteIds.length} favori hazırlandı. Bu cihazda paylaşım desteklenmiyor.`,
    );
    return false;
  } catch {
    Alert.alert("Hata", "Veriler dışa aktarılamadı. Lütfen tekrar deneyin.");
    return false;
  }
}

async function readBackupFromUri(uri: string): Promise<UserDataBackup | null> {
  try {
    const content = await FileSystem.readAsStringAsync(uri, {
      encoding: FileSystem.EncodingType.UTF8,
    });
    return parseUserDataBackup(JSON.parse(content));
  } catch {
    return null;
  }
}

export async function pickUserDataBackup(): Promise<UserDataBackup | null> {
  try {
    const DocumentPicker = await import("expo-document-picker");
    const result = await DocumentPicker.getDocumentAsync({
      type: "application/json",
      copyToCacheDirectory: true,
      multiple: false,
    });

    if (result.canceled || !result.assets?.[0]?.uri) return null;

    const backup = await readBackupFromUri(result.assets[0].uri);
    if (!backup) {
      Alert.alert("Geçersiz Dosya", "Seçilen dosya geçerli bir ŞantiJET yedek dosyası değil.");
    }
    return backup;
  } catch {
    Alert.alert("Hata", "Yedek dosyası okunamadı. Lütfen tekrar deneyin.");
    return null;
  }
}

export function confirmImportMode(
  onSelect: (mode: UserDataImportMode) => void,
  hasExistingData: boolean,
): void {
  if (!hasExistingData) {
    onSelect("replace");
    return;
  }

  Alert.alert(
    "İçe Aktarma",
    "Mevcut verilerinizle yedek dosyası nasıl birleştirilsin?",
    [
      {
        text: "Birleştir",
        onPress: () => onSelect("merge"),
      },
      {
        text: "Değiştir",
        style: "destructive",
        onPress: () => onSelect("replace"),
      },
      { text: "İptal", style: "cancel" },
    ],
  );
}
