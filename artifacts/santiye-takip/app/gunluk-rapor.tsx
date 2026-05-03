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
    purchases,
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

  function buildAutoSummary(projectId: string, dateStr: string): { text: string; workerCount: number; issues: string } {
    const dates = dateAliases(dateStr);
    const same = (d?: string) => !!d && dates.includes(d);
    const out: string[] = [];
    const issueLines: string[] = [];
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
      const parts = [`${present} tam`];
      if (half) parts.push(`${half} yarım`);
      if (izinli) parts.push(`${izinli} izinli`);
      if (raporlu) parts.push(`${raporlu} raporlu`);
      if (mazeret) parts.push(`${mazeret} mazeret`);
      if (tatil) parts.push(`${tatil} tatil`);
      if (absent) parts.push(`${absent} gelmedi`);
      out.push(`[PUANTAJ] ${workerCount} kişi sahada — ${parts.join(", ")} (toplam ${fmtNum(totalHours)} saat)`);
    }

    // İMALAT
    const prods = productions.filter((p) => p.projectId === projectId && same(p.date));
    if (prods.length) {
      out.push(`[İMALAT] ${prods.length} kalem yapıldı:`);
      for (const p of prods) {
        const pct = p.plannedQty > 0 ? Math.round((p.completedQty / p.plannedQty) * 100) : 0;
        out.push(`  - ${p.name}: ${fmtNum(p.completedQty)} ${p.unit}${p.plannedQty ? ` / planlanan ${fmtNum(p.plannedQty)} (%${pct})` : ""}`);
      }
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
      const segs: string[] = [];
      if (doneToday.length) segs.push(`${doneToday.length} görev tamamlandı`);
      if (dueToday.length) segs.push(`${dueToday.length} görev bugün vadeli (açık)`);
      if (overdue.length) segs.push(`${overdue.length} görev gecikmiş`);
      out.push(`[GÖREV] ${segs.join(" • ")}`);
      for (const t of doneToday.slice(0, 5)) out.push(`  - Bitti: ${t.title}${t.assignee ? ` (${t.assignee})` : ""}`);
      if (overdue.length) {
        for (const t of overdue.slice(0, 3)) issueLines.push(`Gecikmiş görev: ${t.title}${t.assignee ? ` (${t.assignee})` : ""}`);
      }
    }

    // İLERLEME (proje genel)
    const allProds = productions.filter((p) => p.projectId === projectId);
    if (allProds.length) {
      const tp = allProds.reduce((s, p) => s + (p.plannedQty || 0), 0);
      const tc = allProds.reduce((s, p) => s + (p.completedQty || 0), 0);
      const overallPct = tp > 0 ? Math.round((tc / tp) * 100) : 0;
      out.push(`[İLERLEME] Proje geneli: %${overallPct} (${allProds.length} imalat kalemi üzerinden)`);
    }

    // MALZEME (teslimat)
    const matsToday = materials.filter((m) => m.projectId === projectId && same(m.deliveryDate));
    if (matsToday.length) {
      const totalVal = matsToday.reduce((s, m) => s + (m.quantity || 0) * (m.unitPrice || 0), 0);
      out.push(`[MALZEME] ${matsToday.length} kalem teslim alındı${totalVal ? ` — toplam ${fmtTL(totalVal)}` : ""}:`);
      for (const m of matsToday.slice(0, 6)) {
        out.push(`  - ${m.name}: ${fmtNum(m.quantity)} ${m.unit}${m.supplier ? ` (${m.supplier})` : ""}`);
      }
    }

    // KANTAR
    const kantarToday = weighbridges.filter((w) => w.projectId === projectId && same(w.date));
    if (kantarToday.length) {
      const totalNet = kantarToday.reduce((s, w) => s + (w.netWeight || 0), 0);
      out.push(`[KANTAR] ${kantarToday.length} fiş — toplam net ${fmtNum(totalNet)} kg (${fmtNum(totalNet / 1000)} ton)`);
      const bySupplier = new Map<string, number>();
      for (const w of kantarToday) bySupplier.set(w.supplier || "—", (bySupplier.get(w.supplier || "—") || 0) + (w.netWeight || 0));
      for (const [sup, net] of Array.from(bySupplier.entries()).slice(0, 4)) {
        out.push(`  - ${sup}: ${fmtNum(net)} kg`);
      }
    }

    // SATIN ALMA
    const purchToday = purchases.filter((p) => p.projectId === projectId && same(p.date));
    if (purchToday.length) {
      const totalKDVli = purchToday.reduce((s, p) => s + (p.quantity || 0) * (p.unitPrice || 0) * (1 + (p.vatRate || 0) / 100), 0);
      const pending = purchToday.filter((p) => p.status === "pending").length;
      out.push(`[SATIN ALMA] ${purchToday.length} sipariş — toplam ${fmtTL(totalKDVli)} (KDV dahil)${pending ? ` • ${pending} bekleyen` : ""}`);
      for (const p of purchToday.slice(0, 5)) {
        out.push(`  - ${p.itemName}: ${fmtNum(p.quantity)} ${p.unit} • ${p.supplier}`);
      }
    }

    if (!out.length) {
      out.push("Bu tarih için kayıt bulunamadı. Modüllere veri girdikten sonra tekrar deneyin.");
    }

    return { text: out.join("\n"), workerCount, issues: issueLines.join("\n") };
  }

  function autoFill() {
    if (!form.projectId || !form.date.trim()) return;
    const r = buildAutoSummary(form.projectId, form.date);
    setForm({
      ...form,
      activities: r.text,
      workerCount: r.workerCount > 0 ? String(r.workerCount) : form.workerCount,
      issues: r.issues ? (form.issues ? form.issues + "\n" + r.issues : r.issues) : form.issues,
    });
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
          renderItem={({ item }) => (
            <TouchableOpacity
              style={[styles.card, { backgroundColor: colors.card }]}
              activeOpacity={0.85}
              onPress={() => open(item)}
            >
              <View style={styles.head}>
                <View>
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

              {item.activities ? (
                <Text
                  style={[styles.body, { color: colors.foreground }]}
                  numberOfLines={3}
                >
                  {item.activities}
                </Text>
              ) : null}
              {item.issues ? (
                <View style={[styles.issueBox, { backgroundColor: "#fee2e2" }]}>
                  <Feather name="alert-triangle" size={13} color="#dc2626" />
                  <Text style={[styles.issueText, { color: "#dc2626" }]} numberOfLines={2}>
                    {item.issues}
                  </Text>
                </View>
              ) : null}
            </TouchableOpacity>
          )}
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
              <Text style={[styles.autoBtnText, { color: colors.primary }]}>Verilerden Özet Oluştur</Text>
              <Text style={[styles.autoBtnSub, { color: colors.mutedForeground }]}>
                Puantaj, imalat, görev, ilerleme, malzeme, kantar ve satın alma verilerinden otomatik doldurur
              </Text>
            </View>
          </TouchableOpacity>
        ) : null}

        <FormInput
          label="Yapılan Faaliyetler"
          value={form.activities}
          onChangeText={(v) => setForm({ ...form, activities: v })}
          multiline
          style={{ height: 160, textAlignVertical: "top" }}
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
    marginBottom: 8,
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
  body: { fontSize: 13, fontFamily: "Inter_400Regular", lineHeight: 18, marginTop: 4 },
  issueBox: {
    flexDirection: "row",
    gap: 6,
    alignItems: "flex-start",
    padding: 10,
    borderRadius: 8,
    marginTop: 10,
  },
  issueText: { flex: 1, fontSize: 12, fontFamily: "Inter_500Medium" },
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
