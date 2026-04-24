import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
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
import { Project, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

const STATUS_LABEL: Record<Project["status"], string> = {
  active: "Aktif",
  paused: "Duraklatıldı",
  completed: "Tamamlandı",
};
const STATUS_COLOR: Record<Project["status"], string> = {
  active: "#16a34a",
  paused: "#d97706",
  completed: "#0891b2",
};

interface FormState {
  name: string;
  location: string;
  contractor: string;
  startDate: string;
  endDate: string;
  budget: string;
  status: Project["status"];
  description: string;
}

const EMPTY_FORM: FormState = {
  name: "",
  location: "",
  contractor: "",
  startDate: "",
  endDate: "",
  budget: "",
  status: "active",
  description: "",
};

export default function ProjectsScreen() {
  const colors = useColors();
  const router = useRouter();
  const { projects, addProject, updateProject, deleteProject } = useApp();
  const perm = usePermission("proje");
  const canEdit = perm === "edit";
  useEffect(() => { if (perm === "none") router.back(); }, [perm]);

  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<FormState>(EMPTY_FORM);

  function open(p?: Project) {
    if (p) {
      setEditId(p.id);
      setForm({
        name: p.name,
        location: p.location,
        contractor: p.contractor,
        startDate: p.startDate,
        endDate: p.endDate,
        budget: String(p.budget || ""),
        status: p.status,
        description: p.description,
      });
    } else {
      setEditId(null);
      setForm(EMPTY_FORM);
    }
    setVisible(true);
  }

  function save() {
    if (!form.name.trim()) return;
    const data = {
      name: form.name.trim(),
      location: form.location.trim(),
      contractor: form.contractor.trim(),
      startDate: form.startDate.trim(),
      endDate: form.endDate.trim(),
      budget: parseFloat(form.budget) || 0,
      status: form.status,
      description: form.description.trim(),
    };
    if (editId) updateProject(editId, data);
    else addProject(data);
    setVisible(false);
  }

  function remove() {
    if (editId) deleteProject(editId);
    setVisible(false);
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Projeler"
        onBack={() => router.back()}
        rightAction={canEdit ? { icon: "plus", onPress: () => open() } : undefined}
      />

      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Henüz proje yok"
          description="İlk projenizi oluşturmak için + düğmesine dokunun"
          actionLabel="Proje Ekle"
          onAction={() => open()}
        />
      ) : (
        <FlatList
          data={projects}
          keyExtractor={(p) => p.id}
          contentContainerStyle={styles.list}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={[styles.card, { backgroundColor: colors.card }]}
              activeOpacity={0.85}
              onPress={() => open(item)}
            >
              <View style={styles.cardHead}>
                <Text style={[styles.cardTitle, { color: colors.foreground }]}>
                  {item.name}
                </Text>
                <View
                  style={[
                    styles.badge,
                    { backgroundColor: STATUS_COLOR[item.status] + "22" },
                  ]}
                >
                  <Text
                    style={[styles.badgeText, { color: STATUS_COLOR[item.status] }]}
                  >
                    {STATUS_LABEL[item.status]}
                  </Text>
                </View>
              </View>

              {item.location ? (
                <View style={styles.row}>
                  <Feather name="map-pin" size={13} color={colors.mutedForeground} />
                  <Text style={[styles.meta, { color: colors.mutedForeground }]}>
                    {item.location}
                  </Text>
                </View>
              ) : null}
              {item.contractor ? (
                <View style={styles.row}>
                  <Feather name="briefcase" size={13} color={colors.mutedForeground} />
                  <Text style={[styles.meta, { color: colors.mutedForeground }]}>
                    {item.contractor}
                  </Text>
                </View>
              ) : null}
              {item.budget > 0 ? (
                <View style={styles.row}>
                  <Feather name="dollar-sign" size={13} color={colors.mutedForeground} />
                  <Text style={[styles.meta, { color: colors.mutedForeground }]}>
                    {item.budget.toLocaleString("tr-TR")} ₺
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
        title={editId ? "Projeyi Düzenle" : "Yeni Proje"}
      >
        <FormInput
          label="Proje Adı"
          value={form.name}
          onChangeText={(v) => setForm({ ...form, name: v })}
          placeholder="Örn: Çankaya Konutları"
        />
        <FormInput
          label="Konum"
          value={form.location}
          onChangeText={(v) => setForm({ ...form, location: v })}
          placeholder="Örn: Ankara / Çankaya"
        />
        <FormInput
          label="Yüklenici"
          value={form.contractor}
          onChangeText={(v) => setForm({ ...form, contractor: v })}
        />
        <FormInput
          label="Başlangıç Tarihi"
          value={form.startDate}
          onChangeText={(v) => setForm({ ...form, startDate: v })}
          placeholder="GG.AA.YYYY"
        />
        <FormInput
          label="Bitiş Tarihi"
          value={form.endDate}
          onChangeText={(v) => setForm({ ...form, endDate: v })}
          placeholder="GG.AA.YYYY"
        />
        <FormInput
          label="Bütçe (₺)"
          value={form.budget}
          onChangeText={(v) => setForm({ ...form, budget: v })}
          keyboardType="numeric"
        />

        <Text style={[styles.label, { color: colors.foreground }]}>Durum</Text>
        <View style={styles.chipRow}>
          {(["active", "paused", "completed"] as const).map((s) => (
            <TouchableOpacity
              key={s}
              onPress={() => setForm({ ...form, status: s })}
              style={[
                styles.chip,
                {
                  backgroundColor:
                    form.status === s ? STATUS_COLOR[s] : colors.muted,
                },
              ]}
              activeOpacity={0.8}
            >
              <Text
                style={[
                  styles.chipText,
                  {
                    color: form.status === s ? "#fff" : colors.foreground,
                  },
                ]}
              >
                {STATUS_LABEL[s]}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <FormInput
          label="Açıklama"
          value={form.description}
          onChangeText={(v) => setForm({ ...form, description: v })}
          multiline
          style={{ height: 80, textAlignVertical: "top" }}
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
  cardHead: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
    marginBottom: 8,
    gap: 10,
  },
  cardTitle: {
    fontSize: 16,
    fontFamily: "Inter_700Bold",
    flex: 1,
  },
  badge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 999,
  },
  badgeText: {
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
  },
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginTop: 4,
  },
  meta: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
  },
  label: {
    fontSize: 14,
    fontFamily: "Inter_600SemiBold",
    marginBottom: 8,
  },
  chipRow: {
    flexDirection: "row",
    gap: 8,
    marginBottom: 14,
  },
  chip: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 999,
  },
  chipText: {
    fontSize: 13,
    fontFamily: "Inter_500Medium",
  },
});
