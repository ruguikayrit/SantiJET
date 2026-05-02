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
import ProjectPicker from "@/components/ProjectPicker";
import { Hakedis, HakedisItem, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

type Status = Hakedis["status"];

interface F {
  projectId: string;
  number: string;
  date: string;
  period: string;
  contractor: string;
  status: Status;
  notes: string;
}

interface TempItem {
  description: string;
  unit: string;
  quantity: string;
  unitPrice: string;
}

const EMPTY_F: F = {
  projectId: "",
  number: "",
  date: "",
  period: "",
  contractor: "",
  status: "draft",
  notes: "",
};

const EMPTY_ITEM: TempItem = { description: "", unit: "", quantity: "", unitPrice: "" };

const STATUS_LABELS: Record<Status, string> = {
  draft: "Taslak",
  submitted: "Gönderildi",
  approved: "Onaylandı",
  paid: "Ödendi",
};

const STATUS_COLORS: Record<Status, string> = {
  draft: "#94a3b8",
  submitted: "#0ea5e9",
  approved: "#16a34a",
  paid: "#e85d04",
};

function genItemId() {
  return Date.now().toString() + Math.random().toString(36).substr(2, 6);
}

function calcTotal(items: HakedisItem[]) {
  return items.reduce((s, i) => s + i.quantity * i.unitPrice, 0);
}

export default function HakedisScreen() {
  const colors = useColors();
  const router = useRouter();
  const { projects, hakedisler, addHakedis, updateHakedis, deleteHakedis } = useApp();
  const perm = usePermission("hakedis");
  const canEdit = perm === "edit";
  useEffect(() => { if (perm === "none") router.back(); }, [perm]);

  const [filter, setFilter] = useState<string | null>(null);
  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<F>(EMPTY_F);
  const [items, setItems] = useState<HakedisItem[]>([]);
  const [tempItem, setTempItem] = useState<TempItem>(EMPTY_ITEM);

  const list = useMemo(
    () => (filter ? hakedisler.filter((h) => h.projectId === filter) : hakedisler),
    [hakedisler, filter]
  );

  function open(h?: Hakedis) {
    if (h) {
      setEditId(h.id);
      setForm({
        projectId: h.projectId,
        number: h.number,
        date: h.date,
        period: h.period,
        contractor: h.contractor,
        status: h.status,
        notes: h.notes,
      });
      setItems(h.items ? [...h.items] : []);
    } else {
      setEditId(null);
      setForm({ ...EMPTY_F, projectId: filter || projects[0]?.id || "" });
      setItems([]);
    }
    setTempItem(EMPTY_ITEM);
    setVisible(true);
  }

  function addItem() {
    if (!tempItem.description.trim()) return;
    const newItem: HakedisItem = {
      id: genItemId(),
      description: tempItem.description.trim(),
      unit: tempItem.unit.trim(),
      quantity: parseFloat(tempItem.quantity) || 0,
      unitPrice: parseFloat(tempItem.unitPrice) || 0,
    };
    setItems((prev) => [...prev, newItem]);
    setTempItem(EMPTY_ITEM);
  }

  function removeItem(id: string) {
    setItems((prev) => prev.filter((i) => i.id !== id));
  }

  function save() {
    if (!form.projectId || !form.number.trim()) return;
    const data = {
      projectId: form.projectId,
      number: form.number.trim(),
      date: form.date.trim(),
      period: form.period.trim(),
      contractor: form.contractor.trim(),
      status: form.status,
      notes: form.notes.trim(),
      items,
    };
    if (editId) updateHakedis(editId, data);
    else addHakedis(data);
    setVisible(false);
  }

  function remove() {
    if (editId) deleteHakedis(editId);
    setVisible(false);
  }

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  const STATUSES: Status[] = ["draft", "submitted", "approved", "paid"];

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Hakediş"
        onBack={() => router.back()}
        rightAction={canEdit && projects.length > 0 ? { icon: "plus", onPress: () => open() } : undefined}
      />

      <ProjectPicker projects={projects} value={filter} onChange={setFilter} />

      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="Hakediş takibi için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : list.length === 0 ? (
        <EmptyState
          icon="file-text"
          title="Hakediş kaydı yok"
          description="Yeni hakediş eklemek için + düğmesine dokunun"
          actionLabel="Hakediş Ekle"
          onAction={() => open()}
        />
      ) : (
        <FlatList
          data={list}
          keyExtractor={(h) => h.id}
          contentContainerStyle={styles.list}
          renderItem={({ item }) => {
            const total = calcTotal(item.items || []);
            return (
              <TouchableOpacity
                style={[styles.card, { backgroundColor: colors.card }]}
                activeOpacity={0.85}
                onPress={() => open(item)}
              >
                <View style={styles.cardTop}>
                  <View style={styles.cardLeft}>
                    <Text style={[styles.proj, { color: colors.primary }]}>
                      {projectName(item.projectId)}
                    </Text>
                    <Text style={[styles.cardTitle, { color: colors.foreground }]}>
                      Hakediş #{item.number}
                    </Text>
                    {item.period ? (
                      <Text style={[styles.cardSub, { color: colors.mutedForeground }]}>
                        {item.period}
                      </Text>
                    ) : null}
                  </View>
                  <View
                    style={[
                      styles.statusBadge,
                      { backgroundColor: STATUS_COLORS[item.status] + "22" },
                    ]}
                  >
                    <Text style={[styles.statusText, { color: STATUS_COLORS[item.status] }]}>
                      {STATUS_LABELS[item.status]}
                    </Text>
                  </View>
                </View>

                <View style={[styles.divider, { backgroundColor: colors.muted }]} />

                <View style={styles.cardMeta}>
                  {item.contractor ? (
                    <View style={styles.metaRow}>
                      <Feather name="user" size={13} color={colors.mutedForeground} />
                      <Text style={[styles.metaText, { color: colors.mutedForeground }]}>
                        {item.contractor}
                      </Text>
                    </View>
                  ) : null}
                  {item.date ? (
                    <View style={styles.metaRow}>
                      <Feather name="calendar" size={13} color={colors.mutedForeground} />
                      <Text style={[styles.metaText, { color: colors.mutedForeground }]}>
                        {item.date}
                      </Text>
                    </View>
                  ) : null}
                </View>

                <View style={styles.totalRow}>
                  <Text style={[styles.totalLabel, { color: colors.mutedForeground }]}>
                    {(item.items || []).length} kalem
                  </Text>
                  <Text style={[styles.totalAmount, { color: colors.primary }]}>
                    {total.toLocaleString("tr-TR")} ₺
                  </Text>
                </View>
              </TouchableOpacity>
            );
          }}
        />
      )}

      <BottomSheet
        visible={visible}
        onClose={() => setVisible(false)}
        title={editId ? "Hakediş Düzenle" : "Yeni Hakediş"}
      >
        <ScrollView showsVerticalScrollIndicator={false}>
          <Text style={[styles.label, { color: colors.foreground }]}>Proje</Text>
          <View style={styles.chips}>
            {projects.map((p) => (
              <TouchableOpacity
                key={p.id}
                onPress={() => setForm({ ...form, projectId: p.id })}
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

          <View style={styles.row}>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Hakediş No"
                value={form.number}
                onChangeText={(v) => setForm({ ...form, number: v })}
                placeholder="Örn: 001"
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
            label="Dönem"
            value={form.period}
            onChangeText={(v) => setForm({ ...form, period: v })}
            placeholder="Örn: Ocak 2025"
          />
          <FormInput
            label="Yüklenici / Firma"
            value={form.contractor}
            onChangeText={(v) => setForm({ ...form, contractor: v })}
            placeholder="Yüklenici adı"
          />

          <Text style={[styles.label, { color: colors.foreground }]}>Durum</Text>
          <View style={styles.chips}>
            {STATUSES.map((s) => (
              <TouchableOpacity
                key={s}
                onPress={() => setForm({ ...form, status: s })}
                style={[
                  styles.chip,
                  {
                    backgroundColor:
                      form.status === s ? STATUS_COLORS[s] : colors.muted,
                  },
                ]}
              >
                <Text
                  style={[
                    styles.chipText,
                    { color: form.status === s ? "#fff" : colors.foreground },
                  ]}
                >
                  {STATUS_LABELS[s]}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          <FormInput
            label="Notlar"
            value={form.notes}
            onChangeText={(v) => setForm({ ...form, notes: v })}
            placeholder="Açıklama veya not"
            multiline
          />

          <Text style={[styles.sectionTitle, { color: colors.foreground }]}>
            Kalemler ({items.length})
          </Text>

          {items.map((it) => (
            <View
              key={it.id}
              style={[styles.itemRow, { backgroundColor: colors.muted }]}
            >
              <View style={{ flex: 1 }}>
                <Text style={[styles.itemDesc, { color: colors.foreground }]}>
                  {it.description}
                </Text>
                <Text style={[styles.itemMeta, { color: colors.mutedForeground }]}>
                  {it.quantity} {it.unit} × {it.unitPrice.toLocaleString("tr-TR")} ₺ ={" "}
                  <Text style={{ color: colors.primary }}>
                    {(it.quantity * it.unitPrice).toLocaleString("tr-TR")} ₺
                  </Text>
                </Text>
              </View>
              <TouchableOpacity onPress={() => removeItem(it.id)} hitSlop={8}>
                <Feather name="x" size={18} color="#dc2626" />
              </TouchableOpacity>
            </View>
          ))}

          <View style={[styles.addItemBox, { borderColor: colors.muted, backgroundColor: colors.card }]}>
            <Text style={[styles.addItemTitle, { color: colors.foreground }]}>Kalem Ekle</Text>
            <FormInput
              label="Tarif / Açıklama"
              value={tempItem.description}
              onChangeText={(v) => setTempItem({ ...tempItem, description: v })}
              placeholder="İş kalemi açıklaması"
            />
            <View style={styles.row}>
              <View style={{ flex: 1 }}>
                <FormInput
                  label="Birim"
                  value={tempItem.unit}
                  onChangeText={(v) => setTempItem({ ...tempItem, unit: v })}
                  placeholder="m², m³, ad"
                />
              </View>
              <View style={{ flex: 1 }}>
                <FormInput
                  label="Miktar"
                  value={tempItem.quantity}
                  onChangeText={(v) => setTempItem({ ...tempItem, quantity: v })}
                  keyboardType="numeric"
                />
              </View>
            </View>
            <FormInput
              label="Birim Fiyat (₺)"
              value={tempItem.unitPrice}
              onChangeText={(v) => setTempItem({ ...tempItem, unitPrice: v })}
              keyboardType="numeric"
            />
            <PrimaryButton label="Kalemi Listele" onPress={addItem} style={{ marginTop: 4 }} />
          </View>

          {items.length > 0 ? (
            <View style={[styles.totalBox, { backgroundColor: colors.primary + "15" }]}>
              <Text style={[styles.totalBoxLabel, { color: colors.mutedForeground }]}>
                Toplam Hakediş
              </Text>
              <Text style={[styles.totalBoxAmount, { color: colors.primary }]}>
                {calcTotal(items).toLocaleString("tr-TR")} ₺
              </Text>
            </View>
          ) : null}

          {canEdit ? <PrimaryButton label="Kaydet" onPress={save} style={{ marginTop: 12 }} /> : null}
          {canEdit && editId ? (
            <PrimaryButton label="Sil" variant="danger" onPress={remove} style={{ marginTop: 10, marginBottom: 8 }} />
          ) : null}
          {!canEdit ? <PrimaryButton label="Kapat" onPress={() => setVisible(false)} style={{ marginTop: 12, marginBottom: 8 }} /> : null}
          {canEdit && !editId ? <View style={{ height: 8 }} /> : null}
        </ScrollView>
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
  cardTop: { flexDirection: "row", justifyContent: "space-between", alignItems: "flex-start" },
  cardLeft: { flex: 1, marginRight: 8 },
  proj: { fontSize: 12, fontFamily: "Inter_600SemiBold", marginBottom: 2 },
  cardTitle: { fontSize: 16, fontFamily: "Inter_700Bold" },
  cardSub: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
  statusBadge: { paddingHorizontal: 10, paddingVertical: 4, borderRadius: 999 },
  statusText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
  divider: { height: 1, marginVertical: 10 },
  cardMeta: { flexDirection: "row", gap: 16, marginBottom: 10 },
  metaRow: { flexDirection: "row", alignItems: "center", gap: 4 },
  metaText: { fontSize: 12, fontFamily: "Inter_400Regular" },
  totalRow: { flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  totalLabel: { fontSize: 12, fontFamily: "Inter_400Regular" },
  totalAmount: { fontSize: 16, fontFamily: "Inter_700Bold" },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  chip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999 },
  chipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
  row: { flexDirection: "row", gap: 8 },
  sectionTitle: {
    fontSize: 14,
    fontFamily: "Inter_700Bold",
    marginTop: 8,
    marginBottom: 10,
  },
  itemRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    padding: 10,
    borderRadius: 8,
    marginBottom: 6,
  },
  itemDesc: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
  itemMeta: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
  addItemBox: {
    borderWidth: 1,
    borderRadius: 10,
    padding: 12,
    marginTop: 8,
    marginBottom: 10,
  },
  addItemTitle: { fontSize: 13, fontFamily: "Inter_700Bold", marginBottom: 8 },
  totalBox: {
    borderRadius: 10,
    padding: 14,
    marginBottom: 8,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  totalBoxLabel: { fontSize: 13, fontFamily: "Inter_500Medium" },
  totalBoxAmount: { fontSize: 20, fontFamily: "Inter_700Bold" },
});
