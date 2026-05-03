import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useEffect, useMemo, useState } from "react";
import {
  FlatList,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";

import BottomSheet from "@/components/BottomSheet";
import DatePickerInput from "@/components/DatePickerInput";
import EmptyState from "@/components/EmptyState";
import FormInput from "@/components/FormInput";
import Header from "@/components/Header";
import PrimaryButton from "@/components/PrimaryButton";
import { DailyReport, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

function todayStr() {
  const d = new Date();
  return `${String(d.getDate()).padStart(2, "0")}.${String(d.getMonth() + 1).padStart(2, "0")}.${d.getFullYear()}`;
}

function dateAliases(s: string): string[] {
  if (!s) return [];
  const ymd = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s.trim());
  if (ymd) return [s.trim(), `${ymd[3]}.${ymd[2]}.${ymd[1]}`];
  const dmy = /^(\d{2})\.(\d{2})\.(\d{4})$/.exec(s.trim());
  if (dmy) return [s.trim(), `${dmy[3]}-${dmy[2]}-${dmy[1]}`];
  return [s.trim()];
}

function fmtTL(n: number) {
  return new Intl.NumberFormat("tr-TR", { maximumFractionDigits: 0 }).format(n) + " ₺";
}

function fmtNum(n: number) {
  return new Intl.NumberFormat("tr-TR", { maximumFractionDigits: 2 }).format(n);
}

interface F {
  projectId: string;
  date: string;
  weather: string;
  temperature: string;
  workerCount: string;
  activities: string;
  issues: string;
  createdBy: string;
}

const EMPTY: F = {
  projectId: "",
  date: todayStr(),
  weather: "",
  temperature: "",
  workerCount: "",
  activities: "",
  issues: "",
  createdBy: "",
};

const WEATHER_OPTS = ["Güneşli", "Bulutlu", "Yağmurlu", "Karlı", "Rüzgarlı"];

interface SectionCard {
  key: string;
  icon: string;
  title: string;
  color: string;
  bg: string;
  metric: string;
  lines: string[];
}

interface AutoSummary {
  cards: SectionCard[];
  workerCount: number;
  issues: string[];
}

export default function GunlukRaporScreen() {
  const colors = useColors();
  const router = useRouter();
  const {
    projects,
    dailyReports,
    addDailyReport,
    updateDailyReport,
    deleteDailyReport,
    attendance,
    productions,
    tasks,
    materials,
    weighbridges,
    appUsers,
  } = useApp();

  const perm = usePermission("gunluk-rapor");
  const canEdit = perm === "edit";
  useEffect(() => { if (perm === "none") { if (router.canGoBack()) router.back(); else router.replace("/"); } }, [perm]);

  const [filter, setFilter] = useState<string | null>(null);
  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<F>(EMPTY);

  const [searchText, setSearchText] = useState("");
  const [searchDate, setSearchDate] = useState("");
  const hasFilter = !!(searchText.trim() || searchDate.trim());

  const list = useMemo(() => {
    let arr = filter ? dailyReports.filter((r) => r.projectId === filter) : dailyReports;
    const q = searchText.trim().toLocaleLowerCase("tr-TR");
    const d = searchDate.trim();
    if (q) {
      arr = arr.filter((r) =>
        [r.activities, r.issues, r.createdBy, r.weather, r.temperature]
          .filter(Boolean)
          .join(" ")
          .toLocaleLowerCase("tr-TR")
          .includes(q)
      );
    }
    if (d) arr = arr.filter((r) => r.date === d);
    return [...arr].sort((a, b) => b.date.localeCompare(a.date));
  }, [dailyReports, filter, searchText, searchDate]);

  function clearFilters() {
    setSearchText("");
    setSearchDate("");
  }

  function open(r?: DailyReport) {
    if (r) {
      setEditId(r.id);
      setForm({
        projectId: r.projectId,
        date: r.date,
        weather: r.weather,
        temperature: r.temperature,
        workerCount: String(r.workerCount || ""),
        activities: r.activities,
        issues: r.issues,
        createdBy: r.createdBy,
      });
    } else {
      setEditId(null);
      setForm({ ...EMPTY, projectId: filter || projects[0]?.id || "" });
    }
    setVisible(true);
  }

  function buildAutoSummary(projectId: string, dateStr: string): AutoSummary {
    const dates = dateAliases(dateStr);
    const same = (d?: string) => !!d && dates.includes(d);
    const cards: SectionCard[] = [];
    const issues: string[] = [];
    let workerCount = 0;

    // PUANTAJ
    const att = attendance.filter((a) => a.projectId === projectId && same(a.date));
    if (att.length) {
      const cnt = (st: string) => att.filter((a) => a.status === st).length;
      const present = cnt("present");
      const half = cnt("half");
      const absent = cnt("absent");
      const izinli = cnt("izinli");
      const raporlu = cnt("raporlu");
      const mazeret = cnt("mazeret");
      const tatil = cnt("tatil");
      const totalHours = att.reduce((s, a) => s + (a.hours || 0), 0);
      workerCount = present + half;
      const lines: string[] = [];
      const parts: string[] = [`${present} tam`];
      if (half) parts.push(`${half} yarım`);
      if (izinli) parts.push(`${izinli} izinli`);
      if (raporlu) parts.push(`${raporlu} raporlu`);
      if (mazeret) parts.push(`${mazeret} mazeret`);
      if (tatil) parts.push(`${tatil} tatil`);
      if (absent) parts.push(`${absent} gelmedi`);
      lines.push(parts.join(" · "));
      lines.push(`Toplam ${fmtNum(totalHours)} saat`);

      // Meslek grubu kırılımı (sadece çalışanlar: tam + yarım)
      const userById = new Map(appUsers.map(u => [u.id, u] as const));
      const groupMap = new Map<string, { count: number; profs: Map<string, number> }>();
      for (const a of att) {
        if (a.status !== "present" && a.status !== "half") continue;
        const u = userById.get(a.workerId);
        const group = ((u?.team || "").trim()) || "Diğer";
        const prof = ((u?.profession || "").trim()) || "Çalışan";
        let g = groupMap.get(group);
        if (!g) { g = { count: 0, profs: new Map() }; groupMap.set(group, g); }
        g.count += 1;
        g.profs.set(prof, (g.profs.get(prof) || 0) + 1);
      }
      if (groupMap.size > 0) {
        const ordered = Array.from(groupMap.entries()).sort((a, b) => b[1].count - a[1].count);
        for (const [grp, info] of ordered) {
          let topProf = "Çalışan"; let topN = -1;
          for (const [p, n] of info.profs) { if (n > topN) { topProf = p; topN = n; } }
          lines.push(`${grp} - ${info.count} ${topProf}`);
        }
      }

      cards.push({
        key: "puantaj",
        icon: "users",
        title: "Puantaj",
        color: "#0ea5e9",
        bg: "#0ea5e91a",
        metric: `${workerCount} kişi`,
        lines,
      });
    }

    // İMALAT
    const prods = productions.filter((p) => p.projectId === projectId && same(p.date));
    if (prods.length) {
      const lines = prods.slice(0, 4).map((p) => {
        const pct = p.plannedQty > 0 ? Math.round((p.completedQty / p.plannedQty) * 100) : 0;
        return `${p.name}: ${fmtNum(p.completedQty)} ${p.unit}${p.plannedQty ? ` (%${pct})` : ""}`;
      });
      if (prods.length > 4) lines.push(`+${prods.length - 4} kalem daha`);
      cards.push({
        key: "imalat",
        icon: "tool",
        title: "İmalat",
        color: "#16a34a",
        bg: "#16a34a1a",
        metric: `${prods.length} kalem`,
        lines,
      });
    }

    // GÖREV
    const projTasks = tasks.filter((t) => t.projectId === projectId);
    const doneToday = projTasks.filter((t) => t.status === "done" && same(t.deadline));
    const dueToday = projTasks.filter((t) => same(t.deadline) && t.status !== "done");
    const ymdToday = dates.find((d) => /^\d{4}-\d{2}-\d{2}$/.test(d)) || "";
    const overdue = ymdToday
      ? projTasks.filter((t) => t.status !== "done" && t.deadline && /^\d{4}-\d{2}-\d{2}$/.test(t.deadline) && t.deadline < ymdToday)
      : [];
    if (doneToday.length || dueToday.length || overdue.length) {
      const lines: string[] = [];
      if (doneToday.length) lines.push(`${doneToday.length} tamamlandı`);
      if (dueToday.length) lines.push(`${dueToday.length} bugün vadeli (açık)`);
      if (overdue.length) lines.push(`${overdue.length} gecikmiş`);
      for (const t of doneToday.slice(0, 3)) lines.push(`Bitti: ${t.title}`);
      if (overdue.length) {
        for (const t of overdue.slice(0, 3)) issues.push(`Gecikmiş görev: ${t.title}${t.assignee ? ` (${t.assignee})` : ""}`);
      }
      cards.push({
        key: "gorev",
        icon: "check-square",
        title: "Görevler",
        color: overdue.length ? "#dc2626" : "#7c3aed",
        bg: overdue.length ? "#dc26261a" : "#7c3aed1a",
        metric: `${doneToday.length}/${doneToday.length + dueToday.length}`,
        lines,
      });
    }

    // İLERLEME (proje genel)
    const allProds = productions.filter((p) => p.projectId === projectId);
    if (allProds.length) {
      const tp = allProds.reduce((s, p) => s + (p.plannedQty || 0), 0);
      const tc = allProds.reduce((s, p) => s + (p.completedQty || 0), 0);
      const overallPct = tp > 0 ? Math.round((tc / tp) * 100) : 0;
      cards.push({
        key: "ilerleme",
        icon: "bar-chart-2",
        title: "Proje İlerleme",
        color: "#1d4ed8",
        bg: "#1d4ed81a",
        metric: `%${overallPct}`,
        lines: [`${allProds.length} imalat kalemi üzerinden`],
      });
    }

    // MALZEME
    const matsToday = materials.filter((m) => m.projectId === projectId && same(m.deliveryDate));
    if (matsToday.length) {
      const totalVal = matsToday.reduce((s, m) => s + (m.quantity || 0) * (m.unitPrice || 0), 0);
      const lines = matsToday.slice(0, 4).map((m) => `${m.name}: ${fmtNum(m.quantity)} ${m.unit}${m.supplier ? ` · ${m.supplier}` : ""}`);
      if (matsToday.length > 4) lines.push(`+${matsToday.length - 4} kalem daha`);
      if (totalVal) lines.push(`Toplam: ${fmtTL(totalVal)}`);
      cards.push({
        key: "malzeme",
        icon: "package",
        title: "Malzeme (Gelen)",
        color: "#ea580c",
        bg: "#ea580c1a",
        metric: `${matsToday.length} kalem`,
        lines,
      });
    }

    // KANTAR
    const kantarToday = weighbridges.filter((w) => w.projectId === projectId && same(w.date));
    if (kantarToday.length) {
      const totalNet = kantarToday.reduce((s, w) => s + (w.netWeight || 0), 0);
      const bySupplier = new Map<string, number>();
      for (const w of kantarToday) bySupplier.set(w.supplier || "—", (bySupplier.get(w.supplier || "—") || 0) + (w.netWeight || 0));
      const lines: string[] = [`Toplam net: ${fmtNum(totalNet / 1000)} ton`];
      for (const [sup, net] of Array.from(bySupplier.entries()).slice(0, 4)) {
        lines.push(`${sup}: ${fmtNum(net / 1000)} ton`);
      }
      cards.push({
        key: "kantar",
        icon: "truck",
        title: "Kantar",
        color: "#9333ea",
        bg: "#9333ea1a",
        metric: `${kantarToday.length} fiş`,
        lines,
      });
    }

    return { cards, workerCount, issues };
  }

  function autoFill() {
    if (!form.projectId || !form.date.trim()) return;
    const r = buildAutoSummary(form.projectId, form.date);
    if (r.workerCount > 0 && !form.workerCount) {
      setForm({ ...form, workerCount: String(r.workerCount) });
    }
  }

  function save() {
    if (!form.projectId || !form.date.trim()) return;
    const data = {
      projectId: form.projectId,
      date: form.date.trim(),
      weather: form.weather,
      temperature: form.temperature.trim(),
      workerCount: parseInt(form.workerCount) || 0,
      activities: form.activities.trim(),
      issues: form.issues.trim(),
      createdBy: form.createdBy.trim(),
    };
    if (editId) updateDailyReport(editId, data);
    else addDailyReport(data);
    setVisible(false);
  }

  function remove() {
    if (editId) deleteDailyReport(editId);
    setVisible(false);
  }

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Günlük Rapor"
        onBack={() => (router.canGoBack() ? router.back() : router.replace("/"))}
        rightAction={canEdit && projects.length > 0 ? { icon: "plus", onPress: () => open() } : undefined}
      />


      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="Günlük rapor için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : (
        <View style={[styles.filterBar, { borderBottomColor: colors.border, backgroundColor: colors.card }]}>
          <View style={styles.filterRow}>
            <View style={[styles.searchBox, { backgroundColor: colors.muted, flex: 1 }]}>
              <Feather name="search" size={13} color={colors.mutedForeground} />
              <TextInput
                value={searchText}
                onChangeText={setSearchText}
                placeholder="Faaliyet, sorun, hava, ekleyen..."
                placeholderTextColor={colors.mutedForeground}
                style={[styles.searchInput, { color: colors.foreground }]}
              />
            </View>
          </View>
          <View style={styles.filterRow}>
            <View style={{ flex: 1 }}>
              <DatePickerInput value={searchDate} onChange={setSearchDate} />
            </View>
            {hasFilter ? (
              <TouchableOpacity onPress={clearFilters} style={[styles.clearBtn, { backgroundColor: colors.muted }]} activeOpacity={0.7}>
                <Feather name="x" size={14} color={colors.foreground} />
                <Text style={[styles.clearBtnText, { color: colors.foreground }]}>Temizle</Text>
              </TouchableOpacity>
            ) : null}
          </View>
        </View>
      )}

      {projects.length === 0 ? null : list.length === 0 ? (
        <EmptyState
          icon="file-text"
          title="Rapor yok"
          description="Bugünün raporunu girmek için + düğmesine dokunun"
          actionLabel="Rapor Ekle"
          onAction={() => open()}
        />
      ) : (
        <FlatList
          data={list}
          keyExtractor={(r) => r.id}
          contentContainerStyle={styles.list}
          renderItem={({ item }) => {
            const summary = buildAutoSummary(item.projectId, item.date);
            const issuesCombined = [item.issues, summary.issues.join("\n")].filter(Boolean).join("\n").trim();
            return (
              <TouchableOpacity
                style={[styles.card, { backgroundColor: colors.card }]}
                activeOpacity={0.85}
                onPress={() => open(item)}
              >
                <View style={styles.head}>
                  <View style={{ flex: 1 }}>
                    <Text style={[styles.proj, { color: colors.primary }]}>
                      {projectName(item.projectId)}
                    </Text>
                    <Text style={[styles.date, { color: colors.foreground }]}>
                      {item.date}
                    </Text>
                  </View>
                  <View style={styles.metaRow}>
                    {item.weather ? (
                      <View style={[styles.tag, { backgroundColor: colors.muted }]}>
                        <Text style={[styles.tagText, { color: colors.foreground }]}>
                          {item.weather}
                          {item.temperature ? ` ${item.temperature}°` : ""}
                        </Text>
                      </View>
                    ) : null}
                    {item.workerCount > 0 ? (
                      <View style={[styles.tag, { backgroundColor: colors.muted }]}>
                        <Feather name="users" size={11} color={colors.foreground} />
                        <Text style={[styles.tagText, { color: colors.foreground }]}>
                          {item.workerCount}
                        </Text>
                      </View>
                    ) : null}
                  </View>
                </View>

                {summary.cards.length > 0 ? (
                  <View style={styles.modCardGrid}>
                    {summary.cards.map((sc) => (
                      <View
                        key={sc.key}
                        style={[styles.modCard, { backgroundColor: sc.bg, borderColor: sc.color + "33" }]}
                      >
                        <View style={styles.modCardHead}>
                          <Feather name={sc.icon as any} size={13} color={sc.color} />
                          <Text style={[styles.modCardTitle, { color: sc.color }]}>{sc.title}</Text>
                          <Text style={[styles.modCardMetric, { color: sc.color }]}>{sc.metric}</Text>
                        </View>
                        {sc.lines.map((ln, i) => (
                          <Text
                            key={i}
                            style={[styles.modCardLine, { color: colors.foreground }]}
                            numberOfLines={2}
                          >
                            {ln}
                          </Text>
                        ))}
                      </View>
                    ))}
                  </View>
                ) : (
                  <Text style={[styles.emptySummary, { color: colors.mutedForeground }]}>
                    Bu tarih için modül verisi yok. Puantaj, imalat, görev, malzeme vs. eklediğinizde burada özet kartları görünür.
                  </Text>
                )}

                {item.activities ? (
                  <View style={[styles.notesBox, { backgroundColor: colors.muted }]}>
                    <Feather name="file-text" size={12} color={colors.mutedForeground} />
                    <Text style={[styles.notesText, { color: colors.foreground }]} numberOfLines={4}>
                      {item.activities}
                    </Text>
                  </View>
                ) : null}

                {issuesCombined ? (
                  <View style={[styles.issueBox, { backgroundColor: "#fee2e2" }]}>
                    <Feather name="alert-triangle" size={13} color="#dc2626" />
                    <Text style={[styles.issueText, { color: "#dc2626" }]} numberOfLines={4}>
                      {issuesCombined}
                    </Text>
                  </View>
                ) : null}

                {item.createdBy ? (
                  <Text style={[styles.byline, { color: colors.mutedForeground }]}>
                    Hazırlayan: {item.createdBy}
                  </Text>
                ) : null}
              </TouchableOpacity>
            );
          }}
        />
      )}

      <BottomSheet
        visible={visible}
        onClose={() => setVisible(false)}
        title={editId ? "Raporu Düzenle" : "Yeni Günlük Rapor"}
      >
        <Text style={[styles.label, { color: colors.foreground }]}>Proje</Text>
        <View style={styles.chips}>
          {projects.map((p) => (
            <TouchableOpacity
              key={p.id}
              onPress={() => setForm({ ...form, projectId: p.id })}
              style={[styles.chip, { backgroundColor: form.projectId === p.id ? colors.primary : colors.muted }]}
            >
              <Text style={[styles.chipText, { color: form.projectId === p.id ? "#fff" : colors.foreground }]}>
                {p.name}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <DatePickerInput
          label="Tarih"
          value={form.date}
          onChange={(v) => setForm({ ...form, date: v })}
        />

        <Text style={[styles.label, { color: colors.foreground }]}>Hava Durumu</Text>
        <View style={styles.chips}>
          {WEATHER_OPTS.map((w) => (
            <TouchableOpacity
              key={w}
              onPress={() => setForm({ ...form, weather: w })}
              style={[styles.chip, { backgroundColor: form.weather === w ? colors.primary : colors.muted }]}
            >
              <Text style={[styles.chipText, { color: form.weather === w ? "#fff" : colors.foreground }]}>
                {w}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <View style={styles.row}>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Sıcaklık (°C)"
              value={form.temperature}
              onChangeText={(v) => setForm({ ...form, temperature: v })}
              keyboardType="numeric"
            />
          </View>
          <View style={{ flex: 1 }}>
            <FormInput
              label="İşçi Sayısı"
              value={form.workerCount}
              onChangeText={(v) => setForm({ ...form, workerCount: v })}
              keyboardType="numeric"
            />
          </View>
        </View>

        {canEdit ? (
          <TouchableOpacity
            onPress={autoFill}
            activeOpacity={0.85}
            style={[styles.autoBtn, { backgroundColor: colors.primary + "1a", borderColor: colors.primary }]}
          >
            <Feather name="zap" size={14} color={colors.primary} />
            <View style={{ flex: 1 }}>
              <Text style={[styles.autoBtnText, { color: colors.primary }]}>İşçi Sayısını Puantajdan Doldur</Text>
              <Text style={[styles.autoBtnSub, { color: colors.mutedForeground }]}>
                Puantaj, imalat, görev, malzeme ve kantar özetleri rapor kartında otomatik görünür.
              </Text>
            </View>
          </TouchableOpacity>
        ) : null}

        <FormInput
          label="Ek Notlar / Faaliyetler (serbest)"
          value={form.activities}
          onChangeText={(v) => setForm({ ...form, activities: v })}
          multiline
          style={{ height: 120, textAlignVertical: "top" }}
          placeholder="Modüllerde olmayan ek bilgi, ziyaretçi, denetim, hava olayı, vs."
        />
        <FormInput
          label="Sorunlar / Notlar"
          value={form.issues}
          onChangeText={(v) => setForm({ ...form, issues: v })}
          multiline
          style={{ height: 70, textAlignVertical: "top" }}
        />
        <FormInput
          label="Hazırlayan"
          value={form.createdBy}
          onChangeText={(v) => setForm({ ...form, createdBy: v })}
        />

        {canEdit ? <PrimaryButton label="Kaydet" onPress={save} style={{ marginTop: 8 }} /> : null}
        {canEdit && editId ? (
          <PrimaryButton label="Sil" variant="danger" onPress={remove} style={{ marginTop: 10 }} />
        ) : null}
        {!canEdit ? <PrimaryButton label="Kapat" onPress={() => setVisible(false)} style={{ marginTop: 8 }} /> : null}
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  list: { padding: 16, gap: 12 },
  card: {
    borderRadius: 12,
    padding: 14,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  head: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
    marginBottom: 10,
    gap: 8,
  },
  proj: { fontSize: 12, fontFamily: "Inter_600SemiBold", marginBottom: 2 },
  date: { fontSize: 16, fontFamily: "Inter_700Bold" },
  metaRow: { flexDirection: "row", gap: 6, flexWrap: "wrap", justifyContent: "flex-end" },
  tag: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 999,
  },
  tagText: { fontSize: 11, fontFamily: "Inter_500Medium" },
  modCardGrid: { gap: 8, marginTop: 4 },
  modCard: {
    borderWidth: 1,
    borderRadius: 10,
    padding: 10,
    gap: 4,
  },
  modCardHead: { flexDirection: "row", alignItems: "center", gap: 6, marginBottom: 4 },
  modCardTitle: { flex: 1, fontSize: 12, fontFamily: "Inter_700Bold" },
  modCardMetric: { fontSize: 12, fontFamily: "Inter_700Bold" },
  modCardLine: { fontSize: 11.5, fontFamily: "Inter_400Regular", lineHeight: 16 },
  emptySummary: { fontSize: 12, fontFamily: "Inter_400Regular", fontStyle: "italic", marginTop: 4 },
  notesBox: {
    flexDirection: "row",
    gap: 6,
    alignItems: "flex-start",
    padding: 10,
    borderRadius: 8,
    marginTop: 10,
  },
  notesText: { flex: 1, fontSize: 12, fontFamily: "Inter_400Regular", lineHeight: 17 },
  issueBox: {
    flexDirection: "row",
    gap: 6,
    alignItems: "flex-start",
    padding: 10,
    borderRadius: 8,
    marginTop: 10,
  },
  issueText: { flex: 1, fontSize: 12, fontFamily: "Inter_500Medium" },
  byline: { fontSize: 11, fontFamily: "Inter_500Medium", marginTop: 8, textAlign: "right" },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  chip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999 },
  chipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
  row: { flexDirection: "row", gap: 8 },
  filterBar: { paddingHorizontal: 12, paddingVertical: 10, gap: 8, borderBottomWidth: StyleSheet.hairlineWidth },
  filterRow: { flexDirection: "row", gap: 8, alignItems: "center" },
  searchBox: { flexDirection: "row", alignItems: "center", gap: 6, paddingHorizontal: 10, paddingVertical: 8, borderRadius: 8, minHeight: 38 },
  searchInput: { flex: 1, fontSize: 13, fontFamily: "Inter_500Medium", padding: 0 },
  clearBtn: { flexDirection: "row", alignItems: "center", gap: 4, paddingHorizontal: 10, paddingVertical: 8, borderRadius: 8 },
  clearBtnText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
  autoBtn: { flexDirection: "row", alignItems: "center", gap: 10, paddingHorizontal: 12, paddingVertical: 10, borderRadius: 10, borderWidth: 1, marginBottom: 12 },
  autoBtnText: { fontSize: 13, fontFamily: "Inter_700Bold" },
  autoBtnSub: { fontSize: 11, fontFamily: "Inter_400Regular", marginTop: 2 },
});
