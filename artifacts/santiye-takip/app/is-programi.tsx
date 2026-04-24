import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useEffect, useMemo, useState } from "react";
import {
  FlatList,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import BottomSheet from "@/components/BottomSheet";
import EmptyState from "@/components/EmptyState";
import FormInput from "@/components/FormInput";
import Header from "@/components/Header";
import PrimaryButton from "@/components/PrimaryButton";
import ProjectPicker from "@/components/ProjectPicker";
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
  useEffect(() => { if (perm === "none") router.back(); }, [perm]);

  const [filter, setFilter] = useState<string | null>(null);
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
        onBack={() => router.back()}
        rightAction={canEdit && projects.length > 0 ? { icon: "plus", onPress: () => open() } : undefined}
      />

      <ProjectPicker projects={projects} value={filter} onChange={setFilter} />

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
            <FormInput
              label="Başlangıç"
              value={form.startDate}
              onChangeText={(v) => setForm({ ...form, startDate: v })}
              placeholder="GG.AA.YYYY"
            />
          </View>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Bitiş"
              value={form.endDate}
              onChangeText={(v) => setForm({ ...form, endDate: v })}
              placeholder="GG.AA.YYYY"
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
});
