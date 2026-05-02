import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useMemo, useState } from "react";
import {
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import EmptyState from "@/components/EmptyState";
import ProjectPicker from "@/components/ProjectPicker";
import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

type Tab = "malzeme" | "iscilik";

type Row = {
  key: string;
  description: string;
  unit: string;
  planned: number;
  actual: number;
  unitPrice: number;
};

function pctColor(p: number) {
  if (p >= 80) return "#16a34a";
  if (p >= 50) return "#d97706";
  if (p > 0) return "#dc2626";
  return "#94a3b8";
}

function fmt(n: number) {
  if (!isFinite(n)) return "0";
  if (Math.abs(n) >= 1000) return n.toLocaleString("tr-TR", { maximumFractionDigits: 0 });
  return n.toLocaleString("tr-TR", { maximumFractionDigits: 2 });
}

export default function IlerlemeScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;

  const { projects, surveys, productions, materials, materialList } = useApp();
  const [filter, setFilter] = useState<string | null>(projects[0]?.id ?? null);
  const [tab, setTab] = useState<Tab>("malzeme");

  const projectId = filter || projects[0]?.id || "";

  const materialNamesLower = useMemo(
    () => new Set(materialList.map((m) => m.name.trim().toLowerCase())),
    [materialList]
  );

  const surveyItems = useMemo(() => {
    return surveys
      .filter((s) => s.projectId === projectId)
      .flatMap((s) => s.items.map((it) => ({ ...it, surveyTitle: s.title })));
  }, [surveys, projectId]);

  const projectMaterials = useMemo(
    () => materials.filter((m) => m.projectId === projectId),
    [materials, projectId]
  );

  const projectProductions = useMemo(
    () => productions.filter((p) => p.projectId === projectId),
    [productions, projectId]
  );

  const malzemeRows: Row[] = useMemo(() => {
    const map = new Map<string, Row>();
    for (const it of surveyItems) {
      const desc = it.description.trim();
      if (!desc) continue;
      const key = desc.toLowerCase();
      if (!materialNamesLower.has(key)) continue;
      const cur = map.get(key);
      if (cur) {
        cur.planned += it.quantity || 0;
      } else {
        map.set(key, {
          key,
          description: desc,
          unit: it.unit || "",
          planned: it.quantity || 0,
          actual: 0,
          unitPrice: it.unitPrice || 0,
        });
      }
    }
    for (const m of projectMaterials) {
      const key = m.name.trim().toLowerCase();
      const cur = map.get(key);
      if (cur) {
        cur.actual += m.quantity || 0;
      }
    }
    return Array.from(map.values()).sort((a, b) => a.description.localeCompare(b.description, "tr"));
  }, [surveyItems, projectMaterials, materialNamesLower]);

  const iscilikRows: Row[] = useMemo(() => {
    const map = new Map<string, Row>();
    for (const it of surveyItems) {
      const desc = it.description.trim();
      if (!desc) continue;
      const key = desc.toLowerCase();
      if (materialNamesLower.has(key)) continue;
      const cur = map.get(key);
      if (cur) {
        cur.planned += it.quantity || 0;
      } else {
        map.set(key, {
          key,
          description: desc,
          unit: it.unit || "",
          planned: it.quantity || 0,
          actual: 0,
          unitPrice: it.unitPrice || 0,
        });
      }
    }
    for (const p of projectProductions) {
      const key = p.name.trim().toLowerCase();
      const cur = map.get(key);
      if (cur) {
        cur.actual += p.completedQty || 0;
      }
    }
    return Array.from(map.values()).sort((a, b) => a.description.localeCompare(b.description, "tr"));
  }, [surveyItems, projectProductions, materialNamesLower]);

  const rows = tab === "malzeme" ? malzemeRows : iscilikRows;

  const totals = useMemo(() => {
    let plannedValue = 0;
    let actualValue = 0;
    for (const r of rows) {
      plannedValue += r.planned * r.unitPrice;
      actualValue += Math.min(r.actual, r.planned) * r.unitPrice;
    }
    const valuePct = plannedValue > 0 ? Math.round((actualValue / plannedValue) * 100) : 0;
    const itemsCompleted = rows.filter((r) => r.planned > 0 && r.actual >= r.planned).length;
    return { plannedValue, actualValue, valuePct, itemsCompleted };
  }, [rows]);

  const noProject = !projectId || projects.length === 0;

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <View style={[styles.header, { backgroundColor: colors.secondary, paddingTop: topPad + 12 }]}>
        <TouchableOpacity
          onPress={() => (router.canGoBack() ? router.back() : router.replace("/" as any))}
          style={styles.backBtn}
        >
          <Feather name="arrow-left" size={22} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.secondaryForeground }]}>İlerleme</Text>
        <View style={{ width: 40 }} />
      </View>

      <ProjectPicker projects={projects} value={filter} onChange={setFilter} includeAll={false} />

      {noProject ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="İlerlemeyi izlemek için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : (
        <>
          <View style={[styles.tabBar, { backgroundColor: colors.card }]}>
            {(
              [
                { key: "malzeme" as Tab, label: "Malzeme", icon: "package" as const },
                { key: "iscilik" as Tab, label: "İşçilik / İmalat", icon: "tool" as const },
              ]
            ).map((t) => {
              const sel = tab === t.key;
              return (
                <TouchableOpacity
                  key={t.key}
                  style={[styles.tabBtn, sel && { backgroundColor: colors.primary }]}
                  onPress={() => setTab(t.key)}
                  activeOpacity={0.8}
                >
                  <Feather name={t.icon} size={14} color={sel ? "#fff" : colors.mutedForeground} />
                  <Text style={[styles.tabText, { color: sel ? "#fff" : colors.mutedForeground }]}>
                    {t.label}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>

          <ScrollView
            contentContainerStyle={[styles.scroll, { paddingBottom: insets.bottom + 24 }]}
            showsVerticalScrollIndicator={false}
          >
            <View style={[styles.summary, { backgroundColor: colors.card, borderColor: colors.border }]}>
              <View style={styles.sumHead}>
                <Text style={[styles.sumTitle, { color: colors.foreground }]}>Genel İlerleme</Text>
                <View style={[styles.bigPct, { backgroundColor: pctColor(totals.valuePct) + "22" }]}>
                  <Text style={[styles.bigPctText, { color: pctColor(totals.valuePct) }]}>
                    %{totals.valuePct}
                  </Text>
                </View>
              </View>
              <View style={[styles.barTrack, { backgroundColor: colors.muted }]}>
                <View
                  style={{
                    width: `${Math.min(100, totals.valuePct)}%`,
                    height: "100%",
                    backgroundColor: pctColor(totals.valuePct),
                    borderRadius: 999,
                  }}
                />
              </View>
              <View style={styles.statsRow}>
                <View style={styles.stat}>
                  <Text style={[styles.statLabel, { color: colors.mutedForeground }]}>Kalem</Text>
                  <Text style={[styles.statVal, { color: colors.foreground }]}>{rows.length}</Text>
                </View>
                <View style={styles.stat}>
                  <Text style={[styles.statLabel, { color: colors.mutedForeground }]}>Tamamlanan</Text>
                  <Text style={[styles.statVal, { color: "#16a34a" }]}>{totals.itemsCompleted}</Text>
                </View>
                <View style={styles.stat}>
                  <Text style={[styles.statLabel, { color: colors.mutedForeground }]}>Keşif Bedeli</Text>
                  <Text style={[styles.statVal, { color: colors.foreground }]}>
                    {fmt(totals.plannedValue)} ₺
                  </Text>
                </View>
                <View style={styles.stat}>
                  <Text style={[styles.statLabel, { color: colors.mutedForeground }]}>Gerçekleşen</Text>
                  <Text style={[styles.statVal, { color: colors.primary }]}>
                    {fmt(totals.actualValue)} ₺
                  </Text>
                </View>
              </View>
            </View>

            {rows.length === 0 ? (
              <View style={[styles.emptyCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
                <Feather name="inbox" size={28} color={colors.mutedForeground} />
                <Text style={[styles.emptyTitle, { color: colors.foreground }]}>
                  {tab === "malzeme" ? "Malzeme kalemi yok" : "İşçilik kalemi yok"}
                </Text>
                <Text style={[styles.emptySub, { color: colors.mutedForeground }]}>
                  {tab === "malzeme"
                    ? "Keşif sayfasına malzeme kalemleri ekleyin ve teslim alınan malzemelerle ilerleme otomatik hesaplansın."
                    : "Keşif veya İmalat sayfasından iş kalemleri ekleyin; gerçekleşmeler ile ilerleme otomatik hesaplansın."}
                </Text>
              </View>
            ) : (
              <View style={[styles.table, { backgroundColor: colors.card, borderColor: colors.border }]}>
                <View style={[styles.thead, { borderBottomColor: colors.border }]}>
                  <Text style={[styles.thDesc, { color: colors.mutedForeground }]}>İş / Malzeme</Text>
                  <Text style={[styles.thNum, { color: colors.mutedForeground }]}>Keşif</Text>
                  <Text style={[styles.thNum, { color: colors.mutedForeground }]}>Gerçek</Text>
                  <Text style={[styles.thPct, { color: colors.mutedForeground }]}>%</Text>
                </View>
                {rows.map((r) => {
                  const pct = r.planned > 0 ? Math.round((r.actual / r.planned) * 100) : 0;
                  const c = pctColor(pct);
                  const noPlan = r.planned === 0;
                  return (
                    <View key={r.key} style={[styles.trow, { borderBottomColor: colors.border }]}>
                      <View style={styles.descCell}>
                        <Text
                          style={[styles.descText, { color: colors.foreground }]}
                          numberOfLines={2}
                        >
                          {r.description}
                        </Text>
                        {r.unit ? (
                          <Text style={[styles.unitText, { color: colors.mutedForeground }]}>
                            {r.unit}
                          </Text>
                        ) : null}
                      </View>
                      <Text style={[styles.numCell, { color: colors.foreground }]}>
                        {fmt(r.planned)}
                      </Text>
                      <Text style={[styles.numCell, { color: colors.foreground }]}>
                        {fmt(r.actual)}
                      </Text>
                      <View style={styles.pctCell}>
                        {noPlan ? (
                          <Text style={[styles.noPlanText, { color: colors.mutedForeground }]}>—</Text>
                        ) : (
                          <>
                            <View style={[styles.pctBadge, { backgroundColor: c + "22" }]}>
                              <Text style={[styles.pctBadgeText, { color: c }]}>%{pct}</Text>
                            </View>
                            <View style={[styles.miniBar, { backgroundColor: colors.muted }]}>
                              <View
                                style={{
                                  width: `${Math.min(100, pct)}%`,
                                  height: "100%",
                                  backgroundColor: c,
                                  borderRadius: 999,
                                }}
                              />
                            </View>
                          </>
                        )}
                      </View>
                    </View>
                  );
                })}
              </View>
            )}
          </ScrollView>
        </>
      )}
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
  backBtn: { width: 40, height: 40, borderRadius: 20, alignItems: "center", justifyContent: "center" },
  headerTitle: { flex: 1, fontSize: 18, textAlign: "center", fontFamily: "Inter_700Bold" },

  tabBar: { flexDirection: "row", padding: 4, marginHorizontal: 16, marginTop: 12, borderRadius: 10, gap: 4 },
  tabBtn: {
    flex: 1,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
    paddingVertical: 10,
    borderRadius: 8,
  },
  tabText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },

  scroll: { padding: 16, gap: 12 },

  summary: { borderRadius: 14, borderWidth: 1, padding: 16, gap: 12 },
  sumHead: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  sumTitle: { fontSize: 15, fontFamily: "Inter_700Bold" },
  bigPct: { paddingHorizontal: 14, paddingVertical: 6, borderRadius: 999 },
  bigPctText: { fontSize: 18, fontFamily: "Inter_700Bold" },
  barTrack: { height: 8, borderRadius: 999, overflow: "hidden" },
  statsRow: { flexDirection: "row", gap: 8 },
  stat: { flex: 1, alignItems: "center" },
  statLabel: { fontSize: 10, fontFamily: "Inter_500Medium", marginBottom: 2 },
  statVal: { fontSize: 13, fontFamily: "Inter_700Bold", textAlign: "center" },

  table: { borderRadius: 14, borderWidth: 1, marginTop: 4, overflow: "hidden" },
  thead: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderBottomWidth: 1,
    gap: 8,
  },
  thDesc: { flex: 2.4, fontSize: 11, fontFamily: "Inter_700Bold", textTransform: "uppercase", letterSpacing: 0.5 },
  thNum: { flex: 0.9, fontSize: 11, fontFamily: "Inter_700Bold", textAlign: "right", textTransform: "uppercase" },
  thPct: { flex: 1.4, fontSize: 11, fontFamily: "Inter_700Bold", textAlign: "right", textTransform: "uppercase" },

  trow: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    gap: 8,
  },
  descCell: { flex: 2.4 },
  descText: { fontSize: 13, fontFamily: "Inter_600SemiBold", lineHeight: 17 },
  unitText: { fontSize: 10, fontFamily: "Inter_400Regular", marginTop: 2 },
  numCell: { flex: 0.9, fontSize: 12, fontFamily: "Inter_500Medium", textAlign: "right" },
  pctCell: { flex: 1.4, alignItems: "flex-end", gap: 4 },
  pctBadge: { paddingHorizontal: 8, paddingVertical: 3, borderRadius: 999 },
  pctBadgeText: { fontSize: 11, fontFamily: "Inter_700Bold" },
  miniBar: { width: "100%", height: 4, borderRadius: 999, overflow: "hidden" },
  noPlanText: { fontSize: 14, fontFamily: "Inter_500Medium" },

  emptyCard: {
    borderRadius: 14,
    borderWidth: 1,
    padding: 24,
    alignItems: "center",
    gap: 8,
  },
  emptyTitle: { fontSize: 14, fontFamily: "Inter_700Bold", marginTop: 6 },
  emptySub: { fontSize: 12, fontFamily: "Inter_400Regular", textAlign: "center", lineHeight: 17 },
});
