import { Feather } from "@expo/vector-icons";
import * as DocumentPicker from "expo-document-picker";
import * as FileSystem from "expo-file-system/legacy";
import { useRouter } from "expo-router";
import * as Sharing from "expo-sharing";
import React, { useState } from "react";
import {
  Alert,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import BottomSheet from "@/components/BottomSheet";
import PrimaryButton from "@/components/PrimaryButton";
import { useApp } from "@/context/AppContext";
import { useI18n } from "@/context/I18nContext";
import { useColors } from "@/hooks/useColors";

export default function VeriYonetimScreen() {
  const colors = useColors();
  const router = useRouter();
  const { t } = useI18n();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;

  const { exportData, importData, logout } = useApp();

  const [exportVisible, setExportVisible] = useState(false);
  const [exportText, setExportText] = useState("");
  const [importVisible, setImportVisible] = useState(false);
  const [importText, setImportText] = useState("");
  const [importFileName, setImportFileName] = useState<string | null>(null);
  const [importMsg, setImportMsg] = useState<{ type: "ok" | "err"; text: string } | null>(null);

  function openExport() {
    const json = exportData();
    setExportText(json);
    setExportVisible(true);
  }

  async function downloadJson() {
    const json = exportText || exportData();
    const stamp = new Date().toISOString().slice(0, 19).replace(/[:T]/g, "-");
    const filename = `santiye-takip-${stamp}.json`;
    if (Platform.OS === "web") {
      const blob = new Blob([json], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      setTimeout(() => URL.revokeObjectURL(url), 1000);
      setExportVisible(false);
    } else {
      try {
        const uri = (FileSystem.cacheDirectory ?? "") + filename;
        await FileSystem.writeAsStringAsync(uri, json, { encoding: FileSystem.EncodingType.UTF8 });
        const canShare = await Sharing.isAvailableAsync();
        if (canShare) {
          await Sharing.shareAsync(uri, { mimeType: "application/json", dialogTitle: "Dosyayı kaydet veya paylaş", UTI: "public.json" });
          setExportVisible(false);
        } else {
          Alert.alert("Hata", "Paylaşım bu cihazda desteklenmiyor.");
        }
      } catch (e: any) {
        Alert.alert("Hata", e?.message || "Dışa aktarma başarısız");
      }
    }
  }

  function pickFile() {
    if (Platform.OS !== "web") return;
    const input = document.createElement("input");
    input.type = "file";
    input.accept = "application/json,.json";
    input.style.cssText = "position:fixed;top:-9999px;left:-9999px;opacity:0;pointer-events:none;";
    document.body.appendChild(input);
    const cleanup = () => {
      if (document.body.contains(input)) document.body.removeChild(input);
    };
    input.onchange = () => {
      const file = input.files?.[0];
      cleanup();
      if (!file) return;
      const reader = new FileReader();
      reader.onload = () => {
        setImportText(String(reader.result || ""));
        setImportFileName(file.name);
        setImportMsg(null);
      };
      reader.onerror = () => Alert.alert("Hata", "Dosya okunamadı");
      reader.readAsText(file);
    };
    input.addEventListener("cancel", cleanup);
    input.click();
  }

  async function pickFileMobile() {
    try {
      const result = await DocumentPicker.getDocumentAsync({
        type: ["application/json", "text/plain", "*/*"],
        copyToCacheDirectory: true,
      });
      if (result.canceled) return;
      const asset = result.assets[0];
      const content = await FileSystem.readAsStringAsync(asset.uri, { encoding: FileSystem.EncodingType.UTF8 });
      setImportText(content);
      setImportFileName(asset.name);
      setImportMsg(null);
    } catch (e: any) {
      Alert.alert("Hata", e?.message || "Dosya okunamadı");
    }
  }

  function doImport() {
    if (!importText.trim()) {
      setImportMsg({ type: "err", text: "Önce bir dosya seçin veya JSON yapıştırın" });
      return;
    }
    const proceed = (confirmed: boolean) => {
      if (!confirmed) return;
      const result = importData(importText);
      if (result.ok) {
        const total = Object.values(result.counts).reduce((a, b) => a + b, 0);
        setImportMsg({ type: "ok", text: `Başarılı: ${total} kayıt yüklendi. Yeniden giriş yapmanız gerekecek.` });
        setImportText("");
        setImportFileName(null);
        setTimeout(() => { setImportVisible(false); setImportMsg(null); logout(); }, 1500);
      } else {
        setImportMsg({ type: "err", text: result.error });
      }
    };
    if (Platform.OS === "web") {
      const ok = window.confirm("Mevcut tüm veriler içe aktarılan dosyayla değiştirilecek. Devam edilsin mi?");
      proceed(ok);
    } else {
      Alert.alert("Verileri Değiştir", "Mevcut tüm veriler içe aktarılan dosyayla değiştirilecek. Devam edilsin mi?", [
        { text: "İptal", style: "cancel" },
        { text: "Devam Et", style: "destructive", onPress: () => proceed(true) },
      ]);
    }
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <View style={[styles.header, { backgroundColor: colors.secondary, paddingTop: topPad + 12 }]}>
        <TouchableOpacity
          onPress={() => (router.canGoBack() ? router.back() : router.replace("/ayarlar" as any))}
          style={styles.backBtn}
        >
          <Feather name="arrow-left" size={22} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.secondaryForeground }]}>
          {t("home.data.title")}
        </Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView contentContainerStyle={[styles.scroll, { paddingBottom: insets.bottom + 24 }]}>
        <Text style={[styles.desc, { color: colors.mutedForeground }]}>
          Tüm uygulama verilerini JSON formatında dışa aktarın veya önceden alınan yedeği geri yükleyin.
        </Text>

        <View style={styles.dataRow}>
          <TouchableOpacity
            style={[styles.dataBtn, { backgroundColor: colors.card, borderColor: colors.muted }]}
            onPress={openExport}
            activeOpacity={0.85}
          >
            <View style={[styles.dataIcon, { backgroundColor: "#dcfce7" }]}>
              <Feather name="download" size={20} color="#16a34a" />
            </View>
            <Text style={[styles.dataLabel, { color: colors.foreground }]}>{t("home.data.export")}</Text>
            <Text style={[styles.dataDesc, { color: colors.mutedForeground }]}>{t("home.data.export.sub")}</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.dataBtn, { backgroundColor: colors.card, borderColor: colors.muted }]}
            onPress={() => { setImportText(""); setImportMsg(null); setImportVisible(true); }}
            activeOpacity={0.85}
          >
            <View style={[styles.dataIcon, { backgroundColor: "#dbeafe" }]}>
              <Feather name="upload" size={20} color="#2563eb" />
            </View>
            <Text style={[styles.dataLabel, { color: colors.foreground }]}>{t("home.data.import")}</Text>
            <Text style={[styles.dataDesc, { color: colors.mutedForeground }]}>{t("home.data.import.sub")}</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>

      <BottomSheet visible={exportVisible} onClose={() => setExportVisible(false)} title={t("home.data.export")}>
        <Text style={[styles.sheetDesc, { color: colors.mutedForeground }]}>{t("home.data.export.desc")}</Text>
        <PrimaryButton
          label={Platform.OS === "web" ? t("home.data.download") : t("common.save")}
          onPress={downloadJson}
          style={{ marginTop: 12 }}
        />
        <PrimaryButton label={t("common.cancel")} variant="cancel" onPress={() => setExportVisible(false)} style={{ marginTop: 10 }} />
      </BottomSheet>

      <BottomSheet
        visible={importVisible}
        onClose={() => { setImportVisible(false); setImportText(""); setImportFileName(null); setImportMsg(null); }}
        title={t("home.data.import")}
      >
        <Text style={[styles.sheetDesc, { color: colors.mutedForeground }]}>{t("home.data.import.desc")}</Text>

        {Platform.OS === "web" ? (
          <>
            <PrimaryButton label={t("home.data.pickFile")} onPress={pickFile} style={{ marginBottom: 12 }} />
            <Text style={[styles.label, { color: colors.foreground }]}>{t("home.data.orPaste")}</Text>
            <TextInput
              value={importText}
              onChangeText={(tx) => { setImportText(tx); setImportFileName(null); setImportMsg(null); }}
              multiline
              placeholder='{"version":3,"data":{...}}'
              placeholderTextColor={colors.mutedForeground}
              style={[styles.importInput, { backgroundColor: colors.muted, color: colors.foreground, borderColor: colors.muted }]}
            />
          </>
        ) : (
          <TouchableOpacity
            style={[styles.filePickBtn, { backgroundColor: colors.muted, borderColor: importFileName ? "#16a34a" : colors.muted }]}
            onPress={pickFileMobile}
            activeOpacity={0.8}
          >
            <View style={[styles.filePickIcon, { backgroundColor: importFileName ? "#dcfce7" : "#dbeafe" }]}>
              <Feather name={importFileName ? "check-circle" : "folder"} size={22} color={importFileName ? "#16a34a" : "#2563eb"} />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={[styles.filePickLabel, { color: colors.foreground }]}>
                {importFileName ? importFileName : t("home.data.fileSelect")}
              </Text>
              <Text style={[styles.filePickSub, { color: colors.mutedForeground }]}>
                {importFileName ? t("home.data.fileSelected") : t("home.data.fileHelp")}
              </Text>
            </View>
            <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
          </TouchableOpacity>
        )}

        {importMsg ? (
          <View style={[styles.msgBox, { backgroundColor: importMsg.type === "ok" ? "#dcfce7" : "#fee2e2" }]}>
            <Feather
              name={importMsg.type === "ok" ? "check-circle" : "alert-circle"}
              size={14}
              color={importMsg.type === "ok" ? "#16a34a" : "#dc2626"}
            />
            <Text style={[styles.msgText, { color: importMsg.type === "ok" ? "#16a34a" : "#dc2626" }]}>{importMsg.text}</Text>
          </View>
        ) : null}

        <PrimaryButton label={t("home.data.doImport")} onPress={doImport} style={{ marginTop: 12 }} />
        <TouchableOpacity
          onPress={() => { setImportVisible(false); setImportText(""); setImportFileName(null); setImportMsg(null); }}
          style={styles.cancelBtn}
        >
          <Text style={[styles.cancelText, { color: colors.mutedForeground }]}>{t("common.close")}</Text>
        </TouchableOpacity>
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  header: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingBottom: 14,
    gap: 8,
  },
  backBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: "center",
    justifyContent: "center",
  },
  headerTitle: {
    flex: 1,
    fontSize: 18,
    fontWeight: "700",
    textAlign: "center",
    fontFamily: "Inter_700Bold",
  },
  scroll: { padding: 16, gap: 16 },
  desc: { fontSize: 13, fontFamily: "Inter_400Regular", lineHeight: 20 },
  dataRow: { flexDirection: "row", gap: 12 },
  dataBtn: {
    flex: 1,
    borderRadius: 14,
    padding: 16,
    alignItems: "center",
    gap: 8,
    borderWidth: 1,
  },
  dataIcon: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: "center",
    justifyContent: "center",
  },
  dataLabel: { fontSize: 13, fontFamily: "Inter_700Bold", textAlign: "center" },
  dataDesc: { fontSize: 11, fontFamily: "Inter_400Regular", textAlign: "center", lineHeight: 16 },
  sheetDesc: { fontSize: 13, fontFamily: "Inter_400Regular", lineHeight: 20, marginBottom: 4 },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  importInput: {
    borderRadius: 8,
    borderWidth: 1,
    padding: 12,
    minHeight: 120,
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    textAlignVertical: "top",
  },
  filePickBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    borderRadius: 12,
    padding: 14,
    borderWidth: 1.5,
  },
  filePickIcon: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: "center",
    justifyContent: "center",
  },
  filePickLabel: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
  filePickSub: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
  msgBox: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    padding: 10,
    borderRadius: 8,
    marginTop: 10,
  },
  msgText: { fontSize: 12, fontFamily: "Inter_500Medium", flex: 1 },
  cancelBtn: { alignItems: "center", paddingVertical: 14 },
  cancelText: { fontSize: 14, fontFamily: "Inter_500Medium" },
});
