import AsyncStorage from "@react-native-async-storage/async-storage";
import { Feather } from "@expo/vector-icons";
import * as DocumentPicker from "expo-document-picker";
import * as FileSystem from "expo-file-system/legacy";
import { useRouter } from "expo-router";
import * as Sharing from "expo-sharing";
import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Animated, {
  runOnJS,
  SharedValue,
  useAnimatedReaction,
  useAnimatedStyle,
  useSharedValue,
  withSpring,
} from "react-native-reanimated";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import BottomSheet from "@/components/BottomSheet";
import PrimaryButton from "@/components/PrimaryButton";
import { SantijetLogo } from "@/components/SantijetLogo";
import SmartSearch from "@/components/SmartSearch";
import { PageKey, Permission, useApp } from "@/context/AppContext";
import { useI18n } from "@/context/I18nContext";
import { useTheme } from "@/context/ThemeContext";
import { useColors } from "@/hooks/useColors";

interface Section {
  key: PageKey;
  label: string;
  icon: string;
  route: string;
  color: string;
  bg: string;
  code: string;
  sub: string;
  count: (a: ReturnType<typeof useApp>) => number;
}

const SECTIONS: Section[] = [
  { key: "proje",        label: "Proje",        icon: "briefcase",   route: "/proje",        color: "#e85d04", bg: "#fef3e2", code: "PR-01", sub: "Aktif şantiye", count: (a) => a.projects.length },
  { key: "dosyalar",     label: "Dosyalar",     icon: "folder",      route: "/dosyalar",     color: "#475569", bg: "#e2e8f0", code: "DS-02", sub: "Arşiv", count: (a) => a.archiveFiles.length },
  { key: "kesif",        label: "Keşif",         icon: "search",      route: "/kesif",        color: "#0ea5e9", bg: "#e0f2fe", code: "KS-03", sub: "Bina", count: (a) => a.surveys.length },
  { key: "is-programi",  label: "İş Programı",   icon: "calendar",    route: "/is-programi",  color: "#8b5cf6", bg: "#ede9fe", code: "IP-04", sub: "Görev", count: (a) => a.scheduleTasks.length },
  { key: "puantaj",      label: "Puantaj",       icon: "users",       route: "/puantaj",      color: "#16a34a", bg: "#dcfce7", code: "PU-05", sub: "Personel", count: (a) => a.attendance.length },
  { key: "gunluk-rapor", label: "Günlük Rapor",  icon: "file-text",   route: "/gunluk-rapor", color: "#0891b2", bg: "#cffafe", code: "GR-06", sub: "Rapor", count: (a) => a.dailyReports.length },
  { key: "imalat",       label: "İmalat",        icon: "tool",        route: "/imalat",       color: "#d97706", bg: "#fef3c7", code: "IM-07", sub: "Aktif kayıt", count: (a) => a.productions.length },
  { key: "gorev",        label: "Görev",         icon: "check-square",route: "/gorev",        color: "#dc2626", bg: "#fee2e2", code: "GV-08", sub: "Bekleyen", count: (a) => a.tasks.length },
  { key: "malzeme",      label: "Malzeme",       icon: "package",     route: "/malzeme",      color: "#059669", bg: "#d1fae5", code: "MZ-09", sub: "Stok hareketi", count: (a) => a.materials.length },
  { key: "taseron",      label: "Taşeron",       icon: "truck",       route: "/taseron",      color: "#7c3aed", bg: "#ede9fe", code: "TS-10", sub: "Firma", count: (a) => a.subcontractors.length },
  { key: "satin-alma",   label: "Satın Alma",    icon: "shopping-cart", route: "/satin-alma", color: "#ea580c", bg: "#ffedd5", code: "SA-11", sub: "Bekleyen", count: (a) => a.purchases.length },
  { key: "kantar",       label: "Kantar",        icon: "truck",       route: "/kantar",       color: "#0d9488", bg: "#ccfbf1", code: "KN-12", sub: "Tartım", count: (a) => a.weighbridges.length },
  { key: "butce",        label: "Bütçe",         icon: "dollar-sign", route: "/butce",        color: "#16213e", bg: "#e0e7ff", code: "BT-13", sub: "Kalem", count: (a) => a.budget.length },
  { key: "hakedis",      label: "Hakediş",       icon: "file-text",   route: "/hakedis",      color: "#be185d", bg: "#fce7f3", code: "HK-14", sub: "Dönem", count: (a) => a.hakedisler.length },
  { key: "ilerleme",     label: "İlerleme",      icon: "trending-up", route: "/ilerleme",     color: "#0d9488", bg: "#ccfbf1", code: "IL-15", sub: "Kayıt", count: (a) => a.surveys.length + a.productions.length },
  { key: "kullanicilar", label: "Kullanıcılar",  icon: "shield",      route: "/kullanicilar", color: "#7c3aed", bg: "#ede9fe", code: "KU-17", sub: "Kişi", count: (a) => a.appUsers.length },
];

const HIVIS_YELLOW = "#facc15";
const HIVIS_BG = "#fef3c7";
const HIVIS_BLACK = "#1c1917";

// ---- Kart renk özelleştirme ----
const TILE_COLORS_KEY = "santiye-tile-colors-v1";

type TileColorMode = "accent" | "fill";
interface TileColorConfig {
  mode: TileColorMode;
  color: string;
}

const SOFT_COLORS = [
  // Sıcak
  "#f87171", "#fb923c", "#fbbf24", "#a3e635", "#4ade80",
  // Serin
  "#34d399", "#22d3ee", "#38bdf8", "#60a5fa", "#818cf8",
  // Pembe / Mor
  "#a78bfa", "#c084fc", "#e879f9", "#f472b6", "#fb7185",
  // Nötr / Toprak
  "#94a3b8", "#78716c", "#6b7280", "#a8a29e", "#64748b",
];

function hexToRgb(hex: string) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return { r, g, b };
}
function fillBg(hex: string) {
  const { r, g, b } = hexToRgb(hex);
  return `rgba(${r},${g},${b},0.13)`;
}
function fillBorder(hex: string) {
  const { r, g, b } = hexToRgb(hex);
  return `rgba(${r},${g},${b},0.35)`;
}

function HazardStripe({ height = 8, segments = 28 }: { height?: number; segments?: number }) {
  return (
    <View style={{ height, backgroundColor: HIVIS_YELLOW, overflow: "hidden", flexDirection: "row" }}>
      {Array.from({ length: segments }).map((_, i) => (
        <View
          key={i}
          style={{
            width: 14,
            height: height * 3,
            marginTop: -height,
            backgroundColor: i % 2 === 0 ? HIVIS_BLACK : "transparent",
            transform: [{ skewX: "-30deg" }],
            marginLeft: -3,
          }}
        />
      ))}
    </View>
  );
}

export default function HomeScreen() {
  const colors = useColors();
  const { themeId } = useTheme();
  const isHiVis = themeId === "hivis";
  const isSteel = themeId === "steel";
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

  // ---- Kart renk özelleştirme ----
  const [tileColors, setTileColors] = useState<Record<string, TileColorConfig>>({});
  const [colorsLoaded, setColorsLoaded] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(TILE_COLORS_KEY)
      .then((raw) => {
        if (raw) {
          try {
            const obj = JSON.parse(raw);
            if (obj && typeof obj === "object") setTileColors(obj);
          } catch {
            // ignore
          }
        }
      })
      .finally(() => setColorsLoaded(true));
  }, []);

  useEffect(() => {
    if (!colorsLoaded) return;
    AsyncStorage.setItem(TILE_COLORS_KEY, JSON.stringify(tileColors)).catch(() => {});
  }, [tileColors, colorsLoaded]);

  // ---- Renk seçici modal ----
  const [cpKey, setCpKey] = useState<string | null>(null);
  const [cpMode, setCpMode] = useState<TileColorMode>("accent");
  const [cpColor, setCpColor] = useState<string>(SOFT_COLORS[0]);

  function openColorPicker(key: string) {
    const existing = tileColors[key];
    setCpMode(existing?.mode ?? "accent");
    setCpColor(existing?.color ?? SOFT_COLORS[0]);
    setCpKey(key);
  }

  function applyColor() {
    if (!cpKey) return;
    setTileColors((prev) => ({ ...prev, [cpKey]: { mode: cpMode, color: cpColor } }));
    setCpKey(null);
  }

  function resetColor() {
    if (!cpKey) return;
    setTileColors((prev) => {
      const next = { ...prev };
      delete next[cpKey];
      return next;
    });
    setCpKey(null);
  }

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
            <SantijetLogo fontSize={22} />
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

        {isHiVis ? (
          <View style={styles.hiVisBanner}>
            <View style={styles.hiVisBannerRow}>
              <Feather name="alert-triangle" size={12} color={HIVIS_BLACK} />
              <Text style={styles.hiVisBannerText}>HI-VIS · İSG MODU</Text>
            </View>
            <HazardStripe height={8} />
          </View>
        ) : null}

        {isSteel ? (
          <Text style={styles.steelBanner}>{t("home.steel.banner")}</Text>
        ) : null}

        <DraggableGrid
          sections={visibleSections}
          onReorder={(newOrder) => setTileOrder(newOrder)}
          tileH={isHiVis ? DG_TILE_H_HIVIS : isSteel ? DG_TILE_H_STEEL : DG_TILE_H_DEFAULT}
          renderTile={(s) => {
            const perm = getPermission(s.key);
            if (isSteel) {
              const idx = visibleSections.indexOf(s) + 1;
              return (
                <View style={styles.steelTileWrap}>
                  <View style={[styles.steelAccent, { backgroundColor: s.color }]} />
                  <View style={styles.steelHead}>
                    <View
                      style={[
                        styles.steelIcon,
                        { backgroundColor: s.color + "22", borderColor: s.color + "55" },
                      ]}
                    >
                      <Feather name={s.icon as any} size={18} color={s.color} />
                    </View>
                    <Text style={styles.steelNum}>#{String(idx).padStart(2, "0")}</Text>
                  </View>
                  <Text style={styles.steelLabel} numberOfLines={1}>
                    {t(`menu.${s.key}`).toUpperCase()}
                  </Text>
                  <View style={styles.steelCountRow}>
                    <Text style={styles.steelCount} numberOfLines={1}>
                      {s.count(app)}
                    </Text>
                    <Text style={styles.steelSub} numberOfLines={1}>
                      {perm === "view" ? t("home.tile.readonly") : t(`home.steel.sub.${s.key}`)}
                    </Text>
                  </View>
                  <View style={styles.steelDivider} />
                  <View style={styles.steelFootRow}>
                    <Text style={styles.steelOpen}>{t("home.steel.open")}</Text>
                    <Feather name="chevron-right" size={12} color="#64748b" />
                  </View>
                </View>
              );
            }
            if (isHiVis) {
              return (
                <View style={styles.hiVisTileWrap}>
                  <View style={styles.hiVisTileShadow} />
                  <View style={styles.hiVisTileInner}>
                    <View style={styles.hiVisHeader}>
                      <Feather name="alert-triangle" size={9} color={HIVIS_YELLOW} />
                      <Text style={styles.hiVisDikkat}>DİKKAT</Text>
                      <View style={{ flex: 1 }} />
                      <Text style={styles.hiVisCode}>{s.code}</Text>
                    </View>
                    <View style={styles.hiVisBody}>
                      <View style={styles.hiVisHeadRow}>
                        <View style={styles.hiVisIconBox}>
                          <Feather name={s.icon as any} size={20} color={HIVIS_YELLOW} />
                        </View>
                        <Text style={styles.hiVisCount} numberOfLines={1}>
                          {s.count(app)}
                        </Text>
                      </View>
                      <Text style={styles.hiVisLabel} numberOfLines={2}>
                        {t(`menu.${s.key}`)}
                      </Text>
                      {perm === "view" ? (
                        <View style={styles.hiVisViewBadge}>
                          <Feather name="eye" size={9} color={HIVIS_YELLOW} />
                          <Text style={styles.hiVisViewText}>{t("home.tile.readonly")}</Text>
                        </View>
                      ) : null}
                    </View>
                    <HazardStripe height={6} segments={20} />
                  </View>
                </View>
              );
            }
            const custom = tileColors[s.key];
            const accentColor = custom ? custom.color : s.color;
            const isFill = custom?.mode === "fill";
            return (
              <View
                style={[
                  styles.tileInner,
                  {
                    backgroundColor: isFill ? fillBg(custom!.color) : colors.card,
                    borderColor: isFill ? fillBorder(custom!.color) : colors.border,
                  },
                ]}
              >
                <View style={[styles.tileAccent, { backgroundColor: accentColor }]} />
                <View style={styles.tileHead}>
                  <View style={[styles.tileIcon, { backgroundColor: isFill ? custom!.color + "22" : s.bg }]}>
                    <Feather name={s.icon as any} size={20} color={accentColor} />
                  </View>
                  {perm === "view" ? (
                    <View style={styles.viewBadge}>
                      <Feather name="eye" size={9} color="#0ea5e9" />
                      <Text style={styles.viewBadgeText}>{t("home.tile.readonly")}</Text>
                    </View>
                  ) : null}
                </View>
                <Text
                  style={[styles.tileLabel, { color: colors.foreground }]}
                  numberOfLines={2}
                >
                  {t(`menu.${s.key}`)}
                </Text>
                <View style={styles.tileFootRow}>
                  <Text style={[styles.tileCount, { color: colors.mutedForeground }]} numberOfLines={1}>
                    {s.count(app)}
                  </Text>
                  <View style={[styles.tileChev, { backgroundColor: colors.muted }]}>
                    <Feather name="chevron-right" size={12} color={colors.mutedForeground} />
                  </View>
                </View>
              </View>
            );
          }}
          onTilePress={(s) => router.push(s.route as any)}
          onDoubleTap={(s) => openColorPicker(s.key)}
        />

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
          <View style={[styles.raporIcon, { backgroundColor: colors.foreground + "1A" }]}>
            <Feather name="settings" size={20} color={colors.foreground} />
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

      {/* ---- Kart Renk Seçici Modal ---- */}
      <Modal
        visible={cpKey !== null}
        transparent
        animationType="fade"
        onRequestClose={() => setCpKey(null)}
      >
        <Pressable style={styles.cpOverlay} onPress={() => setCpKey(null)}>
          <Pressable style={[styles.cpSheet, { backgroundColor: colors.card }]} onPress={() => {}}>
            <View style={styles.cpHeader}>
              <View style={[styles.cpDot, { backgroundColor: cpColor }]} />
              <Text style={[styles.cpTitle, { color: colors.foreground }]}>Kart Rengi</Text>
              <TouchableOpacity onPress={() => setCpKey(null)} hitSlop={10}>
                <Feather name="x" size={18} color={colors.mutedForeground} />
              </TouchableOpacity>
            </View>

            <View style={styles.cpModeRow}>
              <TouchableOpacity
                style={[
                  styles.cpModeBtn,
                  { borderColor: cpMode === "accent" ? cpColor : colors.border },
                  cpMode === "accent" && { backgroundColor: cpColor + "18" },
                ]}
                onPress={() => setCpMode("accent")}
                activeOpacity={0.8}
              >
                <View style={[styles.cpModeAccentDemo, { backgroundColor: cpColor }]} />
                <Text style={[styles.cpModeLbl, { color: cpMode === "accent" ? cpColor : colors.mutedForeground }]}>
                  Sol Kenar
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[
                  styles.cpModeBtn,
                  { borderColor: cpMode === "fill" ? cpColor : colors.border },
                  cpMode === "fill" && { backgroundColor: cpColor + "18" },
                ]}
                onPress={() => setCpMode("fill")}
                activeOpacity={0.8}
              >
                <View style={[styles.cpModeFillDemo, { backgroundColor: cpColor + "2a", borderColor: cpColor + "55" }]} />
                <Text style={[styles.cpModeLbl, { color: cpMode === "fill" ? cpColor : colors.mutedForeground }]}>
                  Dolgu
                </Text>
              </TouchableOpacity>
            </View>

            <View style={styles.cpPalette}>
              {SOFT_COLORS.map((c) => (
                <TouchableOpacity
                  key={c}
                  style={[
                    styles.cpSwatch,
                    { backgroundColor: c },
                    cpColor === c && styles.cpSwatchActive,
                  ]}
                  onPress={() => setCpColor(c)}
                  activeOpacity={0.8}
                />
              ))}
            </View>

            <View style={styles.cpActions}>
              <TouchableOpacity
                style={[styles.cpResetBtn, { borderColor: colors.border }]}
                onPress={resetColor}
                activeOpacity={0.8}
              >
                <Feather name="rotate-ccw" size={13} color={colors.mutedForeground} />
                <Text style={[styles.cpResetTxt, { color: colors.mutedForeground }]}>Sıfırla</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.cpApplyBtn, { backgroundColor: cpColor }]}
                onPress={applyColor}
                activeOpacity={0.8}
              >
                <Feather name="check" size={13} color="#fff" />
                <Text style={styles.cpApplyTxt}>Uygula</Text>
              </TouchableOpacity>
            </View>
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

// ============================================================================
// DraggableGrid: Uzun bas + sürükle ile yeniden sıralanabilen 2 sütunlu grid
// ============================================================================

const DG_COLS = 2;
const DG_GAP = 12;
const DG_TILE_H_DEFAULT = 144;
const DG_TILE_H_HIVIS = 188;
const DG_TILE_H_STEEL = 160;

interface DGSection {
  key: string;
  [k: string]: any;
}

interface DGProps<T extends DGSection> {
  sections: T[];
  onReorder: (newOrder: string[]) => void;
  renderTile: (s: T) => React.ReactNode;
  onTilePress: (s: T) => void;
  onDoubleTap?: (s: T) => void;
  tileH?: number;
}

function slotPos(idx: number, tileW: number, tileH: number) {
  "worklet";
  const col = idx % DG_COLS;
  const row = Math.floor(idx / DG_COLS);
  return { x: col * (tileW + DG_GAP), y: row * (tileH + DG_GAP) };
}

function DraggableGrid<T extends DGSection>({
  sections,
  onReorder,
  renderTile,
  onTilePress,
  onDoubleTap,
  tileH = DG_TILE_H_DEFAULT,
}: DGProps<T>) {
  const [containerW, setContainerW] = useState(0);
  const tileW = containerW > 0 ? (containerW - DG_GAP * (DG_COLS - 1)) / DG_COLS : 0;
  const totalRows = Math.ceil(sections.length / DG_COLS);
  const containerH = totalRows > 0 ? totalRows * tileH + (totalRows - 1) * DG_GAP : 0;

  // key -> index (canlı sıralama, drag esnasında güncellenir)
  const positions = useSharedValue<Record<string, number>>(
    Object.fromEntries(sections.map((s, i) => [s.key, i]))
  );
  const draggingKey = useSharedValue<string | null>(null);
  const tileWShared = useSharedValue(tileW);

  // sections değişince pozisyonları yeniden senkronize et
  useEffect(() => {
    const next: Record<string, number> = {};
    sections.forEach((s, i) => {
      next[s.key] = i;
    });
    positions.value = next;
  }, [sections]);

  useEffect(() => {
    tileWShared.value = tileW;
  }, [tileW]);

  return (
    <View
      onLayout={(e) => setContainerW(e.nativeEvent.layout.width)}
      style={{ width: "100%", height: containerH, marginBottom: 24 }}
    >
      {tileW > 0
        ? sections.map((s) => (
            <DraggableTile
              key={s.key}
              itemKey={s.key}
              total={sections.length}
              tileW={tileW}
              tileH={tileH}
              tileWShared={tileWShared}
              positions={positions}
              draggingKey={draggingKey}
              onReorder={onReorder}
              onPress={() => onTilePress(s)}
              onDoubleTap={onDoubleTap ? () => onDoubleTap(s) : undefined}
            >
              {renderTile(s)}
            </DraggableTile>
          ))
        : null}
    </View>
  );
}

interface DTProps {
  itemKey: string;
  total: number;
  tileW: number;
  tileH: number;
  tileWShared: SharedValue<number>;
  positions: SharedValue<Record<string, number>>;
  draggingKey: SharedValue<string | null>;
  onReorder: (newOrder: string[]) => void;
  onPress: () => void;
  onDoubleTap?: () => void;
  children: React.ReactNode;
}

function DraggableTile({
  itemKey,
  total,
  tileW,
  tileH,
  tileWShared,
  positions,
  draggingKey,
  onReorder,
  onPress,
  onDoubleTap,
  children,
}: DTProps) {
  const tileHShared = useSharedValue(tileH);
  useEffect(() => {
    tileHShared.value = tileH;
  }, [tileH]);
  const tx = useSharedValue(0);
  const ty = useSharedValue(0);
  const scale = useSharedValue(1);
  const z = useSharedValue(0);
  const shadow = useSharedValue(0);
  const initialized = useRef(false);

  // Slot pozisyonuna otomatik geçiş (drag yapılmadığında)
  useAnimatedReaction(
    () => ({
      idx: positions.value[itemKey],
      w: tileWShared.value,
      h: tileHShared.value,
      isDragging: draggingKey.value === itemKey,
    }),
    (cur, prev) => {
      if (cur.w === 0 || cur.idx === undefined) return;
      if (cur.isDragging) return;
      const { x, y } = slotPos(cur.idx, cur.w, cur.h);
      if (!prev || prev.w === 0) {
        // ilk yerleşim — animasyonsuz
        tx.value = x;
        ty.value = y;
      } else {
        tx.value = withSpring(x, { damping: 20, stiffness: 220 });
        ty.value = withSpring(y, { damping: 20, stiffness: 220 });
      }
    }
  );

  useEffect(() => {
    initialized.current = true;
  }, []);

  const startX = useSharedValue(0);
  const startY = useSharedValue(0);

  const drag = Gesture.Pan()
    .activateAfterLongPress(300)
    .onStart(() => {
      draggingKey.value = itemKey;
      startX.value = tx.value;
      startY.value = ty.value;
      scale.value = withSpring(1.08, { damping: 14, stiffness: 220 });
      z.value = 100;
      shadow.value = withSpring(1);
    })
    .onChange((e) => {
      const w = tileWShared.value;
      const h = tileHShared.value;
      if (w === 0) return;
      tx.value = startX.value + e.translationX;
      ty.value = startY.value + e.translationY;
      // Parmağın hangi slot üzerinde olduğunu hesapla
      const cx = tx.value + w / 2;
      const cy = ty.value + h / 2;
      const col = Math.max(0, Math.min(DG_COLS - 1, Math.floor(cx / (w + DG_GAP))));
      const row = Math.max(0, Math.floor(cy / (h + DG_GAP)));
      const newIdx = Math.max(0, Math.min(total - 1, row * DG_COLS + col));
      const myIdx = positions.value[itemKey];
      if (myIdx === undefined || newIdx === myIdx) return;
      // Sırayı yeniden kur ve diğer karelere dağıt
      const entries = Object.entries(positions.value).sort((a, b) => a[1] - b[1]);
      const keys = entries.map(([k]) => k);
      keys.splice(myIdx, 1);
      keys.splice(newIdx, 0, itemKey);
      const next: Record<string, number> = {};
      keys.forEach((k, i) => {
        next[k] = i;
      });
      positions.value = next;
      runOnJS(onReorder)(keys);
    })
    .onEnd(() => {
      draggingKey.value = null;
      scale.value = withSpring(1, { damping: 16, stiffness: 220 });
      shadow.value = withSpring(0);
      const idx = positions.value[itemKey];
      const w = tileWShared.value;
      if (idx !== undefined && w > 0) {
        const { x, y } = slotPos(idx, w, tileHShared.value);
        tx.value = withSpring(x, { damping: 20, stiffness: 220 });
        ty.value = withSpring(y, { damping: 20, stiffness: 220 });
      }
      z.value = 0;
    });

  const tap = Gesture.Tap()
    .maxDuration(280)
    .onEnd((_e, success) => {
      if (success) runOnJS(onPress)();
    });

  // 800 ms hareketsiz uzun basma → renk seçici (sürükleme iptal edilir)
  const colorLongPress = Gesture.LongPress()
    .minDuration(800)
    .maxDistance(12)
    .onStart(() => {
      "worklet";
      if (draggingKey.value === itemKey) {
        draggingKey.value = null;
        scale.value = withSpring(1, { damping: 16, stiffness: 220 });
        shadow.value = withSpring(0);
        z.value = 0;
      }
      if (onDoubleTap) runOnJS(onDoubleTap)();
    });

  const composed = Gesture.Simultaneous(drag, tap, colorLongPress);

  const animStyle = useAnimatedStyle(() => ({
    position: "absolute",
    left: 0,
    top: 0,
    width: tileWShared.value,
    transform: [
      { translateX: tx.value },
      { translateY: ty.value },
      { scale: scale.value },
    ],
    zIndex: z.value,
    elevation: z.value > 0 ? 10 : 2,
    shadowOpacity: 0.06 + shadow.value * 0.18,
    shadowRadius: 4 + shadow.value * 10,
    opacity: draggingKey.value === itemKey ? 0.95 : 1,
  }));

  return (
    <Animated.View style={[{ shadowColor: "#000", shadowOffset: { width: 0, height: 2 } }, animStyle]}>
      <GestureDetector gesture={composed}>
        <Animated.View style={{ width: "100%", height: tileH }}>
          {children}
        </Animated.View>
      </GestureDetector>
    </Animated.View>
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
  tileInner: {
    flex: 1,
    paddingTop: 14,
    paddingBottom: 12,
    paddingHorizontal: 14,
    paddingLeft: 16,
    borderRadius: 12,
    borderWidth: StyleSheet.hairlineWidth,
    gap: 10,
    overflow: "hidden",
    shadowColor: "#0B1E33",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 6,
    elevation: 2,
    justifyContent: "space-between",
  },
  tileAccent: {
    position: "absolute",
    left: 0,
    top: 0,
    bottom: 0,
    width: 4,
  },
  tileHead: {
    flexDirection: "row",
    alignItems: "flex-start",
    justifyContent: "space-between",
    gap: 6,
  },
  tileIcon: {
    width: 38,
    height: 38,
    borderRadius: 9,
    justifyContent: "center",
    alignItems: "center",
  },
  tileLabel: {
    fontSize: 14,
    lineHeight: 18,
    fontFamily: "Inter_700Bold",
    letterSpacing: 0.1,
  },
  tileFootRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    gap: 6,
  },
  tileChev: {
    width: 22,
    height: 22,
    borderRadius: 11,
    alignItems: "center",
    justifyContent: "center",
  },
  tileCount: {
    flex: 1,
    fontSize: 11,
    fontFamily: "Inter_500Medium",
    letterSpacing: 0.1,
  },
  viewBadge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 3,
    backgroundColor: "#e0f2fe",
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  viewBadgeText: {
    fontSize: 9,
    fontFamily: "Inter_600SemiBold",
    color: "#0ea5e9",
  },
  hiVisBanner: {
    marginBottom: 12,
    gap: 6,
  },
  hiVisBannerRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: 4,
  },
  hiVisBannerText: {
    fontSize: 10,
    fontFamily: "Inter_700Bold",
    color: HIVIS_BLACK,
    letterSpacing: 2.5,
  },
  hiVisTileWrap: {
    flex: 1,
    position: "relative",
  },
  hiVisTileShadow: {
    position: "absolute",
    left: 4,
    top: 4,
    right: -4,
    bottom: -4,
    backgroundColor: HIVIS_BLACK,
    borderRadius: 6,
  },
  hiVisTileInner: {
    flex: 1,
    backgroundColor: HIVIS_YELLOW,
    borderColor: HIVIS_BLACK,
    borderWidth: 2,
    borderRadius: 6,
    overflow: "hidden",
  },
  hiVisHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    backgroundColor: HIVIS_BLACK,
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  hiVisDikkat: {
    fontSize: 9,
    fontFamily: "Inter_700Bold",
    color: HIVIS_YELLOW,
    letterSpacing: 1.5,
  },
  hiVisCode: {
    fontSize: 9,
    fontFamily: "Inter_700Bold",
    color: HIVIS_YELLOW,
    letterSpacing: 0.5,
  },
  hiVisBody: {
    padding: 12,
    gap: 8,
  },
  hiVisHeadRow: {
    flexDirection: "row",
    alignItems: "flex-start",
    justifyContent: "space-between",
  },
  hiVisIconBox: {
    width: 38,
    height: 38,
    borderRadius: 6,
    backgroundColor: HIVIS_BLACK,
    alignItems: "center",
    justifyContent: "center",
  },
  hiVisCount: {
    fontSize: 26,
    lineHeight: 28,
    fontFamily: "Inter_700Bold",
    color: HIVIS_BLACK,
  },
  hiVisLabel: {
    fontSize: 13,
    fontFamily: "Inter_700Bold",
    color: HIVIS_BLACK,
    letterSpacing: 0.8,
  },
  hiVisViewBadge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 3,
    alignSelf: "flex-start",
    backgroundColor: HIVIS_BLACK,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 3,
  },
  hiVisViewText: {
    fontSize: 9,
    fontFamily: "Inter_600SemiBold",
    color: HIVIS_YELLOW,
  },
  steelBanner: {
    fontSize: 10,
    fontFamily: "Inter_700Bold",
    color: "#94a3b8",
    letterSpacing: 2,
    paddingHorizontal: 4,
    marginBottom: 12,
  },
  steelTileWrap: {
    flex: 1,
    backgroundColor: "#1e293b",
    borderColor: "rgba(51,65,85,0.6)",
    borderWidth: 1,
    borderRadius: 8,
    overflow: "hidden",
    paddingVertical: 12,
    paddingRight: 12,
    paddingLeft: 16,
    position: "relative",
  },
  steelAccent: {
    position: "absolute",
    left: 0,
    top: 0,
    bottom: 0,
    width: 4,
  },
  steelHead: {
    flexDirection: "row",
    alignItems: "flex-start",
    justifyContent: "space-between",
    marginBottom: 10,
  },
  steelIcon: {
    width: 36,
    height: 36,
    borderRadius: 6,
    borderWidth: 1,
    alignItems: "center",
    justifyContent: "center",
  },
  steelNum: {
    fontSize: 9,
    fontFamily: "Inter_700Bold",
    color: "#64748b",
    letterSpacing: 1,
    marginTop: 2,
  },
  steelLabel: {
    fontSize: 12,
    fontFamily: "Inter_700Bold",
    color: "#ffffff",
    letterSpacing: 0.8,
  },
  steelCountRow: {
    flexDirection: "row",
    alignItems: "baseline",
    gap: 6,
    marginTop: 4,
  },
  steelCount: {
    fontSize: 22,
    fontFamily: "Inter_700Bold",
    color: "#ffffff",
  },
  steelSub: {
    fontSize: 10,
    fontFamily: "Inter_500Medium",
    color: "#94a3b8",
    flexShrink: 1,
  },
  steelDivider: {
    height: 1,
    backgroundColor: "rgba(51,65,85,0.6)",
    marginTop: 8,
  },
  steelFootRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginTop: 6,
  },
  steelOpen: {
    fontSize: 9,
    fontFamily: "Inter_700Bold",
    color: "#64748b",
    letterSpacing: 2,
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
  // ---- Renk seçici modal ----
  cpOverlay: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.45)",
    justifyContent: "center",
    alignItems: "center",
  },
  cpSheet: {
    width: 320,
    borderRadius: 20,
    padding: 20,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.18,
    shadowRadius: 24,
    elevation: 20,
  },
  cpHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    marginBottom: 18,
  },
  cpDot: {
    width: 16,
    height: 16,
    borderRadius: 8,
  },
  cpTitle: {
    flex: 1,
    fontSize: 16,
    fontFamily: "Inter_700Bold",
  },
  cpModeRow: {
    flexDirection: "row",
    gap: 10,
    marginBottom: 20,
  },
  cpModeBtn: {
    flex: 1,
    borderRadius: 12,
    borderWidth: 1.5,
    paddingVertical: 10,
    paddingHorizontal: 12,
    alignItems: "center",
    gap: 8,
  },
  cpModeAccentDemo: {
    width: 28,
    height: 28,
    borderRadius: 6,
    borderLeftWidth: 4,
    borderLeftColor: "transparent",
    position: "relative",
  },
  cpModeFillDemo: {
    width: 28,
    height: 28,
    borderRadius: 6,
    borderWidth: 1.5,
  },
  cpModeLbl: {
    fontSize: 12,
    fontFamily: "Inter_600SemiBold",
  },
  cpPalette: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 10,
    justifyContent: "center",
    marginBottom: 20,
  },
  cpSwatch: {
    width: 40,
    height: 40,
    borderRadius: 20,
  },
  cpSwatchActive: {
    borderWidth: 3,
    borderColor: "#fff",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 4,
    transform: [{ scale: 1.15 }],
  },
  cpActions: {
    flexDirection: "row",
    gap: 10,
  },
  cpResetBtn: {
    flex: 1,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
    borderRadius: 12,
    borderWidth: 1.5,
    paddingVertical: 12,
  },
  cpResetTxt: {
    fontSize: 13,
    fontFamily: "Inter_600SemiBold",
  },
  cpApplyBtn: {
    flex: 2,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
    borderRadius: 12,
    paddingVertical: 12,
  },
  cpApplyTxt: {
    fontSize: 13,
    fontFamily: "Inter_600SemiBold",
    color: "#fff",
  },
});
