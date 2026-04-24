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
import { Material, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

interface F {
  projectId: string;
  name: string;
  unit: string;
  quantity: string;
  usedQty: string;
  supplier: string;
  deliveryDate: string;
  unitPrice: string;
}

const EMPTY: F = {
  projectId: "",
  name: "",
  unit: "",
  quantity: "",
  usedQty: "",
  supplier: "",
  deliveryDate: "",
  unitPrice: "",
};

export default function MalzemeScreen() {
  const colors = useColors();
  const router = useRouter();
  const { projects, materials, addMaterial, updateMaterial, deleteMaterial } = useApp();

  const [filter, setFilter] = useState<string | null>(null);
  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<F>(EMPTY);

  const list = useMemo(
    () => (filter ? materials.filter((m) => m.projectId === filter) : materials),
    [materials, filter]
  );

  function open(m?: Material) {
    if (m) {
      setEditId(m.id);
      setForm({
        projectId: m.projectId,
        name: m.name,
        unit: m.unit,
        quantity: String(m.quantity || ""),
        usedQty: String(m.usedQty || ""),
        supplier: m.supplier,
        deliveryDate: m.deliveryDate,
        unitPrice: String(m.unitPrice || ""),
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
      quantity: parseFloat(form.quantity) || 0,
      usedQty: parseFloat(form.usedQty) || 0,
      supplier: form.supplier.trim(),
      deliveryDate: form.deliveryDate.trim(),
      unitPrice: parseFloat(form.unitPrice) || 0,
    };
    if (editId) updateMaterial(editId, data);
    else addMaterial(data);
    setVisible(false);
  }

  function remove() {
    if (editId) deleteMaterial(editId);
    setVisible(false);
  }

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Malzeme"
        onBack={() => router.back()}
        rightAction={projects.length > 0 ? { icon: "plus", onPress: () => open() } : undefined}
      />

      <ProjectPicker projects={projects} value={filter} onChange={setFilter} />

      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="Malzeme takibi için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : list.length === 0 ? (
        <EmptyState
          icon="package"
          title="Malzeme yok"
          description="Yeni malzeme eklemek için + düğmesine dokunun"
          actionLabel="Malzeme Ekle"
          onAction={() => open()}
        />
      ) : (
        <FlatList
          data={list}
          keyExtractor={(m) => m.id}
          contentContainerStyle={styles.list}
          renderItem={({ item }) => {
            const remaining = item.quantity - item.usedQty;
            const pct = item.quantity > 0
              ? Math.min(100, Math.round((item.usedQty / item.quantity) * 100))
              : 0;
            const lowStock = item.quantity > 0 && remaining / item.quantity < 0.2;
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
                    <Text style={[styles.title, { color: colors.foreground }]}>
                      {item.name}
                    </Text>
                  </View>
                  {lowStock ? (
                    <View style={[styles.badge, { backgroundColor: "#fee2e2" }]}>
                      <Feather name="alert-triangle" size={11} color="#dc2626" />
                      <Text style={[styles.badgeText, { color: "#dc2626" }]}>
                        Az Stok
                      </Text>
                    </View>
                  ) : null}
                </View>

                <View style={styles.qtyRow}>
                  <View style={styles.qtyBox}>
                    <Text style={[styles.qtyLabel, { color: colors.mutedForeground }]}>
                      Toplam
                    </Text>
                    <Text style={[styles.qtyVal, { color: colors.foreground }]}>
                      {item.quantity} {item.unit}
                    </Text>
                  </View>
                  <View style={styles.qtyBox}>
                    <Text style={[styles.qtyLabel, { color: colors.mutedForeground }]}>
                      Kullanılan
                    </Text>
                    <Text style={[styles.qtyVal, { color: colors.foreground }]}>
                      {item.usedQty} {item.unit}
                    </Text>
                  </View>
                  <View style={styles.qtyBox}>
                    <Text style={[styles.qtyLabel, { color: colors.mutedForeground }]}>
                      Kalan
                    </Text>
                    <Text style={[styles.qtyVal, { color: lowStock ? "#dc2626" : "#16a34a" }]}>
                      {remaining} {item.unit}
                    </Text>
                  </View>
                </View>

                <View style={[styles.bar, { backgroundColor: colors.muted }]}>
                  <View style={[styles.barFill, { width: `${pct}%`, backgroundColor: colors.primary }]} />
                </View>

                {item.supplier ? (
                  <View style={styles.metaRow}>
                    <Feather name="truck" size={12} color={colors.mutedForeground} />
                    <Text style={[styles.metaText, { color: colors.mutedForeground }]}>
                      {item.supplier}
                      {item.deliveryDate ? ` · ${item.deliveryDate}` : ""}
                    </Text>
                  </View>
                ) : null}
              </TouchableOpacity>
            );
          }}
        />
      )}

      <BottomSheet
        visible={visible}
        onClose={() => setVisible(false)}
        title={editId ? "Malzemeyi Düzenle" : "Yeni Malzeme"}
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
          label="Malzeme Adı"
          value={form.name}
          onChangeText={(v) => setForm({ ...form, name: v })}
          placeholder="Örn: Çimento CEM I 42.5"
        />
        <View style={styles.row}>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Birim"
              value={form.unit}
              onChangeText={(v) => setForm({ ...form, unit: v })}
              placeholder="kg, ton, m³"
            />
          </View>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Birim Fiyat (₺)"
              value={form.unitPrice}
              onChangeText={(v) => setForm({ ...form, unitPrice: v })}
              keyboardType="numeric"
            />
          </View>
        </View>
        <View style={styles.row}>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Toplam Miktar"
              value={form.quantity}
              onChangeText={(v) => setForm({ ...form, quantity: v })}
              keyboardType="numeric"
            />
          </View>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Kullanılan"
              value={form.usedQty}
              onChangeText={(v) => setForm({ ...form, usedQty: v })}
              keyboardType="numeric"
            />
          </View>
        </View>
        <FormInput
          label="Tedarikçi"
          value={form.supplier}
          onChangeText={(v) => setForm({ ...form, supplier: v })}
        />
        <FormInput
          label="Teslim Tarihi"
          value={form.deliveryDate}
          onChangeText={(v) => setForm({ ...form, deliveryDate: v })}
          placeholder="GG.AA.YYYY"
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
  head: { flexDirection: "row", alignItems: "flex-start", gap: 8, marginBottom: 12 },
  proj: { fontSize: 12, fontFamily: "Inter_600SemiBold", marginBottom: 2 },
  title: { fontSize: 16, fontFamily: "Inter_700Bold" },
  badge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 999,
  },
  badgeText: { fontSize: 10, fontFamily: "Inter_600SemiBold" },
  qtyRow: { flexDirection: "row", gap: 8, marginBottom: 12 },
  qtyBox: { flex: 1 },
  qtyLabel: { fontSize: 11, fontFamily: "Inter_500Medium", marginBottom: 2 },
  qtyVal: { fontSize: 14, fontFamily: "Inter_700Bold" },
  bar: { height: 6, borderRadius: 3, overflow: "hidden" },
  barFill: { height: "100%" },
  metaRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginTop: 10,
  },
  metaText: { fontSize: 12, fontFamily: "Inter_500Medium" },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  chip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999 },
  chipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
  row: { flexDirection: "row", gap: 8 },
});
