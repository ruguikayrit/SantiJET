import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useEffect, useMemo, useState } from "react";
import {
  Alert,
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
import ProjectPicker from "@/components/ProjectPicker";
import UnitPicker from "@/components/UnitPicker";
import { findMaterialByName } from "@/constants/materials";
import {
  Material,
  MaterialMovement,
  MaterialRequest,
  useApp,
} from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

type Tab = "gelen" | "kullanim" | "giden" | "talep";

const TABS: { key: Tab; label: string; icon: string }[] = [
  { key: "gelen", label: "Gelen", icon: "download" },
  { key: "kullanim", label: "Kullanılan", icon: "tool" },
  { key: "giden", label: "Giden", icon: "upload" },
  { key: "talep", label: "Talep", icon: "clipboard" },
];

const REQUEST_STATUS = {
  pending:   { label: "Beklemede",     color: "#f59e0b", bg: "#fef3c7" },
  approved:  { label: "Onaylandı",     color: "#16a34a", bg: "#dcfce7" },
  delivered: { label: "Teslim Edildi", color: "#2563eb", bg: "#dbeafe" },
  rejected:  { label: "Reddedildi",   color: "#dc2626", bg: "#fee2e2" },
};

interface MF {
  projectId: string;
  name: string;
  category: string;
  unit: string;
  quantity: string;
  supplier: string;
  deliveryDate: string;
  unitPrice: string;
  recordDetail: string;
  description: string;
  code: string;
  shippingMethod: string;
  waybillNo: string;
  invoiceNo: string;
  kantarEnabled: boolean;
  supplierKantarSlip: boolean;
  weighApproved: boolean;
}

interface RF {
  projectId: string;
  name: string;
  category: string;
  unit: string;
  quantity: string;
  requestDate: string;
  requestedBy: string;
  status: MaterialRequest["status"];
  note: string;
}

interface MovF {
  projectId: string;
  type: "kullanim" | "giden";
  name: string;
  category: string;
  unit: string;
  quantity: string;
  date: string;
  person: string;
  location: string;
  reason: string;
  note: string;
}

const EMPTY_M: MF = {
  projectId: "", name: "", category: "", unit: "", quantity: "",
  supplier: "", deliveryDate: "", unitPrice: "",
  recordDetail: "", description: "", code: "",
  shippingMethod: "", waybillNo: "", invoiceNo: "",
  kantarEnabled: false,
  supplierKantarSlip: false,
  weighApproved: false,
};

const EMPTY_R: RF = {
  projectId: "", name: "", category: "", unit: "", quantity: "",
  requestDate: "", requestedBy: "", status: "pending", note: "",
};

const EMPTY_MOV: MovF = {
  projectId: "", type: "kullanim", name: "", category: "", unit: "", quantity: "",
  date: "", person: "", location: "", reason: "", note: "",
};

function todayStr() {
  const d = new Date();
  const dd = String(d.getDate()).padStart(2, "0");
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  return `${dd}.${mm}.${d.getFullYear()}`;
}

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
    materialMovements,
    addMaterialMovement,
    updateMaterialMovement,
    deleteMaterialMovement,
  } = useApp();

  const perm = usePermission("malzeme");
  const canEdit = perm === "edit";
  useEffect(() => { if (perm === "none") { if (router.canGoBack()) router.back(); else router.replace("/"); } }, [perm]);

  const [tab, setTab] = useState<Tab>("gelen");
  const [filter, setFilter] = useState<string | null>(null);

  const [mVisible, setMVisible] = useState(false);
  const [mEditId, setMEditId] = useState<string | null>(null);
  const [mForm, setMForm] = useState<MF>(EMPTY_M);

  const [rVisible, setRVisible] = useState(false);
  const [rEditId, setREditId] = useState<string | null>(null);
  const [rForm, setRForm] = useState<RF>(EMPTY_R);

  const [movVisible, setMovVisible] = useState(false);
  const [movEditId, setMovEditId] = useState<string | null>(null);
  const [movForm, setMovForm] = useState<MovF>(EMPTY_MOV);

  const filteredMaterials = useMemo(
    () => (filter ? materials.filter((m) => m.projectId === filter) : materials),
    [materials, filter]
  );
  const filteredRequests = useMemo(
    () => (filter ? materialRequests.filter((r) => r.projectId === filter) : materialRequests),
    [materialRequests, filter]
  );
  const filteredKullanim = useMemo(
    () =>
      (filter ? materialMovements.filter((m) => m.projectId === filter) : materialMovements)
        .filter((m) => m.type === "kullanim"),
    [materialMovements, filter]
  );
  const filteredGiden = useMemo(
    () =>
      (filter ? materialMovements.filter((m) => m.projectId === filter) : materialMovements)
        .filter((m) => m.type === "giden"),
    [materialMovements, filter]
  );

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  // GELEN -----------------------------------------------------
  function openMaterial(m?: Material) {
    if (m) {
      setMEditId(m.id);
      setMForm({
        projectId: m.projectId,
        name: m.name,
        category: m.category || findMaterialByName(m.name)?.category || "",
        unit: m.unit,
        quantity: String(m.quantity || ""),
        supplier: m.supplier,
        deliveryDate: m.deliveryDate,
        unitPrice: String(m.unitPrice || ""),
        recordDetail: m.recordDetail ?? "",
        description: m.description ?? "",
        code: m.code ?? "",
        shippingMethod: m.shippingMethod ?? "",
        waybillNo: m.waybillNo ?? "",
        invoiceNo: m.invoiceNo ?? "",
        kantarEnabled: !!m.kantarEnabled,
        supplierKantarSlip: !!m.supplierKantarSlip,
        weighApproved: !!m.weighApproved,
      });
    } else {
      setMEditId(null);
      setMForm({
        ...EMPTY_M,
        projectId: filter || projects[0]?.id || "",
        deliveryDate: todayStr(),
      });
    }
    setMVisible(true);
  }
  function saveMaterial() {
    if (!mForm.projectId || !mForm.name.trim()) return;
    const data = {
      projectId: mForm.projectId,
      name: mForm.name.trim(),
      category: mForm.category.trim() || undefined,
      unit: mForm.unit.trim(),
      quantity: parseFloat(mForm.quantity) || 0,
      usedQty: 0,
      supplier: mForm.supplier.trim(),
      deliveryDate: mForm.deliveryDate.trim(),
      unitPrice: parseFloat(mForm.unitPrice) || 0,
      recordDetail: mForm.recordDetail.trim() || undefined,
      description: mForm.description.trim() || undefined,
      code: mForm.code.trim() || undefined,
      shippingMethod: mForm.shippingMethod.trim() || undefined,
      waybillNo: mForm.waybillNo.trim() || undefined,
      invoiceNo: mForm.invoiceNo.trim() || undefined,
      kantarEnabled: mForm.kantarEnabled,
      supplierKantarSlip: mForm.supplierKantarSlip,
      weighApproved: mForm.weighApproved,
    };
    if (mEditId) {
      const existing = materials.find((m) => m.id === mEditId);
      updateMaterial(mEditId, { ...data, usedQty: existing?.usedQty ?? 0 });
    } else {
      addMaterial(data);
    }
    setMVisible(false);
  }
  function removeMaterial() {
    if (mEditId) deleteMaterial(mEditId);
    setMVisible(false);
  }

  // TALEP -----------------------------------------------------
  function openRequest(r?: MaterialRequest) {
    if (r) {
      setREditId(r.id);
      setRForm({
        projectId: r.projectId,
        name: r.name,
        category: r.category || findMaterialByName(r.name)?.category || "",
        unit: r.unit,
        quantity: String(r.quantity || ""),
        requestDate: r.requestDate,
        requestedBy: r.requestedBy,
        status: r.status,
        note: r.note,
      });
    } else {
      setREditId(null);
      setRForm({
        ...EMPTY_R,
        projectId: filter || projects[0]?.id || "",
        requestDate: todayStr(),
      });
    }
    setRVisible(true);
  }
  function saveRequest() {
    if (!rForm.projectId || !rForm.name.trim()) return;
    const data = {
      projectId: rForm.projectId,
      name: rForm.name.trim(),
      category: rForm.category.trim() || undefined,
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

  // KULLANIM / GIDEN -----------------------------------------
  function openMovement(type: "kullanim" | "giden", existing?: MaterialMovement) {
    if (existing) {
      setMovEditId(existing.id);
      setMovForm({
        projectId: existing.projectId,
        type: existing.type,
        name: existing.name,
        category: existing.category || findMaterialByName(existing.name)?.category || "",
        unit: existing.unit,
        quantity: String(existing.quantity || ""),
        date: existing.date,
        person: existing.person,
        location: existing.location,
        reason: existing.reason,
        note: existing.note,
      });
    } else {
      setMovEditId(null);
      setMovForm({
        ...EMPTY_MOV,
        type,
        projectId: filter || projects[0]?.id || "",
        date: todayStr(),
      });
    }
    setMovVisible(true);
  }

  // Talepte halihazırda olan malzemelerden hızlı seçim için
  const knownMaterialsForProject = useMemo(() => {
    if (!movForm.projectId) return [] as Material[];
    return materials.filter((m) => m.projectId === movForm.projectId);
  }, [materials, movForm.projectId]);

  // Kullanılan malzeme, projedeki Gelen Malzeme listesinde yoksa uyar
  const stoksuzKullanim = useMemo(() => {
    if (movForm.type !== "kullanim") return false;
    const name = movForm.name.trim().toLowerCase();
    if (!name || !movForm.projectId) return false;
    const exists = materials.some(
      (m) =>
        m.projectId === movForm.projectId &&
        m.name.trim().toLowerCase() === name
    );
    return !exists;
  }, [movForm.type, movForm.name, movForm.projectId, materials]);

  function pickKnownMaterial(m: Material) {
    setMovForm((prev) => ({
      ...prev,
      name: m.name,
      category: m.category || findMaterialByName(m.name)?.category || prev.category,
      unit: m.unit,
    }));
  }

  function saveMovement() {
    if (!movForm.projectId || !movForm.name.trim()) return;
    const data: Omit<MaterialMovement, "id"> = {
      projectId: movForm.projectId,
      type: movForm.type,
      name: movForm.name.trim(),
      category: movForm.category.trim() || undefined,
      unit: movForm.unit.trim(),
      quantity: parseFloat(movForm.quantity) || 0,
      date: movForm.date.trim(),
      person: movForm.person.trim(),
      location: movForm.location.trim(),
      reason: movForm.reason.trim(),
      note: movForm.note.trim(),
    };
    const commit = () => {
      if (movEditId) updateMaterialMovement(movEditId, data);
      else addMaterialMovement(data);
      setMovVisible(false);
    };

    if (stoksuzKullanim) {
      Alert.alert(
        "Stoksuz Malzeme Kullanımı",
        `"${data.name}" malzemesi "${projectName(data.projectId)}" projesinin Gelen Malzeme listesinde bulunmuyor. Stok takibi yapılamayacak.\n\nYine de kaydetmek istiyor musunuz?`,
        [
          { text: "Vazgeç", style: "cancel" },
          { text: "Yine de Kaydet", style: "destructive", onPress: commit },
        ]
      );
      return;
    }
    commit();
  }
  function removeMovement() {
    if (movEditId) deleteMaterialMovement(movEditId);
    setMovVisible(false);
  }

  function onAddPress() {
    if (tab === "gelen") openMaterial();
    else if (tab === "talep") openRequest();
    else if (tab === "kullanim") openMovement("kullanim");
    else openMovement("giden");
  }

  const addAction = canEdit && projects.length > 0
    ? { icon: "plus" as const, onPress: onAddPress }
    : undefined;

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Malzeme"
        onBack={() => (router.canGoBack() ? router.back() : router.replace("/"))}
        rightAction={addAction}
      />

      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={[styles.tabBar, { backgroundColor: colors.card, borderBottomColor: colors.muted }]}
        contentContainerStyle={styles.tabBarContent}
      >
        {TABS.map((t) => {
          const active = tab === t.key;
          return (
            <TouchableOpacity
              key={t.key}
              style={[
                styles.tabBtn,
                active && {
                  borderBottomColor: colors.primary,
                  borderBottomWidth: 2,
                },
              ]}
              onPress={() => setTab(t.key)}
              activeOpacity={0.8}
            >
              <Feather
                name={t.icon as any}
                size={14}
                color={active ? colors.primary : colors.mutedForeground}
              />
              <Text style={[styles.tabText, { color: active ? colors.primary : colors.mutedForeground }]}>
                {t.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </ScrollView>

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
        renderGelen()
      ) : tab === "kullanim" ? (
        renderMovements("kullanim")
      ) : tab === "giden" ? (
        renderMovements("giden")
      ) : (
        renderTalep()
      )}

      {/* GELEN BOTTOM SHEET */}
      <BottomSheet
        visible={mVisible}
        onClose={() => setMVisible(false)}
        title={mEditId ? "Geleni Düzenle" : "Gelen Malzeme Ekle"}
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
          <CategoryPicker
            label="Kategori"
            value={mForm.category}
            onChange={(v) => setMForm({ ...mForm, category: v })}
          />
          <MaterialPicker
            label="Malzeme Adı"
            value={mForm.name}
            category={mForm.category}
            onChange={(name, cat, defUnit) =>
              setMForm({
                ...mForm,
                name,
                category: cat,
                unit: defUnit || mForm.unit || "",
              })
            }
            placeholder="Örn: 10 cm Gazbeton"
          />
          <FormInput
            label="Kayıt Detayları"
            value={mForm.recordDetail}
            onChangeText={(v) => setMForm({ ...mForm, recordDetail: v })}
            placeholder="Kısa başlık / referans"
          />
          <DatePickerInput
            label="Tarih"
            value={mForm.deliveryDate}
            onChange={(v) => setMForm({ ...mForm, deliveryDate: v })}
          />
          <FormInput
            label="Açıklama"
            value={mForm.description}
            onChangeText={(v) => setMForm({ ...mForm, description: v })}
            placeholder="Ek bilgi / notlar"
            multiline
          />
          <FormInput
            label="Poz"
            value={mForm.code}
            onChangeText={(v) => setMForm({ ...mForm, code: v })}
            placeholder="Poz no / iş kalemi"
          />
          <FormInput
            label="Sevk Şekli"
            value={mForm.shippingMethod}
            onChangeText={(v) => setMForm({ ...mForm, shippingMethod: v })}
            placeholder="Tır / Kamyon / Kargo / Elden"
          />
          <View style={styles.twoCol}>
            <View style={{ flex: 1 }}>
              <FormInput
                label="İrsaliye No"
                value={mForm.waybillNo}
                onChangeText={(v) => setMForm({ ...mForm, waybillNo: v })}
              />
            </View>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Fatura No"
                value={mForm.invoiceNo}
                onChangeText={(v) => setMForm({ ...mForm, invoiceNo: v })}
              />
            </View>
          </View>
          <FormInput
            label="Temin Edilen Firma"
            value={mForm.supplier}
            onChangeText={(v) => setMForm({ ...mForm, supplier: v })}
            placeholder="Tedarikçi adı"
          />
          <View style={styles.twoCol}>
            <View style={{ flex: 1 }}>
              <UnitPicker
                label="Birim"
                value={mForm.unit}
                onChange={(v) => setMForm({ ...mForm, unit: v })}
              />
            </View>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Miktar"
                value={mForm.quantity}
                onChangeText={(v) => setMForm({ ...mForm, quantity: v })}
                keyboardType="numeric"
              />
            </View>
          </View>
          <TouchableOpacity
            onPress={() => setMForm({ ...mForm, kantarEnabled: !mForm.kantarEnabled })}
            disabled={!canEdit}
            activeOpacity={0.7}
            style={[
              styles.kantarToggle,
              {
                borderColor: mForm.kantarEnabled ? "#0d9488" : colors.muted,
                backgroundColor: mForm.kantarEnabled ? "#0d948811" : colors.card,
              },
            ]}
          >
            <View
              style={[
                styles.kantarCheck,
                {
                  borderColor: mForm.kantarEnabled ? "#0d9488" : colors.mutedForeground,
                  backgroundColor: mForm.kantarEnabled ? "#0d9488" : "transparent",
                },
              ]}
            >
              {mForm.kantarEnabled ? (
                <Feather name="check" size={14} color="#fff" />
              ) : null}
            </View>
            <View style={{ flex: 1 }}>
              <Text style={[styles.kantarTitle, { color: colors.foreground }]}>
                Kantar
              </Text>
              <Text style={[styles.kantarDesc, { color: colors.mutedForeground }]}>
                {mForm.kantarEnabled
                  ? "Kantar fişi otomatik oluşturulur. Tartım verilerini Kantar sayfasında girin."
                  : mEditId
                  ? "Kapatırsanız bağlı fiş silinmez; bağlantı kopar, fiş Kantar sayfasında kalır"
                  : "Bu malzeme kantara giriyorsa aktif edin"}
              </Text>
            </View>
            <Feather
              name="truck"
              size={20}
              color={mForm.kantarEnabled ? "#0d9488" : colors.mutedForeground}
            />
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => setMForm({ ...mForm, supplierKantarSlip: !mForm.supplierKantarSlip })}
            disabled={!canEdit}
            activeOpacity={0.7}
            style={[
              styles.kantarToggle,
              {
                borderColor: mForm.supplierKantarSlip ? "#0ea5e9" : colors.muted,
                backgroundColor: mForm.supplierKantarSlip ? "#0ea5e911" : colors.card,
              },
            ]}
          >
            <View
              style={[
                styles.kantarCheck,
                {
                  borderColor: mForm.supplierKantarSlip ? "#0ea5e9" : colors.mutedForeground,
                  backgroundColor: mForm.supplierKantarSlip ? "#0ea5e9" : "transparent",
                },
              ]}
            >
              {mForm.supplierKantarSlip ? <Feather name="check" size={14} color="#fff" /> : null}
            </View>
            <View style={{ flex: 1 }}>
              <Text style={[styles.kantarTitle, { color: colors.foreground }]}>
                Tedarikçi Kantar Fişi
              </Text>
              <Text style={[styles.kantarDesc, { color: colors.mutedForeground }]}>
                Tedarikçinin kantar fişi teslim alındıysa işaretleyin
              </Text>
            </View>
            <Feather
              name="file-text"
              size={20}
              color={mForm.supplierKantarSlip ? "#0ea5e9" : colors.mutedForeground}
            />
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => setMForm({ ...mForm, weighApproved: !mForm.weighApproved })}
            disabled={!canEdit}
            activeOpacity={0.7}
            style={[
              styles.kantarToggle,
              {
                borderColor: mForm.weighApproved ? "#16a34a" : colors.muted,
                backgroundColor: mForm.weighApproved ? "#16a34a11" : colors.card,
              },
            ]}
          >
            <View
              style={[
                styles.kantarCheck,
                {
                  borderColor: mForm.weighApproved ? "#16a34a" : colors.mutedForeground,
                  backgroundColor: mForm.weighApproved ? "#16a34a" : "transparent",
                },
              ]}
            >
              {mForm.weighApproved ? <Feather name="check" size={14} color="#fff" /> : null}
            </View>
            <View style={{ flex: 1 }}>
              <Text style={[styles.kantarTitle, { color: colors.foreground }]}>
                Tartı Onayı
              </Text>
              <Text style={[styles.kantarDesc, { color: colors.mutedForeground }]}>
                Tartım kontrol edildi ve onaylandıysa işaretleyin
              </Text>
            </View>
            <Feather
              name="check-circle"
              size={20}
              color={mForm.weighApproved ? "#16a34a" : colors.mutedForeground}
            />
          </TouchableOpacity>

          {canEdit ? <PrimaryButton label="Kaydet" onPress={saveMaterial} style={{ marginTop: 8 }} /> : null}
          {canEdit && mEditId ? (
            <PrimaryButton label="Sil" variant="danger" onPress={removeMaterial} style={{ marginTop: 10 }} />
          ) : null}
          {!canEdit ? (
            <PrimaryButton label="Kapat" onPress={() => setMVisible(false)} style={{ marginTop: 8 }} />
          ) : null}
        </ScrollView>
      </BottomSheet>

      {/* KULLANIM / GIDEN BOTTOM SHEET */}
      <BottomSheet
        visible={movVisible}
        onClose={() => setMovVisible(false)}
        title={
          (movEditId ? "Düzenle: " : "Yeni: ") +
          (movForm.type === "kullanim" ? "Kullanılan Malzeme" : "Giden Malzeme")
        }
      >
        <ScrollView showsVerticalScrollIndicator={false}>
          <Text style={[styles.label, { color: colors.foreground }]}>Proje</Text>
          <View style={styles.chips}>
            {projects.map((p) => (
              <TouchableOpacity
                key={p.id}
                onPress={() => setMovForm({ ...movForm, projectId: p.id })}
                style={[styles.chip, { backgroundColor: movForm.projectId === p.id ? colors.primary : colors.muted }]}
              >
                <Text style={[styles.chipText, { color: movForm.projectId === p.id ? "#fff" : colors.foreground }]}>
                  {p.name}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          {knownMaterialsForProject.length > 0 ? (
            <>
              <Text style={[styles.label, { color: colors.foreground }]}>Mevcut malzemelerden seç</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 14 }}>
                {knownMaterialsForProject.map((m) => {
                  const sel = movForm.name === m.name && movForm.unit === m.unit;
                  return (
                    <TouchableOpacity
                      key={m.id}
                      onPress={() => pickKnownMaterial(m)}
                      style={[
                        styles.knownChip,
                        {
                          backgroundColor: sel ? colors.primary : colors.muted,
                        },
                      ]}
                    >
                      <Feather name="package" size={12} color={sel ? "#fff" : colors.mutedForeground} />
                      <Text
                        style={[
                          styles.chipText,
                          { color: sel ? "#fff" : colors.foreground, marginLeft: 4 },
                        ]}
                      >
                        {m.name}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </ScrollView>
            </>
          ) : null}

          <CategoryPicker
            label="Kategori"
            value={movForm.category}
            onChange={(v) => setMovForm({ ...movForm, category: v })}
          />
          <MaterialPicker
            label="Malzeme Adı"
            value={movForm.name}
            category={movForm.category}
            onChange={(name, cat, defUnit) =>
              setMovForm({
                ...movForm,
                name,
                category: cat,
                unit: defUnit || movForm.unit || "",
              })
            }
            placeholder="Örn: Nervürlü Demir Ø12"
          />
          <View style={styles.twoCol}>
            <View style={{ flex: 1 }}>
              <UnitPicker
                label="Birim"
                value={movForm.unit}
                onChange={(v) => setMovForm({ ...movForm, unit: v })}
              />
            </View>
            <View style={{ flex: 1 }}>
              <FormInput
                label="Miktar"
                value={movForm.quantity}
                onChangeText={(v) => setMovForm({ ...movForm, quantity: v })}
                keyboardType="numeric"
              />
            </View>
          </View>
          {stoksuzKullanim ? (
            <View style={styles.warnBox}>
              <Feather name="alert-triangle" size={16} color="#b45309" />
              <View style={{ flex: 1 }}>
                <Text style={styles.warnTitle}>Stoksuz Malzeme Kullanımı</Text>
                <Text style={styles.warnBody}>
                  Bu malzeme bu projenin Gelen Malzeme listesinde bulunmuyor.
                  Önce Gelen Malzeme olarak ekleyin ya da yine de kaydedebilirsiniz
                  (stok takibi yapılamaz).
                </Text>
              </View>
            </View>
          ) : null}
          <DatePickerInput
            label="Tarih"
            value={movForm.date}
            onChange={(v) => setMovForm({ ...movForm, date: v })}
          />
          <FormInput
            label={movForm.type === "kullanim" ? "Kullanan / Sorumlu" : "Alan kişi / firma"}
            value={movForm.person}
            onChangeText={(v) => setMovForm({ ...movForm, person: v })}
          />
          <FormInput
            label={movForm.type === "kullanim" ? "Kullanılan yer (kat / blok)" : "Hedef (şantiye / depo / iade)"}
            value={movForm.location}
            onChangeText={(v) => setMovForm({ ...movForm, location: v })}
          />
          {movForm.type === "giden" ? (
            <FormInput
              label="Sebep"
              value={movForm.reason}
              onChangeText={(v) => setMovForm({ ...movForm, reason: v })}
              placeholder="İade, transfer, fire, satış..."
            />
          ) : null}
          <FormInput
            label="Not"
            value={movForm.note}
            onChangeText={(v) => setMovForm({ ...movForm, note: v })}
            placeholder="İsteğe bağlı"
          />
          {canEdit ? <PrimaryButton label="Kaydet" onPress={saveMovement} style={{ marginTop: 8 }} /> : null}
          {canEdit && movEditId ? (
            <PrimaryButton label="Sil" variant="danger" onPress={removeMovement} style={{ marginTop: 10 }} />
          ) : null}
          {!canEdit ? (
            <PrimaryButton label="Kapat" onPress={() => setMovVisible(false)} style={{ marginTop: 8 }} />
          ) : null}
        </ScrollView>
      </BottomSheet>

      {/* TALEP BOTTOM SHEET */}
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
          <CategoryPicker
            label="Kategori"
            value={rForm.category}
            onChange={(v) => setRForm({ ...rForm, category: v })}
          />
          <MaterialPicker
            label="Malzeme Adı"
            value={rForm.name}
            category={rForm.category}
            onChange={(name, cat, defUnit) =>
              setRForm({
                ...rForm,
                name,
                category: cat,
                unit: defUnit || rForm.unit || "",
              })
            }
            placeholder="Örn: Nervürlü Demir Ø12"
          />
          <View style={styles.twoCol}>
            <View style={{ flex: 1 }}>
              <UnitPicker
                label="Birim"
                value={rForm.unit}
                onChange={(v) => setRForm({ ...rForm, unit: v })}
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
          <DatePickerInput
            label="Talep Tarihi"
            value={rForm.requestDate}
            onChange={(v) => setRForm({ ...rForm, requestDate: v })}
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

  // Renderers
  function renderGelen() {
    if (filteredMaterials.length === 0) {
      return (
        <EmptyState
          icon="download"
          title="Gelen malzeme yok"
          description="Şantiyeye teslim alınan malzemeleri buraya ekleyin"
          actionLabel={canEdit ? "Gelen Ekle" : undefined}
          onAction={canEdit ? () => openMaterial() : undefined}
        />
      );
    }
    return (
      <FlatList
        data={filteredMaterials}
        keyExtractor={(m) => m.id}
        contentContainerStyle={styles.list}
        renderItem={({ item }) => {
          const metaParts: string[] = [];
          if (item.deliveryDate) metaParts.push(item.deliveryDate);
          if (item.supplier) metaParts.push(item.supplier);
          if (item.code) metaParts.push(`Poz: ${item.code}`);
          if (item.waybillNo) metaParts.push(`İrs: ${item.waybillNo}`);
          if (item.invoiceNo) metaParts.push(`Fat: ${item.invoiceNo}`);
          return (
            <TouchableOpacity
              style={[styles.rowCard, { backgroundColor: colors.card }]}
              activeOpacity={0.85}
              onPress={canEdit ? () => openMaterial(item) : undefined}
            >
              <View style={{ flex: 1, paddingRight: 10 }}>
                <Text style={[styles.projLabel, { color: colors.primary }]}>
                  {projectName(item.projectId)}
                </Text>
                <Text style={[styles.cardTitle, { color: colors.foreground }]} numberOfLines={1}>
                  {item.name}
                </Text>
                {item.category ? (
                  <Text style={[styles.catLabel, { color: colors.mutedForeground }]} numberOfLines={1}>
                    {item.category}
                  </Text>
                ) : null}
                {item.recordDetail ? (
                  <Text style={[styles.metaText, { color: colors.mutedForeground, marginTop: 4 }]} numberOfLines={1}>
                    {item.recordDetail}
                  </Text>
                ) : null}
                {metaParts.length > 0 ? (
                  <Text style={[styles.metaText, { color: colors.mutedForeground, marginTop: 4 }]} numberOfLines={2}>
                    {metaParts.join(" · ")}
                  </Text>
                ) : null}
                {(item.kantarEnabled || item.supplierKantarSlip || item.weighApproved) ? (
                  <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 6, marginTop: 6 }}>
                    {item.kantarEnabled ? (
                      <TouchableOpacity
                        onPress={(e) => { e.stopPropagation(); router.push("/kantar" as any); }}
                        style={[styles.kantarBadge, { backgroundColor: "#0d948822" }]}
                      >
                        <Feather name="truck" size={10} color="#0d9488" />
                        <Text style={[styles.kantarBadgeText, { color: "#0d9488" }]}>
                          Kantar
                        </Text>
                      </TouchableOpacity>
                    ) : null}
                    {item.supplierKantarSlip ? (
                      <View style={[styles.kantarBadge, { backgroundColor: "#0ea5e922" }]}>
                        <Feather name="check-square" size={10} color="#0ea5e9" />
                        <Text style={[styles.kantarBadgeText, { color: "#0ea5e9" }]}>
                          Tedarikçi Fişi
                        </Text>
                      </View>
                    ) : null}
                    {item.weighApproved ? (
                      <View style={[styles.kantarBadge, { backgroundColor: "#16a34a22" }]}>
                        <Feather name="check-circle" size={10} color="#16a34a" />
                        <Text style={[styles.kantarBadgeText, { color: "#16a34a" }]}>
                          Tartı Onaylı
                        </Text>
                      </View>
                    ) : null}
                  </View>
                ) : null}
              </View>
              <View style={[styles.gelenQtyPill, { backgroundColor: colors.muted }]}>
                <Text style={[styles.gelenQtyVal, { color: colors.foreground }]}>{item.quantity}</Text>
                <Text style={[styles.gelenQtyUnit, { color: colors.mutedForeground }]}>{item.unit}</Text>
              </View>
            </TouchableOpacity>
          );
        }}
      />
    );
  }

  function renderMovements(type: "kullanim" | "giden") {
    const data = type === "kullanim" ? filteredKullanim : filteredGiden;
    const meta = type === "kullanim"
      ? {
          icon: "tool" as const,
          title: "Kullanılan malzeme yok",
          description: "İmalatta tüketilen malzemeleri buraya ekleyin",
          actionLabel: "Kullanım Ekle",
          accent: "#16a34a",
        }
      : {
          icon: "upload" as const,
          title: "Giden malzeme yok",
          description: "İade, transfer veya çıkışları buraya ekleyin",
          actionLabel: "Giden Ekle",
          accent: "#dc2626",
        };

    if (data.length === 0) {
      return (
        <EmptyState
          icon={meta.icon}
          title={meta.title}
          description={meta.description}
          actionLabel={canEdit ? meta.actionLabel : undefined}
          onAction={canEdit ? () => openMovement(type) : undefined}
        />
      );
    }
    return (
      <FlatList
        data={data}
        keyExtractor={(m) => m.id}
        contentContainerStyle={styles.list}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={[styles.card, { backgroundColor: colors.card }]}
            activeOpacity={0.85}
            onPress={canEdit ? () => openMovement(type, item) : undefined}
          >
            <View style={styles.cardHead}>
              <View style={{ flex: 1 }}>
                <Text style={[styles.projLabel, { color: colors.primary }]}>
                  {projectName(item.projectId)}
                </Text>
                <Text style={[styles.cardTitle, { color: colors.foreground }]}>
                  {item.name}
                </Text>
                {item.category ? (
                  <Text style={[styles.catLabel, { color: colors.mutedForeground }]}>
                    {item.category}
                  </Text>
                ) : null}
              </View>
              <View style={[styles.qtyPill, { backgroundColor: meta.accent + "18" }]}>
                <Text style={[styles.qtyPillText, { color: meta.accent }]}>
                  {type === "kullanim" ? "−" : "↗"} {item.quantity} {item.unit}
                </Text>
              </View>
            </View>

            <View style={styles.movMeta}>
              {item.date ? (
                <View style={styles.movMetaItem}>
                  <Feather name="calendar" size={12} color={colors.mutedForeground} />
                  <Text style={[styles.metaText, { color: colors.mutedForeground }]}>{item.date}</Text>
                </View>
              ) : null}
              {item.person ? (
                <View style={styles.movMetaItem}>
                  <Feather name="user" size={12} color={colors.mutedForeground} />
                  <Text style={[styles.metaText, { color: colors.mutedForeground }]}>{item.person}</Text>
                </View>
              ) : null}
              {item.location ? (
                <View style={styles.movMetaItem}>
                  <Feather name="map-pin" size={12} color={colors.mutedForeground} />
                  <Text style={[styles.metaText, { color: colors.mutedForeground }]}>{item.location}</Text>
                </View>
              ) : null}
              {type === "giden" && item.reason ? (
                <View style={styles.movMetaItem}>
                  <Feather name="info" size={12} color={colors.mutedForeground} />
                  <Text style={[styles.metaText, { color: colors.mutedForeground }]}>{item.reason}</Text>
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
        )}
      />
    );
  }

  function renderTalep() {
    if (filteredRequests.length === 0) {
      return (
        <EmptyState
          icon="clipboard"
          title="Malzeme talebi yok"
          description="Yeni malzeme taleplerini buraya ekleyin"
          actionLabel={canEdit ? "Talep Ekle" : undefined}
          onAction={canEdit ? () => openRequest() : undefined}
        />
      );
    }
    return (
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
                  {item.category ? (
                    <Text style={[styles.catLabel, { color: colors.mutedForeground }]}>
                      {item.category}
                    </Text>
                  ) : null}
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

              <View style={[styles.approvalsRow, { borderTopColor: colors.border }]}>
                {(["sef", "mudur", "satinAlma"] as const).map((k) => {
                  const checked = item.approvals?.[k] === true;
                  const labelMap: Record<typeof k, string> = {
                    sef: "Şantiye Şefi",
                    mudur: "Proje Müdürü",
                    satinAlma: "Satın Alma",
                  };
                  return (
                    <TouchableOpacity
                      key={k}
                      activeOpacity={canEdit ? 0.7 : 1}
                      onPress={
                        canEdit
                          ? (e) => {
                              e.stopPropagation?.();
                              updateMaterialRequest(item.id, {
                                approvals: { ...(item.approvals || {}), [k]: !checked },
                              });
                            }
                          : undefined
                      }
                      style={styles.approvalItem}
                    >
                      <View
                        style={[
                          styles.approvalBox,
                          {
                            borderColor: checked ? colors.primary : colors.border,
                            backgroundColor: checked ? colors.primary : "transparent",
                          },
                        ]}
                      >
                        {checked ? <Feather name="check" size={12} color="#fff" /> : null}
                      </View>
                      <Text
                        style={[
                          styles.approvalLabel,
                          { color: checked ? colors.foreground : colors.mutedForeground },
                        ]}
                        numberOfLines={1}
                      >
                        {labelMap[k]}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </View>
            </TouchableOpacity>
          );
        }}
      />
    );
  }
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  tabBar: { borderBottomWidth: 1, maxHeight: 48 },
  tabBarContent: { paddingHorizontal: 4 },
  tabBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderBottomWidth: 2,
    borderBottomColor: "transparent",
  },
  tabText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
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
  catLabel: { fontSize: 11, fontFamily: "Inter_500Medium", marginTop: 2 },
  approvalsRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    gap: 8,
    marginTop: 12,
    paddingTop: 10,
    borderTopWidth: 1,
  },
  approvalItem: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    flex: 1,
  },
  approvalBox: {
    width: 18,
    height: 18,
    borderRadius: 4,
    borderWidth: 1.5,
    alignItems: "center",
    justifyContent: "center",
  },
  approvalLabel: {
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
    flexShrink: 1,
  },
  rowCard: {
    flexDirection: "row",
    alignItems: "center",
    padding: 14,
    borderRadius: 14,
    marginBottom: 10,
  },
  gelenQtyPill: {
    flexDirection: "row",
    alignItems: "baseline",
    gap: 4,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 10,
  },
  gelenQtyVal: { fontSize: 16, fontFamily: "Inter_700Bold" },
  gelenQtyUnit: { fontSize: 11, fontFamily: "Inter_500Medium" },
  kantarToggle: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    padding: 12,
    borderRadius: 10,
    borderWidth: 1,
    marginTop: 6,
    marginBottom: 4,
  },
  kantarCheck: {
    width: 22,
    height: 22,
    borderRadius: 6,
    borderWidth: 2,
    justifyContent: "center",
    alignItems: "center",
  },
  kantarTitle: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
  kantarDesc: { fontSize: 11, fontFamily: "Inter_400Regular", marginTop: 2 },
  kantarBadge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 999,
    alignSelf: "flex-start",
    marginTop: 6,
  },
  kantarBadgeText: { fontSize: 10, fontFamily: "Inter_600SemiBold" },
  warnBox: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 10,
    backgroundColor: "#fef3c7",
    borderWidth: 1,
    borderColor: "#fcd34d",
    borderRadius: 10,
    padding: 12,
    marginBottom: 14,
  },
  warnTitle: {
    fontSize: 13,
    fontFamily: "Inter_700Bold",
    color: "#92400e",
    marginBottom: 2,
  },
  warnBody: {
    fontSize: 12,
    fontFamily: "Inter_500Medium",
    color: "#78350f",
    lineHeight: 17,
  },
  badge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 999,
  },
  badgeText: { fontSize: 11, fontFamily: "Inter_600SemiBold" },
  qtyPill: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 999,
  },
  qtyPillText: { fontSize: 12, fontFamily: "Inter_700Bold" },
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
  movMeta: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 12,
    marginBottom: 4,
  },
  movMetaItem: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
  },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  chip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999 },
  chipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
  knownChip: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 999,
    marginRight: 8,
  },
  twoCol: { flexDirection: "row", gap: 8 },
});
