import { Feather } from "@expo/vector-icons";
import * as DocumentPicker from "expo-document-picker";
import * as FileSystem from "expo-file-system";
import { useRouter } from "expo-router";
import * as Sharing from "expo-sharing";
import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  Alert,
  FlatList,
  PanResponder,
  Platform,
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
import PozPicker from "@/components/PozPicker";
import PrimaryButton from "@/components/PrimaryButton";
import { Survey, SurveyItem, useApp } from "@/context/AppContext";
import UnitPicker from "@/components/UnitPicker";
import { useColors } from "@/hooks/useColors";
import { useMergedPozAnalizleri } from "@/hooks/useMergedPozAnalizleri";
import { usePermission } from "@/hooks/usePermission";
import {
  buildKesifCsv,
  groupRowsByProjectAndTitle,
  parseKesifCsv,
  rowToSurveyItem,
} from "@/constants/kesifCsv";

interface FormState {
  projectId: string;
  title: string;
  date: string;
  location: string;
  notes: string;
  itemPozCode: string;
  itemPozCategory: string;
  itemDesc: string;
  itemUnit: string;
  itemMetraj: string;
  itemDate: string;
  itemType: "malzeme" | "iscilik";
}

const EMPTY: FormState = {
  projectId: "",
  title: "",
  date: "",
  location: "",
  notes: "",
  itemPozCode: "",
  itemPozCategory: "",
  itemDesc: "",
  itemUnit: "",
  itemMetraj: "",
  itemDate: "",
  itemType: "malzeme",
};

export default function KesifScreen() {
  const colors = useColors();
  const router = useRouter();
  const { projects, surveys, addSurvey, updateSurvey, deleteSurvey } = useApp();
  const { pozAnalizleri } = useMergedPozAnalizleri();

  const perm = usePermission("kesif");
  const canEdit = perm === "edit";
  useEffect(() => { if (perm === "none") { if (router.canGoBack()) router.back(); else router.replace("/"); } }, [perm]);

  const [filter, setFilter] = useState<string | null>(null);
  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [editItemId, setEditItemId] = useState<string | null>(null);
  const [form, setForm] = useState<FormState>(EMPTY);
  const [expandedSurveyId, setExpandedSurveyId] = useState<string | null>(null);
  const [importVisible, setImportVisible] = useState(false);
  const [importText, setImportText] = useState("");
  const [importBusy, setImportBusy] = useState(false);

  const [dragState, setDragState] = useState<{ fromIndex: number; toIndex: number } | null>(null);
  const dragStateRef = useRef<{ fromIndex: number; toIndex: number } | null>(null);
  const ITEM_ROW_H = 90;

  const list = useMemo(
    () => (filter ? surveys.filter((s) => s.projectId === filter) : surveys),
    [surveys, filter]
  );

  function open(s?: Survey) {
    setEditItemId(null);
    if (s) {
      setEditId(s.id);
      setForm({
        projectId: s.projectId,
        title: s.title,
        date: s.date,
        location: s.location,
        notes: s.notes,
        itemPozCode: "",
        itemPozCategory: "",
        itemDesc: "",
        itemUnit: "",
        itemMetraj: "",
        itemDate: "",
        itemType: "malzeme",
      });
    } else {
      setEditId(null);
      setForm({ ...EMPTY, projectId: filter || projects[0]?.id || "" });
    }
    setVisible(true);
  }

  function loadItemForEdit(it: SurveyItem) {
    setEditItemId(it.id);
    setForm((prev) => ({
      ...prev,
      itemPozCode: it.pozCode || "",
      itemPozCategory: it.pozCategory || "",
      itemDesc: it.description,
      itemUnit: it.unit,
      itemMetraj: String(it.quantity || ""),
      itemDate: it.date || "",
      itemType: it.itemType || "malzeme",
    }));
  }

  function clearItemForm() {
    setEditItemId(null);
    setForm((prev) => ({
      ...prev,
      itemPozCode: "",
      itemPozCategory: "",
      itemDesc: "",
      itemUnit: "",
      itemMetraj: "",
      itemDate: "",
      itemType: "malzeme",
    }));
  }

  function save() {
    if (!form.projectId || !form.title.trim()) return;
    let items =
      editId
        ? [...(surveys.find((x) => x.id === editId)?.items || [])]
        : [];
    if (form.itemDesc.trim()) {
      const metraj = parseFloat(form.itemMetraj) || 0;
      const existingItem = editItemId
        ? items.find((i) => i.id === editItemId)
        : undefined;
      const newItem = {
        id: editItemId || Date.now().toString(),
        description: form.itemDesc.trim(),
        unit: form.itemUnit.trim(),
        quantity: metraj,
        unitPrice: existingItem?.unitPrice ?? 0,
        pozCode: form.itemPozCode.trim() || undefined,
        pozCategory: form.itemPozCategory.trim() || undefined,
        date: form.itemDate.trim() || undefined,
        itemType: form.itemType,
      };
      if (editItemId) {
        items = items.map((i) => (i.id === editItemId ? newItem : i));
      } else {
        items.push(newItem);
      }
    }
    const data = {
      projectId: form.projectId,
      title: form.title.trim(),
      date: form.date.trim(),
      location: form.location.trim(),
      notes: form.notes.trim(),
      items,
    };
    if (editId) {
      updateSurvey(editId, data);
      clearItemForm();
    } else {
      addSurvey(data);
      setVisible(false);
    }
  }

  function remove() {
    if (editId) deleteSurvey(editId);
    setVisible(false);
  }

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  function applyImport(text: string) {
    const result = parseKesifCsv(text);
    if (result.rows.length === 0) {
      Alert.alert(
        "İçe aktarma başarısız",
        result.errors.length > 0
          ? result.errors.slice(0, 5).join("\n")
          : "Hiç geçerli satır bulunamadı.",
      );
      return;
    }
    const { groups, missingProjects } = groupRowsByProjectAndTitle(
      result.rows,
      projects,
    );
    let created = 0;
    let updated = 0;
    let addedItems = 0;
    let suffix = 0;
    const norm = (s: string) => s.trim().toLowerCase();
    for (const g of Array.from(groups.values())) {
      const existing = surveys.find(
        (s) => s.projectId === g.projectId && norm(s.title) === norm(g.title),
      );
      const newItems: SurveyItem[] = g.rows.map((r) => rowToSurveyItem(r, suffix++));
      const firstRow = g.rows[0];
      if (existing) {
        updateSurvey(existing.id, {
          ...existing,
          date: existing.date || firstRow.surveyDate,
          notes: existing.notes || firstRow.surveyNotes,
          items: [...existing.items, ...newItems],
        });
        updated++;
      } else {
        addSurvey({
          projectId: g.projectId,
          title: g.title,
          date: firstRow.surveyDate,
          location: "",
          notes: firstRow.surveyNotes,
          items: newItems,
        });
        created++;
      }
      addedItems += newItems.length;
    }
    setImportVisible(false);
    setImportText("");
    const lines = [
      `${created} yeni keşif oluşturuldu.`,
      `${updated} mevcut keşfe kalem eklendi.`,
      `Toplam ${addedItems} kalem aktarıldı.`,
    ];
    if (missingProjects.length > 0)
      lines.push(`Atlanan proje (kayıtlı değil): ${missingProjects.join(", ")}`);
    if (result.errors.length > 0)
      lines.push(`${result.errors.length} satır hatalı.`);
    Alert.alert("İçe aktarıldı", lines.join("\n"));
  }

  async function pickCsvFile() {
    try {
      setImportBusy(true);
      const res = await DocumentPicker.getDocumentAsync({
        type: ["text/csv", "text/comma-separated-values", "application/vnd.ms-excel", "text/plain", "*/*"],
        copyToCacheDirectory: true,
      });
      if (res.canceled || !res.assets?.[0]) return;
      const asset = res.assets[0];
      let text = "";
      if (Platform.OS === "web" && (asset as any).file) {
        text = await ((asset as any).file as File).text();
      } else {
        text = await (FileSystem as any).readAsStringAsync(asset.uri, { encoding: "utf8" });
      }
      applyImport(text);
    } catch (e: any) {
      Alert.alert("Hata", String(e?.message || e));
    } finally {
      setImportBusy(false);
    }
  }

  async function exportCsv() {
    try {
      setImportBusy(true);
      const csv = buildKesifCsv(surveys, projects);
      if (Platform.OS === "web") {
        const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = "kesif.csv";
        document.body.appendChild(a);
        a.click();
        a.remove();
        URL.revokeObjectURL(url);
      } else {
        const dir = (FileSystem as any).cacheDirectory ?? (FileSystem as any).documentDirectory;
        const fileUri = `${dir}kesif.csv`;
        await (FileSystem as any).writeAsStringAsync(fileUri, csv, { encoding: "utf8" });
        if (await Sharing.isAvailableAsync()) {
          await Sharing.shareAsync(fileUri, { mimeType: "text/csv", dialogTitle: "Keşif Verisini Paylaş" });
        } else {
          Alert.alert("Kaydedildi", fileUri);
        }
      }
    } catch (e: any) {
      Alert.alert("Hata", String(e?.message || e));
    } finally {
      setImportBusy(false);
    }
  }

  function deleteItem(itemId: string) {
    if (!editId) return;
    const s = surveys.find((x) => x.id === editId);
    if (!s) return;
    updateSurvey(editId, { ...s, items: s.items.filter((i) => i.id !== itemId) });
  }

  function copyItem(itemId: string) {
    if (!editId) return;
    const s = surveys.find((x) => x.id === editId);
    if (!s) return;
    const idx = s.items.findIndex((i) => i.id === itemId);
    if (idx === -1) return;
    const copy: SurveyItem = { ...s.items[idx], id: Date.now().toString() };
    const newItems = [
      ...s.items.slice(0, idx + 1),
      copy,
      ...s.items.slice(idx + 1),
    ];
    updateSurvey(editId, { ...s, items: newItems });
  }

  function reorderItems(fromIdx: number, toIdx: number) {
    if (!editId || fromIdx === toIdx) return;
    const s = surveys.find((x) => x.id === editId);
    if (!s) return;
    const items = [...s.items];
    const [moved] = items.splice(fromIdx, 1);
    items.splice(toIdx, 0, moved);
    updateSurvey(editId, { ...s, items });
  }

  const currentItems = editId
    ? surveys.find((x) => x.id === editId)?.items || []
    : [];

  const displayItems = useMemo(() => {
    if (!dragState) return currentItems;
    const { fromIndex, toIndex } = dragState;
    const arr = [...currentItems];
    const [moved] = arr.splice(fromIndex, 1);
    arr.splice(toIndex, 0, moved);
    return arr;
  }, [currentItems, dragState]);

  function makeDragResponder(index: number) {
    return PanResponder.create({
      onStartShouldSetPanResponder: () => false,
      onStartShouldSetPanResponderCapture: () => false,
      onMoveShouldSetPanResponder: (_, g) => Math.abs(g.dy) > 4,
      onMoveShouldSetPanResponderCapture: (_, g) => Math.abs(g.dy) > 4,
      onPanResponderGrant: () => {
        const ds = { fromIndex: index, toIndex: index };
        dragStateRef.current = ds;
        setDragState(ds);
      },
      onPanResponderMove: (_, g) => {
        const from = dragStateRef.current?.fromIndex ?? index;
        const toIndex = Math.max(0, Math.min(
          currentItems.length - 1,
          Math.round(from + g.dy / ITEM_ROW_H)
        ));
        const next = { fromIndex: from, toIndex };
        dragStateRef.current = next;
        setDragState(next);
      },
      onPanResponderRelease: () => {
        const ds = dragStateRef.current;
        if (ds) reorderItems(ds.fromIndex, ds.toIndex);
        dragStateRef.current = null;
        setDragState(null);
      },
      onPanResponderTerminate: () => {
        dragStateRef.current = null;
        setDragState(null);
      },
    });
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Keşif"
        onBack={() => (router.canGoBack() ? router.back() : router.replace("/"))}
        rightAction={canEdit && projects.length > 0 ? { icon: "plus", onPress: () => open() } : undefined}
        extraActions={
          canEdit
            ? [
                { icon: "upload", onPress: () => { setImportText(""); setImportVisible(true); } },
                { icon: "download", onPress: exportCsv },
              ]
            : undefined
        }
      />


      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="Keşif kaydı oluşturmak için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : list.length === 0 ? (
        <EmptyState
          icon="search"
          title="Keşif kaydı yok"
          description="Saha keşif kaydınızı oluşturmak için + düğmesine dokunun"
          actionLabel="Keşif Ekle"
          onAction={() => open()}
        />
      ) : (
        <FlatList
          data={list}
          keyExtractor={(s) => s.id}
          contentContainerStyle={styles.list}
          renderItem={({ item: survey }) => {
            const isExpanded = expandedSurveyId === survey.id;
            return (
              <View style={[styles.cardWrap, { backgroundColor: colors.card }]}>
                <TouchableOpacity
                  style={styles.cardHeader}
                  activeOpacity={0.85}
                  onPress={() => {
                    if (isExpanded) {
                      open(survey);
                    } else {
                      setExpandedSurveyId(survey.id);
                    }
                  }}
                >
                  <View style={{ flex: 1 }}>
                    <Text style={[styles.proj, { color: colors.primary }]}>
                      {projectName(survey.projectId)}
                    </Text>
                    <Text style={[styles.title, { color: colors.foreground }]}>
                      {survey.title}
                    </Text>
                    {survey.date ? (
                      <View style={styles.row}>
                        <Feather name="calendar" size={13} color={colors.mutedForeground} />
                        <Text style={[styles.meta, { color: colors.mutedForeground }]}>
                          {survey.date}
                        </Text>
                      </View>
                    ) : null}
                    <View style={styles.footer}>
                      <Text style={[styles.itemCount, { color: colors.mutedForeground }]}>
                        {survey.items.length} kalem
                      </Text>
                      <Text style={[styles.expandHint, { color: colors.mutedForeground }]}>
                        {isExpanded ? "tekrar tıkla → düzenle" : "tıkla → kalemleri gör"}
                      </Text>
                    </View>
                  </View>
                  <Feather
                    name={isExpanded ? "chevron-up" : "chevron-down"}
                    size={18}
                    color={colors.mutedForeground}
                    style={{ marginLeft: 8, alignSelf: "center" }}
                  />
                </TouchableOpacity>

                {isExpanded ? (
                  <View style={[styles.accordionBody, { borderTopColor: colors.border }]}>
                    {survey.items.length === 0 ? (
                      <Text style={[styles.emptyItems, { color: colors.mutedForeground }]}>
                        Henüz kalem eklenmemiş.
                      </Text>
                    ) : (
                      survey.items.map((it, idx) => {
                        const analiz = it.pozCode
                          ? pozAnalizleri.find((a) => a.pozNo === it.pozCode)
                          : null;
                        const malzemeKalemleri = analiz
                          ? analiz.kalemler.filter((k) => k.tip === "malzeme")
                          : [];
                        return (
                          <View
                            key={it.id}
                            style={[
                              styles.accordionItem,
                              {
                                borderTopWidth: idx === 0 ? 0 : StyleSheet.hairlineWidth,
                                borderTopColor: colors.border,
                              },
                            ]}
                          >
                            {it.pozCode ? (
                              <Text style={[styles.accordionPoz, { color: colors.primary }]}>
                                {it.pozCode}
                              </Text>
                            ) : null}
                            <Text style={[styles.accordionDesc, { color: colors.foreground }]}>
                              {it.description}
                            </Text>
                            <Text style={[styles.accordionQty, { color: colors.mutedForeground }]}>
                              {it.quantity} {it.unit}
                            </Text>
                            {malzemeKalemleri.length > 0 ? (
                              <View style={[styles.malzemeBox, { backgroundColor: colors.muted }]}>
                                <Text style={[styles.malzemeBoxTitle, { color: colors.mutedForeground }]}>
                                  Analiz Malzemeleri — {analiz!.analizAdi}
                                </Text>
                                <View style={[styles.malzemeBoxHeader, { borderBottomColor: colors.border }]}>
                                  <Text style={[styles.malzemeColLabel, { color: colors.mutedForeground, flex: 1 }]}>Malzeme</Text>
                                  <Text style={[styles.malzemeColLabel, { color: colors.mutedForeground, width: 90, textAlign: "right" }]}>
                                    Hesap ({analiz!.olcuBirimi})
                                  </Text>
                                </View>
                                {malzemeKalemleri.map((k) => {
                                  const hesap = it.quantity * k.miktar;
                                  return (
                                    <View key={k.id} style={styles.malzemeRow}>
                                      <Text style={[styles.malzemeName, { color: colors.foreground }]} numberOfLines={2}>
                                        {k.tanim}
                                      </Text>
                                      <Text style={[styles.malzemeQtyText, { color: colors.primary }]}>
                                        {hesap % 1 === 0 ? hesap : hesap.toFixed(2)} {k.olcuBirimi}
                                      </Text>
                                    </View>
                                  );
                                })}
                              </View>
                            ) : null}
                          </View>
                        );
                      })
                    )}
                    <TouchableOpacity
                      onPress={() => { open(survey); setExpandedSurveyId(null); }}
                      style={[styles.accordionEditBtn, { borderTopColor: colors.border }]}
                    >
                      <Feather name="edit-2" size={14} color={colors.primary} />
                      <Text style={[styles.accordionEditBtnText, { color: colors.primary }]}>
                        Keşfi Düzenle
                      </Text>
                    </TouchableOpacity>
                  </View>
                ) : null}
              </View>
            );
          }}
        />
      )}

      <BottomSheet
        visible={visible}
        onClose={() => setVisible(false)}
        title={editId ? "Keşfi Düzenle" : "Yeni Keşif"}
        scrollEnabled={dragState === null}
      >
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
                  {
                    color: form.projectId === p.id ? "#fff" : colors.foreground,
                  },
                ]}
              >
                {p.name}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <FormInput
          label="Başlık"
          value={form.title}
          onChangeText={(v) => setForm({ ...form, title: v })}
          placeholder="Örn: Bodrum kazı keşfi"
        />
        <FormInput
          label="Açıklama"
          value={form.notes}
          onChangeText={(v) => setForm({ ...form, notes: v })}
          multiline
          style={{ height: 70, textAlignVertical: "top" }}
        />

        {editId && currentItems.length > 0 ? (
          <>
            <View style={styles.itemHeaderRow}>
              <Text style={[styles.label, { color: colors.foreground, marginTop: 8, marginBottom: 0 }]}>
                Kalemler ({currentItems.length})
              </Text>
              {dragState ? (
                <Text style={{ fontSize: 11, color: colors.mutedForeground, fontFamily: "Inter_400Regular" }}>
                  ≡ sürükleyerek sırala
                </Text>
              ) : null}
            </View>
            <View style={{ marginBottom: 14, marginTop: 8 }}>
              {displayItems.map((it, displayIdx) => {
                const sel = editItemId === it.id;
                const isDragging = dragState?.fromIndex !== undefined &&
                  currentItems[dragState.fromIndex]?.id === it.id;
                const isDropTarget = dragState !== null && displayIdx === dragState.toIndex && !isDragging;
                const dragResponder = canEdit ? makeDragResponder(displayIdx) : null;

                return (
                  <View
                    key={it.id}
                    style={[
                      styles.itemRow,
                      {
                        backgroundColor: isDragging
                          ? colors.primary + "28"
                          : sel ? colors.primary + "18" : colors.muted,
                        borderColor: isDragging
                          ? colors.primary
                          : isDropTarget ? "#f59e0b"
                          : sel ? colors.primary : colors.border,
                        borderWidth: isDropTarget ? 2 : StyleSheet.hairlineWidth,
                        opacity: isDragging ? 0.75 : 1,
                      },
                    ]}
                  >
                    {canEdit ? (
                      <View
                        {...(dragResponder?.panHandlers ?? {})}
                        style={styles.dragHandle}
                        hitSlop={{ top: 8, bottom: 8, left: 4, right: 4 }}
                      >
                        <Feather name="menu" size={18} color={colors.mutedForeground} />
                      </View>
                    ) : null}

                    <TouchableOpacity
                      onPress={() => canEdit && loadItemForEdit(it)}
                      activeOpacity={0.7}
                      style={{ flex: 1 }}
                    >
                      <View style={{ flexDirection: "row", alignItems: "center", gap: 6, marginBottom: 4 }}>
                        <View style={[
                          styles.typeBadge,
                          { backgroundColor: (it.itemType || "malzeme") === "malzeme" ? "#05966922" : "#0ea5e922" }
                        ]}>
                          <Text style={[styles.typeBadgeText, { color: (it.itemType || "malzeme") === "malzeme" ? "#059669" : "#0ea5e9" }]}>
                            {(it.itemType || "malzeme") === "malzeme" ? "Malzeme" : "İşçilik"}
                          </Text>
                        </View>
                        {it.pozCode ? (
                          <Text style={[styles.itemCode, { color: colors.primary }]} numberOfLines={1}>
                            {it.pozCode}{it.pozCategory ? ` · ${it.pozCategory}` : ""}
                          </Text>
                        ) : null}
                      </View>
                      <Text style={[styles.itemDesc, { color: colors.foreground }]} numberOfLines={2}>
                        {it.description}
                      </Text>
                      <Text style={[styles.itemMeta, { color: colors.mutedForeground }]} numberOfLines={1}>
                        {it.quantity} {it.unit}
                        {it.date ? ` · ${it.date}` : ""}
                      </Text>
                    </TouchableOpacity>

                    {canEdit ? (
                      <View style={{ flexDirection: "column", gap: 6, alignItems: "center" }}>
                        <TouchableOpacity
                          onPress={() => copyItem(it.id)}
                          hitSlop={8}
                          style={styles.itemDel}
                        >
                          <Feather name="copy" size={15} color={colors.primary} />
                        </TouchableOpacity>
                        <TouchableOpacity
                          onPress={() => deleteItem(it.id)}
                          hitSlop={8}
                          style={styles.itemDel}
                        >
                          <Feather name="trash-2" size={15} color="#ef4444" />
                        </TouchableOpacity>
                      </View>
                    ) : null}
                  </View>
                );
              })}
            </View>
          </>
        ) : null}

        <View style={styles.itemHeaderRow}>
          <Text style={[styles.label, { color: colors.foreground, marginTop: 8, marginBottom: 0 }]}>
            {editItemId ? "Kalemi Düzenle" : "Yeni Kalem Ekle"}
          </Text>
          {editItemId ? (
            <TouchableOpacity onPress={clearItemForm} hitSlop={8}>
              <Text style={[styles.clearLink, { color: colors.primary }]}>Yeni Ekle</Text>
            </TouchableOpacity>
          ) : null}
        </View>

        <Text style={[styles.label, { color: colors.foreground, marginBottom: 8 }]}>Kalem Tipi</Text>
        <View style={[styles.chips, { marginBottom: 14 }]}>
          {(["malzeme", "iscilik"] as const).map((t) => {
            const sel = form.itemType === t;
            return (
              <TouchableOpacity
                key={t}
                onPress={() => setForm({ ...form, itemType: t })}
                style={[
                  styles.chip,
                  {
                    backgroundColor: sel
                      ? t === "malzeme" ? "#059669" : "#0ea5e9"
                      : colors.muted,
                    flexDirection: "row", alignItems: "center", gap: 6,
                  },
                ]}
              >
                <Feather
                  name={t === "malzeme" ? "package" : "tool"}
                  size={13}
                  color={sel ? "#fff" : colors.foreground}
                />
                <Text style={[styles.chipText, { color: sel ? "#fff" : colors.foreground }]}>
                  {t === "malzeme" ? "Malzeme" : "İşçilik"}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>

        <PozPicker
          label="Poz Tarifi"
          value={form.itemPozCode}
          onChange={(poz) =>
            setForm({
              ...form,
              itemPozCode: poz.code,
              itemPozCategory: poz.category,
              itemDesc: poz.name,
              itemUnit: poz.unit,
            })
          }
        />

        <FormInput
          label="Poz No"
          value={form.itemPozCode}
          onChangeText={(v) => setForm({ ...form, itemPozCode: v })}
          placeholder="Örn: Y.16.050/01"
        />

        <FormInput
          label="İmalat Adı"
          value={form.itemDesc}
          onChangeText={(v) => setForm({ ...form, itemDesc: v })}
          placeholder="Poz seçince otomatik dolar"
        />
        <View style={styles.row2}>
          <View style={{ flex: 1 }}>
            <UnitPicker
              label="Birim"
              value={form.itemUnit}
              onChange={(v) => setForm({ ...form, itemUnit: v })}
            />
          </View>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Metraj"
              value={form.itemMetraj}
              onChangeText={(v) => setForm({ ...form, itemMetraj: v })}
              keyboardType="numeric"
            />
          </View>
        </View>
        <DatePickerInput
          label="Tarih"
          value={form.itemDate}
          onChange={(v) => setForm({ ...form, itemDate: v })}
        />

        {canEdit ? <PrimaryButton label="Kaydet" onPress={save} style={{ marginTop: 8 }} /> : null}
        {canEdit && editId ? (
          <PrimaryButton label="Sil" variant="danger" onPress={remove} style={{ marginTop: 10 }} />
        ) : null}
        {!canEdit ? <PrimaryButton label="Kapat" onPress={() => setVisible(false)} style={{ marginTop: 8 }} /> : null}
      </BottomSheet>

      <BottomSheet
        visible={importVisible}
        onClose={() => setImportVisible(false)}
        title="Keşif İçe Aktar (CSV)"
      >
        <Text style={{ fontSize: 12, color: colors.mutedForeground, lineHeight: 18, marginBottom: 12, fontFamily: "Inter_400Regular" }}>
          Format: proje;baslik;tarih;aciklama;poz_kodu;poz_kategori;kalem_aciklama;birim;metraj;kalem_tarih{"\n"}
          İlk satır başlık. Ayraç olarak ; , veya TAB desteklenir.{"\n"}
          Aynı proje + başlık satırları tek keşifte gruplanır. Mevcut keşfe kalem eklenir, yenisi varsa oluşturulur.{"\n"}
          Proje adı sistemde mevcut olmalı.
        </Text>
        <PrimaryButton
          label={importBusy ? "Yükleniyor..." : "Dosya Seç (CSV)"}
          onPress={pickCsvFile}
          style={{ marginTop: 4 }}
        />
        <Text style={[styles.label, { color: colors.foreground, marginTop: 16 }]}>
          veya CSV içeriğini yapıştırın
        </Text>
        <FormInput
          label=""
          value={importText}
          onChangeText={setImportText}
          placeholder={"proje;baslik;tarih;aciklama;poz_kodu;poz_kategori;kalem_aciklama;birim;metraj;kalem_tarih\nA Şantiye;Bodrum kazı;2026-05-01;;Y.14.002/01;Hafriyat ve Toprak;Makine ile yumuşak toprak kazısı;m³;120;2026-05-01"}
          multiline
          numberOfLines={8}
          style={{ minHeight: 160, paddingTop: 12, fontFamily: "Inter_400Regular" }}
        />
        <PrimaryButton
          label="Yapıştırılanı İçe Aktar"
          onPress={() => applyImport(importText)}
          style={{ marginTop: 8 }}
        />
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
  cardWrap: {
    borderRadius: 12,
    overflow: "hidden",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  cardHeader: {
    flexDirection: "row",
    alignItems: "center",
    padding: 14,
  },
  expandHint: { fontSize: 11, fontFamily: "Inter_400Regular" },
  accordionBody: { borderTopWidth: StyleSheet.hairlineWidth },
  accordionItem: { paddingHorizontal: 14, paddingVertical: 10 },
  accordionPoz: { fontSize: 11, fontFamily: "Inter_700Bold", marginBottom: 2 },
  accordionDesc: { fontSize: 13, fontFamily: "Inter_600SemiBold", marginBottom: 2 },
  accordionQty: { fontSize: 12, fontFamily: "Inter_400Regular" },
  emptyItems: { padding: 14, fontSize: 13, fontFamily: "Inter_400Regular", textAlign: "center" },
  malzemeBox: { marginTop: 8, borderRadius: 8, padding: 10 },
  malzemeBoxTitle: { fontSize: 11, fontFamily: "Inter_500Medium", marginBottom: 6 },
  malzemeBoxHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    paddingBottom: 4,
    marginBottom: 4,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  malzemeColLabel: { fontSize: 10, fontFamily: "Inter_500Medium" },
  malzemeRow: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 3 },
  malzemeName: { fontSize: 12, fontFamily: "Inter_400Regular", flex: 1, marginRight: 8 },
  malzemeQtyText: { fontSize: 12, fontFamily: "Inter_700Bold" },
  accordionEditBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    padding: 12,
    borderTopWidth: StyleSheet.hairlineWidth,
  },
  accordionEditBtnText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
  proj: { fontSize: 12, fontFamily: "Inter_600SemiBold", marginBottom: 4 },
  title: { fontSize: 16, fontFamily: "Inter_700Bold", marginBottom: 6 },
  row: { flexDirection: "row", alignItems: "center", gap: 6, marginTop: 4 },
  row2: { flexDirection: "row", gap: 8 },
  meta: { fontSize: 13, fontFamily: "Inter_400Regular" },
  footer: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginTop: 10,
    paddingTop: 10,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: "#e5e7eb",
  },
  itemCount: { fontSize: 12, fontFamily: "Inter_500Medium" },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  chip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999 },
  chipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
  itemRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    padding: 10,
    borderRadius: 8,
    borderWidth: StyleSheet.hairlineWidth,
    marginBottom: 6,
  },
  typeBadge: { paddingHorizontal: 7, paddingVertical: 2, borderRadius: 6 },
  typeBadgeText: { fontSize: 10, fontFamily: "Inter_700Bold" },
  itemCode: { fontSize: 11, fontFamily: "Inter_700Bold", marginBottom: 0 },
  itemDesc: { fontSize: 13, fontFamily: "Inter_600SemiBold", marginBottom: 2 },
  itemMeta: { fontSize: 11, fontFamily: "Inter_400Regular" },
  itemDel: { padding: 6 },
  itemHeaderRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 8,
    marginTop: 8,
  },
  clearLink: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
  dragHandle: {
    padding: 6,
    justifyContent: "center",
    alignItems: "center",
    cursor: "grab" as any,
  },
});
