import AsyncStorage from "@react-native-async-storage/async-storage";
import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
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

import HomeBrandMark from "@/components/HomeBrandMark";
import PrimaryButton from "@/components/PrimaryButton";
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

// Referans sırasına göre dizilmiş modüller
const SECTIONS: Section[] = [
  { key: "proje",        label: "Proje",        icon: "briefcase",     route: "/proje",        color: "#e85d04", bg: "#fef3e2", code: "PR-01", sub: "Aktif Proje",   count: (a) => a.projects.length },
  { key: "gunluk-rapor", label: "Günlük Rapor",  icon: "file-text",     route: "/gunluk-rapor", color: "#0891b2", bg: "#cffafe", code: "GR-02", sub: "Bugün",         count: (a) => a.dailyReports.length },
  { key: "puantaj",      label: "Puantaj",       icon: "users",         route: "/puantaj",      color: "#16a34a", bg: "#dcfce7", code: "PU-03", sub: "Personel",      count: (a) => a.attendance.length },
  { key: "gorev",        label: "Görev",         icon: "check-square",  route: "/gorev",        color: "#dc2626", bg: "#fee2e2", code: "GV-04", sub: "Açık Görev",    count: (a) => a.tasks.length },
  { key: "imalat",       label: "İmalat",        icon: "tool",          route: "/imalat",       color: "#d97706", bg: "#fef3c7", code: "IM-05", sub: "Devam Eden",    count: (a) => a.productions.length },
  { key: "ilerleme",     label: "İlerleme",      icon: "trending-up",   route: "/ilerleme",     color: "#0d9488", bg: "#ccfbf1", code: "IL-06", sub: "Kayıt",         count: (a) => a.surveys.length + a.productions.length },
  { key: "malzeme",      label: "Malzeme",       icon: "package",       route: "/malzeme",      color: "#059669", bg: "#d1fae5", code: "MZ-07", sub: "Kritik Stok",   count: (a) => a.materials.length },
  { key: "kantar",       label: "Kantar",        icon: "truck",         route: "/kantar",       color: "#0d9488", bg: "#ccfbf1", code: "KN-08", sub: "Bugün Giriş",   count: (a) => a.weighbridges.length },
  { key: "kesif",        label: "Keşif",         icon: "search",        route: "/kesif",        color: "#0ea5e9", bg: "#e0f2fe", code: "KS-09", sub: "Keşif",         count: (a) => a.surveys.length },
  { key: "is-programi",  label: "İş Programı",   icon: "calendar",      route: "/is-programi",  color: "#8b5cf6", bg: "#ede9fe", code: "IP-10", sub: "Aktif İş",      count: (a) => a.scheduleTasks.length },
  { key: "satin-alma",   label: "Satın Alma",    icon: "shopping-cart", route: "/satin-alma",   color: "#ea580c", bg: "#ffedd5", code: "SA-11", sub: "Açık Talep",    count: (a) => a.purchases.length },
  { key: "hakedis",      label: "Hakediş",       icon: "file-text",     route: "/hakedis",      color: "#be185d", bg: "#fce7f3", code: "HK-12", sub: "Bekleyen",      count: (a) => a.hakedisler.length },
  { key: "butce",        label: "Yaklaşık Maliyet", icon: "dollar-sign", route: "/butce",        color: "#16213e", bg: "#e0e7ff", code: "YM-13", sub: "Kalem",         count: (a) => a.surveys.reduce((s, sv) => s + sv.items.length, 0) },
  { key: "taseron",      label: "Taşeron",       icon: "truck",         route: "/taseron",      color: "#7c3aed", bg: "#ede9fe", code: "TS-14", sub: "Taşeron",       count: (a) => a.subcontractors.length },
  { key: "kullanicilar", label: "Personel",       icon: "shield",        route: "/kullanicilar", color: "#7c3aed", bg: "#ede9fe", code: "KU-15", sub: "Personel",      count: (a) => a.appUsers.length },
  { key: "dosyalar",     label: "Dosyalar",      icon: "folder",        route: "/dosyalar",     color: "#475569", bg: "#e2e8f0", code: "DS-16", sub: "Dosya",         count: (a) => a.archiveFiles.length },
];

// Modül neon renkleri (referans ekranına göre)
const SECTION_NEON: Record<string, string> = {
  "proje":        "#3b82f6",
  "gunluk-rapor": "#f97316",
  "puantaj":      "#8b5cf6",
  "gorev":        "#22c55e",
  "imalat":       "#3b82f6",
  "ilerleme":     "#f97316",
  "malzeme":      "#f97316",
  "kantar":       "#22c55e",
  "kesif":        "#60a5fa",
  "is-programi":  "#f97316",
  "satin-alma":   "#ec4899",
  "hakedis":      "#06b6d4",
  "butce":        "#22c55e",
  "taseron":      "#f97316",
  "kullanicilar": "#8b5cf6",
  "dosyalar":     "#64748b",
};

// Modül sıra numaraları
const SECTION_NUM: Record<string, string> = {
  "proje": "01", "gunluk-rapor": "02", "puantaj": "03", "gorev": "04",
  "imalat": "05", "ilerleme": "06", "malzeme": "07", "kantar": "08",
  "kesif": "09", "is-programi": "10", "satin-alma": "11", "hakedis": "12",
  "butce": "13", "taseron": "14", "kullanicilar": "15", "dosyalar": "16",
};

const TILE_COLORS_KEY = "santiye-tile-colors-v1";

type TileColorMode = "accent" | "fill";
interface TileColorConfig {
  mode: TileColorMode;
  color: string;
}

const SOFT_COLORS = [
  "#f87171", "#fb923c", "#fbbf24", "#a3e635", "#4ade80",
  "#34d399", "#22d3ee", "#38bdf8", "#60a5fa", "#818cf8",
  "#a78bfa", "#c084fc", "#e879f9", "#f472b6", "#fb7185",
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

function HazardStripe({
  height = 8,
  segments = 28,
  accent,
  ink,
}: {
  height?: number;
  segments?: number;
  accent: string;
  ink: string;
}) {
  return (
    <View style={{ height, backgroundColor: accent, overflow: "hidden", flexDirection: "row" }}>
      {Array.from({ length: segments }).map((_, i) => (
        <View
          key={i}
          style={{
            width: 14,
            height: height * 3,
            marginTop: -height,
            backgroundColor: i % 2 === 0 ? ink : "transparent",
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
  const { theme } = useTheme();
  const isHiVis = theme.layout === "hivis";
  const isSteel = theme.layout === "steel";
  const hiVisAccent = colors.card;
  const hiVisInk = colors.primary;
  const router = useRouter();
  const app = useApp();
  const { t } = useI18n();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 67 : insets.top;

  const { currentRole, currentAppUser, workspaceInfo, syncStatus, pushToCloud, pullFromCloud } = app;
  const isAdmin = currentRole?.isAdmin === true;

  // Tarih
  const today = new Date();
  const dateStr = today.toLocaleDateString("tr-TR", { day: "numeric", month: "long", year: "numeric" });
  const dayStr = today.toLocaleDateString("tr-TR", { weekday: "long" });

  function getPermission(key: PageKey): Permission {
    if (!currentRole) return "none";
    return currentRole.permissions[key] ?? "none";
  }

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
          } catch { }
        }
      })
      .finally(() => setOrderLoaded(true));
  }, []);

  useEffect(() => {
    if (!orderLoaded) return;
    AsyncStorage.setItem(ORDER_KEY, JSON.stringify(tileOrder)).catch(() => {});
  }, [tileOrder, orderLoaded]);

  const [tileColors, setTileColors] = useState<Record<string, TileColorConfig>>({});
  const [colorsLoaded, setColorsLoaded] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(TILE_COLORS_KEY)
      .then((raw) => {
        if (raw) {
          try {
            const obj = JSON.parse(raw);
            if (obj && typeof obj === "object") setTileColors(obj);
          } catch { }
        }
      })
      .finally(() => setColorsLoaded(true));
  }, []);

  useEffect(() => {
    if (!colorsLoaded) return;
    AsyncStorage.setItem(TILE_COLORS_KEY, JSON.stringify(tileColors)).catch(() => {});
  }, [tileColors, colorsLoaded]);

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
      if (s) { result.push(s); byKey.delete(k); }
    }
    for (const s of allowed) {
      if (byKey.has(s.key as string)) result.push(s);
    }
    return result;
  }, [tileOrder, currentRole]);

  const visibleSections = orderedSections;

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>

      {/* ─────────────────────────────────────────────────────
          HEADER
      ───────────────────────────────────────────────────── */}
      <View style={[styles.appHeader, { backgroundColor: colors.secondary, paddingTop: topPad + 8 }]}>
        <HomeBrandMark />

        <View style={styles.headerRight}>
          <View style={styles.headerBellWrap}>
            <Feather name="bell" size={20} color="#94a3b8" />
          </View>
          <TouchableOpacity
            onPress={() => router.push("/ayarlar" as any)}
            style={styles.headerMenuBtn}
            hitSlop={10}
          >
            <Feather name="menu" size={22} color="#cbd5e1" />
          </TouchableOpacity>
        </View>
      </View>

      {/* ─────────────────────────────────────────────────────
          SCROLL CONTENT
      ───────────────────────────────────────────────────── */}
      <ScrollView
        contentContainerStyle={[styles.scroll, { paddingBottom: insets.bottom + 24 }]}
        showsVerticalScrollIndicator={false}
        keyboardShouldPersistTaps="handled"
      >
        {/* Welcome Card */}
        <View style={[styles.welcomeCard, { backgroundColor: colors.secondary, borderColor: "rgba(255,255,255,0.07)" }]}>
          <View style={styles.welcomeLeft}>
            <Text style={styles.welcomeGreet}>{t("home.welcome")}</Text>
            <Text style={[styles.welcomeName, { color: colors.secondaryForeground }]} numberOfLines={1}>
              {(currentAppUser?.name ?? "").toUpperCase()}
            </Text>
            <Text style={[styles.welcomeRole, { color: "#94a3b8" }]} numberOfLines={1}>
              {currentRole?.name ?? ""}
            </Text>
            {workspaceInfo ? (
              <View style={styles.welcomeCompanyRow}>
                <Feather name="layers" size={12} color="#e85d04" />
                <Text style={[styles.welcomeCompanyName, { color: "#cbd5e1" }]} numberOfLines={1}>
                  {workspaceInfo.id === "local" ? t("home.workspace.local") : workspaceInfo.company_name}
                </Text>
                {workspaceInfo.id !== "local" && (
                  <View style={styles.codePill}>
                    <Text style={styles.codePillText}>{workspaceInfo.invite_code}</Text>
                  </View>
                )}
              </View>
            ) : null}
          </View>

          <View style={styles.welcomeDateBlock}>
            <Feather name="calendar" size={16} color="#60a5fa" />
            <Text style={[styles.welcomeDateMain, { color: colors.secondaryForeground }]}>
              {dateStr}
            </Text>
            <Text style={styles.welcomeDateSub}>{dayStr}</Text>
          </View>
        </View>

        <SmartSearch topInset={insets.bottom} />

        {isHiVis ? (
          <View style={[styles.hiVisBanner, { backgroundColor: hiVisAccent }]}>
            <View style={styles.hiVisBannerRow}>
              <Feather name="alert-triangle" size={12} color={hiVisInk} />
              <Text style={[styles.hiVisBannerText, { color: hiVisInk }]}>
                {theme.id === "hivis-orange"
                  ? "TURUNCU · İSG MODU"
                  : theme.id === "hivis-lime"
                    ? "LIME · İSG MODU"
                    : "HI-VIS · İSG MODU"}
              </Text>
            </View>
            <HazardStripe height={8} accent={hiVisAccent} ink={hiVisInk} />
          </View>
        ) : null}

        {isSteel ? (
          <Text style={[styles.steelBanner, { color: colors.mutedForeground }]}>
            {theme.id === "steel-copper"
              ? "BAKIR & BETON"
              : theme.id === "steel-blueprint"
                ? "BLUEPRINT"
                : t("home.steel.banner")}
          </Text>
        ) : null}

        <DraggableGrid
          sections={visibleSections}
          onReorder={(newOrder) => setTileOrder(newOrder)}
          tileH={isHiVis ? DG_TILE_H_HIVIS : isSteel ? DG_TILE_H_STEEL : DG_TILE_H_DEFAULT}
          renderTile={(s) => {
            const perm = getPermission(s.key);

            // ── Hi-Vis tema ──────────────────────────────────────
            if (isHiVis) {
              return (
                <View style={styles.hiVisTileWrap}>
                  <View style={[styles.hiVisTileShadow, { backgroundColor: hiVisInk }]} />
                  <View style={[styles.hiVisTileInner, { backgroundColor: hiVisAccent, borderColor: hiVisInk }]}>
                    <View style={[styles.hiVisHeader, { backgroundColor: hiVisInk }]}>
                      <Feather name="alert-triangle" size={9} color={hiVisAccent} />
                      <Text style={[styles.hiVisDikkat, { color: hiVisAccent }]}>DİKKAT</Text>
                      <View style={{ flex: 1 }} />
                      <Text style={[styles.hiVisCode, { color: hiVisAccent }]}>{s.code}</Text>
                    </View>
                    <View style={styles.hiVisBody}>
                      <View style={styles.hiVisHeadRow}>
                        <View style={[styles.hiVisIconBox, { backgroundColor: hiVisInk }]}>
                          <Feather name={s.icon as any} size={20} color={hiVisAccent} />
                        </View>
                        <Text style={[styles.hiVisCount, { color: hiVisInk }]} numberOfLines={1}>{s.count(app)}</Text>
                      </View>
                      <Text style={[styles.hiVisLabel, { color: hiVisInk }]} numberOfLines={2}>{t(`menu.${s.key}`)}</Text>
                      {perm === "view" ? (
                        <View style={[styles.hiVisViewBadge, { backgroundColor: hiVisInk }]}>
                          <Feather name="eye" size={9} color={hiVisAccent} />
                          <Text style={[styles.hiVisViewText, { color: hiVisAccent }]}>{t("home.tile.readonly")}</Text>
                        </View>
                      ) : null}
                    </View>
                    <HazardStripe height={6} segments={20} accent={hiVisAccent} ink={hiVisInk} />
                  </View>
                </View>
              );
            }

            if (isSteel) {
              const idx = visibleSections.indexOf(s) + 1;
              return (
                <View style={[styles.steelTileWrap, { backgroundColor: colors.card, borderColor: colors.border }]}>
                  <View style={[styles.steelAccent, { backgroundColor: s.color }]} />
                  <View style={styles.steelHead}>
                    <View style={[styles.steelIcon, { backgroundColor: s.color + "22", borderColor: s.color + "55" }]}>
                      <Feather name={s.icon as any} size={18} color={s.color} />
                    </View>
                    <Text style={[styles.steelNum, { color: colors.mutedForeground }]}>#{String(idx).padStart(2, "0")}</Text>
                  </View>
                  <Text style={[styles.steelLabel, { color: colors.foreground }]} numberOfLines={2}>{t(`menu.${s.key}`).toUpperCase()}</Text>
                  <View style={styles.steelCountRow}>
                    <Text style={[styles.steelCount, { color: colors.foreground }]} numberOfLines={1}>{s.count(app)}</Text>
                    <Text style={[styles.steelSub, { color: colors.mutedForeground }]} numberOfLines={1}>
                      {perm === "view" ? t("home.tile.readonly") : t(`home.steel.sub.${s.key}`)}
                    </Text>
                  </View>
                  <View style={[styles.steelDivider, { backgroundColor: colors.border }]} />
                  <View style={styles.steelFootRow}>
                    <Text style={[styles.steelOpen, { color: colors.mutedForeground }]}>{t("home.steel.open")}</Text>
                    <Feather name="chevron-right" size={12} color={colors.mutedForeground} />
                  </View>
                </View>
              );
            }

            // ── Varsayılan premium kart ──────────────────────────
            const custom = tileColors[s.key];
            const neonColor = custom ? custom.color : (SECTION_NEON[s.key] ?? s.color);
            const isFill = custom?.mode === "fill";
            const tileNum = SECTION_NUM[s.key] ?? "";

            return (
              <View
                style={[
                  styles.tileInner,
                  {
                    backgroundColor: isFill ? fillBg(neonColor) : colors.card,
                    borderColor: isFill ? fillBorder(neonColor) : (neonColor + "33"),
                  },
                ]}
              >
                {/* Kart üst satırı: numara + izin rozeti */}
                <View style={styles.tileTopRow}>
                  <Text style={styles.tileNum}>{tileNum}</Text>
                  {perm === "view" ? (
                    <View style={styles.viewBadge}>
                      <Feather name="eye" size={8} color="#0ea5e9" />
                    </View>
                  ) : null}
                </View>

                {/* İkon */}
                <View style={styles.tileIconWrap}>
                  <View style={[styles.tileIconCircle, { backgroundColor: neonColor + "1e" }]}>
                    <Feather name={s.icon as any} size={26} color={neonColor} />
                  </View>
                </View>

                {/* Başlık */}
                <Text style={[styles.tileLabel, { color: colors.cardForeground }]} numberOfLines={2}>
                  {t(`menu.${s.key}`).toUpperCase()}
                </Text>

                {/* Alt bilgi satırı */}
                <View style={styles.tileFootRow}>
                  <View style={[styles.tileDot, { backgroundColor: neonColor }]} />
                  <Text style={[styles.tileInfo, { color: neonColor }]} numberOfLines={1}>
                    {s.count(app)} {s.sub}
                  </Text>
                  <View style={[styles.tileChevCircle, { borderColor: neonColor + "55" }]}>
                    <Feather name="chevron-right" size={9} color={neonColor} />
                  </View>
                </View>
              </View>
            );
          }}
          onTilePress={(s) => router.push(s.route as any)}
          onDoubleTap={(s) => openColorPicker(s.key)}
        />

        {/* Hızlı erişim butonları */}
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

      </ScrollView>

      {/* ── Kart Renk Seçici Modal ── */}
      <Modal visible={cpKey !== null} transparent animationType="fade" onRequestClose={() => setCpKey(null)}>
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
                style={[styles.cpModeBtn, { borderColor: cpMode === "accent" ? cpColor : colors.border }, cpMode === "accent" && { backgroundColor: cpColor + "18" }]}
                onPress={() => setCpMode("accent")}
                activeOpacity={0.8}
              >
                <View style={[styles.cpModeAccentDemo, { backgroundColor: cpColor }]} />
                <Text style={[styles.cpModeLbl, { color: cpMode === "accent" ? cpColor : colors.mutedForeground }]}>Sol Kenar</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.cpModeBtn, { borderColor: cpMode === "fill" ? cpColor : colors.border }, cpMode === "fill" && { backgroundColor: cpColor + "18" }]}
                onPress={() => setCpMode("fill")}
                activeOpacity={0.8}
              >
                <View style={[styles.cpModeFillDemo, { backgroundColor: cpColor + "2a", borderColor: cpColor + "55" }]} />
                <Text style={[styles.cpModeLbl, { color: cpMode === "fill" ? cpColor : colors.mutedForeground }]}>Dolgu</Text>
              </TouchableOpacity>
            </View>

            <View style={styles.cpPalette}>
              {SOFT_COLORS.map((c) => (
                <TouchableOpacity
                  key={c}
                  style={[styles.cpSwatch, { backgroundColor: c }, cpColor === c && styles.cpSwatchActive]}
                  onPress={() => setCpColor(c)}
                  activeOpacity={0.8}
                />
              ))}
            </View>

            <View style={styles.cpActions}>
              <TouchableOpacity style={[styles.cpResetBtn, { borderColor: colors.border }]} onPress={resetColor} activeOpacity={0.8}>
                <Feather name="rotate-ccw" size={13} color={colors.mutedForeground} />
                <Text style={[styles.cpResetTxt, { color: colors.mutedForeground }]}>Sıfırla</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[styles.cpApplyBtn, { backgroundColor: cpColor }]} onPress={applyColor} activeOpacity={0.8}>
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
// DraggableGrid
// ============================================================================

const DG_COLS = 3;
const DG_GAP = 10;
const DG_TILE_H_DEFAULT = 132;
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

  const positions = useSharedValue<Record<string, number>>(
    Object.fromEntries(sections.map((s, i) => [s.key, i]))
  );
  const draggingKey = useSharedValue<string | null>(null);
  const tileWShared = useSharedValue(tileW);

  useEffect(() => {
    const next: Record<string, number> = {};
    sections.forEach((s, i) => { next[s.key] = i; });
    positions.value = next;
  }, [sections]);

  useEffect(() => { tileWShared.value = tileW; }, [tileW]);

  return (
    <View
      onLayout={(e) => setContainerW(e.nativeEvent.layout.width)}
      style={{ width: "100%", height: containerH, marginBottom: 20 }}
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
  itemKey, total, tileW, tileH, tileWShared, positions, draggingKey,
  onReorder, onPress, onDoubleTap, children,
}: DTProps) {
  const tileHShared = useSharedValue(tileH);
  useEffect(() => { tileHShared.value = tileH; }, [tileH]);
  const tx = useSharedValue(0);
  const ty = useSharedValue(0);
  const scale = useSharedValue(1);
  const z = useSharedValue(0);
  const shadow = useSharedValue(0);
  const initialized = useRef(false);

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
        tx.value = x;
        ty.value = y;
      } else {
        tx.value = withSpring(x, { damping: 20, stiffness: 220 });
        ty.value = withSpring(y, { damping: 20, stiffness: 220 });
      }
    }
  );

  useEffect(() => { initialized.current = true; }, []);

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
      const cx = tx.value + w / 2;
      const cy = ty.value + h / 2;
      const col = Math.max(0, Math.min(DG_COLS - 1, Math.floor(cx / (w + DG_GAP))));
      const row = Math.max(0, Math.floor(cy / (h + DG_GAP)));
      const newIdx = Math.max(0, Math.min(total - 1, row * DG_COLS + col));
      const myIdx = positions.value[itemKey];
      if (myIdx === undefined || newIdx === myIdx) return;
      const entries = Object.entries(positions.value).sort((a, b) => a[1] - b[1]);
      const keys = entries.map(([k]) => k);
      keys.splice(myIdx, 1);
      keys.splice(newIdx, 0, itemKey);
      const next: Record<string, number> = {};
      keys.forEach((k, i) => { next[k] = i; });
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
    .onEnd((_e, success) => { if (success) runOnJS(onPress)(); });

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

// ============================================================================
// Stiller
// ============================================================================

const styles = StyleSheet.create({
  root: { flex: 1 },

  // ── Header ──────────────────────────────────────────────────────
  appHeader: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 16,
    paddingBottom: 12,
    gap: 8,
  },
  headerMenuBtn: {
    width: 40,
    height: 40,
    justifyContent: "center",
    alignItems: "center",
  },
  headerRight: {
    flexDirection: "row",
    alignItems: "center",
    gap: 2,
  },
  headerBellWrap: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: "rgba(255,255,255,0.06)",
    justifyContent: "center",
    alignItems: "center",
  },

  // ── Welcome Card ─────────────────────────────────────────────────
  welcomeCard: {
    flexDirection: "row",
    alignItems: "flex-start",
    borderRadius: 16,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    gap: 12,
  },
  welcomeLeft: { flex: 1 },
  welcomeGreet: {
    color: "#64748b",
    fontSize: 13,
    fontFamily: "Inter_400Regular",
  },
  welcomeName: {
    fontSize: 20,
    fontFamily: "Inter_700Bold",
    letterSpacing: 0.5,
    marginTop: 3,
  },
  welcomeRole: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    marginTop: 2,
  },
  welcomeCompanyRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginTop: 10,
    flexWrap: "wrap",
  },
  welcomeCompanyName: {
    fontSize: 13,
    fontFamily: "Inter_600SemiBold",
  },
  welcomeDateBlock: {
    alignItems: "flex-end",
    gap: 3,
    paddingTop: 2,
  },
  welcomeDateMain: {
    fontSize: 12,
    fontFamily: "Inter_600SemiBold",
    marginTop: 4,
    textAlign: "right",
  },
  welcomeDateSub: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    color: "#64748b",
  },

  // ── Sync Bar ──────────────────────────────────────────────────────
  syncBar: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 12,
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 10,
    backgroundColor: "rgba(255,255,255,0.03)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.06)",
  },
  conflictBar: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    marginBottom: 8,
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
  syncLeft: { flexDirection: "row", alignItems: "center", gap: 6, flex: 1 },
  syncCode: { color: "#cbd5e1", fontSize: 11, fontFamily: "Inter_500Medium", flex: 1 },
  codePill: {
    backgroundColor: "rgba(232,93,4,0.18)",
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  codePillText: { color: "#e85d04", fontSize: 10, fontFamily: "Inter_700Bold", letterSpacing: 1 },
  syncBtns: { flexDirection: "row", gap: 10, marginLeft: 10 },
  syncBtn: {
    width: 28, height: 28, borderRadius: 8,
    backgroundColor: "rgba(255,255,255,0.07)",
    justifyContent: "center", alignItems: "center",
  },
  switchWsBtn: {
    flexDirection: "row", alignItems: "center", gap: 6, marginLeft: 10,
    backgroundColor: "rgba(232,93,4,0.15)", borderColor: "#e85d04",
    borderWidth: 1, borderRadius: 8, paddingHorizontal: 10, paddingVertical: 6,
  },
  switchWsText: { color: "#e85d04", fontSize: 11, fontFamily: "Inter_600SemiBold" },

  // ── Scroll ────────────────────────────────────────────────────────
  scroll: { padding: 12, paddingTop: 14 },
  sectionLabel: { fontSize: 16, fontFamily: "Inter_700Bold", marginBottom: 12, marginLeft: 4 },

  // ── Premium Tile (varsayılan 3-sütun) ─────────────────────────────
  tileInner: {
    flex: 1,
    padding: 10,
    borderRadius: 14,
    borderWidth: 1,
    overflow: "hidden",
    justifyContent: "space-between",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
  },
  tileTopRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  tileNum: {
    fontSize: 10,
    fontFamily: "Inter_700Bold",
    color: "#334155",
    letterSpacing: 0.5,
  },
  tileIconWrap: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    paddingVertical: 4,
  },
  tileIconCircle: {
    width: 50,
    height: 50,
    borderRadius: 25,
    justifyContent: "center",
    alignItems: "center",
  },
  tileLabel: {
    fontSize: 10,
    fontFamily: "Inter_700Bold",
    textAlign: "center",
    letterSpacing: 0.4,
  },
  tileFootRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
  },
  tileDot: {
    width: 5,
    height: 5,
    borderRadius: 3,
  },
  tileInfo: {
    flex: 1,
    fontSize: 9,
    fontFamily: "Inter_500Medium",
  },
  tileChevCircle: {
    width: 18,
    height: 18,
    borderRadius: 9,
    borderWidth: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  viewBadge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 2,
    backgroundColor: "#e0f2fe",
    paddingHorizontal: 4,
    paddingVertical: 2,
    borderRadius: 4,
  },
  viewBadgeText: { fontSize: 9, fontFamily: "Inter_600SemiBold", color: "#0ea5e9" },

  // ── Hi-Vis Tile ───────────────────────────────────────────────────
  hiVisBanner: { marginBottom: 12, gap: 6, borderRadius: 6, overflow: "hidden", paddingTop: 8 },
  hiVisBannerRow: { flexDirection: "row", alignItems: "center", gap: 6, paddingHorizontal: 8, paddingBottom: 6 },
  hiVisBannerText: { fontSize: 10, fontFamily: "Inter_700Bold", letterSpacing: 2.5 },
  hiVisTileWrap: { flex: 1, position: "relative" },
  hiVisTileShadow: { position: "absolute", left: 4, top: 4, right: -4, bottom: -4, borderRadius: 6 },
  hiVisTileInner: { flex: 1, borderWidth: 2, borderRadius: 6, overflow: "hidden" },
  hiVisHeader: { flexDirection: "row", alignItems: "center", gap: 4, paddingHorizontal: 8, paddingVertical: 4 },
  hiVisDikkat: { fontSize: 9, fontFamily: "Inter_700Bold", letterSpacing: 1.5 },
  hiVisCode: { fontSize: 9, fontFamily: "Inter_700Bold", letterSpacing: 0.5 },
  hiVisBody: { padding: 12, gap: 8 },
  hiVisHeadRow: { flexDirection: "row", alignItems: "flex-start", justifyContent: "space-between" },
  hiVisIconBox: { width: 38, height: 38, borderRadius: 6, alignItems: "center", justifyContent: "center" },
  hiVisCount: { fontSize: 26, lineHeight: 28, fontFamily: "Inter_700Bold" },
  hiVisLabel: { fontSize: 13, fontFamily: "Inter_700Bold", letterSpacing: 0.8 },
  hiVisViewBadge: { flexDirection: "row", alignItems: "center", gap: 3, alignSelf: "flex-start", paddingHorizontal: 6, paddingVertical: 2, borderRadius: 3 },
  hiVisViewText: { fontSize: 9, fontFamily: "Inter_600SemiBold" },

  // ── Steel Tile ────────────────────────────────────────────────────
  steelBanner: { fontSize: 10, fontFamily: "Inter_700Bold", color: "#94a3b8", letterSpacing: 2, paddingHorizontal: 4, marginBottom: 12 },
  steelTileWrap: { flex: 1, backgroundColor: "#1e293b", borderColor: "rgba(51,65,85,0.6)", borderWidth: 1, borderRadius: 8, overflow: "hidden", paddingVertical: 12, paddingRight: 12, paddingLeft: 16, position: "relative" },
  steelAccent: { position: "absolute", left: 0, top: 0, bottom: 0, width: 4 },
  steelHead: { flexDirection: "row", alignItems: "flex-start", justifyContent: "space-between", marginBottom: 10 },
  steelIcon: { width: 36, height: 36, borderRadius: 6, borderWidth: 1, alignItems: "center", justifyContent: "center" },
  steelNum: { fontSize: 9, fontFamily: "Inter_700Bold", color: "#64748b", letterSpacing: 1, marginTop: 2 },
  steelLabel: { fontSize: 12, fontFamily: "Inter_700Bold", color: "#ffffff", letterSpacing: 0.8 },
  steelCountRow: { flexDirection: "row", alignItems: "baseline", gap: 6, marginTop: 4 },
  steelCount: { fontSize: 22, fontFamily: "Inter_700Bold", color: "#ffffff" },
  steelSub: { fontSize: 10, fontFamily: "Inter_500Medium", color: "#94a3b8", flexShrink: 1 },
  steelDivider: { height: 1, backgroundColor: "rgba(51,65,85,0.6)", marginTop: 8 },
  steelFootRow: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginTop: 6 },
  steelOpen: { fontSize: 9, fontFamily: "Inter_700Bold", color: "#64748b", letterSpacing: 2 },

  // ── Hızlı Erişim Butonları ────────────────────────────────────────
  raporBtn: { flexDirection: "row", alignItems: "center", gap: 12, padding: 14, borderRadius: 14, borderWidth: 1.5, marginTop: 12, shadowColor: "#000", shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 4, elevation: 2 },
  raporIcon: { width: 42, height: 42, borderRadius: 10, alignItems: "center", justifyContent: "center" },
  raporTitle: { fontSize: 15, fontFamily: "Inter_700Bold" },
  raporSub: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
  aiPill: { paddingHorizontal: 8, paddingVertical: 3, borderRadius: 999 },
  aiPillText: { fontSize: 10, fontWeight: "800", letterSpacing: 0.5, fontFamily: "Inter_700Bold" },

  // ── Admin Veri ────────────────────────────────────────────────────
  dataRow: { flexDirection: "row", gap: 12 },
  dataBtn: { flex: 1, padding: 14, borderRadius: 14, borderWidth: 1, gap: 8 },
  dataIcon: { width: 40, height: 40, borderRadius: 20, justifyContent: "center", alignItems: "center" },
  dataLabel: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
  dataDesc: { fontSize: 11, fontFamily: "Inter_400Regular", lineHeight: 15 },

  // ── BottomSheet ───────────────────────────────────────────────────
  sheetDesc: { fontSize: 13, fontFamily: "Inter_400Regular", marginBottom: 12, lineHeight: 18 },
  label: { fontSize: 13, fontFamily: "Inter_600SemiBold", marginBottom: 6 },
  importInput: { minHeight: 120, maxHeight: 180, borderRadius: 8, padding: 10, fontSize: 12, fontFamily: Platform.OS === "ios" ? "Menlo" : "monospace", textAlignVertical: "top", borderWidth: 1 },
  msgBox: { flexDirection: "row", alignItems: "center", gap: 8, padding: 10, borderRadius: 8, marginTop: 10 },
  msgText: { flex: 1, fontSize: 12, fontFamily: "Inter_500Medium" },
  cancelBtn: { alignItems: "center", paddingVertical: 12, marginTop: 4 },
  cancelText: { fontSize: 13, fontFamily: "Inter_500Medium" },
  filePickBtn: { flexDirection: "row", alignItems: "center", gap: 12, padding: 14, borderRadius: 12, borderWidth: 1.5, marginBottom: 4 },
  filePickIcon: { width: 44, height: 44, borderRadius: 22, justifyContent: "center", alignItems: "center" },
  filePickLabel: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
  filePickSub: { fontSize: 11, fontFamily: "Inter_400Regular", marginTop: 2 },

  // ── Renk Seçici Modal ──────────────────────────────────────────────
  cpOverlay: { flex: 1, backgroundColor: "rgba(0,0,0,0.45)", justifyContent: "center", alignItems: "center" },
  cpSheet: { width: 320, borderRadius: 20, padding: 20, shadowColor: "#000", shadowOffset: { width: 0, height: 8 }, shadowOpacity: 0.18, shadowRadius: 24, elevation: 20 },
  cpHeader: { flexDirection: "row", alignItems: "center", gap: 10, marginBottom: 18 },
  cpDot: { width: 16, height: 16, borderRadius: 8 },
  cpTitle: { flex: 1, fontSize: 16, fontFamily: "Inter_700Bold" },
  cpModeRow: { flexDirection: "row", gap: 10, marginBottom: 20 },
  cpModeBtn: { flex: 1, borderRadius: 12, borderWidth: 1.5, paddingVertical: 10, paddingHorizontal: 12, alignItems: "center", gap: 8 },
  cpModeAccentDemo: { width: 28, height: 28, borderRadius: 6, borderLeftWidth: 4, borderLeftColor: "transparent", position: "relative" },
  cpModeFillDemo: { width: 28, height: 28, borderRadius: 6, borderWidth: 1.5 },
  cpModeLbl: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
  cpPalette: { flexDirection: "row", flexWrap: "wrap", gap: 10, justifyContent: "center", marginBottom: 20 },
  cpSwatch: { width: 40, height: 40, borderRadius: 20 },
  cpSwatchActive: { borderWidth: 3, borderColor: "#fff", shadowColor: "#000", shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.25, shadowRadius: 4, elevation: 4, transform: [{ scale: 1.15 }] },
  cpActions: { flexDirection: "row", gap: 10 },
  cpResetBtn: { flex: 1, flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 6, borderRadius: 12, borderWidth: 1.5, paddingVertical: 12 },
  cpResetTxt: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
  cpApplyBtn: { flex: 2, flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 6, borderRadius: 12, paddingVertical: 12 },
  cpApplyTxt: { fontSize: 13, fontFamily: "Inter_600SemiBold", color: "#fff" },
});
