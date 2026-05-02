import * as DocumentPicker from "expo-document-picker";
import * as FileSystem from "expo-file-system/legacy";
import * as Sharing from "expo-sharing";
import { Platform } from "react-native";

function timestamp() {
  const d = new Date();
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}_${pad(
    d.getHours()
  )}${pad(d.getMinutes())}`;
}

export async function exportJSON(json: string): Promise<void> {
  const filename = `butce-yedek-${timestamp()}.json`;

  if (Platform.OS === "web") {
    const blob = new Blob([json], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    return;
  }

  const dir = FileSystem.cacheDirectory ?? FileSystem.documentDirectory;
  if (!dir) throw new Error("Dosya dizini bulunamadı");
  const path = dir + filename;
  await FileSystem.writeAsStringAsync(path, json, {
    encoding: FileSystem.EncodingType.UTF8,
  });
  const canShare = await Sharing.isAvailableAsync();
  if (canShare) {
    await Sharing.shareAsync(path, {
      mimeType: "application/json",
      dialogTitle: "Bütçe yedeğini paylaş",
      UTI: "public.json",
    });
  }
}

export async function pickJSON(): Promise<string | null> {
  if (Platform.OS === "web") {
    return new Promise((resolve) => {
      const input = document.createElement("input");
      input.type = "file";
      input.accept = "application/json,.json";
      input.onchange = () => {
        const file = input.files?.[0];
        if (!file) return resolve(null);
        const reader = new FileReader();
        reader.onload = () => resolve(String(reader.result ?? ""));
        reader.onerror = () => resolve(null);
        reader.readAsText(file);
      };
      input.oncancel = () => resolve(null);
      input.click();
    });
  }

  const result = await DocumentPicker.getDocumentAsync({
    type: ["application/json", "text/plain", "*/*"],
    copyToCacheDirectory: true,
  });
  if (result.canceled) return null;
  const asset = result.assets?.[0];
  if (!asset?.uri) return null;
  return await FileSystem.readAsStringAsync(asset.uri, {
    encoding: FileSystem.EncodingType.UTF8,
  });
}
