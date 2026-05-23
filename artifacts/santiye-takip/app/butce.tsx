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
import { Survey, SurveyItem, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

interface PriceForm {
  unitPrice: string;
}

export default function ButceScreen() {
  const colors = useColors();
  const router = useRouter();
  const { projects, surveys, updateSurvey } = useApp();

  const perm = usePermission("butce");
  const canEdit = perm === "edit";
  useEffect(() => {
    if (perm === "none") {
      if (router.canGoBack()) router.back();
      else router.replace("/");
    }
  }, [perm]);

  const [filterProject, setFilterProject] = useState<string | null>(null);
  const [visible, setVisible] = useState(false);
  const [editSurveyId, setEditSurveyId] = useState<string | null>(null);
  const [editItemId, setEditItemId] = useState<string | null>(null);
  const [priceForm, setPriceForm] = useState<PriceForm>({ unitPrice: "" });

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  const allItems = useMemo(() => {
    const base = filterProject
      ? surveys.filter((s) => s.projectId === filterProject)
      : surveys;
    return base.flatMap((s) =>
      s.items.map((it) => ({ ...it, surveyId: s.id, surveyTitle: s.title, projectId: s.projectId }))
    );
  }, [surveys, filterProject]);

  const totalMaliyet = useMemo(() => {
    return allItems.reduce((sum, it) => sum + it.quantity * (it.unitPrice ?? 0), 0);
  }, [allItems]);

  const totalMetraj = useMemo(() => {
    return allItems.reduce((sum, it) => sum + it.quantity, 0);
  }, [allItems]);

  const itemsWithPrice = useMemo(() => allItems.filter((it) => (it.unitPrice ?? 0) > 0), [allItems]);

  function openItem(surveyId: string, item: SurveyItem) {
    if (!canEdit) return;
    setEditSurveyId(surveyId);
    setEditItemId(item.id);
    setPriceForm({ unitPrice: item.unitPrice ? String(item.unitPrice) : "" });
    setVisible(true);
  }

  function savePriceForm() {
    if (!editSurveyId || !editItemId) return;
    const survey = surveys.find((s) => s.id === editSurveyId);
    if (!survey) return;
    const unitPrice = parseFloat(priceForm.unitPrice) || 0;
    const newItems = survey.items.map((it) =>
      it.id === editItemId ? { ...it, unitPrice } : it
    );
    updateSurvey(editSurveyId, { ...survey, items: newItems });
    setVisible(false);
  }

  const editingItem = useMemo(() => {
    if (!editSurveyId || !editItemId) return null;
    const s = surveys.find((x) => x.id === editSurveyId);
    return s?.items.find((i) => i.id === editItemId) ?? null;
  }, [editSurveyId, editItemId, surveys]);

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Yaklaşık Maliyet"
        onBack={() => (router.canGoBack() ? router.back() : router.replace("/"))}
      />

      {projects.length === 0 ? (
        <EmptyState
          icon="dollar-sign"
          title="Önce proje ekleyin"
          description="Yaklaşık maliyet takibi için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : (
        <>
          <View style={[styles.summaryCard, { backgroundColor: colors.card }]}>
            <View style={styles.sumRow}>
              <View style={styles.sumBox}>
                <Text style={[styles.sumLabel, { color: colors.mutedForeground }]}>Toplam Kalem</Text>
                <Text style={[styles.sumNum, { color: colors.foreground }]}>{allItems.length}</Text>
              </View>
              <View style={[styles.sumDivider, { backgroundColor: colors.border }]} />
              <View style={styles.sumBox}>
                <Text style={[styles.sumLabel, { color: colors.mutedForeground }]}>Fiyatlanan</Text>
                <Text style={[styles.sumNum, { color: "#16a34a" }]}>{itemsWithPrice.length}</Text>
              </View>
              <View style={[styles.sumDivider, { backgroundColor: colors.border }]} />
              <View style={styles.sumBox}>
                <Text style={[styles.sumLabel, { color: colors.mutedForeground }]}>Yaklaşık Maliyet</Text>
                <Text style={[styles.sumNum, { color: colors.primary }]} numberOfLines={1}>
                  {totalMaliyet.toLocaleString("tr-TR", { maximumFractionDigits: 0 })} ₺
                </Text>
              </View>
            </View>
          </View>

          {projects.length > 1 ? (
            <View style={styles.filterRow}>
              <TouchableOpacity
                onPress={() => setFilterProject(null)}
                style={[
                  styles.filterChip,
                  { backgroundColor: filterProject === null ? colors.primary : colors.muted },
                ]}
              >
                <Text style={[styles.filterChipText, { color: filterProject === null ? "#fff" : colors.foreground }]}>
                  Tüm Projeler
                </Text>
              </TouchableOpacity>
              {projects.map((p) => (
                <TouchableOpacity
                  key={p.id}
                  onPress={() => setFilterProject(p.id === filterProject ? null : p.id)}
                  style={[
                    styles.filterChip,
                    { backgroundColor: filterProject === p.id ? colors.primary : colors.muted },
                  ]}
                >
                  <Text style={[styles.filterChipText, { color: filterProject === p.id ? "#fff" : colors.foreground }]}>
                    {p.name}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          ) : null}

          {allItems.length === 0 ? (
            <EmptyState
              icon="search"
              title="Keşif kalemi yok"
              description="Keşif modülünden kalemler ekledikçe burada görünür"
              actionLabel="Keşif Modülüne Git"
              onAction={() => router.push("/kesif" as any)}
            />
          ) : (
            <FlatList
              data={allItems}
              keyExtractor={(it) => it.surveyId + "_" + it.id}
              contentContainerStyle={styles.list}
              renderItem={({ item }) => {
                const maliyet = item.quantity * (item.unitPrice ?? 0);
                const hasPrice = (item.unitPrice ?? 0) > 0;
                return (
                  <TouchableOpacity
                    style={[styles.card, { backgroundColor: colors.card }]}
                    activeOpacity={0.85}
                    onPress={() => openItem(item.surveyId, item)}
                  >
                    <View style={{ flex: 1 }}>
                      <View style={{ flexDirection: "row", alignItems: "center", gap: 6, marginBottom: 3 }}>
                        <Text style={[styles.proj, { color: colors.primary }]}>
                          {projectName(item.projectId)}
                        </Text>
                        <Text style={[styles.surveyTag, { color: colors.mutedForeground }]}>
                          · {item.surveyTitle}
                        </Text>
                      </View>
                      <View style={{ flexDirection: "row", alignItems: "center", gap: 6, marginBottom: 3 }}>
                        <View style={[
                          styles.typeBadge,
                          { backgroundColor: (item.itemType || "malzeme") === "malzeme" ? "#05966922" : "#0ea5e922" },
                        ]}>
                          <Text style={[styles.typeBadgeText, { color: (item.itemType || "malzeme") === "malzeme" ? "#059669" : "#0ea5e9" }]}>
                            {(item.itemType || "malzeme") === "malzeme" ? "Malzeme" : "İşçilik"}
                          </Text>
                        </View>
                        {item.pozCode ? (
                          <Text style={[styles.pozCode, { color: colors.primary }]} numberOfLines={1}>
                            {item.pozCode}
                          </Text>
                        ) : null}
                      </View>
                      <Text style={[styles.desc, { color: colors.foreground }]} numberOfLines={2}>
                        {item.description}
                      </Text>
                      <View style={styles.metaRow}>
                        <Text style={[styles.meta, { color: colors.mutedForeground }]}>
                          {item.quantity} {item.unit}
                        </Text>
                        <Text style={[styles.meta, { color: colors.mutedForeground }]}>×</Text>
                        <Text style={[styles.meta, { color: hasPrice ? colors.foreground : colors.mutedForeground }]}>
                          {hasPrice ? `${(item.unitPrice ?? 0).toLocaleString("tr-TR")} ₺/birim` : "Birim fiyat gir"}
                        </Text>
                      </View>
                    </View>
                    <View style={{ alignItems: "flex-end", gap: 4 }}>
                      {hasPrice ? (
                        <Text style={[styles.maliyet, { color: "#16a34a" }]}>
                          {maliyet.toLocaleString("tr-TR", { maximumFractionDigits: 0 })} ₺
                        </Text>
                      ) : (
                        <View style={[styles.priceBtn, { backgroundColor: colors.primary + "18", borderColor: colors.primary }]}>
                          <Feather name="edit-2" size={12} color={colors.primary} />
                          <Text style={[styles.priceBtnText, { color: colors.primary }]}>Fiyat</Text>
                        </View>
                      )}
                    </View>
                  </TouchableOpacity>
                );
              }}
            />
          )}
        </>
      )}

      <BottomSheet
        visible={visible}
        onClose={() => setVisible(false)}
        title="Birim Fiyat Gir"
      >
        {editingItem ? (
          <>
            <View style={[styles.itemPreview, { backgroundColor: colors.muted, borderColor: colors.border }]}>
              <Text style={[styles.previewDesc, { color: colors.foreground }]} numberOfLines={2}>
                {editingItem.description}
              </Text>
              <Text style={[styles.previewMeta, { color: colors.mutedForeground }]}>
                {editingItem.quantity} {editingItem.unit}
                {editingItem.pozCode ? `  ·  ${editingItem.pozCode}` : ""}
              </Text>
            </View>
            <FormInput
              label="Birim Fiyat (₺)"
              value={priceForm.unitPrice}
              onChangeText={(v) => setPriceForm({ unitPrice: v })}
              keyboardType="numeric"
              placeholder="Örn: 1250"
            />
            {priceForm.unitPrice && parseFloat(priceForm.unitPrice) > 0 ? (
              <View style={[styles.totalPreview, { backgroundColor: "#16a34a22", borderColor: "#16a34a" }]}>
                <Text style={[styles.totalPreviewLabel, { color: colors.mutedForeground }]}>Hesaplanan Maliyet</Text>
                <Text style={[styles.totalPreviewNum, { color: "#16a34a" }]}>
                  {(editingItem.quantity * (parseFloat(priceForm.unitPrice) || 0)).toLocaleString("tr-TR", { maximumFractionDigits: 0 })} ₺
                </Text>
                <Text style={[styles.totalPreviewSub, { color: colors.mutedForeground }]}>
                  {editingItem.quantity} {editingItem.unit} × {parseFloat(priceForm.unitPrice).toLocaleString("tr-TR")} ₺
                </Text>
              </View>
            ) : null}
            {canEdit ? (
              <PrimaryButton label="Kaydet" onPress={savePriceForm} style={{ marginTop: 12 }} />
            ) : null}
          </>
        ) : null}
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  summaryCard: {
    margin: 16,
    marginBottom: 8,
    borderRadius: 14,
    padding: 16,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 2,
  },
  sumRow: { flexDirection: "row", alignItems: "center" },
  sumBox: { flex: 1, alignItems: "center", gap: 4 },
  sumDivider: { width: StyleSheet.hairlineWidth, height: 36 },
  sumLabel: { fontSize: 10, fontFamily: "Inter_500Medium", textAlign: "center" },
  sumNum: { fontSize: 15, fontFamily: "Inter_700Bold", textAlign: "center" },
  filterRow: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
    paddingHorizontal: 16,
    marginBottom: 8,
  },
  filterChip: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: 999 },
  filterChipText: { fontSize: 12, fontFamily: "Inter_500Medium" },
  list: { padding: 16, gap: 10 },
  card: {
    borderRadius: 12,
    padding: 14,
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  proj: { fontSize: 11, fontFamily: "Inter_700Bold" },
  surveyTag: { fontSize: 11, fontFamily: "Inter_400Regular" },
  typeBadge: { paddingHorizontal: 7, paddingVertical: 2, borderRadius: 6 },
  typeBadgeText: { fontSize: 10, fontFamily: "Inter_700Bold" },
  pozCode: { fontSize: 11, fontFamily: "Inter_600SemiBold" },
  desc: { fontSize: 13, fontFamily: "Inter_600SemiBold", marginBottom: 4 },
  metaRow: { flexDirection: "row", alignItems: "center", gap: 6, flexWrap: "wrap" },
  meta: { fontSize: 12, fontFamily: "Inter_400Regular" },
  maliyet: { fontSize: 15, fontFamily: "Inter_700Bold" },
  priceBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    borderWidth: 1,
  },
  priceBtnText: { fontSize: 11, fontFamily: "Inter_600SemiBold" },
  itemPreview: {
    borderRadius: 10,
    padding: 12,
    borderWidth: StyleSheet.hairlineWidth,
    marginBottom: 16,
  },
  previewDesc: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 4 },
  previewMeta: { fontSize: 12, fontFamily: "Inter_400Regular" },
  totalPreview: {
    borderRadius: 10,
    padding: 14,
    borderWidth: 1,
    marginBottom: 8,
    alignItems: "center",
  },
  totalPreviewLabel: { fontSize: 11, fontFamily: "Inter_500Medium", marginBottom: 4 },
  totalPreviewNum: { fontSize: 22, fontFamily: "Inter_700Bold" },
  totalPreviewSub: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
});
