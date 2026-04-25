import { Feather } from "@expo/vector-icons";
import * as DocumentPicker from "expo-document-picker";
import * as FileSystem from "expo-file-system/legacy";
import { useRouter } from "expo-router";
import * as Sharing from "expo-sharing";
import React, { useState } from "react";
import {
  ActivityIndicator,
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
import { PageKey, Permission, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

interface Section {
  key: PageKey;
  label: string;
  icon: string;
  route: string;
  color: string;
  bg: string;
  count: (a: ReturnType<typeof useApp>) => number;
}

const SECTIONS: Section[] = [
  { key: "proje",        label: "Proje",        icon: "briefcase",   route: "/proje",        color: "#e85d04", bg: "#fef3e2", count: (a) => a.projects.length },
  { key: "kesif",        label: "Keşif",         icon: "search",      route: "/kesif",        color: "#0ea5e9", bg: "#e0f2fe", count: (a) => a.surveys.length },
  { key: "is-programi",  label: "İş Programı",   icon: "calendar",    route: "/is-programi",  color: "#8b5cf6", bg: "#ede9fe", count: (a) => a.scheduleTasks.length },
  { key: "puantaj",      label: "Puantaj",       icon: "users",       route: "/puantaj",      color: "#16a34a", bg: "#dcfce7", count: (a) => a.attendance.length },
  { key: "gunluk-rapor", label: "Günlük Rapor",  icon: "file-text",   route: "/gunluk-rapor", color: "#0891b2", bg: "#cffafe", count: (a) => a.dailyReports.length },
  { key: "imalat",       label: "İmalat",        icon: "tool",        route: "/imalat",       color: "#d97706", bg: "#fef3c7", count: (a) => a.productions.length },
  { key: "gorev",        label: "Görev",         icon: "check-square",route: "/gorev",        color: "#dc2626", bg: "#fee2e2", count: (a) => a.tasks.length },
  { key: "malzeme",      label: "Malzeme",       icon: "package",     route: "/malzeme",      color: "#059669", bg: "#d1fae5", count: (a) => a.materials.length },
  { key: "taseron",      label: "Taşeron",       icon: "truck",       route: "/taseron",      color: "#7c3aed", bg: "#ede9fe", count: (a) => a.subcontractors.length },
  { key: "butce",        label: "Bütçe",         icon: "dollar-sign", route: "/butce",        color: "#16213e", bg: "#e0e7ff", count: (a) => a.budget.length },
  { key: "hakedis",      label: "Hakediş",       icon: "file-text",   route: "/hakedis",      color: "#be185d", bg: "#fce7f3", count: (a) => a.hakedisler.length },
  { key: "kullanicilar", label: "Kullanıcılar",  icon: "shield",      route: "/kullanicilar", color: "#7c3aed", bg: "#ede9fe", count: (a) => a.appUsers.length },
];

export default function HomeScreen() {
  const colors = useColors();
  const router = useRouter();
  const app = useApp();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 67 : insets.top;

  const { currentRole, currentAppUser, logout, exportData, importData, workspaceInfo, syncStatus, pushToCloud, pullFromCloud } = app;
  const isAdmin = currentRole?.isAdmin === true;

  const [exportVisible, setExportVisible] = useState(false);
  const [exportText, setExportText] = useState("");

  const [importVisible, setImportVisible] = useState(false);
  const [importText, setImportText] = useState("");
  const [importFileName, setImportFileName] = useState<string | null>(null);
  const [importMsg, setImportMsg] = useState<{ type: "ok" | "err"; text: string } | null>(null);

  function getPermission(key: PageKey): Permission {
    if (!currentRole) return "none";
    return currentRole.permissions[key] ?? "none";
  }

  const visibleSections = SECTIONS.filter(
    (s) => getPermission(s.key) !== "none"
  );

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
          await Sharing.shareAsync(uri, {
            mimeType: "application/json",
            dialogTitle: "Dosyayı kaydet veya paylaş",
            UTI: "public.json",
          });
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
    input.onchange = () => {
      const file = input.files?.[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onload = () => {
        setImportText(String(reader.result || ""));
        setImportFileName(file.name);
        setImportMsg(null);
      };
      reader.readAsText(file);
    };
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
      const content = await FileSystem.readAsStringAsync(asset.uri, {
        encoding: FileSystem.EncodingType.UTF8,
      });
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
        setTimeout(() => {
          setImportVisible(false);
          setImportMsg(null);
          logout();
        }, 1500);
      } else {
        setImportMsg({ type: "err", text: result.error });
      }
    };

    if (Platform.OS === "web") {
      const ok = window.confirm(
        "Mevcut tüm veriler içe aktarılan dosyayla değiştirilecek. Devam edilsin mi?"
      );
      proceed(ok);
    } else {
      Alert.alert(
        "Verileri Değiştir",
        "Mevcut tüm veriler içe aktarılan dosyayla değiştirilecek. Devam edilsin mi?",
        [
          { text: "İptal", style: "cancel" },
          { text: "Devam Et", style: "destructive", onPress: () => proceed(true) },
        ]
      );
    }
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <View
        style={[
          styles.hero,
          { backgroundColor: colors.secondary, paddingTop: topPad + 12 },
        ]}
      >
        <View style={styles.heroRow}>
          <View style={{ flex: 1 }}>
            <Text style={styles.heroSub}>Hoş Geldiniz</Text>
            <Text style={styles.heroTitle}>Şantiye Takip</Text>
            <Text style={styles.heroDesc}>
              {app.projects.length} aktif proje · {app.workers.length} personel
            </Text>
          </View>

          {currentAppUser ? (
            <View style={styles.userBadge}>
              <Text style={styles.userInitial}>
                {currentAppUser.name.charAt(0).toUpperCase()}
              </Text>
              <Text style={styles.userName} numberOfLines={1}>
                {currentAppUser.name}
              </Text>
              <Text style={styles.userRole} numberOfLines={1}>
                {currentRole?.name}
              </Text>
              <TouchableOpacity
                onPress={logout}
                style={styles.logoutBtn}
                hitSlop={8}
              >
                <Feather name="log-out" size={14} color="#94a3b8" />
                <Text style={styles.logoutText}>Çıkış</Text>
              </TouchableOpacity>
            </View>
          ) : null}
        </View>

        {/* Workspace sync bar */}
        {workspaceInfo && (
          <View style={styles.syncBar}>
            <View style={styles.syncLeft}>
              <Feather name="layers" size={12} color="#e85d04" />
              <Text style={styles.syncCode} numberOfLines={1}>
                {workspaceInfo.id === "local"
                  ? "Yerel Kullanım"
                  : workspaceInfo.company_name}
              </Text>
              {workspaceInfo.id !== "local" && (
                <View style={styles.codePill}>
                  <Text style={styles.codePillText}>{workspaceInfo.invite_code}</Text>
                </View>
              )}
            </View>
            {workspaceInfo.id !== "local" && (
              <View style={styles.syncBtns}>
                <TouchableOpacity
                  onPress={pullFromCloud}
                  disabled={syncStatus === "syncing"}
                  style={[styles.syncBtn, { opacity: syncStatus === "syncing" ? 0.5 : 1 }]}
                  hitSlop={6}
                >
                  {syncStatus === "syncing" ? (
                    <ActivityIndicator size={13} color="#0ea5e9" />
                  ) : (
                    <Feather
                      name="download-cloud"
                      size={14}
                      color={syncStatus === "error" ? "#dc2626" : syncStatus === "success" ? "#16a34a" : "#0ea5e9"}
                    />
                  )}
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={pushToCloud}
                  disabled={syncStatus === "syncing"}
                  style={[styles.syncBtn, { opacity: syncStatus === "syncing" ? 0.5 : 1 }]}
                  hitSlop={6}
                >
                  {syncStatus === "syncing" ? (
                    <ActivityIndicator size={13} color="#e85d04" />
                  ) : (
                    <Feather
                      name="upload-cloud"
                      size={14}
                      color={syncStatus === "error" ? "#dc2626" : syncStatus === "success" ? "#16a34a" : "#e85d04"}
                    />
                  )}
                </TouchableOpacity>
              </View>
            )}
          </View>
        )}

        {workspaceInfo && workspaceInfo.id !== "local" && syncStatus === "conflict" && (
          <View style={styles.conflictBar}>
            <Feather name="alert-triangle" size={13} color="#fbbf24" />
            <Text style={styles.conflictText} numberOfLines={2}>
              Başka biri değişiklik yaptı. Kendi yüklemenizden önce indirin.
            </Text>
          </View>
        )}
        {workspaceInfo && workspaceInfo.id !== "local" && syncStatus === "auth_error" && (
          <View style={styles.conflictBar}>
            <Feather name="lock" size={13} color="#fbbf24" />
            <Text style={styles.conflictText} numberOfLines={2}>
              Oturum süresi doldu. Lütfen tekrar giriş yapın.
            </Text>
          </View>
        )}
      </View>

      <ScrollView
        contentContainerStyle={[
          styles.scroll,
          { paddingBottom: insets.bottom + 24 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.grid}>
          {visibleSections.map((s) => {
            const perm = getPermission(s.key);
            return (
              <TouchableOpacity
                key={s.key}
                style={[styles.tile, { backgroundColor: colors.card }]}
                onPress={() => router.push(s.route as any)}
                activeOpacity={0.85}
              >
                <View style={[styles.tileIcon, { backgroundColor: s.bg }]}>
                  <Feather name={s.icon as any} size={28} color={s.color} />
                </View>
                <Text
                  style={[styles.tileLabel, { color: colors.foreground }]}
                  numberOfLines={1}
                >
                  {s.label}
                </Text>
                <View style={styles.tileBottom}>
                  <Text
                    style={[styles.tileCount, { color: colors.mutedForeground }]}
                  >
                    {s.count(app)} kayıt
                  </Text>
                  {perm === "view" ? (
                    <View style={styles.viewBadge}>
                      <Feather name="eye" size={10} color="#0ea5e9" />
                      <Text style={styles.viewBadgeText}>Salt okunur</Text>
                    </View>
                  ) : null}
                </View>
              </TouchableOpacity>
            );
          })}
        </View>

        <TouchableOpacity
          style={[styles.raporBtn, { backgroundColor: colors.card, borderColor: colors.primary + "40" }]}
          onPress={() => router.push("/rapor" as any)}
          activeOpacity={0.85}
        >
          <View style={[styles.raporIcon, { backgroundColor: colors.primary + "20" }]}>
            <Feather name="bar-chart-2" size={20} color={colors.primary} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={[styles.raporTitle, { color: colors.foreground }]}>Rapor Oluştur</Text>
            <Text style={[styles.raporSub, { color: colors.mutedForeground }]}>PDF veya Excel formatında dışa aktar</Text>
          </View>
          <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
        </TouchableOpacity>

        {isAdmin ? (
          <>
            <Text style={[styles.sectionLabel, { color: colors.foreground, marginTop: 24 }]}>
              Veri Yönetimi
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
                <Text style={[styles.dataLabel, { color: colors.foreground }]}>
                  Verileri Dışa Aktar
                </Text>
                <Text style={[styles.dataDesc, { color: colors.mutedForeground }]}>
                  Tüm kayıtları JSON dosyası olarak kaydet
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.dataBtn, { backgroundColor: colors.card, borderColor: colors.muted }]}
                onPress={() => { setImportText(""); setImportMsg(null); setImportVisible(true); }}
                activeOpacity={0.85}
              >
                <View style={[styles.dataIcon, { backgroundColor: "#dbeafe" }]}>
                  <Feather name="upload" size={20} color="#2563eb" />
                </View>
                <Text style={[styles.dataLabel, { color: colors.foreground }]}>
                  Verileri İçe Aktar
                </Text>
                <Text style={[styles.dataDesc, { color: colors.mutedForeground }]}>
                  JSON yedeğinden geri yükle
                </Text>
              </TouchableOpacity>
            </View>
          </>
        ) : null}
      </ScrollView>

      <BottomSheet
        visible={exportVisible}
        onClose={() => setExportVisible(false)}
        title="Verileri Dışa Aktar"
      >
        <Text style={[styles.sheetDesc, { color: colors.mutedForeground }]}>
          Tüm projeler, personel, kayıtlar ve roller dahil tüm uygulama verisi.
        </Text>
        <PrimaryButton
          label={Platform.OS === "web" ? "Dosyayı İndir" : "Kaydet"}
          onPress={downloadJson}
          style={{ marginTop: 12 }}
        />
        <PrimaryButton
          label="İptal"
          variant="danger"
          onPress={() => setExportVisible(false)}
          style={{ marginTop: 10 }}
        />
      </BottomSheet>

      <BottomSheet
        visible={importVisible}
        onClose={() => { setImportVisible(false); setImportText(""); setImportFileName(null); setImportMsg(null); }}
        title="Verileri İçe Aktar"
      >
        <Text style={[styles.sheetDesc, { color: colors.mutedForeground }]}>
          Mevcut tüm veriler içe aktarılan dosyayla değiştirilecek. Önce yedek almanız önerilir.
        </Text>

        {Platform.OS === "web" ? (
          <>
            <PrimaryButton
              label="JSON Dosyası Seç"
              onPress={pickFile}
              style={{ marginBottom: 12 }}
            />
            <Text style={[styles.label, { color: colors.foreground }]}>
              Veya JSON'u yapıştırın:
            </Text>
            <TextInput
              value={importText}
              onChangeText={(t) => { setImportText(t); setImportFileName(null); setImportMsg(null); }}
              multiline
              placeholder='{"version":3,"data":{...}}'
              placeholderTextColor={colors.mutedForeground}
              style={[
                styles.importInput,
                { backgroundColor: colors.muted, color: colors.foreground, borderColor: colors.muted },
              ]}
            />
          </>
        ) : (
          <>
            <TouchableOpacity
              style={[styles.filePickBtn, { backgroundColor: colors.muted, borderColor: importFileName ? "#16a34a" : colors.muted }]}
              onPress={pickFileMobile}
              activeOpacity={0.8}
            >
              <View style={[styles.filePickIcon, { backgroundColor: importFileName ? "#dcfce7" : "#dbeafe" }]}>
                <Feather
                  name={importFileName ? "check-circle" : "folder"}
                  size={22}
                  color={importFileName ? "#16a34a" : "#2563eb"}
                />
              </View>
              <View style={{ flex: 1 }}>
                <Text style={[styles.filePickLabel, { color: colors.foreground }]}>
                  {importFileName ? importFileName : "Dosya Seç"}
                </Text>
                <Text style={[styles.filePickSub, { color: colors.mutedForeground }]}>
                  {importFileName ? "Dosyalar uygulamasından seçildi" : "Dosyalar uygulamasından JSON seç"}
                </Text>
              </View>
              <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
            </TouchableOpacity>
          </>
        )}

        {importMsg ? (
          <View
            style={[
              styles.msgBox,
              { backgroundColor: importMsg.type === "ok" ? "#dcfce7" : "#fee2e2" },
            ]}
          >
            <Feather
              name={importMsg.type === "ok" ? "check-circle" : "alert-circle"}
              size={14}
              color={importMsg.type === "ok" ? "#16a34a" : "#dc2626"}
            />
            <Text
              style={[
                styles.msgText,
                { color: importMsg.type === "ok" ? "#16a34a" : "#dc2626" },
              ]}
            >
              {importMsg.text}
            </Text>
          </View>
        ) : null}

        <PrimaryButton
          label="İçe Aktar"
          onPress={doImport}
          style={{ marginTop: 12 }}
        />
        <TouchableOpacity
          onPress={() => { setImportVisible(false); setImportText(""); setImportFileName(null); setImportMsg(null); }}
          style={styles.cancelBtn}
        >
          <Text style={[styles.cancelText, { color: colors.mutedForeground }]}>Kapat</Text>
        </TouchableOpacity>
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  hero: {
    paddingHorizontal: 20,
    paddingBottom: 24,
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
  },
  heroRow: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 12,
  },
  heroSub: {
    color: "#cbd5e1",
    fontSize: 14,
    fontFamily: "Inter_400Regular",
  },
  heroTitle: {
    color: "#fff",
    fontSize: 24,
    fontFamily: "Inter_700Bold",
    marginTop: 2,
  },
  heroDesc: {
    color: "#94a3b8",
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    marginTop: 4,
  },
  userBadge: {
    alignItems: "center",
    minWidth: 80,
  },
  userInitial: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "#e85d0422",
    color: "#e85d04",
    fontSize: 18,
    fontFamily: "Inter_700Bold",
    textAlign: "center",
    lineHeight: 40,
    overflow: "hidden",
  },
  userName: {
    color: "#f1f5f9",
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
    marginTop: 4,
    maxWidth: 80,
  },
  userRole: {
    color: "#94a3b8",
    fontSize: 10,
    fontFamily: "Inter_400Regular",
    maxWidth: 80,
  },
  logoutBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 3,
    marginTop: 6,
  },
  logoutText: {
    color: "#94a3b8",
    fontSize: 11,
    fontFamily: "Inter_500Medium",
  },
  syncBar: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginTop: 10,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.08)",
  },
  conflictBar: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    marginTop: 8,
    paddingHorizontal: 10,
    paddingVertical: 8,
    borderRadius: 8,
    backgroundColor: "rgba(251,191,36,0.15)",
    borderWidth: 1,
    borderColor: "rgba(251,191,36,0.4)",
  },
  conflictText: {
    color: "#fef3c7",
    fontSize: 11,
    fontFamily: "Inter_500Medium",
    flex: 1,
  },
  syncLeft: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    flex: 1,
  },
  syncCode: {
    color: "#cbd5e1",
    fontSize: 11,
    fontFamily: "Inter_500Medium",
    flex: 1,
  },
  codePill: {
    backgroundColor: "rgba(232,93,4,0.18)",
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  codePillText: {
    color: "#e85d04",
    fontSize: 10,
    fontFamily: "Inter_700Bold",
    letterSpacing: 1,
  },
  syncBtns: {
    flexDirection: "row",
    gap: 10,
    marginLeft: 10,
  },
  syncBtn: {
    width: 28,
    height: 28,
    borderRadius: 8,
    backgroundColor: "rgba(255,255,255,0.07)",
    justifyContent: "center",
    alignItems: "center",
  },
  scroll: { padding: 16 },
  sectionLabel: {
    fontSize: 16,
    fontFamily: "Inter_700Bold",
    marginBottom: 12,
    marginLeft: 4,
  },
  grid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 12,
  },
  tile: {
    width: "47.5%",
    paddingVertical: 18,
    paddingHorizontal: 16,
    borderRadius: 14,
    gap: 8,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 2,
  },
  tileIcon: {
    width: 50,
    height: 50,
    borderRadius: 25,
    justifyContent: "center",
    alignItems: "center",
  },
  tileLabel: {
    fontSize: 15,
    fontFamily: "Inter_600SemiBold",
  },
  tileBottom: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    flexWrap: "wrap",
  },
  tileCount: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
  },
  viewBadge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 3,
    backgroundColor: "#e0f2fe",
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 999,
  },
  viewBadgeText: {
    fontSize: 9,
    fontFamily: "Inter_600SemiBold",
    color: "#0ea5e9",
  },
  raporBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    padding: 14,
    borderRadius: 14,
    borderWidth: 1.5,
    marginTop: 16,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  raporIcon: { width: 42, height: 42, borderRadius: 10, alignItems: "center", justifyContent: "center" },
  raporTitle: { fontSize: 15, fontFamily: "Inter_700Bold" },
  raporSub: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
  dataRow: {
    flexDirection: "row",
    gap: 12,
  },
  dataBtn: {
    flex: 1,
    padding: 14,
    borderRadius: 14,
    borderWidth: 1,
    gap: 8,
  },
  dataIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: "center",
    alignItems: "center",
  },
  dataLabel: {
    fontSize: 14,
    fontFamily: "Inter_600SemiBold",
  },
  dataDesc: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    lineHeight: 15,
  },
  sheetDesc: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    marginBottom: 12,
    lineHeight: 18,
  },
  jsonBox: {
    borderRadius: 8,
    padding: 10,
    marginBottom: 4,
  },
  jsonText: {
    fontSize: 11,
    fontFamily: Platform.OS === "ios" ? "Menlo" : "monospace",
  },
  label: {
    fontSize: 13,
    fontFamily: "Inter_600SemiBold",
    marginBottom: 6,
  },
  importInput: {
    minHeight: 120,
    maxHeight: 180,
    borderRadius: 8,
    padding: 10,
    fontSize: 12,
    fontFamily: Platform.OS === "ios" ? "Menlo" : "monospace",
    textAlignVertical: "top",
    borderWidth: 1,
  },
  msgBox: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    padding: 10,
    borderRadius: 8,
    marginTop: 10,
  },
  msgText: {
    flex: 1,
    fontSize: 12,
    fontFamily: "Inter_500Medium",
  },
  cancelBtn: {
    alignItems: "center",
    paddingVertical: 12,
    marginTop: 4,
  },
  cancelText: {
    fontSize: 13,
    fontFamily: "Inter_500Medium",
  },
  filePickBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    padding: 14,
    borderRadius: 12,
    borderWidth: 1.5,
    marginBottom: 4,
  },
  filePickIcon: {
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: "center",
    alignItems: "center",
  },
  filePickLabel: {
    fontSize: 14,
    fontFamily: "Inter_600SemiBold",
  },
  filePickSub: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    marginTop: 2,
  },
});
