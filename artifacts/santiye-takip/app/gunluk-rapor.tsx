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
import { DailyReport, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

function todayStr() {
  const d = new Date();
  return `${String(d.getDate()).padStart(2, "0")}.${String(d.getMonth() + 1).padStart(2, "0")}.${d.getFullYear()}`;
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
  const { projects, dailyReports, addDailyReport, updateDailyReport, deleteDailyReport } = useApp();

  const [filter, setFilter] = useState<string | null>(null);
  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<F>(EMPTY);

  const list = useMemo(() => {
    const arr = filter ? dailyReports.filter((r) => r.projectId === filter) : dailyReports;
    return [...arr].sort((a, b) => b.date.localeCompare(a.date));
  }, [dailyReports, filter]);

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
        onBack={() => router.back()}
        rightAction={projects.length > 0 ? { icon: "plus", onPress: () => open() } : undefined}
      />

      <ProjectPicker projects={projects} value={filter} onChange={setFilter} />

      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="Günlük rapor için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : list.length === 0 ? (
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

        <FormInput
          label="Tarih"
          value={form.date}
          onChangeText={(v) => setForm({ ...form, date: v })}
          placeholder="GG.AA.YYYY"
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

        <FormInput
          label="Yapılan Faaliyetler"
          value={form.activities}
          onChangeText={(v) => setForm({ ...form, activities: v })}
          multiline
          style={{ height: 90, textAlignVertical: "top" }}
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
});
