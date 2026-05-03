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
import PozPicker from "@/components/PozPicker";
import PrimaryButton from "@/components/PrimaryButton";
import { Production, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

interface F {
  projectId: string;
  pozCode: string;
  name: string;
  unit: string;
  category: string;
  plannedQty: string;
  completedQty: string;
  date: string;
  description: string;
}

const EMPTY: F = {
  projectId: "",
  pozCode: "",
  name: "",
  unit: "",
  category: "",
  plannedQty: "",
  completedQty: "",
  date: "",
  description: "",
};

export default function ImalatScreen() {
  const colors = useColors();
  const router = useRouter();
  const { projects, productions, addProduction, updateProduction, deleteProduction } = useApp();
  const perm = usePermission("imalat");
  const canEdit = perm === "edit";
  useEffect(() => { if (perm === "none") { if (router.canGoBack()) router.back(); else router.replace("/"); } }, [perm]);

  const [filter, setFilter] = useState<string | null>(null);
  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<F>(EMPTY);

  const list = useMemo(
    () => (filter ? productions.filter((p) => p.projectId === filter) : productions),
    [productions, filter]
  );

  function open(p?: Production) {
    if (p) {
      setEditId(p.id);
      setForm({
        projectId: p.projectId,
        pozCode: p.pozCode || "",
        name: p.name,
        unit: p.unit,
        category: p.pozCategory || "",
        plannedQty: String(p.plannedQty || ""),
        completedQty: String(p.completedQty || ""),
        date: p.date,
        description: p.description || "",
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
      unit: form.unit.trim(),
      plannedQty: parseFloat(form.plannedQty) || 0,
      completedQty: parseFloat(form.completedQty) || 0,
      unitPrice: 0,
      date: form.date.trim(),
      pozCode: form.pozCode.trim() || undefined,
      pozCategory: form.category.trim() || undefined,
      description: form.description.trim() || undefined,
    };
    if (editId) updateProduction(editId, data);
    else addProduction(data);
    setVisible(false);
  }

  function remove() {
    if (editId) deleteProduction(editId);
    setVisible(false);
  }

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="İmalat"
        onBack={() => (router.canGoBack() ? router.back() : router.replace("/"))}
        rightAction={canEdit && projects.length > 0 ? { icon: "plus", onPress: () => open() } : undefined}
      />


      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="İmalat takibi için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : list.length === 0 ? (
        <EmptyState
          icon="tool"
          title="İmalat kaydı yok"
          description="Yeni imalat kalemi eklemek için + düğmesine dokunun"
          actionLabel="İmalat Ekle"
          onAction={() => open()}
        />
      ) : (
        <FlatList
          data={list}
          keyExtractor={(p) => p.id}
          contentContainerStyle={styles.list}
          renderItem={({ item }) => {
            const pct = item.plannedQty > 0
              ? Math.min(100, Math.round((item.completedQty / item.plannedQty) * 100))
              : 0;
            return (
              <TouchableOpacity
                style={[styles.card, { backgroundColor: colors.card }]}
                activeOpacity={0.85}
                onPress={() => open(item)}
              >
                <Text style={[styles.proj, { color: colors.primary }]}>
                  {projectName(item.projectId)}
                </Text>
                {item.pozCode ? (
                  <Text style={[styles.pozCode, { color: colors.mutedForeground }]}>
                    {item.pozCode}
                    {item.pozCategory ? ` · ${item.pozCategory}` : ""}
                  </Text>
                ) : null}
                <Text style={[styles.title, { color: colors.foreground }]}>
                  {item.name}
                </Text>

                <View style={styles.qtyRow}>
                  <View style={styles.qtyBox}>
                    <Text style={[styles.qtyLabel, { color: colors.mutedForeground }]}>
                      Planlanan
                    </Text>
                    <Text style={[styles.qtyVal, { color: colors.foreground }]}>
                      {item.plannedQty} {item.unit}
                    </Text>
                  </View>
                  <View style={styles.qtyBox}>
                    <Text style={[styles.qtyLabel, { color: colors.mutedForeground }]}>
                      Tamamlanan
                    </Text>
                    <Text style={[styles.qtyVal, { color: "#16a34a" }]}>
                      {item.completedQty} {item.unit}
                    </Text>
                  </View>
                  <View style={styles.qtyBox}>
                    <Text style={[styles.qtyLabel, { color: colors.mutedForeground }]}>
                      Kalan
                    </Text>
                    <Text style={[styles.qtyVal, { color: colors.foreground }]}>
                      {Math.max(0, item.plannedQty - item.completedQty)} {item.unit}
                    </Text>
                  </View>
                </View>

                <View style={[styles.bar, { backgroundColor: colors.muted }]}>
                  <View style={[styles.barFill, { width: `${pct}%`, backgroundColor: colors.primary }]} />
                </View>
                <Text style={[styles.pct, { color: colors.mutedForeground }]}>
                  %{pct} tamamlandı
                </Text>
              </TouchableOpacity>
            );
          }}
        />
      )}

      <BottomSheet
        visible={visible}
        onClose={() => setVisible(false)}
        title={editId ? "İmalatı Düzenle" : "Yeni İmalat"}
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

        <PozPicker
          label="Poz Tarifi"
          value={form.pozCode}
          onChange={(poz) =>
            setForm({
              ...form,
              pozCode: poz.code,
              name: poz.name,
              unit: poz.unit,
              category: poz.category,
            })
          }
        />

        <FormInput
          label="İmalat Adı"
          value={form.name}
          onChangeText={(v) => setForm({ ...form, name: v })}
          placeholder="Poz seçince otomatik dolar"
        />
        <View style={styles.row}>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Birim"
              value={form.unit}
              onChangeText={(v) => setForm({ ...form, unit: v })}
              placeholder="m³, m², ad"
            />
          </View>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Planlanan"
              value={form.plannedQty}
              onChangeText={(v) => setForm({ ...form, plannedQty: v })}
              keyboardType="numeric"
            />
          </View>
        </View>
        <View style={styles.row}>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Gerçekleşen"
              value={form.completedQty}
              onChangeText={(v) => setForm({ ...form, completedQty: v })}
              keyboardType="numeric"
            />
          </View>
          <View style={{ flex: 1 }}>
            <DatePickerInput
              label="Tarih"
              value={form.date}
              onChange={(v) => setForm({ ...form, date: v })}
            />
          </View>
        </View>

        <FormInput
          label="Açıklama"
          value={form.description}
          onChangeText={(v) => setForm({ ...form, description: v })}
          placeholder="İmalat ile ilgili notlar, detaylar..."
          multiline
          numberOfLines={4}
          style={{ minHeight: 90, paddingTop: 10 }}
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
  proj: { fontSize: 12, fontFamily: "Inter_600SemiBold", marginBottom: 4 },
  pozCode: { fontSize: 11, fontFamily: "Inter_500Medium", marginBottom: 2 },
  title: { fontSize: 16, fontFamily: "Inter_700Bold", marginBottom: 12 },
  qtyRow: { flexDirection: "row", gap: 8, marginBottom: 12 },
  qtyBox: { flex: 1 },
  qtyLabel: { fontSize: 11, fontFamily: "Inter_500Medium", marginBottom: 2 },
  qtyVal: { fontSize: 14, fontFamily: "Inter_700Bold" },
  bar: { height: 6, borderRadius: 3, overflow: "hidden" },
  barFill: { height: "100%" },
  pct: { fontSize: 11, fontFamily: "Inter_500Medium", marginTop: 6 },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  chip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999 },
  chipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
  row: { flexDirection: "row", gap: 8 },
});
