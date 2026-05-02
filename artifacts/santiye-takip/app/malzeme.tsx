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
import UnitPicker from "@/components/UnitPicker";
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
  unit: string;
  quantity: string;
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

interface MovF {
  projectId: string;
  type: "kullanim" | "giden";
  name: string;
  unit: string;
  quantity: string;
  date: string;
  person: string;
  location: string;
  reason: string;
  note: string;
}

const EMPTY_M: MF = {
  projectId: "", name: "", unit: "", quantity: "",
  supplier: "", deliveryDate: "", unitPrice: "",
};

const EMPTY_R: RF = {
  projectId: "", name: "", unit: "", quantity: "",
  requestDate: "", requestedBy: "", status: "pending", note: "",
};

const EMPTY_MOV: MovF = {
  projectId: "", type: "kullanim", name: "", unit: "", quantity: "",
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
  useEffect(() => { if (perm === "none") router.back(); }, [perm]);

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

  // Stok özeti: aynı proje + isim + birim için (gelen toplamı + eski usedQty düşülmüş) - kullanım - giden
  function stockFor(material: Material) {
    const key = (m: { projectId: string; name: string; unit: string }) =>
      `${m.projectId}|${m.name.trim().toLowerCase()}|${m.unit.trim().toLowerCase()}`;
    const k = key(material);
    const usedFromMovements = materialMovements
      .filter((m) => key(m) === k)
      .reduce((s, m) => s + (m.quantity || 0), 0);
    const remaining = (material.quantity || 0) - (material.usedQty || 0) - usedFromMovements;
    return { remaining, usedFromMovements };
  }

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
        unit: m.unit,
        quantity: String(m.quantity || ""),
        supplier: m.supplier,
        deliveryDate: m.deliveryDate,
        unitPrice: String(m.unitPrice || ""),
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
      unit: mForm.unit.trim(),
      quantity: parseFloat(mForm.quantity) || 0,
      usedQty: 0,
      supplier: mForm.supplier.trim(),
      deliveryDate: mForm.deliveryDate.trim(),
      unitPrice: parseFloat(mForm.unitPrice) || 0,
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

  function pickKnownMaterial(m: Material) {
    setMovForm((prev) => ({
      ...prev,
      name: m.name,
      unit: m.unit,
    }));
  }

  function saveMovement() {
    if (!movForm.projectId || !movForm.name.trim()) return;
    const data: Omit<MaterialMovement, "id"> = {
      projectId: movForm.projectId,
      type: movForm.type,
      name: movForm.name.trim(),
      unit: movForm.unit.trim(),
      quantity: parseFloat(movForm.quantity) || 0,
      date: movForm.date.trim(),
      person: movForm.person.trim(),
      location: movForm.location.trim(),
      reason: movForm.reason.trim(),
      note: movForm.note.trim(),
    };
    if (movEditId) updateMaterialMovement(movEditId, data);
    else addMaterialMovement(data);
    setMovVisible(false);
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
        onBack={() => router.back()}
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
          <FormInput
            label="Malzeme Adı"
            value={mForm.name}
            onChangeText={(v) => setMForm({ ...mForm, name: v })}
            placeholder="Örn: Çimento CEM I 42.5"
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
                label="Birim Fiyat (₺)"
                value={mForm.unitPrice}
                onChangeText={(v) => setMForm({ ...mForm, unitPrice: v })}
                keyboardType="numeric"
              />
            </View>
          </View>
          <FormInput
            label="Gelen Miktar"
            value={mForm.quantity}
            onChangeText={(v) => setMForm({ ...mForm, quantity: v })}
            keyboardType="numeric"
          />
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

          <FormInput
            label="Malzeme Adı"
            value={movForm.name}
            onChangeText={(v) => setMovForm({ ...movForm, name: v })}
            placeholder="Örn: Demir Ø12"
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
          <FormInput
            label="Tarih"
            value={movForm.date}
            onChangeText={(v) => setMovForm({ ...movForm, date: v })}
            placeholder="GG.AA.YYYY"
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
          <FormInput
            label="Malzeme Adı"
            value={rForm.name}
            onChangeText={(v) => setRForm({ ...rForm, name: v })}
            placeholder="Örn: Demir Ø12"
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
          const { remaining, usedFromMovements } = stockFor(item);
          const totalUsed = (item.usedQty || 0) + usedFromMovements;
          const pct = item.quantity > 0
            ? Math.min(100, Math.max(0, Math.round((totalUsed / item.quantity) * 100)))
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
                  <Text style={[styles.qtyLabel, { color: colors.mutedForeground }]}>Gelen</Text>
                  <Text style={[styles.qtyVal, { color: colors.foreground }]}>{item.quantity} {item.unit}</Text>
                </View>
                <View style={styles.qtyBox}>
                  <Text style={[styles.qtyLabel, { color: colors.mutedForeground }]}>Kullanılan</Text>
                  <Text style={[styles.qtyVal, { color: colors.foreground }]}>{totalUsed} {item.unit}</Text>
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
                    <Text style={[styles.metaText, { color: colors.mutedForeground, marginLeft: "auto", flex: 0 }]}>
                      {item.unitPrice.toLocaleString("tr-TR")} ₺/{item.unit}
                    </Text>
                  ) : null}
                </View>
              ) : null}
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
