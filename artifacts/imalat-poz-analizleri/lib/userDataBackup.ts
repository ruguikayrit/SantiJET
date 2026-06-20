import * as FileSystem from "expo-file-system/legacy";
import * as Sharing from "expo-sharing";
import { Alert, Platform } from "react-native";

import { PozAnaliz } from "@/constants/pozAnalizleri";

export const BACKUP_VERSION = 1;

export interface UserDataBackup {
  version: typeof BACKUP_VERSION;
  app: "santijet-bfa";
  exportedAt: string;
  pozAnalizleri: PozAnaliz[];
  favoriteIds: string[];
  themeId?: string;
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
        dialogTitle: "Verileri Kaydet",
      });
      return true;
    }

    Alert.alert(
      "Yedekleme",
      `${backup.pozAnalizleri.length} özel analiz ve ${backup.favoriteIds.length} favori kaydedildi. Bu cihazda paylaşım desteklenmiyor.`,
    );
    return false;
  } catch {
    Alert.alert("Hata", "Veriler kaydedilemedi. Lütfen tekrar deneyin.");
    return false;
  }
}
