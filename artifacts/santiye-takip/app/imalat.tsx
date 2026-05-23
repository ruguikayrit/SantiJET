import { useRouter } from "expo-router";
import React, { useEffect, useMemo, useState } from "react";
import {
  Alert,
  FlatList,
  Image,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { Feather } from "@expo/vector-icons";
import * as ImagePicker from "expo-image-picker";

import BottomSheet from "@/components/BottomSheet";
import EmptyState from "@/components/EmptyState";
import DatePickerInput from "@/components/DatePickerInput";
import FormInput from "@/components/FormInput";
import Header from "@/components/Header";
import MultiSelectBar from "@/components/MultiSelectBar";
import PozPicker from "@/components/PozPicker";
import UnitPicker from "@/components/UnitPicker";
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
  images: string[];
  mixerCount: string;
  pumpCount: string;
  pumpInfo: string;
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
  images: [],
  mixerCount: "",
  pumpCount: "",
  pumpInfo: "",
};

export default function ImalatScreen() {
  const colors = useColors();
  const router = useRouter();
  const { projects, productions, addProduction, updateProduction, deleteProduction, surveys } = useApp();
  const perm = usePermission("imalat");
  const canEdit = perm === "edit";
  useEffect(() => { if (perm === "none") { if (router.canGoBack()) router.back(); else router.replace("/"); } }, [perm]);

  const [filter, setFilter] = useState<string | null>(null);
  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<F>(EMPTY);

  const [searchName, setSearchName] = useState("");
  const [searchPoz, setSearchPoz] = useState("");
  const [searchDate, setSearchDate] = useState("");

  const [imMode, setImMode] = useState<"kesif" | "serbest">("serbest");
  const [selectMode, setSelectMode] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  function toggleSelect(id: string) {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  }
  function exitSelect() { setSelectMode(false); setSelectedIds(new Set()); }
  function bulkDelete() {
    selectedIds.forEach((id) => deleteProduction(id));
    exitSelect();
  }
  function enterSelectWith(id: string) {
    setSelectMode(true);
    setSelectedIds(new Set([id]));
  }

  const hasFilter = !!(searchName.trim() || searchPoz.trim() || searchDate.trim());

  const list = useMemo(() => {
    let l = filter ? productions.filter((p) => p.projectId === filter) : productions;
    const n = searchName.trim().toLocaleLowerCase("tr-TR");
    const pz = searchPoz.trim().toLocaleLowerCase("tr-TR");
    const d = searchDate.trim();
    if (n) l = l.filter((p) => (p.name || "").toLocaleLowerCase("tr-TR").includes(n));
    if (pz) l = l.filter((p) =>
      ((p.pozCode || "") + " " + (p.pozCategory || "")).toLocaleLowerCase("tr-TR").includes(pz)
    );
    if (d) l = l.filter((p) => p.date === d);
    return l;
  }, [productions, filter, searchName, searchPoz, searchDate]);

  function clearFilters() {
    setSearchName("");
    setSearchPoz("");
    setSearchDate("");
  }

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
        images: Array.isArray(p.images) ? p.images : [],
        mixerCount: p.mixerCount || "",
        pumpCount: p.pumpCount || "",
        pumpInfo: p.pumpInfo || "",
      });
    } else {
      setEditId(null);
      setForm({ ...EMPTY, projectId: filter || projects[0]?.id || "" });
    }
    setVisible(true);
  }

  const isBetonForm = /beton\s*dökümü/i.test(form.name) || /beton\s*dökümü/i.test(form.category);

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
      images: form.images.length > 0 ? form.images : undefined,
      mixerCount: isBetonForm ? (form.mixerCount.trim() || undefined) : undefined,
      pumpCount: isBetonForm ? (form.pumpCount.trim() || undefined) : undefined,
      pumpInfo: isBetonForm ? (form.pumpInfo.trim() || undefined) : undefined,
    };
    if (editId) updateProduction(editId, data);
    else addProduction(data);
    setVisible(false);
  }

  function remove() {
    if (editId) deleteProduction(editId);
    setVisible(false);
  }

  async function pickFromCamera() {
    try {
      const perm = await ImagePicker.requestCameraPermissionsAsync();
      if (!perm.granted) {
        Alert.alert("İzin gerekli", "Kameraya erişim izni verilmedi.");
        return;
      }
      const res = await ImagePicker.launchCameraAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        quality: 0.7,
      });
      if (!res.canceled && res.assets?.[0]?.uri) {
        setForm((f) => ({ ...f, images: [...f.images, res.assets[0].uri] }));
      }
    } catch (e: any) {
      Alert.alert("Hata", e?.message || "Kamera açılamadı.");
    }
  }

  async function pickFromGallery() {
    try {
      const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
      if (!perm.granted) {
        Alert.alert("İzin gerekli", "Galeriye erişim izni verilmedi.");
        return;
      }
      const res = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        quality: 0.7,
        allowsMultipleSelection: true,
      });
      if (!res.canceled && res.assets?.length) {
        const uris = res.assets.map((a) => a.uri).filter(Boolean);
        setForm((f) => ({ ...f, images: [...f.images, ...uris] }));
      }
    } catch (e: any) {
      Alert.alert("Hata", e?.message || "Galeri açılamadı.");
    }
  }

  function addImage() {
    if (Platform.OS === "web") {
      pickFromGallery();
      return;
    }
    Alert.alert("İmalat Resmi Ekle", "Kaynak seçin", [
      { text: "Vazgeç", style: "cancel" },
      { text: "Kamera", onPress: pickFromCamera },
      { text: "Galeri", onPress: pickFromGallery },
    ]);
  }

  function removeImage(idx: number) {
    setForm((f) => ({ ...f, images: f.images.filter((_, i) => i !== idx) }));
  }

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="İmalat"
        onBack={() => (router.canGoBack() ? router.back() : router.replace("/"))}
        rightAction={
          selectMode
            ? undefined
            : canEdit && projects.length > 0
            ? { icon: "plus", onPress: () => open() }
            : undefined
        }
      />
      {selectMode ? (
        <MultiSelectBar
          count={selectedIds.size}
          onCancel={exitSelect}
          onDelete={bulkDelete}
          itemLabel="imalat kaydı"
        />
      ) : null}


      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="İmalat takibi için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : (
        <View style={[styles.filterBar, { borderBottomColor: colors.border, backgroundColor: colors.card }]}>
          <View style={styles.filterRow}>
            <View style={[styles.searchBox, { backgroundColor: colors.muted, flex: 1 }]}>
              <Feather name="tool" size={13} color={colors.mutedForeground} />
              <TextInput
                value={searchName}
                onChangeText={setSearchName}
                placeholder="İmalat adı"
                placeholderTextColor={colors.mutedForeground}
                style={[styles.searchInput, { color: colors.foreground }]}
              />
            </View>
            <View style={[styles.searchBox, { backgroundColor: colors.muted, flex: 1 }]}>
              <Feather name="hash" size={13} color={colors.mutedForeground} />
              <TextInput
                value={searchPoz}
                onChangeText={setSearchPoz}
                placeholder="Poz"
                placeholderTextColor={colors.mutedForeground}
                style={[styles.searchInput, { color: colors.foreground }]}
              />
            </View>
          </View>
          <View style={styles.filterRow}>
            <View style={{ flex: 1 }}>
              <DatePickerInput
                value={searchDate}
                onChange={setSearchDate}
              />
            </View>
            {hasFilter ? (
              <TouchableOpacity
                onPress={clearFilters}
                style={[styles.clearBtn, { backgroundColor: colors.muted }]}
                activeOpacity={0.7}
              >
                <Feather name="x" size={14} color={colors.foreground} />
                <Text style={[styles.clearBtnText, { color: colors.foreground }]}>Temizle</Text>
              </TouchableOpacity>
            ) : null}
          </View>
        </View>
      )}

      {projects.length === 0 ? null : list.length === 0 ? (
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
            const isSel = selectedIds.has(item.id);
            return (
            <TouchableOpacity
              style={[
                styles.card,
                styles.cardRow,
                { backgroundColor: colors.card },
                isSel && { borderWidth: 2, borderColor: "#dc2626" },
              ]}
              activeOpacity={0.85}
              onPress={() => {
                if (selectMode) toggleSelect(item.id);
                else open(item);
              }}
              onLongPress={() => { if (canEdit) enterSelectWith(item.id); }}
            >
              <View style={{ flex: 1, paddingRight: 10 }}>
                <Text style={[styles.proj, { color: colors.primary }]}>
                  {projectName(item.projectId)}
                </Text>
                {item.pozCode ? (
                  <Text style={[styles.pozCode, { color: colors.mutedForeground }]}>
                    {item.pozCode}
                    {item.pozCategory ? ` · ${item.pozCategory}` : ""}
                  </Text>
                ) : null}
                <Text style={[styles.title, { color: colors.foreground, marginBottom: 0 }]} numberOfLines={2}>
                  {item.name}
                </Text>
                {item.description ? (
                  <Text style={[styles.desc, { color: colors.mutedForeground }]} numberOfLines={3}>
                    {item.description}
                  </Text>
                ) : null}
              </View>
              <View style={[styles.metrajPill, { backgroundColor: colors.muted }]}>
                <Text style={[styles.metrajLabel, { color: colors.mutedForeground }]}>
                  Gerçekleşen Miktar
                </Text>
                <Text style={[styles.metrajVal, { color: "#16a34a" }]}>
                  {item.completedQty} {item.unit}
                </Text>
              </View>
              {selectMode ? (
                <View style={[styles.selDot, { borderColor: isSel ? "#dc2626" : colors.mutedForeground, backgroundColor: isSel ? "#dc2626" : "transparent" }]}>
                  {isSel ? <Feather name="check" size={12} color="#fff" /> : null}
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

        <Text style={[styles.label, { color: colors.foreground }]}>Poz Kaynağı</Text>
        <View style={[styles.chips, { marginBottom: 16 }]}>
          <TouchableOpacity
            onPress={() => setImMode("kesif")}
            style={[styles.chip, { backgroundColor: imMode === "kesif" ? colors.primary : colors.muted, flex: 1, alignItems: "center" }]}
          >
            <Text style={[styles.chipText, { color: imMode === "kesif" ? "#fff" : colors.foreground }]}>
              Keşif Kaleminden
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            onPress={() => setImMode("serbest")}
            style={[styles.chip, { backgroundColor: imMode === "serbest" ? colors.primary : colors.muted, flex: 1, alignItems: "center" }]}
          >
            <Text style={[styles.chipText, { color: imMode === "serbest" ? "#fff" : colors.foreground }]}>
              Keşif Dışı
            </Text>
          </TouchableOpacity>
        </View>

        {imMode === "kesif" ? (() => {
          const projItems = surveys
            .filter((s) => s.projectId === form.projectId)
            .flatMap((s) => s.items.map((it) => ({ ...it, surveyTitle: s.title })));
          return (
            <>
              <Text style={[styles.label, { color: colors.foreground }]}>Keşif Kalemi Seç</Text>
              {projItems.length === 0 ? (
                <View style={[styles.emptyPicker, { backgroundColor: colors.muted }]}>
                  <Text style={[styles.emptyPickerText, { color: colors.mutedForeground }]}>
                    Bu proje için keşif kalemi bulunamadı.
                  </Text>
                </View>
              ) : (
                <View style={[styles.pickerList, { borderColor: colors.border, marginBottom: 16 }]}>
                  {projItems.map((it, idx) => {
                    const sel = form.pozCode === (it.pozCode || "") && form.name === it.description;
                    return (
                      <TouchableOpacity
                        key={it.id}
                        onPress={() =>
                          setForm((prev) => ({
                            ...prev,
                            name: it.description,
                            unit: it.unit,
                            pozCode: it.pozCode || "",
                            category: it.pozCategory || prev.category,
                          }))
                        }
                        activeOpacity={0.8}
                        style={[
                          styles.pickerRow,
                          {
                            backgroundColor: sel ? colors.primary + "15" : "transparent",
                            borderTopWidth: idx === 0 ? 0 : StyleSheet.hairlineWidth,
                            borderTopColor: colors.border,
                          },
                        ]}
                      >
                        <View style={[styles.pickerDot, { backgroundColor: sel ? colors.primary : colors.muted }]}>
                          {sel ? <Feather name="check" size={12} color="#fff" /> : null}
                        </View>
                        <View style={{ flex: 1 }}>
                          <Text style={[styles.pickerName, { color: sel ? colors.primary : colors.foreground }]} numberOfLines={2}>
                            {it.description}
                          </Text>
                          <Text style={[styles.pickerMeta, { color: colors.mutedForeground }]} numberOfLines={1}>
                            {it.surveyTitle}{it.pozCode ? ` · ${it.pozCode}` : ""} · {it.quantity} {it.unit}
                          </Text>
                        </View>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              )}
            </>
          );
        })() : (
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
        )}

        <FormInput
          label="İmalat Adı"
          value={form.name}
          onChangeText={(v) => setForm({ ...form, name: v })}
          placeholder="Poz seçince otomatik dolar"
        />
        <View style={styles.row}>
          <View style={{ flex: 1 }}>
            <UnitPicker
              label="Birim"
              value={form.unit}
              onChange={(v) => setForm({ ...form, unit: v })}
            />
          </View>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Gerçekleşen Miktar"
              value={form.completedQty}
              onChangeText={(v) => setForm({ ...form, completedQty: v })}
              keyboardType="numeric"
            />
          </View>
        </View>
        <DatePickerInput
          label="Tarih"
          value={form.date}
          onChange={(v) => setForm({ ...form, date: v })}
        />

        {isBetonForm ? (
          <>
            <Text style={[styles.label, { color: colors.foreground, marginTop: 6 }]}>
              Beton Dökümü Detayları
            </Text>
            <View style={styles.row}>
              <View style={{ flex: 1 }}>
                <FormInput
                  label="Mikser Sayısı"
                  value={form.mixerCount}
                  onChangeText={(v) => setForm({ ...form, mixerCount: v })}
                  placeholder="Örn: 8"
                  keyboardType="numeric"
                />
              </View>
              <View style={{ flex: 1 }}>
                <FormInput
                  label="Pompa Sayısı"
                  value={form.pumpCount}
                  onChangeText={(v) => setForm({ ...form, pumpCount: v })}
                  placeholder="Örn: 1"
                  keyboardType="numeric"
                />
              </View>
            </View>
            <FormInput
              label="Pompa Bilgileri"
              value={form.pumpInfo}
              onChangeText={(v) => setForm({ ...form, pumpInfo: v })}
              placeholder="Örn: 42m boom, firma adı, plaka"
              multiline
              numberOfLines={3}
              style={{ minHeight: 70, paddingTop: 10 }}
            />
          </>
        ) : null}

        <FormInput
          label="Açıklama"
          value={form.description}
          onChangeText={(v) => setForm({ ...form, description: v })}
          placeholder="İmalat ile ilgili notlar, detaylar..."
          multiline
          numberOfLines={4}
          style={{ minHeight: 90, paddingTop: 10 }}
        />

        <Text style={[styles.label, { color: colors.foreground, marginTop: 4 }]}>İmalat Resimleri</Text>
        {form.images.length > 0 ? (
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 10 }}>
            {form.images.map((uri, idx) => (
              <View key={`${uri}-${idx}`} style={styles.thumbWrap}>
                <Image source={{ uri }} style={styles.thumb} />
                {canEdit ? (
                  <TouchableOpacity
                    onPress={() => removeImage(idx)}
                    style={styles.thumbRemove}
                    activeOpacity={0.85}
                  >
                    <Feather name="x" size={12} color="#fff" />
                  </TouchableOpacity>
                ) : null}
              </View>
            ))}
          </ScrollView>
        ) : null}
        {canEdit ? (
          <TouchableOpacity
            onPress={addImage}
            activeOpacity={0.85}
            style={[styles.addImgBtn, { borderColor: colors.primary }]}
          >
            <Feather name="camera" size={16} color={colors.primary} />
            <Text style={[styles.addImgBtnText, { color: colors.primary }]}>İmalat Resmi Ekle</Text>
          </TouchableOpacity>
        ) : null}

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
  selDot: { width: 22, height: 22, borderRadius: 11, borderWidth: 2, alignItems: "center", justifyContent: "center", marginLeft: 8 },
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
  emptyPicker: { borderRadius: 10, padding: 16, alignItems: "center", marginBottom: 16 },
  emptyPickerText: { fontSize: 13, fontFamily: "Inter_400Regular" },
  pickerList: { borderWidth: 1, borderRadius: 10, overflow: "hidden", marginBottom: 16 },
  pickerRow: { flexDirection: "row", alignItems: "center", gap: 10, paddingHorizontal: 12, paddingVertical: 10 },
  pickerDot: { width: 20, height: 20, borderRadius: 10, alignItems: "center", justifyContent: "center" },
  pickerName: { fontSize: 13, fontFamily: "Inter_500Medium", marginBottom: 2 },
  pickerMeta: { fontSize: 11, fontFamily: "Inter_400Regular" },
  row: { flexDirection: "row", gap: 8 },
  cardRow: { flexDirection: "row", alignItems: "center" },
  metrajPill: {
    alignItems: "flex-end",
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 12,
    minWidth: 110,
  },
  metrajLabel: { fontSize: 10, fontFamily: "Inter_500Medium", marginBottom: 4, textTransform: "uppercase", letterSpacing: 0.4 },
  metrajVal: { fontSize: 16, fontFamily: "Inter_700Bold" },
  desc: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 6, lineHeight: 17 },
  thumbWrap: { marginRight: 8, position: "relative" },
  thumb: { width: 92, height: 92, borderRadius: 10, backgroundColor: "#0001" },
  thumbRemove: {
    position: "absolute",
    top: -6,
    right: -6,
    width: 22,
    height: 22,
    borderRadius: 11,
    backgroundColor: "#dc2626",
    alignItems: "center",
    justifyContent: "center",
  },
  addImgBtn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    paddingVertical: 12,
    paddingHorizontal: 14,
    borderRadius: 10,
    borderWidth: 1.5,
    borderStyle: "dashed",
    marginBottom: 6,
  },
  addImgBtnText: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
  filterBar: {
    paddingHorizontal: 12,
    paddingVertical: 10,
    gap: 8,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  filterRow: { flexDirection: "row", gap: 8, alignItems: "center" },
  searchBox: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 8,
    borderRadius: 8,
    minHeight: 38,
  },
  searchInput: {
    flex: 1,
    fontSize: 13,
    fontFamily: "Inter_500Medium",
    padding: 0,
  },
  clearBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 8,
    borderRadius: 8,
  },
  clearBtnText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
});
