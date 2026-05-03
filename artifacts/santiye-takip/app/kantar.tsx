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
import CategoryPicker from "@/components/CategoryPicker";
import DatePickerInput from "@/components/DatePickerInput";
import EmptyState from "@/components/EmptyState";
import FormInput from "@/components/FormInput";
import Header from "@/components/Header";
import MaterialPicker from "@/components/MaterialPicker";
import PrimaryButton from "@/components/PrimaryButton";
import UnitPicker from "@/components/UnitPicker";
import { Weighbridge, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

interface F {
  projectId: string;
  date: string;
  materialName: string;
  category: string;
  supplier: string;
  plate: string;
  irsaliyeNo: string;
  grossWeight: string;
  tareWeight: string;
  unit: string;
  entryTime: string;
  exitTime: string;
  supplierIrsaliyeNo: string;
  supplierGrossWeight: string;
  supplierTareWeight: string;
}

const EMPTY: F = {
  projectId: "",
  date: "",
  materialName: "",
  category: "",
  supplier: "",
  plate: "",
  irsaliyeNo: "",
  grossWeight: "",
  tareWeight: "",
  unit: "kg",
  entryTime: "",
  exitTime: "",
  supplierIrsaliyeNo: "",
  supplierGrossWeight: "",
  supplierTareWeight: "",
};

function nowHHmm() {
  const d = new Date();
  return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}

function fmtNum(n: number) {
  return n.toLocaleString("tr-TR", { maximumFractionDigits: 2 });
}

export default function KantarScreen() {
  const colors = useColors();
  const router = useRouter();
  const {
    projects,
    materials,
    weighbridges,
    addWeighbridge,
    updateWeighbridge,
    deleteWeighbridge,
  } = useApp();

  const perm = usePermission("kantar");
  const canEdit = perm === "edit";
  useEffect(() => {
    if (perm === "none") {
      if (router.canGoBack()) router.back();
      else router.replace("/");
    }
  }, [perm]);

  const [filter, setFilter] = useState<string | null>(null);
  const [materialFilter, setMaterialFilter] = useState<string | null>(null);
  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<F>(EMPTY);

  const projectScoped = useMemo(
    () => (filter ? weighbridges.filter((w) => w.projectId === filter) : weighbridges),
    [weighbridges, filter]
  );

  const materialNames = useMemo(() => {
    const set = new Set<string>();
    for (const w of projectScoped) {
      const name = (w.materialName || "").trim();
      if (name) set.add(name);
    }
    return Array.from(set).sort((a, b) => a.localeCompare(b, "tr"));
  }, [projectScoped]);

  // Aktif malzeme filtresi mevcut listede yoksa otomatik temizle
  useEffect(() => {
    if (materialFilter && !materialNames.includes(materialFilter)) {
      setMaterialFilter(null);
    }
  }, [materialFilter, materialNames]);

  const list = useMemo(() => {
    const arr = materialFilter
      ? projectScoped.filter((w) => (w.materialName || "").trim() === materialFilter)
      : projectScoped;
    return [...arr].sort((a, b) => (b.date || "").localeCompare(a.date || ""));
  }, [projectScoped, materialFilter]);

  const summary = useMemo(() => {
    let totalNet = 0;
    let pending = 0;
    for (const w of list) {
      totalNet += w.netWeight || 0;
      if (!w.grossWeight || !w.tareWeight) pending += 1;
    }
    return { count: list.length, totalNet, pending };
  }, [list]);

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  function open(w?: Weighbridge) {
    if (w) {
      setEditId(w.id);
      // Bağlı malzemeden güncel ad/kategori/birim bilgisini çek (varsa)
      const linked = w.materialId ? materials.find((m) => m.id === w.materialId) : undefined;
      setForm({
        projectId: w.projectId,
        date: w.date,
        materialName: linked?.name || w.materialName,
        category: linked?.category || w.category || "",
        supplier: w.supplier || linked?.supplier || "",
        plate: w.plate,
        irsaliyeNo: w.irsaliyeNo,
        grossWeight: String(w.grossWeight || ""),
        tareWeight: String(w.tareWeight || ""),
        unit: w.unit || linked?.unit || "kg",
        entryTime: w.entryTime || "",
        exitTime: w.exitTime || "",
        supplierIrsaliyeNo: w.supplierIrsaliyeNo || "",
        supplierGrossWeight: w.supplierGrossWeight != null ? String(w.supplierGrossWeight) : "",
        supplierTareWeight: w.supplierTareWeight != null ? String(w.supplierTareWeight) : "",
      });
    } else {
      setEditId(null);
      setForm({
        ...EMPTY,
        projectId: filter || projects[0]?.id || "",
        date: new Date().toISOString().slice(0, 10),
        entryTime: nowHHmm(),
      });
    }
    setVisible(true);
  }

  function save() {
    if (!form.projectId || !form.materialName.trim()) return;
    const gross = parseFloat(form.grossWeight) || 0;
    const tare = parseFloat(form.tareWeight) || 0;
    const data: Omit<Weighbridge, "id"> = {
      projectId: form.projectId,
      date: form.date.trim(),
      materialName: form.materialName.trim(),
      category: form.category.trim() || undefined,
      supplier: form.supplier.trim(),
      plate: form.plate.trim().toUpperCase(),
      driver: "",
      irsaliyeNo: form.irsaliyeNo.trim(),
      grossWeight: gross,
      tareWeight: tare,
      netWeight: Math.max(0, gross - tare),
      unit: form.unit.trim() || "kg",
      notes: "",
      entryTime: form.entryTime.trim() || undefined,
      exitTime: form.exitTime.trim() || undefined,
      supplierIrsaliyeNo: form.supplierIrsaliyeNo.trim() || undefined,
      supplierGrossWeight: form.supplierGrossWeight.trim() ? parseFloat(form.supplierGrossWeight) || 0 : undefined,
      supplierTareWeight: form.supplierTareWeight.trim() ? parseFloat(form.supplierTareWeight) || 0 : undefined,
      supplierTonnage:
        form.supplierGrossWeight.trim() || form.supplierTareWeight.trim()
          ? Math.max(0, (parseFloat(form.supplierGrossWeight) || 0) - (parseFloat(form.supplierTareWeight) || 0))
          : undefined,
    };
    if (editId) updateWeighbridge(editId, data);
    else addWeighbridge(data);
    setVisible(false);
  }

  function remove() {
    if (editId) deleteWeighbridge(editId);
    setVisible(false);
  }

  const formNet = useMemo(() => {
    const g = parseFloat(form.grossWeight) || 0;
    const t = parseFloat(form.tareWeight) || 0;
    return Math.max(0, g - t);
  }, [form.grossWeight, form.tareWeight]);

  const supplierFormNet = useMemo(() => {
    const g = parseFloat(form.supplierGrossWeight) || 0;
    const t = parseFloat(form.supplierTareWeight) || 0;
    return Math.max(0, g - t);
  }, [form.supplierGrossWeight, form.supplierTareWeight]);

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Kantar"
        onBack={() => (router.canGoBack() ? router.back() : router.replace("/"))}
        rightAction={canEdit && projects.length > 0 ? { icon: "plus", onPress: () => open() } : undefined}
      />


      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="Kantar fişleri için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : (
        <>
          {materialNames.length > 0 ? (
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.matFilters}
              style={styles.matFiltersWrap}
            >
              <TouchableOpacity
                onPress={() => setMaterialFilter(null)}
                style={[
                  styles.matChip,
                  {
                    backgroundColor:
                      materialFilter === null ? "#0d9488" : colors.muted,
                  },
                ]}
              >
                <Text
                  style={[
                    styles.matChipText,
                    { color: materialFilter === null ? "#fff" : colors.foreground },
                  ]}
                >
                  Tümü ({projectScoped.length})
                </Text>
              </TouchableOpacity>
              {materialNames.map((name) => {
                const count = projectScoped.filter(
                  (w) => (w.materialName || "").trim() === name
                ).length;
                const active = materialFilter === name;
                return (
                  <TouchableOpacity
                    key={name}
                    onPress={() => setMaterialFilter(active ? null : name)}
                    style={[
                      styles.matChip,
                      { backgroundColor: active ? "#0d9488" : colors.muted },
                    ]}
                  >
                    <Text
                      style={[
                        styles.matChipText,
                        { color: active ? "#fff" : colors.foreground },
                      ]}
                      numberOfLines={1}
                    >
                      {name} ({count})
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
          ) : null}

          <View style={styles.summaryRow}>
            <View style={[styles.sumBox, { backgroundColor: "#16213e22" }]}>
              <Text style={[styles.sumLabel, { color: colors.foreground }]}>Fiş</Text>
              <Text style={[styles.sumNum, { color: "#16213e" }]}>{summary.count}</Text>
            </View>
            <View style={[styles.sumBox, { backgroundColor: "#0d948822" }]}>
              <Text style={[styles.sumLabel, { color: colors.foreground }]}>Toplam Net</Text>
              <Text style={[styles.sumNum, { color: "#0d9488" }]}>
                {materialFilter ? `${fmtNum(summary.totalNet)} kg` : "-"}
              </Text>
            </View>
            <View style={[styles.sumBox, { backgroundColor: "#d9770622" }]}>
              <Text style={[styles.sumLabel, { color: colors.foreground }]}>Tartılmamış</Text>
              <Text style={[styles.sumNum, { color: "#d97706" }]}>{summary.pending}</Text>
            </View>
          </View>

          {list.length === 0 ? (
            <EmptyState
              icon="truck"
              title="Kantar fişi yok"
              description="Kantara giren malzemenin irsaliye verilerini buraya girin"
              actionLabel={canEdit ? "Fiş Ekle" : undefined}
              onAction={canEdit ? () => open() : undefined}
            />
          ) : (
            <FlatList
              data={list}
              keyExtractor={(w) => w.id}
              contentContainerStyle={styles.list}
              renderItem={({ item }) => {
                const metaParts: string[] = [];
                if (item.date) metaParts.push(item.date);
                if (item.supplier) metaParts.push(item.supplier);
                if (item.entryTime || item.exitTime) {
                  metaParts.push(
                    `${item.entryTime || "—"} → ${item.exitTime || "—"}`
                  );
                }
                return (
                  <TouchableOpacity
                    style={[styles.card, { backgroundColor: colors.card }]}
                    activeOpacity={0.85}
                    onPress={canEdit ? () => open(item) : undefined}
                  >
                    <View
                      style={[
                        styles.iconBox,
                        { backgroundColor: "#0d948822" },
                      ]}
                    >
                      <Feather name="truck" size={20} color="#0d9488" />
                    </View>
                    <View style={{ flex: 1 }}>
                      <Text
                        style={[styles.proj, { color: colors.primary }]}
                        numberOfLines={1}
                      >
                        {projectName(item.projectId)}
                      </Text>
                      <Text
                        style={[styles.title, { color: colors.foreground }]}
                        numberOfLines={1}
                      >
                        {item.materialName}
                      </Text>
                      {metaParts.length > 0 ? (
                        <Text
                          style={[styles.meta, { color: colors.mutedForeground }]}
                          numberOfLines={2}
                        >
                          {metaParts.join(" · ")}
                        </Text>
                      ) : null}
                      {item.materialId ? (
                        <View style={styles.linkRow}>
                          <View
                            style={[
                              styles.linkBadge,
                              { backgroundColor: "#05966922" },
                            ]}
                          >
                            <Feather name="package" size={10} color="#059669" />
                            <Text
                              style={[styles.linkBadgeText, { color: "#059669" }]}
                            >
                              Gelen Malzeme
                            </Text>
                          </View>
                        </View>
                      ) : null}
                    </View>
                    <View style={styles.weightCol}>
                      <View style={styles.tonRow}>
                        <Text style={[styles.tonLabel, { color: colors.mutedForeground }]}>
                          Tedarikçi
                        </Text>
                        <Text style={[styles.tonVal, { color: "#0ea5e9" }]}>
                          {item.supplierTonnage != null ? fmtNum(item.supplierTonnage) : "—"}
                          <Text style={[styles.tonUnit, { color: colors.mutedForeground }]}>
                            {" "}{item.unit || "kg"}
                          </Text>
                        </Text>
                      </View>
                      <View style={[styles.tonRow, { marginTop: 6 }]}>
                        <Text style={[styles.tonLabel, { color: colors.mutedForeground }]}>
                          Şantiye
                        </Text>
                        <Text style={[styles.tonVal, { color: "#0d9488" }]}>
                          {fmtNum(item.netWeight)}
                          <Text style={[styles.tonUnit, { color: colors.mutedForeground }]}>
                            {" "}{item.unit || "kg"}
                          </Text>
                        </Text>
                      </View>
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
        title={editId ? "Kantar Fişini Düzenle" : "Kantar Fişi Ekle"}
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
                  {
                    backgroundColor:
                      form.projectId === p.id ? colors.primary : colors.muted,
                  },
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

          <DatePickerInput
            label="Tarih"
            value={form.date}
            onChange={(v) => setForm({ ...form, date: v })}
          />

          <CategoryPicker
            label="Kategori"
            value={form.category}
            onChange={(v) => setForm({ ...form, category: v })}
          />
          <MaterialPicker
            label="Malzeme"
            value={form.materialName}
            category={form.category}
            onChange={(name, cat, defUnit) =>
              setForm({
                ...form,
                materialName: name,
                category: cat,
                unit: defUnit || form.unit || "kg",
              })
            }
            placeholder="Örn: Hazır Beton C25"
          />

          <View style={styles.twoCol}>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Araç Plaka"
                value={form.plate}
                onChangeText={(v) => setForm({ ...form, plate: v })}
                placeholder="34 ABC 123"
                autoCapitalize="characters"
              />
            </View>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Kantar Fiş No"
                value={form.irsaliyeNo}
                onChangeText={(v) => setForm({ ...form, irsaliyeNo: v })}
                placeholder="Fiş numarası"
              />
            </View>
          </View>

          <FormInput
            label="Firma Adı"
            value={form.supplier}
            onChangeText={(v) => setForm({ ...form, supplier: v })}
            placeholder="Firma / Tedarikçi adı"
          />

          <UnitPicker
            label="Malzeme Birimi"
            value={form.unit}
            onChange={(v) => setForm({ ...form, unit: v })}
          />

          <View style={styles.twoCol}>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Dolu Miktar"
                value={form.grossWeight}
                onChangeText={(v) => setForm({ ...form, grossWeight: v })}
                keyboardType="numeric"
                placeholder="0"
              />
            </View>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Boş Miktar"
                value={form.tareWeight}
                onChangeText={(v) => setForm({ ...form, tareWeight: v })}
                keyboardType="numeric"
                placeholder="0"
              />
            </View>
          </View>

          <View style={[styles.netBox, { backgroundColor: "#0d948822" }]}>
            <View>
              <Text style={[styles.netBoxLabel, { color: colors.foreground }]}>
                Net Miktar
              </Text>
              <Text style={[styles.netBoxHint, { color: colors.mutedForeground }]}>
                Dolu − Boş otomatik hesaplanır
              </Text>
            </View>
            <Text style={[styles.netBoxVal, { color: "#0d9488" }]}>
              {fmtNum(formNet)} {form.unit || "kg"}
            </Text>
          </View>

          <View style={styles.twoCol}>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Giriş Saati"
                value={form.entryTime}
                onChangeText={(v) => setForm({ ...form, entryTime: v })}
                placeholder="08:30"
              />
            </View>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Çıkış Saati"
                value={form.exitTime}
                onChangeText={(v) => setForm({ ...form, exitTime: v })}
                placeholder="09:15"
              />
            </View>
          </View>
          <View style={{ flexDirection: "row", gap: 8, marginTop: -6, marginBottom: 12 }}>
            <TouchableOpacity
              onPress={() => setForm({ ...form, entryTime: nowHHmm() })}
              style={{ paddingHorizontal: 10, paddingVertical: 6, borderRadius: 999, backgroundColor: colors.muted }}
            >
              <Text style={{ fontSize: 11, color: colors.foreground }}>Şimdi (Giriş)</Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={() => setForm({ ...form, exitTime: nowHHmm() })}
              style={{ paddingHorizontal: 10, paddingVertical: 6, borderRadius: 999, backgroundColor: colors.muted }}
            >
              <Text style={{ fontSize: 11, color: colors.foreground }}>Şimdi (Çıkış)</Text>
            </TouchableOpacity>
          </View>

          <View style={[styles.sectionHeader, { borderTopColor: colors.muted }]}>
            <Feather name="file-text" size={14} color={colors.primary} />
            <Text style={[styles.sectionTitle, { color: colors.foreground }]}>
              Tedarikçi Kantar Fişi Bilgileri
            </Text>
          </View>
          <FormInput
            label="İrsaliye Numarası"
            value={form.supplierIrsaliyeNo}
            onChangeText={(v) => setForm({ ...form, supplierIrsaliyeNo: v })}
            placeholder="Tedarikçi irsaliye no"
          />

          <View style={styles.twoCol}>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Dolu Miktar"
                value={form.supplierGrossWeight}
                onChangeText={(v) => setForm({ ...form, supplierGrossWeight: v })}
                keyboardType="numeric"
                placeholder="0"
              />
            </View>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Boş Miktar"
                value={form.supplierTareWeight}
                onChangeText={(v) => setForm({ ...form, supplierTareWeight: v })}
                keyboardType="numeric"
                placeholder="0"
              />
            </View>
          </View>

          <View style={[styles.netBox, { backgroundColor: "#0ea5e922" }]}>
            <View>
              <Text style={[styles.netBoxLabel, { color: colors.foreground }]}>
                Tedarikçi Net Miktar
              </Text>
              <Text style={[styles.netBoxHint, { color: colors.mutedForeground }]}>
                Dolu − Boş otomatik hesaplanır
              </Text>
            </View>
            <Text style={[styles.netBoxVal, { color: "#0ea5e9" }]}>
              {fmtNum(supplierFormNet)} {form.unit || "kg"}
            </Text>
          </View>

          {canEdit ? <PrimaryButton label="Kaydet" onPress={save} style={{ marginTop: 8 }} /> : null}
          {canEdit && editId ? (
            <PrimaryButton label="Sil" variant="danger" onPress={remove} style={{ marginTop: 10 }} />
          ) : null}
          {!canEdit ? (
            <PrimaryButton label="Kapat" onPress={() => setVisible(false)} style={{ marginTop: 8 }} />
          ) : null}
        </ScrollView>
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  matFiltersWrap: {
    flexGrow: 0,
    flexShrink: 0,
  },
  matFilters: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    gap: 8,
    flexDirection: "row",
    alignItems: "center",
  },
  matChip: {
    paddingHorizontal: 12,
    height: 32,
    justifyContent: "center",
    borderRadius: 999,
    maxWidth: 220,
  },
  matChipText: { fontSize: 12, fontFamily: "Inter_500Medium" },
  summaryRow: { flexDirection: "row", gap: 8, paddingHorizontal: 16, marginTop: 4 },
  sumBox: { flex: 1, padding: 10, borderRadius: 10, alignItems: "center" },
  sumLabel: { fontSize: 11, fontFamily: "Inter_500Medium" },
  sumNum: { fontSize: 13, fontFamily: "Inter_700Bold", marginTop: 4 },
  list: { padding: 16, gap: 10 },
  card: {
    borderRadius: 12,
    padding: 12,
    flexDirection: "row",
    alignItems: "flex-start",
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
  proj: { fontSize: 11, fontFamily: "Inter_600SemiBold" },
  title: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginTop: 3 },
  meta: { fontSize: 11, fontFamily: "Inter_400Regular", marginTop: 4 },
  linkRow: { flexDirection: "row", marginTop: 6 },
  linkBadge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 3,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 999,
  },
  linkBadgeText: { fontSize: 10, fontFamily: "Inter_600SemiBold" },
  weightCol: { alignItems: "flex-end", minWidth: 130 },
  tonRow: { alignItems: "flex-end" },
  tonLabel: { fontSize: 10, fontFamily: "Inter_500Medium" },
  tonVal: { fontSize: 15, fontFamily: "Inter_700Bold", marginTop: 1 },
  tonUnit: { fontSize: 10, fontFamily: "Inter_500Medium" },
  netVal: { fontSize: 18, fontFamily: "Inter_700Bold" },
  netUnit: { fontSize: 11, fontFamily: "Inter_500Medium", marginTop: 1 },
  subWeight: { fontSize: 10, fontFamily: "Inter_400Regular", marginTop: 4, textAlign: "right" },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8, marginTop: 4 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  chip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999 },
  chipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
  twoCol: { flexDirection: "row", gap: 10 },
  netBox: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    padding: 12,
    borderRadius: 10,
    marginBottom: 14,
  },
  netBoxLabel: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
  netBoxHint: { fontSize: 11, fontFamily: "Inter_400Regular", marginTop: 2 },
  netBoxVal: { fontSize: 18, fontFamily: "Inter_700Bold" },
  sectionHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingTop: 14,
    marginTop: 8,
    marginBottom: 10,
    borderTopWidth: 1,
  },
  sectionTitle: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
});
