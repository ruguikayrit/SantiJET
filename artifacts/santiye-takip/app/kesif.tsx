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
import DatePickerInput from "@/components/DatePickerInput";
import FormInput from "@/components/FormInput";
import Header from "@/components/Header";
import PrimaryButton from "@/components/PrimaryButton";
import { Survey, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

interface FormState {
  projectId: string;
  title: string;
  date: string;
  location: string;
  notes: string;
  itemDesc: string;
  itemUnit: string;
  itemQty: string;
  itemPrice: string;
}

const EMPTY: FormState = {
  projectId: "",
  title: "",
  date: "",
  location: "",
  notes: "",
  itemDesc: "",
  itemUnit: "",
  itemQty: "",
  itemPrice: "",
};

export default function KesifScreen() {
  const colors = useColors();
  const router = useRouter();
  const { projects, surveys, addSurvey, updateSurvey, deleteSurvey } = useApp();

  const perm = usePermission("kesif");
  const canEdit = perm === "edit";
  useEffect(() => { if (perm === "none") { if (router.canGoBack()) router.back(); else router.replace("/"); } }, [perm]);

  const [filter, setFilter] = useState<string | null>(null);
  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<FormState>(EMPTY);

  const list = useMemo(
    () => (filter ? surveys.filter((s) => s.projectId === filter) : surveys),
    [surveys, filter]
  );

  function open(s?: Survey) {
    if (s) {
      setEditId(s.id);
      setForm({
        projectId: s.projectId,
        title: s.title,
        date: s.date,
        location: s.location,
        notes: s.notes,
        itemDesc: "",
        itemUnit: "",
        itemQty: "",
        itemPrice: "",
      });
    } else {
      setEditId(null);
      setForm({ ...EMPTY, projectId: filter || projects[0]?.id || "" });
    }
    setVisible(true);
  }

  function save() {
    if (!form.projectId || !form.title.trim()) return;
    const items =
      editId
        ? surveys.find((x) => x.id === editId)?.items || []
        : [];
    if (form.itemDesc.trim()) {
      items.push({
        id: Date.now().toString(),
        description: form.itemDesc.trim(),
        unit: form.itemUnit.trim(),
        quantity: parseFloat(form.itemQty) || 0,
        unitPrice: parseFloat(form.itemPrice) || 0,
      });
    }
    const data = {
      projectId: form.projectId,
      title: form.title.trim(),
      date: form.date.trim(),
      location: form.location.trim(),
      notes: form.notes.trim(),
      items,
    };
    if (editId) updateSurvey(editId, data);
    else addSurvey(data);
    setVisible(false);
  }

  function remove() {
    if (editId) deleteSurvey(editId);
    setVisible(false);
  }

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  function totalCost(s: Survey) {
    return s.items.reduce((sum, i) => sum + i.quantity * i.unitPrice, 0);
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Keşif"
        onBack={() => (router.canGoBack() ? router.back() : router.replace("/"))}
        rightAction={canEdit && projects.length > 0 ? { icon: "plus", onPress: () => open() } : undefined}
      />


      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="Keşif kaydı oluşturmak için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : list.length === 0 ? (
        <EmptyState
          icon="search"
          title="Keşif kaydı yok"
          description="Saha keşif kaydınızı oluşturmak için + düğmesine dokunun"
          actionLabel="Keşif Ekle"
          onAction={() => open()}
        />
      ) : (
        <FlatList
          data={list}
          keyExtractor={(s) => s.id}
          contentContainerStyle={styles.list}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={[styles.card, { backgroundColor: colors.card }]}
              activeOpacity={0.85}
              onPress={() => open(item)}
            >
              <Text style={[styles.proj, { color: colors.primary }]}>
                {projectName(item.projectId)}
              </Text>
              <Text style={[styles.title, { color: colors.foreground }]}>
                {item.title}
              </Text>
              {item.location ? (
                <View style={styles.row}>
                  <Feather name="map-pin" size={13} color={colors.mutedForeground} />
                  <Text style={[styles.meta, { color: colors.mutedForeground }]}>
                    {item.location}
                  </Text>
                </View>
              ) : null}
              {item.date ? (
                <View style={styles.row}>
                  <Feather name="calendar" size={13} color={colors.mutedForeground} />
                  <Text style={[styles.meta, { color: colors.mutedForeground }]}>
                    {item.date}
                  </Text>
                </View>
              ) : null}
              <View style={styles.footer}>
                <Text style={[styles.itemCount, { color: colors.mutedForeground }]}>
                  {item.items.length} kalem
                </Text>
                <Text style={[styles.total, { color: colors.foreground }]}>
                  {totalCost(item).toLocaleString("tr-TR")} ₺
                </Text>
              </View>
            </TouchableOpacity>
          )}
        />
      )}

      <BottomSheet
        visible={visible}
        onClose={() => setVisible(false)}
        title={editId ? "Keşfi Düzenle" : "Yeni Keşif"}
      >
        <Text style={[styles.label, { color: colors.foreground }]}>Proje</Text>
        <View style={styles.chips}>
          {projects.map((p) => (
            <TouchableOpacity
              key={p.id}
              onPress={() => setForm({ ...form, projectId: p.id })}
              style={[
                styles.chip,
                {
                  backgroundColor:
                    form.projectId === p.id ? colors.primary : colors.muted,
                },
              ]}
            >
              <Text
                style={[
                  styles.chipText,
                  {
                    color: form.projectId === p.id ? "#fff" : colors.foreground,
                  },
                ]}
              >
                {p.name}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <FormInput
          label="Başlık"
          value={form.title}
          onChangeText={(v) => setForm({ ...form, title: v })}
          placeholder="Örn: Bodrum kazı keşfi"
        />
        <FormInput
          label="Konum"
          value={form.location}
          onChangeText={(v) => setForm({ ...form, location: v })}
        />
        <DatePickerInput
          label="Tarih"
          value={form.date}
          onChange={(v) => setForm({ ...form, date: v })}
        />
        <FormInput
          label="Notlar"
          value={form.notes}
          onChangeText={(v) => setForm({ ...form, notes: v })}
          multiline
          style={{ height: 70, textAlignVertical: "top" }}
        />

        <Text style={[styles.label, { color: colors.foreground, marginTop: 8 }]}>
          Yeni Kalem Ekle
        </Text>
        <FormInput
          label="Açıklama"
          value={form.itemDesc}
          onChangeText={(v) => setForm({ ...form, itemDesc: v })}
          placeholder="Örn: Beton dökümü"
        />
        <View style={styles.three}>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Birim"
              value={form.itemUnit}
              onChangeText={(v) => setForm({ ...form, itemUnit: v })}
              placeholder="m³"
            />
          </View>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Miktar"
              value={form.itemQty}
              onChangeText={(v) => setForm({ ...form, itemQty: v })}
              keyboardType="numeric"
            />
          </View>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Fiyat (₺)"
              value={form.itemPrice}
              onChangeText={(v) => setForm({ ...form, itemPrice: v })}
              keyboardType="numeric"
            />
          </View>
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
  proj: { fontSize: 12, fontFamily: "Inter_600SemiBold", marginBottom: 4 },
  title: { fontSize: 16, fontFamily: "Inter_700Bold", marginBottom: 6 },
  row: { flexDirection: "row", alignItems: "center", gap: 6, marginTop: 4 },
  meta: { fontSize: 13, fontFamily: "Inter_400Regular" },
  footer: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginTop: 10,
    paddingTop: 10,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: "#e5e7eb",
  },
  itemCount: { fontSize: 12, fontFamily: "Inter_500Medium" },
  total: { fontSize: 15, fontFamily: "Inter_700Bold" },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  chip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999 },
  chipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
  three: { flexDirection: "row", gap: 8 },
});
