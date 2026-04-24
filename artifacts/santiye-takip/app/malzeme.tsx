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
import FormInput from "@/components/FormInput";
import Header from "@/components/Header";
import PrimaryButton from "@/components/PrimaryButton";
import ProjectPicker from "@/components/ProjectPicker";
import { Material, MaterialRequest, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

type Tab = "gelen" | "talep";

const REQUEST_STATUS = {
  pending:   { label: "Beklemede",     color: "#f59e0b", bg: "#fef3c7" },
  approved:  { label: "Onaylandı",     color: "#16a34a", bg: "#dcfce7" },
  delivered: { label: "Teslim Edildi", color: "#2563eb", bg: "#dbeafe" },
  rejected:  { label: "Reddedildi",   color: "#dc2626", bg: "#fee2e2" },
};

interface MF {
  projectId: string;
  name: string;
  unit: string;
  quantity: string;
  usedQty: string;
  supplier: string;
  deliveryDate: string;
  unitPrice: string;
}

interface RF {
  projectId: string;
  name: string;
  unit: string;
  quantity: string;
  requestDate: string;
  requestedBy: string;
  status: MaterialRequest["status"];
  note: string;
}

const EMPTY_M: MF = {
  projectId: "",
  name: "",
  unit: "",
  quantity: "",
  usedQty: "",
  supplier: "",
  deliveryDate: "",
  unitPrice: "",
};

const EMPTY_R: RF = {
  projectId: "",
  name: "",
  unit: "",
  quantity: "",
  requestDate: "",
  requestedBy: "",
  status: "pending",
  note: "",
};

export default function MalzemeScreen() {
  const colors = useColors();
  const router = useRouter();
  const {
    projects,
    materials,
    addMaterial,
    updateMaterial,
    deleteMaterial,
    materialRequests,
    addMaterialRequest,
    updateMaterialRequest,
    deleteMaterialRequest,
  } = useApp();

  const perm = usePermission("malzeme");
  const canEdit = perm === "edit";
  useEffect(() => { if (perm === "none") router.back(); }, [perm]);

  const [tab, setTab] = useState<Tab>("gelen");
  const [filter, setFilter] = useState<string | null>(null);

  const [mVisible, setMVisible] = useState(false);
  const [mEditId, setMEditId] = useState<string | null>(null);
  const [mForm, setMForm] = useState<MF>(EMPTY_M);

  const [rVisible, setRVisible] = useState(false);
  const [rEditId, setREditId] = useState<string | null>(null);
  const [rForm, setRForm] = useState<RF>(EMPTY_R);

  const filteredMaterials = useMemo(
    () => (filter ? materials.filter((m) => m.projectId === filter) : materials),
    [materials, filter]
  );

  const filteredRequests = useMemo(
    () => (filter ? materialRequests.filter((r) => r.projectId === filter) : materialRequests),
    [materialRequests, filter]
  );

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  function openMaterial(m?: Material) {
    if (m) {
      setMEditId(m.id);
      setMForm({
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
      setMEditId(null);
      setMForm({ ...EMPTY_M, projectId: filter || projects[0]?.id || "" });
    }
    setMVisible(true);
  }

  function saveMaterial() {
    if (!mForm.projectId || !mForm.name.trim()) return;
    const data = {
      projectId: mForm.projectId,
      name: mForm.name.trim(),
      unit: mForm.unit.trim(),
      quantity: parseFloat(mForm.quantity) || 0,
      usedQty: parseFloat(mForm.usedQty) || 0,
      supplier: mForm.supplier.trim(),
      deliveryDate: mForm.deliveryDate.trim(),
      unitPrice: parseFloat(mForm.unitPrice) || 0,
    };
    if (mEditId) updateMaterial(mEditId, data);
    else addMaterial(data);
    setMVisible(false);
  }

  function removeMaterial() {
    if (mEditId) deleteMaterial(mEditId);
    setMVisible(false);
  }

  function openRequest(r?: MaterialRequest) {
    if (r) {
      setREditId(r.id);
      setRForm({
        projectId: r.projectId,
        name: r.name,
        unit: r.unit,
        quantity: String(r.quantity || ""),
        requestDate: r.requestDate,
        requestedBy: r.requestedBy,
        status: r.status,
        note: r.note,
      });
    } else {
      setREditId(null);
      setRForm({ ...EMPTY_R, projectId: filter || projects[0]?.id || "" });
    }
    setRVisible(true);
  }

  function saveRequest() {
    if (!rForm.projectId || !rForm.name.trim()) return;
    const data = {
      projectId: rForm.projectId,
      name: rForm.name.trim(),
      unit: rForm.unit.trim(),
      quantity: parseFloat(rForm.quantity) || 0,
      requestDate: rForm.requestDate.trim(),
      requestedBy: rForm.requestedBy.trim(),
      status: rForm.status,
      note: rForm.note.trim(),
    };
    if (rEditId) updateMaterialRequest(rEditId, data);
    else addMaterialRequest(data);
    setRVisible(false);
  }

  function removeRequest() {
    if (rEditId) deleteMaterialRequest(rEditId);
    setRVisible(false);
  }

  const addAction = canEdit && projects.length > 0
    ? { icon: "plus" as const, onPress: () => tab === "gelen" ? openMaterial() : openRequest() }
    : undefined;

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Malzeme"
        onBack={() => router.back()}
        rightAction={addAction}
      />

      <View style={[styles.tabBar, { backgroundColor: colors.card, borderBottomColor: colors.muted }]}>
        {(["gelen", "talep"] as Tab[]).map((t) => (
          <TouchableOpacity
            key={t}
            style={[styles.tabBtn, tab === t && { borderBottomColor: colors.primary, borderBottomWidth: 2 }]}
            onPress={() => setTab(t)}
            activeOpacity={0.8}
          >
            <Text style={[styles.tabText, { color: tab === t ? colors.primary : colors.mutedForeground }]}>
              {t === "gelen" ? "Gelen Malzeme" : "Malzeme Talebi"}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      <ProjectPicker projects={projects} value={filter} onChange={setFilter} />

      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="Malzeme takibi için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : tab === "gelen" ? (
        filteredMaterials.length === 0 ? (
          <EmptyState
            icon="package"
            title="Gelen malzeme yok"
            description="Teslim alınan malzemeleri buraya ekleyin"
            actionLabel={canEdit ? "Malzeme Ekle" : undefined}
            onAction={canEdit ? () => openMaterial() : undefined}
          />
        ) : (
          <FlatList
            data={filteredMaterials}
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
                  onPress={canEdit ? () => openMaterial(item) : undefined}
                >
                  <View style={styles.cardHead}>
                    <View style={{ flex: 1 }}>
                      <Text style={[styles.projLabel, { color: colors.primary }]}>
                        {projectName(item.projectId)}
                      </Text>
                      <Text style={[styles.cardTitle, { color: colors.foreground }]}>
                        {item.name}
                      </Text>
                    </View>
                    {lowStock ? (
                      <View style={[styles.badge, { backgroundColor: "#fee2e2" }]}>
                        <Feather name="alert-triangle" size={11} color="#dc2626" />
                        <Text style={[styles.badgeText, { color: "#dc2626" }]}>Az Stok</Text>
                      </View>
                    ) : null}
                  </View>

                  <View style={styles.qtyRow}>
                    <View style={styles.qtyBox}>
                      <Text style={[styles.qtyLabel, { color: colors.mutedForeground }]}>Toplam</Text>
                      <Text style={[styles.qtyVal, { color: colors.foreground }]}>{item.quantity} {item.unit}</Text>
                    </View>
                    <View style={styles.qtyBox}>
                      <Text style={[styles.qtyLabel, { color: colors.mutedForeground }]}>Kullanılan</Text>
                      <Text style={[styles.qtyVal, { color: colors.foreground }]}>{item.usedQty} {item.unit}</Text>
                    </View>
                    <View style={styles.qtyBox}>
                      <Text style={[styles.qtyLabel, { color: colors.mutedForeground }]}>Kalan</Text>
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
                        {item.supplier}{item.deliveryDate ? ` · ${item.deliveryDate}` : ""}
                      </Text>
                      {item.unitPrice > 0 ? (
                        <Text style={[styles.metaText, { color: colors.mutedForeground, marginLeft: "auto" }]}>
                          {item.unitPrice.toLocaleString("tr-TR")} ₺/{item.unit}
                        </Text>
                      ) : null}
                    </View>
                  ) : null}
                </TouchableOpacity>
              );
            }}
          />
        )
      ) : (
        filteredRequests.length === 0 ? (
          <EmptyState
            icon="clipboard"
            title="Malzeme talebi yok"
            description="Yeni malzeme taleplerini buraya ekleyin"
            actionLabel={canEdit ? "Talep Ekle" : undefined}
            onAction={canEdit ? () => openRequest() : undefined}
          />
        ) : (
          <FlatList
            data={filteredRequests}
            keyExtractor={(r) => r.id}
            contentContainerStyle={styles.list}
            renderItem={({ item }) => {
              const st = REQUEST_STATUS[item.status];
              return (
                <TouchableOpacity
                  style={[styles.card, { backgroundColor: colors.card }]}
                  activeOpacity={0.85}
                  onPress={canEdit ? () => openRequest(item) : undefined}
                >
                  <View style={styles.cardHead}>
                    <View style={{ flex: 1 }}>
                      <Text style={[styles.projLabel, { color: colors.primary }]}>
                        {projectName(item.projectId)}
                      </Text>
                      <Text style={[styles.cardTitle, { color: colors.foreground }]}>
                        {item.name}
                      </Text>
                    </View>
                    <View style={[styles.badge, { backgroundColor: st.bg }]}>
                      <Text style={[styles.badgeText, { color: st.color }]}>{st.label}</Text>
                    </View>
                  </View>

                  <View style={styles.reqRow}>
                    <View style={styles.reqBox}>
                      <Text style={[styles.qtyLabel, { color: colors.mutedForeground }]}>Miktar</Text>
                      <Text style={[styles.qtyVal, { color: colors.foreground }]}>
                        {item.quantity} {item.unit}
                      </Text>
                    </View>
                    {item.requestedBy ? (
                      <View style={styles.reqBox}>
                        <Text style={[styles.qtyLabel, { color: colors.mutedForeground }]}>Talep Eden</Text>
                        <Text style={[styles.qtyVal, { color: colors.foreground }]}>{item.requestedBy}</Text>
                      </View>
                    ) : null}
                    {item.requestDate ? (
                      <View style={styles.reqBox}>
                        <Text style={[styles.qtyLabel, { color: colors.mutedForeground }]}>Tarih</Text>
                        <Text style={[styles.qtyVal, { color: colors.foreground }]}>{item.requestDate}</Text>
                      </View>
                    ) : null}
                  </View>

                  {item.note ? (
                    <View style={styles.metaRow}>
                      <Feather name="file-text" size={12} color={colors.mutedForeground} />
                      <Text style={[styles.metaText, { color: colors.mutedForeground }]}>{item.note}</Text>
                    </View>
                  ) : null}
                </TouchableOpacity>
              );
            }}
          />
        )
      )}

      <BottomSheet
        visible={mVisible}
        onClose={() => setMVisible(false)}
        title={mEditId ? "Malzemeyi Düzenle" : "Gelen Malzeme Ekle"}
      >
        <ScrollView showsVerticalScrollIndicator={false}>
          <Text style={[styles.label, { color: colors.foreground }]}>Proje</Text>
          <View style={styles.chips}>
            {projects.map((p) => (
              <TouchableOpacity
                key={p.id}
                onPress={() => setMForm({ ...mForm, projectId: p.id })}
                style={[styles.chip, { backgroundColor: mForm.projectId === p.id ? colors.primary : colors.muted }]}
              >
                <Text style={[styles.chipText, { color: mForm.projectId === p.id ? "#fff" : colors.foreground }]}>
                  {p.name}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
          <FormInput
            label="Malzeme Adı"
            value={mForm.name}
            onChangeText={(v) => setMForm({ ...mForm, name: v })}
            placeholder="Örn: Çimento CEM I 42.5"
          />
          <View style={styles.twoCol}>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Birim"
                value={mForm.unit}
                onChangeText={(v) => setMForm({ ...mForm, unit: v })}
                placeholder="kg, ton, m³"
              />
            </View>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Birim Fiyat (₺)"
                value={mForm.unitPrice}
                onChangeText={(v) => setMForm({ ...mForm, unitPrice: v })}
                keyboardType="numeric"
              />
            </View>
          </View>
          <View style={styles.twoCol}>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Toplam Miktar"
                value={mForm.quantity}
                onChangeText={(v) => setMForm({ ...mForm, quantity: v })}
                keyboardType="numeric"
              />
            </View>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Kullanılan"
                value={mForm.usedQty}
                onChangeText={(v) => setMForm({ ...mForm, usedQty: v })}
                keyboardType="numeric"
              />
            </View>
          </View>
          <FormInput
            label="Tedarikçi"
            value={mForm.supplier}
            onChangeText={(v) => setMForm({ ...mForm, supplier: v })}
          />
          <FormInput
            label="Teslim Tarihi"
            value={mForm.deliveryDate}
            onChangeText={(v) => setMForm({ ...mForm, deliveryDate: v })}
            placeholder="GG.AA.YYYY"
          />
          {canEdit ? <PrimaryButton label="Kaydet" onPress={saveMaterial} style={{ marginTop: 8 }} /> : null}
          {canEdit && mEditId ? (
            <PrimaryButton label="Sil" variant="danger" onPress={removeMaterial} style={{ marginTop: 10 }} />
          ) : null}
          {!canEdit ? (
            <PrimaryButton label="Kapat" onPress={() => setMVisible(false)} style={{ marginTop: 8 }} />
          ) : null}
        </ScrollView>
      </BottomSheet>

      <BottomSheet
        visible={rVisible}
        onClose={() => setRVisible(false)}
        title={rEditId ? "Talebi Düzenle" : "Malzeme Talebi Ekle"}
      >
        <ScrollView showsVerticalScrollIndicator={false}>
          <Text style={[styles.label, { color: colors.foreground }]}>Proje</Text>
          <View style={styles.chips}>
            {projects.map((p) => (
              <TouchableOpacity
                key={p.id}
                onPress={() => setRForm({ ...rForm, projectId: p.id })}
                style={[styles.chip, { backgroundColor: rForm.projectId === p.id ? colors.primary : colors.muted }]}
              >
                <Text style={[styles.chipText, { color: rForm.projectId === p.id ? "#fff" : colors.foreground }]}>
                  {p.name}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
          <FormInput
            label="Malzeme Adı"
            value={rForm.name}
            onChangeText={(v) => setRForm({ ...rForm, name: v })}
            placeholder="Örn: Demir Ø12"
          />
          <View style={styles.twoCol}>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Birim"
                value={rForm.unit}
                onChangeText={(v) => setRForm({ ...rForm, unit: v })}
                placeholder="kg, adet, m²"
              />
            </View>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Miktar"
                value={rForm.quantity}
                onChangeText={(v) => setRForm({ ...rForm, quantity: v })}
                keyboardType="numeric"
              />
            </View>
          </View>
          <FormInput
            label="Talep Eden"
            value={rForm.requestedBy}
            onChangeText={(v) => setRForm({ ...rForm, requestedBy: v })}
          />
          <FormInput
            label="Talep Tarihi"
            value={rForm.requestDate}
            onChangeText={(v) => setRForm({ ...rForm, requestDate: v })}
            placeholder="GG.AA.YYYY"
          />
          <Text style={[styles.label, { color: colors.foreground, marginTop: 4 }]}>Durum</Text>
          <View style={styles.chips}>
            {(Object.keys(REQUEST_STATUS) as MaterialRequest["status"][]).map((s) => (
              <TouchableOpacity
                key={s}
                onPress={() => canEdit && setRForm({ ...rForm, status: s })}
                style={[
                  styles.chip,
                  {
                    backgroundColor:
                      rForm.status === s ? REQUEST_STATUS[s].color : colors.muted,
                  },
                ]}
              >
                <Text style={[styles.chipText, { color: rForm.status === s ? "#fff" : colors.foreground }]}>
                  {REQUEST_STATUS[s].label}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
          <FormInput
            label="Not / Açıklama"
            value={rForm.note}
            onChangeText={(v) => setRForm({ ...rForm, note: v })}
            placeholder="İsteğe bağlı"
          />
          {canEdit ? <PrimaryButton label="Kaydet" onPress={saveRequest} style={{ marginTop: 8 }} /> : null}
          {canEdit && rEditId ? (
            <PrimaryButton label="Sil" variant="danger" onPress={removeRequest} style={{ marginTop: 10 }} />
          ) : null}
          {!canEdit ? (
            <PrimaryButton label="Kapat" onPress={() => setRVisible(false)} style={{ marginTop: 8 }} />
          ) : null}
        </ScrollView>
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  tabBar: {
    flexDirection: "row",
    borderBottomWidth: 1,
  },
  tabBtn: {
    flex: 1,
    paddingVertical: 12,
    alignItems: "center",
    borderBottomWidth: 2,
    borderBottomColor: "transparent",
  },
  tabText: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
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
  cardHead: { flexDirection: "row", alignItems: "flex-start", gap: 8, marginBottom: 12 },
  projLabel: { fontSize: 12, fontFamily: "Inter_600SemiBold", marginBottom: 2 },
  cardTitle: { fontSize: 16, fontFamily: "Inter_700Bold" },
  badge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 999,
  },
  badgeText: { fontSize: 11, fontFamily: "Inter_600SemiBold" },
  qtyRow: { flexDirection: "row", gap: 8, marginBottom: 12 },
  qtyBox: { flex: 1 },
  qtyLabel: { fontSize: 11, fontFamily: "Inter_500Medium", marginBottom: 2 },
  qtyVal: { fontSize: 14, fontFamily: "Inter_700Bold" },
  reqRow: { flexDirection: "row", gap: 8, marginBottom: 8, flexWrap: "wrap" },
  reqBox: { minWidth: 80 },
  bar: { height: 6, borderRadius: 3, overflow: "hidden" },
  barFill: { height: "100%" },
  metaRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginTop: 10,
  },
  metaText: { fontSize: 12, fontFamily: "Inter_500Medium", flex: 1 },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  chip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999 },
  chipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
  twoCol: { flexDirection: "row", gap: 8 },
});
