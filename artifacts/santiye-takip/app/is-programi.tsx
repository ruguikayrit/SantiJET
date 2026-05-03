import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useEffect, useMemo, useState } from "react";
import {
  FlatList,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import BottomSheet from "@/components/BottomSheet";
import EmptyState from "@/components/EmptyState";
import DatePickerInput from "@/components/DatePickerInput";
import FormInput from "@/components/FormInput";
import Header from "@/components/Header";
import PrimaryButton from "@/components/PrimaryButton";
import { ScheduleTask, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

const STATUS_LABEL: Record<ScheduleTask["status"], string> = {
  planned: "Planlandı",
  in_progress: "Devam Ediyor",
  completed: "Tamamlandı",
  delayed: "Gecikti",
};
const STATUS_COLOR: Record<ScheduleTask["status"], string> = {
  planned: "#0891b2",
  in_progress: "#d97706",
  completed: "#16a34a",
  delayed: "#dc2626",
};

interface F {
  projectId: string;
  name: string;
  startDate: string;
  endDate: string;
  progress: string;
  status: ScheduleTask["status"];
  responsible: string;
}

const EMPTY: F = {
  projectId: "",
  name: "",
  startDate: "",
  endDate: "",
  progress: "0",
  status: "planned",
  responsible: "",
};

export default function IsProgramiScreen() {
  const colors = useColors();
  const router = useRouter();
  const { projects, scheduleTasks, addScheduleTask, updateScheduleTask, deleteScheduleTask } = useApp();

  const perm = usePermission("is-programi");
  const canEdit = perm === "edit";
  useEffect(() => { if (perm === "none") { if (router.canGoBack()) router.back(); else router.replace("/"); } }, [perm]);

  const [filter, setFilter] = useState<string | null>(null);
  const [view, setView] = useState<"liste" | "gantt">("gantt");
  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<F>(EMPTY);

  const list = useMemo(
    () => (filter ? scheduleTasks.filter((s) => s.projectId === filter) : scheduleTasks),
    [scheduleTasks, filter]
  );

  function open(t?: ScheduleTask) {
    if (t) {
      setEditId(t.id);
      setForm({
        projectId: t.projectId,
        name: t.name,
        startDate: t.startDate,
        endDate: t.endDate,
        progress: String(t.progress || 0),
        status: t.status,
        responsible: t.responsible,
      });
    } else {
      setEditId(null);
      setForm({ ...EMPTY, projectId: filter || projects[0]?.id || "" });
    }
    setVisible(true);
  }

  function save() {
    if (!form.projectId || !form.name.trim()) return;
    const data = {
      projectId: form.projectId,
      name: form.name.trim(),
      startDate: form.startDate.trim(),
      endDate: form.endDate.trim(),
      progress: Math.max(0, Math.min(100, parseFloat(form.progress) || 0)),
      status: form.status,
      responsible: form.responsible.trim(),
    };
    if (editId) updateScheduleTask(editId, data);
    else addScheduleTask(data);
    setVisible(false);
  }

  function remove() {
    if (editId) deleteScheduleTask(editId);
    setVisible(false);
  }

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="İş Programı"
        onBack={() => (router.canGoBack() ? router.back() : router.replace("/"))}
        rightAction={canEdit && projects.length > 0 ? { icon: "plus", onPress: () => open() } : undefined}
      />


      {projects.length > 0 ? (
        <View style={[styles.toolbar, { backgroundColor: colors.card, borderBottomColor: colors.border }]}>
          <View style={[styles.tabs, { backgroundColor: colors.muted }]}>
            <TouchableOpacity
              onPress={() => setView("gantt")}
              style={[styles.tabBtn, view === "gantt" && { backgroundColor: colors.primary }]}
              activeOpacity={0.85}
            >
              <Feather name="bar-chart-2" size={13} color={view === "gantt" ? "#fff" : colors.foreground} />
              <Text style={[styles.tabText, { color: view === "gantt" ? "#fff" : colors.foreground }]}>Gantt</Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={() => setView("liste")}
              style={[styles.tabBtn, view === "liste" && { backgroundColor: colors.primary }]}
              activeOpacity={0.85}
            >
              <Feather name="list" size={13} color={view === "liste" ? "#fff" : colors.foreground} />
              <Text style={[styles.tabText, { color: view === "liste" ? "#fff" : colors.foreground }]}>Liste</Text>
            </TouchableOpacity>
          </View>
          {projects.length > 1 ? (
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.projChips}>
              <TouchableOpacity
                onPress={() => setFilter(null)}
                style={[styles.projChip, { backgroundColor: filter === null ? colors.primary : colors.muted }]}
              >
                <Text style={[styles.projChipText, { color: filter === null ? "#fff" : colors.foreground }]}>Tümü</Text>
              </TouchableOpacity>
              {projects.map((p) => {
                const active = filter === p.id;
                return (
                  <TouchableOpacity
                    key={p.id}
                    onPress={() => setFilter(active ? null : p.id)}
                    style={[styles.projChip, { backgroundColor: active ? colors.primary : colors.muted }]}
                  >
                    <Text style={[styles.projChipText, { color: active ? "#fff" : colors.foreground }]} numberOfLines={1}>
                      {p.name}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
          ) : null}
        </View>
      ) : null}

      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="İş programı oluşturmak için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : list.length === 0 ? (
        <EmptyState
          icon="calendar"
          title="İş programı boş"
          description="Yeni iş kalemi eklemek için + düğmesine dokunun"
          actionLabel="İş Ekle"
          onAction={() => open()}
        />
      ) : view === "gantt" ? (
        list.every((t) => !t.startDate || !t.endDate) ? (
          <View style={{ padding: 16 }}>
            <View style={[styles.emptyGantt, { backgroundColor: colors.card, borderColor: colors.border }]}>
              <Feather name="calendar" size={28} color={colors.mutedForeground} />
              <Text style={[styles.emptyGanttTitle, { color: colors.foreground }]}>Gantt için tarih gerekli</Text>
              <Text style={[styles.emptyGanttSub, { color: colors.mutedForeground }]}>
                {list.length} iş kalemi var ama başlangıç/bitiş tarihi girilmemiş. Liste görünümünden tarihleri girin; Gantt otomatik oluşacaktır.
              </Text>
              <TouchableOpacity
                onPress={() => setView("liste")}
                style={[styles.emptyGanttBtn, { backgroundColor: colors.primary }]}
                activeOpacity={0.85}
              >
                <Feather name="list" size={14} color="#fff" />
                <Text style={styles.emptyGanttBtnText}>Liste Görünümüne Geç</Text>
              </TouchableOpacity>
            </View>
          </View>
        ) : (
          <GanttView
            tasks={list}
            colors={colors}
            projectName={projectName}
            onPressTask={(t) => open(t)}
            statusColor={STATUS_COLOR}
          />
        )
      ) : (
        <FlatList
          data={list}
          keyExtractor={(t) => t.id}
          contentContainerStyle={styles.list}
          renderItem={({ item }) => (
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
                  <Text style={[styles.title, { color: colors.foreground }]}>
                    {item.name}
                  </Text>
                </View>
                <View
                  style={[styles.badge, { backgroundColor: STATUS_COLOR[item.status] + "22" }]}
                >
                  <Text style={[styles.badgeText, { color: STATUS_COLOR[item.status] }]}>
                    {STATUS_LABEL[item.status]}
                  </Text>
                </View>
              </View>

              {(item.startDate || item.endDate) ? (
                <View style={styles.row}>
                  <Feather name="calendar" size={13} color={colors.mutedForeground} />
                  <Text style={[styles.meta, { color: colors.mutedForeground }]}>
                    {item.startDate || "—"} → {item.endDate || "—"}
                  </Text>
                </View>
              ) : null}
              {item.responsible ? (
                <View style={styles.row}>
                  <Feather name="user" size={13} color={colors.mutedForeground} />
                  <Text style={[styles.meta, { color: colors.mutedForeground }]}>
                    {item.responsible}
                  </Text>
                </View>
              ) : null}

              <View style={[styles.bar, { backgroundColor: colors.muted }]}>
                <View
                  style={[
                    styles.barFill,
                    {
                      width: `${item.progress}%`,
                      backgroundColor: STATUS_COLOR[item.status],
                    },
                  ]}
                />
              </View>
              <Text style={[styles.progressText, { color: colors.mutedForeground }]}>
                %{item.progress} tamamlandı
              </Text>
            </TouchableOpacity>
          )}
        />
      )}

      <BottomSheet
        visible={visible}
        onClose={() => setVisible(false)}
        title={editId ? "İşi Düzenle" : "Yeni İş Kalemi"}
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

        <FormInput
          label="İş Adı"
          value={form.name}
          onChangeText={(v) => setForm({ ...form, name: v })}
          placeholder="Örn: Temel kazısı"
        />
        <View style={styles.row2}>
          <View style={{ flex: 1 }}>
            <DatePickerInput
              label="Başlangıç"
              value={form.startDate}
              onChange={(v) => setForm({ ...form, startDate: v })}
            />
          </View>
          <View style={{ flex: 1 }}>
            <DatePickerInput
              label="Bitiş"
              value={form.endDate}
              onChange={(v) => setForm({ ...form, endDate: v })}
            />
          </View>
        </View>
        <FormInput
          label="Sorumlu"
          value={form.responsible}
          onChangeText={(v) => setForm({ ...form, responsible: v })}
        />
        <FormInput
          label="İlerleme (%)"
          value={form.progress}
          onChangeText={(v) => setForm({ ...form, progress: v })}
          keyboardType="numeric"
        />

        <Text style={[styles.label, { color: colors.foreground }]}>Durum</Text>
        <View style={styles.chips}>
          {(Object.keys(STATUS_LABEL) as ScheduleTask["status"][]).map((s) => (
            <TouchableOpacity
              key={s}
              onPress={() => setForm({ ...form, status: s })}
              style={[styles.chip, { backgroundColor: form.status === s ? STATUS_COLOR[s] : colors.muted }]}
            >
              <Text style={[styles.chipText, { color: form.status === s ? "#fff" : colors.foreground }]}>
                {STATUS_LABEL[s]}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

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
  head: { flexDirection: "row", alignItems: "flex-start", gap: 8, marginBottom: 6 },
  proj: { fontSize: 12, fontFamily: "Inter_600SemiBold", marginBottom: 2 },
  title: { fontSize: 16, fontFamily: "Inter_700Bold" },
  badge: { paddingHorizontal: 10, paddingVertical: 4, borderRadius: 999 },
  badgeText: { fontSize: 11, fontFamily: "Inter_600SemiBold" },
  row: { flexDirection: "row", alignItems: "center", gap: 6, marginTop: 4 },
  meta: { fontSize: 13, fontFamily: "Inter_400Regular" },
  bar: { height: 6, borderRadius: 3, marginTop: 12, overflow: "hidden" },
  barFill: { height: "100%", borderRadius: 3 },
  progressText: { fontSize: 11, fontFamily: "Inter_500Medium", marginTop: 6 },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  chip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999 },
  chipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
  row2: { flexDirection: "row", gap: 8 },
  toolbar: { paddingHorizontal: 12, paddingVertical: 8, gap: 8, borderBottomWidth: StyleSheet.hairlineWidth },
  tabs: { flexDirection: "row", padding: 3, borderRadius: 10, gap: 3, alignSelf: "flex-start" },
  tabBtn: { flexDirection: "row", alignItems: "center", gap: 5, paddingHorizontal: 12, paddingVertical: 6, borderRadius: 8 },
  tabText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
  projChips: { gap: 6, paddingVertical: 2 },
  projChip: { paddingHorizontal: 10, paddingVertical: 5, borderRadius: 999, maxWidth: 160 },
  projChipText: { fontSize: 11, fontFamily: "Inter_600SemiBold" },
  ganttRoot: { flex: 1, padding: 12 },
  ganttCanvas: { borderRadius: 10, borderWidth: StyleSheet.hairlineWidth, overflow: "hidden" },
  ganttHeadText: { fontSize: 11, fontFamily: "Inter_700Bold", textTransform: "uppercase", letterSpacing: 0.5 },
  ganttRowLeft: { paddingHorizontal: 10, justifyContent: "center", borderBottomWidth: StyleSheet.hairlineWidth },
  legend: { flexDirection: "row", flexWrap: "wrap", gap: 12, padding: 10, marginTop: 10, borderRadius: 8, borderWidth: StyleSheet.hairlineWidth },
  legendItem: { flexDirection: "row", alignItems: "center", gap: 6 },
  legendDot: { width: 10, height: 10, borderRadius: 3 },
  legendText: { fontSize: 11, fontFamily: "Inter_500Medium" },
  emptyGantt: { padding: 24, borderRadius: 12, borderWidth: StyleSheet.hairlineWidth, alignItems: "center", gap: 8 },
  emptyGanttTitle: { fontSize: 15, fontFamily: "Inter_700Bold", marginTop: 4 },
  emptyGanttSub: { fontSize: 12, fontFamily: "Inter_400Regular", textAlign: "center", lineHeight: 17 },
  emptyGanttBtn: { flexDirection: "row", alignItems: "center", gap: 6, paddingHorizontal: 16, paddingVertical: 10, borderRadius: 8, marginTop: 8 },
  emptyGanttBtnText: { color: "#fff", fontSize: 13, fontFamily: "Inter_600SemiBold" },
  ganttRowName: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
  ganttRowSub: { fontSize: 10, fontFamily: "Inter_400Regular", marginTop: 1 },
  ganttRight: { flex: 1 },
  ganttDayCol: { borderRightWidth: StyleSheet.hairlineWidth },
  ganttMonthLabel: { fontSize: 10, fontFamily: "Inter_700Bold", textAlign: "center", marginTop: 2 },
  ganttDayLabel: { fontSize: 10, fontFamily: "Inter_500Medium", textAlign: "center" },
  ganttBar: { position: "absolute", height: 22, borderRadius: 6, top: 11, overflow: "hidden", flexDirection: "row" },
  ganttBarFill: { height: "100%" },
  ganttBarText: { position: "absolute", left: 6, right: 6, top: 4, fontSize: 10, fontFamily: "Inter_700Bold" },
  todayLine: { position: "absolute", top: 0, bottom: 0, width: 2 },
  todayDot: { position: "absolute", top: 4, width: 8, height: 8, borderRadius: 4, marginLeft: -3 },
  noDateBanner: { paddingVertical: 10, paddingHorizontal: 12, borderRadius: 8, marginTop: 10, flexDirection: "row", alignItems: "center", gap: 8 },
  noDateText: { fontSize: 12, fontFamily: "Inter_500Medium", flex: 1 },
});

const TR_MONTHS = ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"];

function parseYMD(s: string): Date | null {
  if (!s) return null;
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s.trim());
  if (!m) return null;
  const d = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
  return isNaN(d.getTime()) ? null : d;
}
function daysBetween(a: Date, b: Date) {
  return Math.round((b.getTime() - a.getTime()) / 86400000);
}
function addDays(d: Date, n: number) {
  const r = new Date(d);
  r.setDate(r.getDate() + n);
  return r;
}

function GanttView(props: {
  tasks: ScheduleTask[];
  colors: ReturnType<typeof useColors>;
  projectName: (id: string) => string;
  onPressTask: (t: ScheduleTask) => void;
  statusColor: Record<ScheduleTask["status"], string>;
}) {
  const { tasks, colors, projectName, onPressTask, statusColor } = props;

  const dated = useMemo(() => {
    return tasks
      .map((t) => ({ t, s: parseYMD(t.startDate), e: parseYMD(t.endDate) }))
      .filter((x) => x.s && x.e && x.e!.getTime() >= x.s!.getTime()) as { t: ScheduleTask; s: Date; e: Date }[];
  }, [tasks]);
  const undated = tasks.length - dated.length;

  const today = useMemo(() => {
    const n = new Date();
    return new Date(n.getFullYear(), n.getMonth(), n.getDate());
  }, []);

  const range = useMemo(() => {
    if (dated.length === 0) {
      const start = addDays(today, -3);
      const end = addDays(today, 14);
      return { start, end, days: daysBetween(start, end) + 1 };
    }
    let minS = dated[0].s;
    let maxE = dated[0].e;
    for (const x of dated) {
      if (x.s.getTime() < minS.getTime()) minS = x.s;
      if (x.e.getTime() > maxE.getTime()) maxE = x.e;
    }
    const start = addDays(minS, -1);
    const end = addDays(maxE, 1);
    return { start, end, days: daysBetween(start, end) + 1 };
  }, [dated, today]);

  const dayWidth = range.days <= 21 ? 36 : range.days <= 60 ? 22 : range.days <= 120 ? 14 : 9;
  const rowHeight = 44;
  const headerHeight = 44;
  const totalWidth = range.days * dayWidth;

  const days = useMemo(() => {
    const arr: Date[] = [];
    for (let i = 0; i < range.days; i++) arr.push(addDays(range.start, i));
    return arr;
  }, [range]);

  const monthBands = useMemo(() => {
    const bands: { label: string; offset: number; width: number }[] = [];
    let curM = days[0]?.getMonth();
    let curY = days[0]?.getFullYear();
    let startIdx = 0;
    for (let i = 1; i <= days.length; i++) {
      const d = days[i];
      if (i === days.length || d.getMonth() !== curM || d.getFullYear() !== curY) {
        bands.push({
          label: `${TR_MONTHS[curM]} ${curY}`,
          offset: startIdx * dayWidth,
          width: (i - startIdx) * dayWidth,
        });
        if (i < days.length) {
          curM = d.getMonth();
          curY = d.getFullYear();
          startIdx = i;
        }
      }
    }
    return bands;
  }, [days, dayWidth]);

  const todayOffset = (() => {
    const d = daysBetween(range.start, today);
    if (d < 0 || d > range.days) return -1;
    return d * dayWidth + dayWidth / 2;
  })();

  const showDayNum = dayWidth >= 14;

  const NAME_W = 140;

  return (
    <View style={styles.ganttRoot}>
      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={{ paddingBottom: 16 }}
        showsVerticalScrollIndicator={true}
      >
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={true}
          contentContainerStyle={{ flexGrow: 1 }}
        >
          <View
            style={[
              styles.ganttCanvas,
              { borderColor: colors.border, backgroundColor: colors.card, width: NAME_W + totalWidth },
            ]}
          >
            {/* Header row */}
            <View style={{ flexDirection: "row", height: headerHeight, borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: colors.border }}>
              <View style={{ width: NAME_W, justifyContent: "center", paddingHorizontal: 10, borderRightWidth: StyleSheet.hairlineWidth, borderRightColor: colors.border }}>
                <Text style={[styles.ganttHeadText, { color: colors.mutedForeground }]}>İş Kalemi</Text>
              </View>
              <View style={{ width: totalWidth }}>
                <View style={{ height: 20, position: "relative" }}>
                  {monthBands.map((b, i) => (
                    <View
                      key={i}
                      style={{
                        position: "absolute",
                        left: b.offset,
                        width: b.width,
                        top: 0,
                        bottom: 0,
                        borderLeftWidth: i === 0 ? 0 : StyleSheet.hairlineWidth,
                        borderLeftColor: colors.border,
                        justifyContent: "center",
                      }}
                    >
                      <Text style={[styles.ganttMonthLabel, { color: colors.foreground }]} numberOfLines={1}>
                        {b.label}
                      </Text>
                    </View>
                  ))}
                </View>
                {showDayNum ? (
                  <View style={{ flexDirection: "row", height: 20 }}>
                    {days.map((d, i) => {
                      const isToday = d.getTime() === today.getTime();
                      const isWeekend = d.getDay() === 0 || d.getDay() === 6;
                      return (
                        <View key={i} style={{ width: dayWidth, alignItems: "center", justifyContent: "center" }}>
                          <Text
                            style={[
                              styles.ganttDayLabel,
                              {
                                color: isToday
                                  ? colors.primary
                                  : isWeekend
                                  ? colors.mutedForeground
                                  : colors.foreground,
                                fontFamily: isToday ? "Inter_700Bold" : "Inter_500Medium",
                              },
                            ]}
                          >
                            {d.getDate()}
                          </Text>
                        </View>
                      );
                    })}
                  </View>
                ) : null}
              </View>
            </View>

            {/* Task rows */}
            {dated.map(({ t, s, e }) => {
              const offset = daysBetween(range.start, s) * dayWidth;
              const width = (daysBetween(s, e) + 1) * dayWidth;
              const fillPct = Math.max(0, Math.min(100, t.progress || 0));
              const c = statusColor[t.status];
              const overdue = today.getTime() > e.getTime() && fillPct < 100;
              return (
                <View key={t.id} style={{ flexDirection: "row", height: rowHeight, borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: colors.border }}>
                  <TouchableOpacity
                    onPress={() => onPressTask(t)}
                    activeOpacity={0.7}
                    style={{ width: NAME_W, paddingHorizontal: 10, justifyContent: "center", borderRightWidth: StyleSheet.hairlineWidth, borderRightColor: colors.border }}
                  >
                    <Text style={[styles.ganttRowName, { color: colors.foreground }]} numberOfLines={1}>
                      {t.name}
                    </Text>
                    <Text style={[styles.ganttRowSub, { color: colors.mutedForeground }]} numberOfLines={1}>
                      {projectName(t.projectId)}
                    </Text>
                  </TouchableOpacity>
                  <View style={{ width: totalWidth, position: "relative" }}>
                    {/* weekend stripes */}
                    {days.map((d, i) => {
                      const wknd = d.getDay() === 0 || d.getDay() === 6;
                      if (!wknd) return null;
                      return (
                        <View
                          key={i}
                          style={{
                            position: "absolute",
                            left: i * dayWidth,
                            width: dayWidth,
                            top: 0,
                            bottom: 0,
                            backgroundColor: colors.muted,
                            opacity: 0.35,
                          }}
                        />
                      );
                    })}
                    {todayOffset >= 0 ? (
                      <View
                        style={[
                          styles.todayLine,
                          { left: todayOffset - 1, backgroundColor: colors.primary, opacity: 0.55 },
                        ]}
                      />
                    ) : null}
                    <TouchableOpacity
                      activeOpacity={0.8}
                      onPress={() => onPressTask(t)}
                      style={[
                        styles.ganttBar,
                        {
                          left: offset,
                          width: Math.max(width, 6),
                          backgroundColor: c + "33",
                          borderWidth: 1,
                          borderColor: overdue ? "#dc2626" : c,
                        },
                      ]}
                    >
                      <View style={[styles.ganttBarFill, { width: `${fillPct}%`, backgroundColor: c }]} />
                      {width >= 56 ? (
                        <Text style={[styles.ganttBarText, { color: colors.foreground }]} numberOfLines={1}>
                          %{fillPct}
                        </Text>
                      ) : null}
                    </TouchableOpacity>
                  </View>
                </View>
              );
            })}
          </View>
        </ScrollView>

        {undated > 0 ? (
          <View style={[styles.noDateBanner, { backgroundColor: colors.muted }]}>
            <Feather name="alert-circle" size={14} color={colors.mutedForeground} />
            <Text style={[styles.noDateText, { color: colors.mutedForeground }]}>
              {undated} kalemde başlangıç/bitiş tarihi eksik — Gantt'ta görünmez. Liste görünümünden tarih girin.
            </Text>
          </View>
        ) : null}

        <View style={[styles.legend, { backgroundColor: colors.card, borderColor: colors.border }]}>
          {(Object.keys(statusColor) as ScheduleTask["status"][]).map((s) => (
            <View key={s} style={styles.legendItem}>
              <View style={[styles.legendDot, { backgroundColor: statusColor[s] }]} />
              <Text style={[styles.legendText, { color: colors.foreground }]}>
                {s === "planned" ? "Planlandı" : s === "in_progress" ? "Devam" : s === "completed" ? "Tamamlandı" : "Gecikti"}
              </Text>
            </View>
          ))}
          <View style={styles.legendItem}>
            <View style={[styles.legendDot, { backgroundColor: colors.primary }]} />
            <Text style={[styles.legendText, { color: colors.foreground }]}>Bugün</Text>
          </View>
        </View>
      </ScrollView>
    </View>
  );
}
