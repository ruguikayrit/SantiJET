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
import { BudgetEntry, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

const TYPE_LABEL: Record<BudgetEntry["type"], string> = {
  income: "Gelir",
  expense: "Gider",
};
const TYPE_COLOR: Record<BudgetEntry["type"], string> = {
  income: "#16a34a",
  expense: "#dc2626",
};

interface F {
  projectId: string;
  type: BudgetEntry["type"];
  category: string;
  description: string;
  amount: string;
  date: string;
}

const EMPTY: F = {
  projectId: "",
  type: "expense",
  category: "",
  description: "",
  amount: "",
  date: "",
};

export default function ButceScreen() {
  const colors = useColors();
  const router = useRouter();
  const { projects, budget, addBudget, updateBudget, deleteBudget } = useApp();

  const perm = usePermission("butce");
  const canEdit = perm === "edit";
  useEffect(() => { if (perm === "none") { if (router.canGoBack()) router.back(); else router.replace("/"); } }, [perm]);

  const [filter, setFilter] = useState<string | null>(null);
  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<F>(EMPTY);

  const list = useMemo(() => {
    const arr = filter ? budget.filter((b) => b.projectId === filter) : budget;
    return [...arr].sort((a, b) => b.date.localeCompare(a.date));
  }, [budget, filter]);

  const summary = useMemo(() => {
    let income = 0, expense = 0;
    for (const b of list) {
      if (b.type === "income") income += b.amount;
      else expense += b.amount;
    }
    return { income, expense, net: income - expense };
  }, [list]);

  function open(b?: BudgetEntry) {
    if (b) {
      setEditId(b.id);
      setForm({
        projectId: b.projectId,
        type: b.type,
        category: b.category,
        description: b.description,
        amount: String(b.amount || ""),
        date: b.date,
      });
    } else {
      setEditId(null);
      setForm({ ...EMPTY, projectId: filter || projects[0]?.id || "" });
    }
    setVisible(true);
  }

  function save() {
    if (!form.projectId || !form.amount) return;
    const data = {
      projectId: form.projectId,
      type: form.type,
      category: form.category.trim(),
      description: form.description.trim(),
      amount: parseFloat(form.amount) || 0,
      date: form.date.trim(),
    };
    if (editId) updateBudget(editId, data);
    else addBudget(data);
    setVisible(false);
  }

  function remove() {
    if (editId) deleteBudget(editId);
    setVisible(false);
  }

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Yaklaşık Maliyet"
        onBack={() => (router.canGoBack() ? router.back() : router.replace("/"))}
        rightAction={canEdit && projects.length > 0 ? { icon: "plus", onPress: () => open() } : undefined}
      />


      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="Yaklaşık maliyet takibi için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : (
        <>
          <View style={styles.summaryRow}>
            <View style={[styles.sumBox, { backgroundColor: TYPE_COLOR.income + "22" }]}>
              <Text style={[styles.sumLabel, { color: colors.foreground }]}>Gelir</Text>
              <Text style={[styles.sumNum, { color: TYPE_COLOR.income }]}>
                {summary.income.toLocaleString("tr-TR")} ₺
              </Text>
            </View>
            <View style={[styles.sumBox, { backgroundColor: TYPE_COLOR.expense + "22" }]}>
              <Text style={[styles.sumLabel, { color: colors.foreground }]}>Gider</Text>
              <Text style={[styles.sumNum, { color: TYPE_COLOR.expense }]}>
                {summary.expense.toLocaleString("tr-TR")} ₺
              </Text>
            </View>
            <View style={[styles.sumBox, { backgroundColor: colors.secondary + "22" }]}>
              <Text style={[styles.sumLabel, { color: colors.foreground }]}>Net</Text>
              <Text
                style={[
                  styles.sumNum,
                  { color: summary.net >= 0 ? TYPE_COLOR.income : TYPE_COLOR.expense },
                ]}
              >
                {summary.net.toLocaleString("tr-TR")} ₺
              </Text>
            </View>
          </View>

          {list.length === 0 ? (
            <EmptyState
              icon="dollar-sign"
              title="Kayıt yok"
              description="Yeni gelir veya gider eklemek için + düğmesine dokunun"
              actionLabel="Kayıt Ekle"
              onAction={() => open()}
            />
          ) : (
            <FlatList
              data={list}
              keyExtractor={(b) => b.id}
              contentContainerStyle={styles.list}
              renderItem={({ item }) => (
                <TouchableOpacity
                  style={[styles.card, { backgroundColor: colors.card }]}
                  activeOpacity={0.85}
                  onPress={() => open(item)}
                >
                  <View
                    style={[
                      styles.iconBox,
                      { backgroundColor: TYPE_COLOR[item.type] + "22" },
                    ]}
                  >
                    <Feather
                      name={item.type === "income" ? "arrow-down-left" : "arrow-up-right"}
                      size={18}
                      color={TYPE_COLOR[item.type]}
                    />
                  </View>
                  <View style={{ flex: 1 }}>
                    <Text style={[styles.proj, { color: colors.primary }]}>
                      {projectName(item.projectId)}
                    </Text>
                    <Text style={[styles.title, { color: colors.foreground }]}>
                      {item.category || TYPE_LABEL[item.type]}
                    </Text>
                    {item.description ? (
                      <Text
                        style={[styles.desc, { color: colors.mutedForeground }]}
                        numberOfLines={1}
                      >
                        {item.description}
                      </Text>
                    ) : null}
                    {item.date ? (
                      <Text style={[styles.date, { color: colors.mutedForeground }]}>
                        {item.date}
                      </Text>
                    ) : null}
                  </View>
                  <Text
                    style={[
                      styles.amount,
                      { color: TYPE_COLOR[item.type] },
                    ]}
                  >
                    {item.type === "income" ? "+" : "-"}
                    {item.amount.toLocaleString("tr-TR")} ₺
                  </Text>
                </TouchableOpacity>
              )}
            />
          )}
        </>
      )}

      <BottomSheet
        visible={visible}
        onClose={() => setVisible(false)}
        title={editId ? "Kaydı Düzenle" : "Yeni Kayıt"}
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

        <Text style={[styles.label, { color: colors.foreground }]}>Tür</Text>
        <View style={styles.chips}>
          {(Object.keys(TYPE_LABEL) as BudgetEntry["type"][]).map((t) => (
            <TouchableOpacity
              key={t}
              onPress={() => setForm({ ...form, type: t })}
              style={[styles.chip, { backgroundColor: form.type === t ? TYPE_COLOR[t] : colors.muted }]}
            >
              <Text style={[styles.chipText, { color: form.type === t ? "#fff" : colors.foreground }]}>
                {TYPE_LABEL[t]}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <FormInput
          label="Kategori"
          value={form.category}
          onChangeText={(v) => setForm({ ...form, category: v })}
          placeholder="Örn: İşçilik, Malzeme, Yakıt"
        />
        <FormInput
          label="Tutar (₺)"
          value={form.amount}
          onChangeText={(v) => setForm({ ...form, amount: v })}
          keyboardType="numeric"
        />
        <DatePickerInput
          label="Tarih"
          value={form.date}
          onChange={(v) => setForm({ ...form, date: v })}
        />
        <FormInput
          label="Açıklama"
          value={form.description}
          onChangeText={(v) => setForm({ ...form, description: v })}
          multiline
          style={{ height: 70, textAlignVertical: "top" }}
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
  summaryRow: {
    flexDirection: "row",
    gap: 8,
    paddingHorizontal: 16,
    marginTop: 12,
  },
  sumBox: {
    flex: 1,
    padding: 10,
    borderRadius: 10,
    alignItems: "center",
  },
  sumLabel: { fontSize: 11, fontFamily: "Inter_500Medium" },
  sumNum: { fontSize: 14, fontFamily: "Inter_700Bold", marginTop: 4 },
  list: { padding: 16, gap: 10 },
  card: {
    borderRadius: 12,
    padding: 12,
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  iconBox: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: "center",
    alignItems: "center",
  },
  proj: { fontSize: 11, fontFamily: "Inter_600SemiBold", marginBottom: 2 },
  title: { fontSize: 15, fontFamily: "Inter_600SemiBold" },
  desc: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
  date: { fontSize: 11, fontFamily: "Inter_400Regular", marginTop: 2 },
  amount: { fontSize: 15, fontFamily: "Inter_700Bold" },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  chip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999 },
  chipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
});
