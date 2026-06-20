import { Asset } from "expo-asset";
import * as FileSystem from "expo-file-system/legacy";
import * as Sharing from "expo-sharing";
import { Alert, Linking, Platform } from "react-native";

import { YYBM_PDF_ASSETS } from "@/constants/yybmPdfAssets";

async function resolvePdfUri(donemId: string): Promise<string | null> {
  const moduleId = YYBM_PDF_ASSETS[donemId];
  if (moduleId == null) return null;

  const asset = Asset.fromModule(moduleId);
  await asset.downloadAsync();

  const sourceUri = asset.localUri ?? asset.uri;
  if (!sourceUri) return null;

  const safeName = donemId.replace(/\//g, "-");
  const cachePath = `${FileSystem.cacheDirectory}yybm-${safeName}.pdf`;

  if (sourceUri === cachePath) return cachePath;

  await FileSystem.copyAsync({ from: sourceUri, to: cachePath });
  return cachePath;
}

export async function openYybmPdf(donemId: string): Promise<void> {
  try {
    const uri = await resolvePdfUri(donemId);
    if (!uri) {
      Alert.alert("Hata", "PDF dosyası bulunamadı.");
      return;
    }

    if (Platform.OS === "web") {
      if (typeof window !== "undefined") {
        window.open(uri, "_blank");
      }
      return;
    }

    if (await Sharing.isAvailableAsync()) {
      await Sharing.shareAsync(uri, {
        mimeType: "application/pdf",
        UTI: "com.adobe.pdf",
        dialogTitle: "YYBM PDF",
      });
      return;
    }

    const canOpen = await Linking.canOpenURL(uri);
    if (canOpen) {
      await Linking.openURL(uri);
      return;
    }

    Alert.alert("Hata", "PDF görüntüleyici açılamadı.");
  } catch {
    Alert.alert("Hata", "PDF açılırken bir sorun oluştu.");
  }
}
