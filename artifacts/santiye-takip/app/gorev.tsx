import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useMemo, useState } from "react";
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
import { Task, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

const STATUS_LABEL: Record<Task["status"], string> = {
  open: "Açık",
  in_progress: "Devam Ediyor",
  done: "Tamamlandı",
};
const STATUS_COLOR: Record<Task["status"], string> = {
  open: "#0891b2",
  in_progress: "#d97706",
  done: "#16a34a",
};
const PRIORITY_LABEL: Record<Task["priority"], string> = {
  low: "Düşük",
  medium: "Orta",
  high: "Yüksek",
};
const PRIORITY_COLOR: Record<Task["priority"], string> = {
  low: "#6b7280",
  medium: "#d97706",
  high: "#dc2626",
};

interface F {
  projectId: string;
  title: string;
  description: string;
  assignee: string;
  deadline: string;
  priority: Task["priority"];
  status: Task["status"];
}

const EMPTY: F = {
  projectId: "",
  title: "",
  description: "",
  assignee: "",
  deadline: "",
  priority: "medium",
  status: "open",
};

export default function GorevScreen() {
  const colors = useColors();
  const router = useRouter();
  const { projects, tasks, addTask, updateTask, deleteTask } = useApp();

  const [filter, setFilter] = useState<string | null>(null);
  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<F>(EMPTY);

  const list = useMemo(() => {
    const arr = filter ? tasks.filter((t) => t.projectId === filter) : tasks;
    const order = { open: 0, in_progress: 1, done: 2 };
    return [...arr].sort((a, b) => order[a.status] - order[b.status]);
  }, [tasks, filter]);

  function open(t?: Task) {
    if (t) {
      setEditId(t.id);
      setForm({
        projectId: t.projectId,
        title: t.title,
        description: t.description,
        assignee: t.assignee,
        deadline: t.deadline,
        priority: t.priority,
        status: t.status,
      });
    } else {
      setEditId(null);
      setForm({ ...EMPTY, projectId: filter || projects[0]?.id || "" });
    }
    setVisible(true);
  }

  function save() {
    if (!form.projectId || !form.title.trim()) return;
    const data = {
      projectId: form.projectId,
      title: form.title.trim(),
      description: form.description.trim(),
      assignee: form.assignee.trim(),
      deadline: form.deadline.trim(),
      priority: form.priority,
      status: form.status,
    };
    if (editId) updateTask(editId, data);
    else addTask(data);
    setVisible(false);
  }

  function remove() {
    if (editId) deleteTask(editId);
    setVisible(false);
  }

  function toggleStatus(t: Task) {
    const next: Task["status"] =
      t.status === "open" ? "in_progress" : t.status === "in_progress" ? "done" : "open";
    updateTask(t.id, { status: next });
  }

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Görevler"
        onBack={() => router.back()}
        rightAction={projects.length > 0 ? { icon: "plus", onPress: () => open() } : undefined}
      />

      <ProjectPicker projects={projects} value={filter} onChange={setFilter} />

      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="Görev oluşturmak için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : list.length === 0 ? (
        <EmptyState
          icon="check-square"
          title="Görev yok"
          description="Yeni görev eklemek için + düğmesine dokunun"
          actionLabel="Görev Ekle"
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
              <View style={styles.row}>
                <TouchableOpacity onPress={() => toggleStatus(item)} style={styles.checkBox}>
                  <View
                    style={[
                      styles.check,
                      {
                        backgroundColor:
                          item.status === "done" ? STATUS_COLOR.done : "transparent",
                        borderColor:
                          item.status === "done" ? STATUS_COLOR.done : colors.border,
                      },
                    ]}
                  >
                    {item.status === "done" ? (
                      <Feather name="check" size={14} color="#fff" />
                    ) : item.status === "in_progress" ? (
                      <View style={[styles.dot, { backgroundColor: STATUS_COLOR.in_progress }]} />
                    ) : null}
                  </View>
                </TouchableOpacity>

                <View style={{ flex: 1 }}>
                  <Text style={[styles.proj, { color: colors.primary }]}>
                    {projectName(item.projectId)}
                  </Text>
                  <Text
                    style={[
                      styles.title,
                      {
                        color: colors.foreground,
                        textDecorationLine: item.status === "done" ? "line-through" : "none",
                        opacity: item.status === "done" ? 0.6 : 1,
                      },
                    ]}
                  >
                    {item.title}
                  </Text>
                  {item.description ? (
                    <Text
                      style={[styles.desc, { color: colors.mutedForeground }]}
                      numberOfLines={2}
                    >
                      {item.description}
                    </Text>
                  ) : null}

                  <View style={styles.metaRow}>
                    <View
                      style={[
                        styles.pill,
                        { backgroundColor: PRIORITY_COLOR[item.priority] + "22" },
                      ]}
                    >
                      <Text
                        style={[styles.pillText, { color: PRIORITY_COLOR[item.priority] }]}
                      >
                        {PRIORITY_LABEL[item.priority]}
                      </Text>
                    </View>
                    {item.assignee ? (
                      <View style={styles.metaItem}>
                        <Feather name="user" size={11} color={colors.mutedForeground} />
                        <Text style={[styles.metaText, { color: colors.mutedForeground }]}>
                          {item.assignee}
                        </Text>
                      </View>
                    ) : null}
                    {item.deadline ? (
                      <View style={styles.metaItem}>
                        <Feather name="clock" size={11} color={colors.mutedForeground} />
                        <Text style={[styles.metaText, { color: colors.mutedForeground }]}>
                          {item.deadline}
                        </Text>
                      </View>
                    ) : null}
                  </View>
                </View>
              </View>
            </TouchableOpacity>
          )}
        />
      )}

      <BottomSheet
        visible={visible}
        onClose={() => setVisible(false)}
        title={editId ? "Görevi Düzenle" : "Yeni Görev"}
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
          label="Başlık"
          value={form.title}
          onChangeText={(v) => setForm({ ...form, title: v })}
          placeholder="Örn: Demir teslim alımı"
        />
        <FormInput
          label="Açıklama"
          value={form.description}
          onChangeText={(v) => setForm({ ...form, description: v })}
          multiline
          style={{ height: 70, textAlignVertical: "top" }}
        />
        <FormInput
          label="Sorumlu"
          value={form.assignee}
          onChangeText={(v) => setForm({ ...form, assignee: v })}
        />
        <FormInput
          label="Son Tarih"
          value={form.deadline}
          onChangeText={(v) => setForm({ ...form, deadline: v })}
          placeholder="GG.AA.YYYY"
        />

        <Text style={[styles.label, { color: colors.foreground }]}>Öncelik</Text>
        <View style={styles.chips}>
          {(Object.keys(PRIORITY_LABEL) as Task["priority"][]).map((p) => (
            <TouchableOpacity
              key={p}
              onPress={() => setForm({ ...form, priority: p })}
              style={[styles.chip, { backgroundColor: form.priority === p ? PRIORITY_COLOR[p] : colors.muted }]}
            >
              <Text style={[styles.chipText, { color: form.priority === p ? "#fff" : colors.foreground }]}>
                {PRIORITY_LABEL[p]}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <Text style={[styles.label, { color: colors.foreground }]}>Durum</Text>
        <View style={styles.chips}>
          {(Object.keys(STATUS_LABEL) as Task["status"][]).map((s) => (
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

        <PrimaryButton label="Kaydet" onPress={save} style={{ marginTop: 8 }} />
        {editId ? (
          <PrimaryButton label="Sil" variant="danger" onPress={remove} style={{ marginTop: 10 }} />
        ) : null}
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  list: { padding: 16, gap: 10 },
  card: {
    borderRadius: 12,
    padding: 12,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  row: { flexDirection: "row", gap: 10 },
  checkBox: { paddingTop: 2 },
  check: {
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 2,
    justifyContent: "center",
    alignItems: "center",
  },
  dot: { width: 8, height: 8, borderRadius: 4 },
  proj: { fontSize: 11, fontFamily: "Inter_600SemiBold", marginBottom: 2 },
  title: { fontSize: 15, fontFamily: "Inter_600SemiBold" },
  desc: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2, lineHeight: 16 },
  metaRow: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
    alignItems: "center",
    marginTop: 8,
  },
  pill: { paddingHorizontal: 8, paddingVertical: 3, borderRadius: 999 },
  pillText: { fontSize: 10, fontFamily: "Inter_600SemiBold" },
  metaItem: { flexDirection: "row", alignItems: "center", gap: 4 },
  metaText: { fontSize: 11, fontFamily: "Inter_500Medium" },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  chip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999 },
  chipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
});
