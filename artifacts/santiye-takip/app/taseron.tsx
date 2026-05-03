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
import DatePickerInput from "@/components/DatePickerInput";
import EmptyState from "@/components/EmptyState";
import FormInput from "@/components/FormInput";
import Header from "@/components/Header";
import PrimaryButton from "@/components/PrimaryButton";
import { Subcontractor, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

const STATUS_LABEL: Record<Subcontractor["status"], string> = {
  active: "Aktif",
  completed: "Tamamlandı",
  cancelled: "İptal",
};
const STATUS_COLOR: Record<Subcontractor["status"], string> = {
  active: "#16a34a",
  completed: "#0891b2",
  cancelled: "#dc2626",
};

interface F {
  projectId: string;
  name: string;
  contactPerson: string;
  phone: string;
  email: string;
  specialty: string;
  contractAmount: string;
  startDate: string;
  endDate: string;
  status: Subcontractor["status"];
  notes: string;
}

const EMPTY: F = {
  projectId: "",
  name: "",
  contactPerson: "",
  phone: "",
  email: "",
  specialty: "",
  contractAmount: "",
  startDate: "",
  endDate: "",
  status: "active",
  notes: "",
};

function fmt(n: number) {
  return n.toLocaleString("tr-TR", { minimumFractionDigits: 0 });
}

export default function TaseronScreen() {
  const colors = useColors();
  const router = useRouter();
  const { projects, subcontractors, addSubcontractor, updateSubcontractor, deleteSubcontractor } = useApp();

  const perm = usePermission("taseron");
  const canEdit = perm === "edit";
  useEffect(() => { if (perm === "none") { if (router.canGoBack()) router.back(); else router.replace("/"); } }, [perm]);

  const [filter, setFilter] = useState<string | null>(null);
  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<F>(EMPTY);

  const list = useMemo(() => {
    const arr = filter
      ? subcontractors.filter((s) => s.projectId === filter)
      : subcontractors;
    const order = { active: 0, completed: 1, cancelled: 2 };
    return [...arr].sort((a, b) => order[a.status] - order[b.status]);
  }, [subcontractors, filter]);

  function open(s?: Subcontractor) {
    if (s) {
      setEditId(s.id);
      setForm({
        projectId: s.projectId,
        name: s.name,
        contactPerson: s.contactPerson,
        phone: s.phone,
        email: s.email,
        specialty: s.specialty,
        contractAmount: s.contractAmount ? String(s.contractAmount) : "",
        startDate: s.startDate,
        endDate: s.endDate,
        status: s.status,
        notes: s.notes,
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
      contactPerson: form.contactPerson.trim(),
      phone: form.phone.trim(),
      email: form.email.trim(),
      specialty: form.specialty.trim(),
      contractAmount: parseFloat(form.contractAmount.replace(",", ".")) || 0,
      startDate: form.startDate,
      endDate: form.endDate,
      status: form.status,
      notes: form.notes.trim(),
    };
    if (editId) updateSubcontractor(editId, data);
    else addSubcontractor(data);
    setVisible(false);
  }

  function remove() {
    if (editId) deleteSubcontractor(editId);
    setVisible(false);
  }

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  const set = (k: keyof F) => (v: string) => setForm((f) => ({ ...f, [k]: v }));

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Taşeronlar"
        onBack={() => (router.canGoBack() ? router.back() : router.replace("/"))}
        rightAction={canEdit && projects.length > 0 ? { icon: "plus", onPress: () => open() } : undefined}
      />


      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="Taşeron eklemek için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : list.length === 0 ? (
        <EmptyState
          icon="truck"
          title="Taşeron yok"
          description="Yeni taşeron eklemek için + düğmesine dokunun"
          actionLabel="Taşeron Ekle"
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
              <View style={styles.cardHead}>
                <View style={{ flex: 1 }}>
                  <Text style={[styles.cardName, { color: colors.foreground }]}>
                    {item.name}
                  </Text>
                  <Text style={[styles.cardProj, { color: colors.primary }]}>
                    {projectName(item.projectId)}
                  </Text>
                </View>
                <View
                  style={[
                    styles.statusBadge,
                    { backgroundColor: STATUS_COLOR[item.status] + "20" },
                  ]}
                >
                  <View
                    style={[styles.statusDot, { backgroundColor: STATUS_COLOR[item.status] }]}
                  />
                  <Text style={[styles.statusText, { color: STATUS_COLOR[item.status] }]}>
                    {STATUS_LABEL[item.status]}
                  </Text>
                </View>
              </View>

              <View style={styles.metaGrid}>
                {item.specialty ? (
                  <View style={styles.metaItem}>
                    <Feather name="tool" size={12} color={colors.mutedForeground} />
                    <Text style={[styles.metaText, { color: colors.mutedForeground }]}>
                      {item.specialty}
                    </Text>
                  </View>
                ) : null}
                {item.contactPerson ? (
                  <View style={styles.metaItem}>
                    <Feather name="user" size={12} color={colors.mutedForeground} />
                    <Text style={[styles.metaText, { color: colors.mutedForeground }]}>
                      {item.contactPerson}
                    </Text>
                  </View>
                ) : null}
                {item.phone ? (
                  <View style={styles.metaItem}>
                    <Feather name="phone" size={12} color={colors.mutedForeground} />
                    <Text style={[styles.metaText, { color: colors.mutedForeground }]}>
                      {item.phone}
                    </Text>
                  </View>
                ) : null}
                {item.contractAmount > 0 ? (
                  <View style={styles.metaItem}>
                    <Feather name="file-text" size={12} color={colors.mutedForeground} />
                    <Text style={[styles.metaText, { color: colors.mutedForeground }]}>
                      {fmt(item.contractAmount)} ₺
                    </Text>
                  </View>
                ) : null}
              </View>

              {(item.startDate || item.endDate) ? (
                <View style={[styles.dateRow, { borderTopColor: colors.muted }]}>
                  <Feather name="calendar" size={11} color={colors.mutedForeground} />
                  <Text style={[styles.dateText, { color: colors.mutedForeground }]}>
                    {item.startDate || "—"} → {item.endDate || "—"}
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
        title={editId ? "Taşeronu Düzenle" : "Yeni Taşeron"}
      >
        <Text style={[styles.label, { color: colors.foreground }]}>Proje</Text>
        <View style={styles.chips}>
          {projects.map((p) => (
            <TouchableOpacity
              key={p.id}
              onPress={() => setForm((f) => ({ ...f, projectId: p.id }))}
              style={[
                styles.chip,
                { backgroundColor: form.projectId === p.id ? colors.primary : colors.muted },
              ]}
            >
              <Text
                style={[
                  styles.chipText,
                  { color: form.projectId === p.id ? "#fff" : colors.foreground },
                ]}
              >
                {p.name}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <FormInput
          label="Firma / Taşeron Adı"
          value={form.name}
          onChangeText={set("name")}
          placeholder="Örn: ABC İnşaat Ltd."
        />
        <FormInput
          label="Uzmanlık Alanı"
          value={form.specialty}
          onChangeText={set("specialty")}
          placeholder="Örn: Betonarme, Çatı, Elektrik"
        />

        <View style={styles.row}>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Yetkili Kişi"
              value={form.contactPerson}
              onChangeText={set("contactPerson")}
            />
          </View>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Telefon"
              value={form.phone}
              onChangeText={set("phone")}
              keyboardType="phone-pad"
            />
          </View>
        </View>

        <FormInput
          label="E-posta"
          value={form.email}
          onChangeText={set("email")}
          keyboardType="email-address"
        />

        <FormInput
          label="Sözleşme Bedeli (₺)"
          value={form.contractAmount}
          onChangeText={set("contractAmount")}
          keyboardType="numeric"
          placeholder="0"
        />

        <View style={styles.row}>
          <View style={{ flex: 1 }}>
            <DatePickerInput
              label="Başlangıç Tarihi"
              value={form.startDate}
              onChange={set("startDate")}
            />
          </View>
          <View style={{ flex: 1 }}>
            <DatePickerInput
              label="Bitiş Tarihi"
              value={form.endDate}
              onChange={set("endDate")}
            />
          </View>
        </View>

        <Text style={[styles.label, { color: colors.foreground }]}>Durum</Text>
        <View style={styles.chips}>
          {(Object.keys(STATUS_LABEL) as Subcontractor["status"][]).map((s) => (
            <TouchableOpacity
              key={s}
              onPress={() => setForm((f) => ({ ...f, status: s }))}
              style={[
                styles.chip,
                { backgroundColor: form.status === s ? STATUS_COLOR[s] : colors.muted },
              ]}
            >
              <Text
                style={[
                  styles.chipText,
                  { color: form.status === s ? "#fff" : colors.foreground },
                ]}
              >
                {STATUS_LABEL[s]}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <FormInput
          label="Notlar"
          value={form.notes}
          onChangeText={set("notes")}
          multiline
          style={{ height: 70, textAlignVertical: "top" }}
        />

        {canEdit ? (
          <PrimaryButton label="Kaydet" onPress={save} style={{ marginTop: 8 }} />
        ) : null}
        {canEdit && editId ? (
          <PrimaryButton label="Sil" variant="danger" onPress={remove} style={{ marginTop: 10 }} />
        ) : null}
        {!canEdit ? (
          <PrimaryButton label="Kapat" onPress={() => setVisible(false)} style={{ marginTop: 8 }} />
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
  cardHead: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 10,
    marginBottom: 10,
  },
  cardName: { fontSize: 15, fontFamily: "Inter_700Bold" },
  cardProj: { fontSize: 11, fontFamily: "Inter_600SemiBold", marginTop: 2 },
  statusBadge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 5,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 999,
  },
  statusDot: { width: 6, height: 6, borderRadius: 3 },
  statusText: { fontSize: 11, fontFamily: "Inter_600SemiBold" },
  metaGrid: { flexDirection: "row", flexWrap: "wrap", gap: 10 },
  metaItem: { flexDirection: "row", alignItems: "center", gap: 5 },
  metaText: { fontSize: 12, fontFamily: "Inter_400Regular" },
  dateRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginTop: 10,
    paddingTop: 10,
    borderTopWidth: 1,
  },
  dateText: { fontSize: 11, fontFamily: "Inter_500Medium" },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  chip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999 },
  chipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
  row: { flexDirection: "row", gap: 8 },
});
