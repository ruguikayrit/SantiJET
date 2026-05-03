import AsyncStorage from "@react-native-async-storage/async-storage";
import { Feather } from "@expo/vector-icons";
import * as DocumentPicker from "expo-document-picker";
import * as FileSystem from "expo-file-system/legacy";
import { useRouter } from "expo-router";
import * as Sharing from "expo-sharing";
import React, { useEffect, useMemo, useState } from "react";
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
import SmartSearch from "@/components/SmartSearch";
import { PageKey, Permission, useApp } from "@/context/AppContext";
import { useI18n } from "@/context/I18nContext";
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
  { key: "satin-alma",   label: "Satın Alma",    icon: "shopping-cart", route: "/satin-alma", color: "#ea580c", bg: "#ffedd5", count: (a) => a.purchases.length },
  { key: "kantar",       label: "Kantar",        icon: "truck",       route: "/kantar",       color: "#0d9488", bg: "#ccfbf1", count: (a) => a.weighbridges.length },
  { key: "butce",        label: "Bütçe",         icon: "dollar-sign", route: "/butce",        color: "#16213e", bg: "#e0e7ff", count: (a) => a.budget.length },
  { key: "hakedis",      label: "Hakediş",       icon: "file-text",   route: "/hakedis",      color: "#be185d", bg: "#fce7f3", count: (a) => a.hakedisler.length },
  { key: "ilerleme",     label: "İlerleme",      icon: "trending-up", route: "/ilerleme",     color: "#0d9488", bg: "#ccfbf1", count: (a) => a.surveys.length + a.productions.length },
  { key: "finans",       label: "Finans",        icon: "credit-card", route: "/finans",       color: "#00C896", bg: "#d1fae5", count: () => 0 },
  { key: "kullanicilar", label: "Kullanıcılar",  icon: "shield",      route: "/kullanicilar", color: "#7c3aed", bg: "#ede9fe", count: (a) => a.appUsers.length },
];

export default function HomeScreen() {
  const colors = useColors();
  const router = useRouter();
  const app = useApp();
  const { t } = useI18n();
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

  // ---- Modül sıralama (cihaza özel) ----
  const ORDER_KEY = "santiye-tile-order-v1";
  const [tileOrder, setTileOrder] = useState<string[]>([]);
  const [reorderMode, setReorderMode] = useState(false);
  const [orderLoaded, setOrderLoaded] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(ORDER_KEY)
      .then((raw) => {
        if (raw) {
          try {
            const arr = JSON.parse(raw);
            if (Array.isArray(arr)) setTileOrder(arr.filter((x) => typeof x === "string"));
          } catch {
            // ignore
          }
        }
      })
      .finally(() => setOrderLoaded(true));
  }, []);

  useEffect(() => {
    if (!orderLoaded) return;
    AsyncStorage.setItem(ORDER_KEY, JSON.stringify(tileOrder)).catch(() => {});
  }, [tileOrder, orderLoaded]);

  const orderedSections = useMemo(() => {
    const allowed = SECTIONS.filter((s) => getPermission(s.key) !== "none");
    const byKey = new Map(allowed.map((s) => [s.key as string, s]));
    const result: typeof allowed = [];
    for (const k of tileOrder) {
      const s = byKey.get(k);
      if (s) {
        result.push(s);
        byKey.delete(k);
      }
    }
    // Listede olmayan (yeni eklenmiş) modüller sona eklenir
    for (const s of allowed) {
      if (byKey.has(s.key as string)) result.push(s);
    }
    return result;
  }, [tileOrder, currentRole]);

  function moveSection(key: string, dir: -1 | 1) {
    const keys = orderedSections.map((s) => s.key as string);
    const i = keys.indexOf(key);
    if (i < 0) return;
    const j = i + dir;
    if (j < 0 || j >= keys.length) return;
    const tmp = keys[i];
    keys[i] = keys[j];
    keys[j] = tmp;
    setTileOrder(keys);
  }

  const visibleSections = orderedSections;

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
            <Text style={styles.heroSub}>{t("home.welcome")}</Text>
            <Text style={styles.heroTitle}>{t("app.title")}</Text>
            <Text style={styles.heroDesc}>
              {app.projects.length} {t("home.stats.activeProjects")} · {app.workers.length} {t("home.stats.workers")}
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
                <Text style={styles.logoutText}>{t("home.logout")}</Text>
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
                  ? t("home.workspace.local")
                  : workspaceInfo.company_name}
              </Text>
              {workspaceInfo.id !== "local" && (
                <View style={styles.codePill}>
                  <Text style={styles.codePillText}>{workspaceInfo.invite_code}</Text>
                </View>
              )}
            </View>
            {workspaceInfo.id !== "local" ? (
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
            ) : (
              <TouchableOpacity
                onPress={() => router.push("/workspace-setup" as any)}
                style={styles.switchWsBtn}
                hitSlop={6}
                activeOpacity={0.85}
              >
                <Feather name="log-in" size={12} color="#e85d04" />
                <Text style={styles.switchWsText}>{t("home.workspace.connect")}</Text>
              </TouchableOpacity>
            )}
          </View>
        )}

        {workspaceInfo && workspaceInfo.id !== "local" && syncStatus === "conflict" && (
          <View style={styles.conflictBar}>
            <Feather name="alert-triangle" size={13} color="#fbbf24" />
            <Text style={styles.conflictText} numberOfLines={2}>
              {t("home.workspace.conflict")}
            </Text>
          </View>
        )}
        {workspaceInfo && workspaceInfo.id !== "local" && syncStatus === "auth_error" && (
          <View style={styles.conflictBar}>
            <Feather name="lock" size={13} color="#fbbf24" />
            <Text style={styles.conflictText} numberOfLines={2}>
              {t("home.workspace.authError")}
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
        keyboardShouldPersistTaps="handled"
      >
        <SmartSearch topInset={insets.bottom} />

        {reorderMode ? (
          <View style={[styles.reorderBar, { backgroundColor: colors.primary + "15", borderColor: colors.primary }]}>
            <Feather name="move" size={14} color={colors.primary} />
            <Text style={[styles.reorderText, { color: colors.primary }]} numberOfLines={2}>
              Sıralama modu — okları kullanarak modülleri taşıyın
            </Text>
            <TouchableOpacity
              onPress={() => setReorderMode(false)}
              style={[styles.reorderDone, { backgroundColor: colors.primary }]}
              hitSlop={6}
            >
              <Feather name="check" size={14} color="#fff" />
              <Text style={styles.reorderDoneText}>Bitti</Text>
            </TouchableOpacity>
          </View>
        ) : null}

        <View style={styles.grid}>
          {visibleSections.map((s, idx) => {
            const perm = getPermission(s.key);
            const isFirst = idx === 0;
            const isLast = idx === visibleSections.length - 1;
            return (
              <TouchableOpacity
                key={s.key}
                style={[
                  styles.tile,
                  {
                    backgroundColor: colors.card,
                    borderWidth: reorderMode ? 1.5 : 0,
                    borderColor: reorderMode ? colors.primary : "transparent",
                  },
                ]}
                onPress={() => {
                  if (reorderMode) return;
                  router.push(s.route as any);
                }}
                onLongPress={() => setReorderMode(true)}
                delayLongPress={350}
                activeOpacity={reorderMode ? 1 : 0.85}
              >
                <View style={[styles.tileIcon, { backgroundColor: s.bg }]}>
                  <Feather name={s.icon as any} size={28} color={s.color} />
                </View>
                <Text
                  style={[styles.tileLabel, { color: colors.foreground }]}
                  numberOfLines={1}
                >
                  {t(`menu.${s.key}`)}
                </Text>
                {reorderMode ? (
                  <View style={styles.reorderArrows}>
                    <TouchableOpacity
                      onPress={() => moveSection(s.key as string, -1)}
                      disabled={isFirst}
                      style={[
                        styles.arrowBtn,
                        { backgroundColor: isFirst ? colors.muted : colors.primary + "20", opacity: isFirst ? 0.4 : 1 },
                      ]}
                      hitSlop={8}
                    >
                      <Feather name="arrow-left" size={16} color={colors.primary} />
                    </TouchableOpacity>
                    <Text style={[styles.posText, { color: colors.mutedForeground }]}>
                      {idx + 1}/{visibleSections.length}
                    </Text>
                    <TouchableOpacity
                      onPress={() => moveSection(s.key as string, 1)}
                      disabled={isLast}
                      style={[
                        styles.arrowBtn,
                        { backgroundColor: isLast ? colors.muted : colors.primary + "20", opacity: isLast ? 0.4 : 1 },
                      ]}
                      hitSlop={8}
                    >
                      <Feather name="arrow-right" size={16} color={colors.primary} />
                    </TouchableOpacity>
                  </View>
                ) : (
                  <View style={styles.tileBottom}>
                    <Text
                      style={[styles.tileCount, { color: colors.mutedForeground }]}
                    >
                      {s.count(app)}
                    </Text>
                    {perm === "view" ? (
                      <View style={styles.viewBadge}>
                        <Feather name="eye" size={10} color="#0ea5e9" />
                        <Text style={styles.viewBadgeText}>{t("home.tile.readonly")}</Text>
                      </View>
                    ) : null}
                  </View>
                )}
              </TouchableOpacity>
            );
          })}
        </View>

        <TouchableOpacity
          style={[styles.raporBtn, { backgroundColor: colors.card, borderColor: colors.primary + "60", borderWidth: 1.5 }]}
          onPress={() => router.push("/asistan" as any)}
          activeOpacity={0.85}
        >
          <View style={[styles.raporIcon, { backgroundColor: colors.primary }]}>
            <Feather name="cpu" size={20} color={colors.primaryForeground} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={[styles.raporTitle, { color: colors.foreground }]}>{t("home.assistant.title")}</Text>
            <Text style={[styles.raporSub, { color: colors.mutedForeground }]}>{t("home.assistant.sub")}</Text>
          </View>
          <View style={[styles.aiPill, { backgroundColor: colors.primary + "20" }]}>
            <Text style={[styles.aiPillText, { color: colors.primary }]}>{t("home.assistant.new")}</Text>
          </View>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.raporBtn, { backgroundColor: colors.card, borderColor: colors.primary + "40", marginTop: 10 }]}
          onPress={() => router.push("/rapor" as any)}
          activeOpacity={0.85}
        >
          <View style={[styles.raporIcon, { backgroundColor: colors.primary + "20" }]}>
            <Feather name="bar-chart-2" size={20} color={colors.primary} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={[styles.raporTitle, { color: colors.foreground }]}>{t("home.report.title")}</Text>
            <Text style={[styles.raporSub, { color: colors.mutedForeground }]}>{t("home.report.sub")}</Text>
          </View>
          <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.raporBtn, { backgroundColor: colors.card, borderColor: colors.secondary + "40", marginTop: 10 }]}
          onPress={() => router.push("/ayarlar" as any)}
          activeOpacity={0.85}
        >
          <View style={[styles.raporIcon, { backgroundColor: colors.secondary + "20" }]}>
            <Feather name="settings" size={20} color={colors.secondary} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={[styles.raporTitle, { color: colors.foreground }]}>{t("settings.title")}</Text>
            <Text style={[styles.raporSub, { color: colors.mutedForeground }]}>{t("settings.sub")}</Text>
          </View>
          <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
        </TouchableOpacity>

        {isAdmin ? (
          <>
            <Text style={[styles.sectionLabel, { color: colors.foreground, marginTop: 24 }]}>
              {t("home.data.title")}
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
                  {t("home.data.export")}
                </Text>
                <Text style={[styles.dataDesc, { color: colors.mutedForeground }]}>
                  {t("home.data.export.sub")}
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
                  {t("home.data.import")}
                </Text>
                <Text style={[styles.dataDesc, { color: colors.mutedForeground }]}>
                  {t("home.data.import.sub")}
                </Text>
              </TouchableOpacity>
            </View>
          </>
        ) : null}
      </ScrollView>

      <BottomSheet
        visible={exportVisible}
        onClose={() => setExportVisible(false)}
        title={t("home.data.export")}
      >
        <Text style={[styles.sheetDesc, { color: colors.mutedForeground }]}>
          {t("home.data.export.desc")}
        </Text>
        <PrimaryButton
          label={Platform.OS === "web" ? t("home.data.download") : t("common.save")}
          onPress={downloadJson}
          style={{ marginTop: 12 }}
        />
        <PrimaryButton
          label={t("common.cancel")}
          variant="cancel"
          onPress={() => setExportVisible(false)}
          style={{ marginTop: 10 }}
        />
      </BottomSheet>

      <BottomSheet
        visible={importVisible}
        onClose={() => { setImportVisible(false); setImportText(""); setImportFileName(null); setImportMsg(null); }}
        title={t("home.data.import")}
      >
        <Text style={[styles.sheetDesc, { color: colors.mutedForeground }]}>
          {t("home.data.import.desc")}
        </Text>

        {Platform.OS === "web" ? (
          <>
            <PrimaryButton
              label={t("home.data.pickFile")}
              onPress={pickFile}
              style={{ marginBottom: 12 }}
            />
            <Text style={[styles.label, { color: colors.foreground }]}>
              {t("home.data.orPaste")}
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
                  {importFileName ? importFileName : t("home.data.fileSelect")}
                </Text>
                <Text style={[styles.filePickSub, { color: colors.mutedForeground }]}>
                  {importFileName ? t("home.data.fileSelected") : t("home.data.fileHelp")}
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
          label={t("home.data.doImport")}
          onPress={doImport}
          style={{ marginTop: 12 }}
        />
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
  switchWsBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginLeft: 10,
    backgroundColor: "rgba(232,93,4,0.15)",
    borderColor: "#e85d04",
    borderWidth: 1,
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  switchWsText: {
    color: "#e85d04",
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
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
  reorderBar: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingVertical: 10,
    paddingHorizontal: 12,
    borderRadius: 10,
    borderWidth: 1,
    marginHorizontal: 16,
    marginBottom: 10,
  },
  reorderText: { flex: 1, fontSize: 12, fontFamily: "Inter_500Medium" },
  reorderDone: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
  },
  reorderDoneText: { color: "#fff", fontSize: 12, fontFamily: "Inter_600SemiBold" },
  reorderArrows: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginTop: 8,
    gap: 4,
  },
  arrowBtn: {
    width: 30,
    height: 30,
    borderRadius: 15,
    justifyContent: "center",
    alignItems: "center",
  },
  posText: { fontSize: 11, fontFamily: "Inter_600SemiBold" },
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
  aiPill: { paddingHorizontal: 8, paddingVertical: 3, borderRadius: 999 },
  aiPillText: { fontSize: 10, fontWeight: "800", letterSpacing: 0.5, fontFamily: "Inter_700Bold" },
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
