import { Feather } from "@expo/vector-icons";
import { useRouter, useLocalSearchParams } from "expo-router";
import React, { useEffect, useMemo, useState } from "react";
import {
  Alert,
  ActivityIndicator,
  FlatList,
  Keyboard,
  KeyboardAvoidingView,
  Modal,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useApp } from "@/context/AppContext";
import { BulkExportModal } from "@/components/BulkExportModal";
import { ExportFormatModal } from "@/components/ExportFormatModal";
import { useBfaCatalog } from "@/hooks/useBfaCatalog";
import { useColors } from "@/hooks/useColors";
import { useRecentViews } from "@/hooks/useRecentViews";
import { AnalizExportFormat, exportAnaliz, exportBulkAnalizler, PdfPaperOrientation, waitForShareSheet, buildAnalizExcelHtml, buildAnalizHtml } from "@/lib/analizExport";
import {
  BfaDiscipline,
  BfaModuleKey,
  getBfaModuleDef,
  getBfaScreenTitle,
  isBfaDiscipline,
  isBfaModuleKey,
} from "@/constants/bfaModules";
import {
  AnalizKalemi,
  IMALAT_POZ_KATEGORILERI,
  OLCU_BIRIMLERI,
  PozAnaliz,
  buildPozKategoriFiltreleri,
  hesaplaAnalizToplam,
  matchesPozAnalizSearch,
} from "@/constants/pozAnalizleri";

// ─── Yardımcı Fonksiyonlar ─────────────────────────────────────

function genKId(): string {
  return "k" + Date.now().toString(36) + Math.random().toString(36).substr(2, 5);
}

function trFmt(n: number): string {
  return n.toLocaleString("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function parseN(s: string): number {
  const v = parseFloat(s.replace(",", "."));
  return Number.isFinite(v) ? v : 0;
}

function tarihFmt(iso: string): string {
  try {
    return new Date(iso).toLocaleDateString("tr-TR");
  } catch {
    return iso;
  }
}

function isResmiAnaliz(analiz: PozAnaliz): boolean {
  return analiz.kaynakTip === "sistem";
}

type Colors = ReturnType<typeof useColors>;

// ─── Ana Bileşen ───────────────────────────────────────────────

export default function ImalatPozlariScreen() {
  const colors = useColors();
  const router = useRouter();
  const params = useLocalSearchParams<{ id?: string; q?: string; modul?: string; cat?: string; new?: string }>();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;

  const { addPozAnaliz, updatePozAnaliz, deletePozAnaliz, clonePozAnaliz, isFavorite, toggleFavorite } =
    useApp();
  const { recordView } = useRecentViews();

  const modulParam = params.modul ? String(params.modul) : "insaat";
  const modul: BfaModuleKey = isBfaModuleKey(modulParam) ? modulParam : "insaat";
  const moduleDef = getBfaModuleDef(modul);
  const canCreateAnaliz = isBfaDiscipline(modul);

  const { getModuleAnalizleri, loading: catalogLoading, error: catalogError } =
    useBfaCatalog();

  const modulAnalizleri = useMemo(
    () => getModuleAnalizleri(modul),
    [getModuleAnalizleri, modul],
  );

  const [search, setSearch] = useState(() => (params.q ? String(params.q) : ""));
  const [catFilter, setCatFilter] = useState<string | null>(() =>
    params.cat ? String(params.cat) : null,
  );
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [isEditing, setIsEditing] = useState(false);
  const [editDraft, setEditDraft] = useState<PozAnaliz | null>(null);

  const [cloneVisible, setCloneVisible] = useState(false);
  const [cloneAd, setCloneAd] = useState("");
  const [exportVisible, setExportVisible] = useState(false);
  const [bulkExportVisible, setBulkExportVisible] = useState(false);
  const [selectMode, setSelectMode] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(() => new Set());
  const [metrajMiktar, setMetrajMiktar] = useState("1");

  const [catPickerOpen, setCatPickerOpen] = useState(false);

  const [newVisible, setNewVisible] = useState(() => String(params.new) === "1");
  const [newForm, setNewForm] = useState({
    pozNo: "",
    analizAdi: "",
    olcuBirimi: "m²",
    kategori: IMALAT_POZ_KATEGORILERI[0] as string,
  });

  const selected = useMemo(
    () => modulAnalizleri.find((a) => a.id === selectedId) ?? null,
    [modulAnalizleri, selectedId],
  );

  const categories = useMemo(
    () => ["Tümü", ...buildPozKategoriFiltreleri(modulAnalizleri)],
    [modulAnalizleri],
  );

  const kategoriSayilari = useMemo(() => {
    const counts = new Map<string, number>();
    for (const a of modulAnalizleri) {
      const k = (a.kategori || "").trim();
      if (!k) continue;
      counts.set(k, (counts.get(k) ?? 0) + 1);
    }
    return counts;
  }, [modulAnalizleri]);

  const filtered = useMemo(() => {
    return modulAnalizleri
      .filter((a) => {
        if (!catFilter) return true;
        return (a.kategori || "").trim() === catFilter;
      })
      .filter((a) => matchesPozAnalizSearch(a, search))
      .sort((a, b) => a.pozNo.localeCompare(b.pozNo, "tr"));
  }, [modulAnalizleri, catFilter, search]);

  const catFilterLabel = useMemo(() => {
    if (!catFilter) return `Tümü (${modulAnalizleri.length})`;
    return `${catFilter} (${kategoriSayilari.get(catFilter) ?? 0})`;
  }, [catFilter, modulAnalizleri.length, kategoriSayilari]);

  const screenTitle = useMemo(
    () => getBfaScreenTitle(modul, catFilter),
    [modul, catFilter],
  );

  function selectCategory(cat: string) {
    setCatFilter(cat === "Tümü" ? null : cat);
    setCatPickerOpen(false);
  }

  function openDetail(id: string) {
    setSelectedId(id);
    setIsEditing(false);
    setEditDraft(null);
    void recordView(id);
  }

  useEffect(() => {
    setMetrajMiktar("1");
  }, [selectedId]);

  useEffect(() => {
    if (params.q) {
      setSearch(String(params.q));
    }
  }, [params.q]);

  useEffect(() => {
    if (params.cat) {
      setCatFilter(String(params.cat));
    }
  }, [params.cat]);

  useEffect(() => {
    if (!params.id || catalogLoading) return;
    const id = String(params.id);
    if (modulAnalizleri.some((a) => a.id === id)) {
      openDetail(id);
    }
  }, [params.id, catalogLoading, modulAnalizleri]);

  function goBack() {
    if (isEditing) {
      Alert.alert("Kaydedilmedi", "Değişiklikler kaydedilmedi. Çıkmak istiyor musunuz?", [
        { text: "İptal", style: "cancel" },
        {
          text: "Çık",
          onPress: () => {
            setIsEditing(false);
            setEditDraft(null);
          },
        },
      ]);
      return;
    }
    setSelectedId(null);
    setEditDraft(null);
  }

  function startEdit() {
    if (!selected) return;
    if (isResmiAnaliz(selected)) {
      Alert.alert(
        "Resmi Analiz",
        "Resmi analizler düzenlenemez. Kopyalayarak özelleştirebilirsiniz.",
        [
          { text: "İptal", style: "cancel" },
          { text: "Kopyala ve Düzenle", onPress: handleCopyAndEdit },
        ],
      );
      return;
    }
    setEditDraft(JSON.parse(JSON.stringify(selected)));
    setIsEditing(true);
  }

  function handleCopyAndEdit() {
    if (!selected || !selectedId) return;
    const kopya = clonePozAnaliz(selectedId, "Kopya — " + selected.analizAdi, selected);
    setCloneVisible(false);
    setSelectedId(kopya.id);
    setEditDraft(JSON.parse(JSON.stringify(kopya)));
    setIsEditing(true);
  }

  function saveEdit() {
    if (!editDraft) return;
    const totals = hesaplaAnalizToplam(editDraft);
    updatePozAnaliz(editDraft.id, { ...editDraft, ...totals });
    setIsEditing(false);
    setEditDraft(null);
  }

  function cancelEdit() {
    setIsEditing(false);
    setEditDraft(null);
  }

  function updateDraftField(field: keyof PozAnaliz, value: any) {
    setEditDraft((prev) => (prev ? { ...prev, [field]: value } : prev));
  }

  function updateKalemField(idx: number, field: keyof AnalizKalemi, raw: string) {
    setEditDraft((prev) => {
      if (!prev) return prev;
      const kalemler = [...prev.kalemler];
      const k: any = { ...kalemler[idx] };
      if (field === "miktar" || field === "birimFiyati") {
        k[field] = parseN(raw);
        k.tutar =
          (field === "miktar" ? parseN(raw) : k.miktar) *
          (field === "birimFiyati" ? parseN(raw) : k.birimFiyati);
        k.tutar = Math.round(k.tutar * 100) / 100;
      } else {
        k[field] = raw;
      }
      kalemler[idx] = k;
      return { ...prev, kalemler };
    });
  }

  function addKalem(tip: "malzeme" | "iscilik" | "ekipman") {
    const yeni: AnalizKalemi = {
      id: genKId(),
      tip,
      pozNo: "",
      tanim: "",
      olcuBirimi: "Sa",
      miktar: 0,
      birimFiyati: 0,
      tutar: 0,
    };
    setEditDraft((prev) =>
      prev ? { ...prev, kalemler: [...prev.kalemler, yeni] } : prev
    );
  }

  function removeKalem(idx: number) {
    setEditDraft((prev) => {
      if (!prev) return prev;
      return { ...prev, kalemler: prev.kalemler.filter((_, i) => i !== idx) };
    });
  }

  function handleDelete() {
    if (!selected) return;
    if (selected.kaynakTip === "sistem") {
      Alert.alert(
        "Silinemez",
        "Sistem kayıtları silinemez. Kopyalayarak özelleştirebilirsiniz."
      );
      return;
    }
    Alert.alert(
      "Analizi Sil",
      `"${selected.analizAdi}" silinsin mi?`,
      [
        { text: "İptal", style: "cancel" },
        {
          text: "Sil",
          style: "destructive",
          onPress: () => {
            deletePozAnaliz(selected.id);
            setSelectedId(null);
          },
        },
      ]
    );
  }

  function handleClone() {
    if (!selected) return;
    setCloneAd("Kopya — " + selected.analizAdi);
    setCloneVisible(true);
  }

  function doClone() {
    if (!selectedId || !cloneAd.trim()) return;
    const kopya = clonePozAnaliz(selectedId, cloneAd.trim(), selected ?? undefined);
    setCloneVisible(false);
    setSelectedId(kopya.id);
  }

  async function handleExportFormat(format: AnalizExportFormat, pdfOrientation?: PdfPaperOrientation) {
    const analiz = isEditing && editDraft ? editDraft : selected;
    if (!analiz) return;
    setExportVisible(false);
    await waitForShareSheet();
    await exportAnaliz(analiz, format, { pdfOrientation });
  }

  const selectedAnalizler = useMemo(
    () => modulAnalizleri.filter((a) => selectedIds.has(a.id)),
    [modulAnalizleri, selectedIds],
  );

  function toggleSelectMode() {
    setSelectMode((prev) => {
      if (prev) setSelectedIds(new Set());
      return !prev;
    });
  }

  function toggleSelected(id: string) {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  function handleCompareSelected() {
    if (selectedIds.size < 2) {
      Alert.alert("Karşılaştırma", "En az 2 analiz seçin.");
      return;
    }
    router.push({
      pathname: "/analiz-karsilastir",
      params: { ids: [...selectedIds].join(",") },
    } as any);
  }

  async function handleBulkExportFormat(format: AnalizExportFormat, pdfOrientation?: PdfPaperOrientation) {
    if (!selectedAnalizler.length) return;
    setBulkExportVisible(false);
    setSelectMode(false);
    setSelectedIds(new Set());
    await waitForShareSheet();
    await exportBulkAnalizler(selectedAnalizler, format, { pdfOrientation });
  }

  const displayAnaliz = isEditing && editDraft ? editDraft : selected;

  // ── Detay görünümü ──
  if (selectedId && displayAnaliz) {
    const totals = hesaplaAnalizToplam(displayAnaliz);
    const resmi = isResmiAnaliz(displayAnaliz);
    const metrajQty = parseN(metrajMiktar);
    const metrajToplam = Math.round(metrajQty * totals.birimFiyati * 100) / 100;

    return (
      <View style={{ flex: 1, backgroundColor: colors.background }}>
        {/* Header */}
        <View
          style={[
            st.header,
            { backgroundColor: colors.secondary, paddingTop: topPad + 12 },
          ]}
        >
          <TouchableOpacity onPress={goBack} style={st.backBtn}>
            <Feather name="arrow-left" size={22} color={colors.secondaryForeground} />
          </TouchableOpacity>
          <Text
            style={[st.headerTitle, { color: colors.secondaryForeground }]}
            numberOfLines={1}
          >
            Analiz Detayı
          </Text>
          {isEditing ? (
            <View style={{ flexDirection: "row", gap: 8 }}>
              <TouchableOpacity
                onPress={cancelEdit}
                style={[st.hBtn, { backgroundColor: colors.secondaryForeground + "22" }]}
              >
                <Text style={{ color: colors.secondaryForeground, fontSize: 13 }}>İptal</Text>
              </TouchableOpacity>
              <TouchableOpacity
                onPress={saveEdit}
                style={[st.hBtn, { backgroundColor: colors.primary }]}
              >
                <Text style={{ color: colors.primaryForeground, fontSize: 13, fontWeight: "700" }}>
                  Kaydet
                </Text>
              </TouchableOpacity>
            </View>
          ) : (
            <View style={{ width: 40 }} />
          )}
        </View>

        <ScrollView
          contentContainerStyle={{ paddingBottom: insets.bottom + 100 }}
          keyboardShouldPersistTaps="handled"
        >
          {/* Üst bilgi kartı */}
          <View
            style={[
              st.infoCard,
              { backgroundColor: colors.card, borderColor: colors.border },
            ]}
          >
            {resmi && (
              <View style={[st.resmiBadge, { backgroundColor: "#2563eb18", borderColor: "#2563eb44" }]}>
                <Feather name="shield" size={13} color="#2563eb" />
                <Text style={st.resmiBadgeText}>Resmi Analiz — Salt Okunur</Text>
              </View>
            )}
            <View style={st.infoRow}>
              <Text style={[st.infoLabel, { color: colors.mutedForeground }]}>Poz No</Text>
              {isEditing ? (
                <TextInput
                  style={[st.infoInput, { color: colors.foreground, borderColor: colors.border }]}
                  value={displayAnaliz.pozNo}
                  onChangeText={(v) => updateDraftField("pozNo", v)}
                />
              ) : (
                <Text style={[st.infoValue, { color: colors.primary }]}>
                  {displayAnaliz.pozNo}
                </Text>
              )}
            </View>
            <View style={st.infoRow}>
              <Text style={[st.infoLabel, { color: colors.mutedForeground }]}>Analiz Adı</Text>
              {isEditing ? (
                <TextInput
                  style={[
                    st.infoInput,
                    { color: colors.foreground, borderColor: colors.border, flex: 1 },
                  ]}
                  value={displayAnaliz.analizAdi}
                  onChangeText={(v) => updateDraftField("analizAdi", v)}
                  multiline
                />
              ) : (
                <Text style={[st.infoValue, { color: colors.foreground, flex: 1 }]}>
                  {displayAnaliz.analizAdi}
                </Text>
              )}
            </View>
            <View style={st.infoRow}>
              <Text style={[st.infoLabel, { color: colors.mutedForeground }]}>Ölçü Birimi</Text>
              {isEditing ? (
                <TextInput
                  style={[st.infoInput, { color: colors.foreground, borderColor: colors.border, width: 80 }]}
                  value={displayAnaliz.olcuBirimi}
                  onChangeText={(v) => updateDraftField("olcuBirimi", v)}
                />
              ) : (
                <Text style={[st.infoValue, { color: colors.foreground }]}>
                  {displayAnaliz.olcuBirimi}
                </Text>
              )}
            </View>
            <View style={[st.infoRow, { borderBottomWidth: 0 }]}>
              <Text style={[st.infoLabel, { color: colors.mutedForeground }]}>Son Güncelleme</Text>
              <Text style={[st.infoValue, { color: colors.mutedForeground }]}>
                {tarihFmt(displayAnaliz.guncellemeTarihi)}
              </Text>
            </View>
          </View>

          {!isEditing && (
            <View
              style={[
                st.metrajCard,
                { backgroundColor: colors.card, borderColor: colors.border },
              ]}
            >
              <View style={st.metrajHeader}>
                <Feather name="pie-chart" size={16} color={colors.primary} />
                <Text style={[st.metrajTitle, { color: colors.foreground }]}>Metraj Hesaplama</Text>
              </View>
              <View style={st.metrajRow}>
                <Text style={[st.metrajLabel, { color: colors.mutedForeground }]}>Miktar</Text>
                <TextInput
                  style={[
                    st.metrajInput,
                    { color: colors.foreground, borderColor: colors.border, backgroundColor: colors.background },
                  ]}
                  value={metrajMiktar}
                  onChangeText={setMetrajMiktar}
                  keyboardType="decimal-pad"
                  placeholder="0"
                  placeholderTextColor={colors.mutedForeground}
                />
                <Text style={[st.metrajUnit, { color: colors.foreground }]}>
                  {displayAnaliz.olcuBirimi}
                </Text>
              </View>
              <View style={st.metrajSummary}>
                <Text style={[st.metrajLine, { color: colors.mutedForeground }]}>
                  Birim fiyat: {trFmt(totals.birimFiyati)} TL / {displayAnaliz.olcuBirimi}
                </Text>
                <Text style={[st.metrajTotal, { color: colors.primary }]}>
                  Toplam: {trFmt(metrajToplam)} TL
                </Text>
              </View>
            </View>
          )}

          {/* Analiz Tablosu */}
          <View style={{ marginHorizontal: 12, marginTop: 12 }}>
            <ScrollView horizontal showsHorizontalScrollIndicator>
              <View>
                {/* Tablo başlığı */}
                <View
                  style={[
                    st.tRow,
                    { backgroundColor: colors.card, borderColor: colors.border },
                  ]}
                >
                  {["Poz No", "Tanımı", "Ölçü\nBirimi", "Miktarı", "Birim Fiyatı\n(TL)", "Tutarı\n(TL)"].map(
                    (h, i) => (
                      <Text
                        key={i}
                        style={[
                          st.th,
                          { color: colors.foreground, borderColor: colors.border },
                          colWidth(i),
                        ]}
                      >
                        {h}
                      </Text>
                    )
                  )}
                  {isEditing && <View style={{ width: 32 }} />}
                </View>

                {/* Malzeme / İşçilik / Ekipman bölümleri */}
                {(["malzeme", "iscilik", "ekipman"] as const).map((tip) => {
                  const tipAd =
                    tip === "malzeme" ? "Malzeme" : tip === "iscilik" ? "İşçilik" : "Ekipman";
                  const rows = displayAnaliz.kalemler
                    .map((k, i) => ({ k, i }))
                    .filter(({ k }) => k.tip === tip);

                  if (!rows.length && !isEditing) return null;

                  return (
                    <View key={tip}>
                      {/* Grup başlığı */}
                      <View
                        style={[
                          st.groupRow,
                          { backgroundColor: colors.card + "CC", borderColor: colors.border },
                        ]}
                      >
                        <Text
                          style={[
                            st.groupText,
                            { color: colors.foreground, flex: 1 },
                          ]}
                        >
                          {tipAd}
                        </Text>
                        {isEditing && (
                          <TouchableOpacity onPress={() => addKalem(tip)} style={st.addRowBtn}>
                            <Feather name="plus" size={14} color={colors.primary} />
                            <Text style={{ color: colors.primary, fontSize: 12, marginLeft: 2 }}>
                              Satır Ekle
                            </Text>
                          </TouchableOpacity>
                        )}
                      </View>

                      {/* Kalem satırları */}
                      {rows.map(({ k, i }) => (
                        <View
                          key={k.id}
                          style={[
                            st.tRow,
                            { borderColor: colors.border, backgroundColor: colors.background },
                          ]}
                        >
                          <KalemCell
                            val={k.pozNo}
                            width={COL[0]}
                            editable={isEditing}
                            onEdit={(v) => updateKalemField(i, "pozNo", v)}
                            colors={colors}
                            mono
                          />
                          <KalemCell
                            val={k.tanim}
                            width={COL[1]}
                            editable={isEditing}
                            onEdit={(v) => updateKalemField(i, "tanim", v)}
                            colors={colors}
                            multiline
                          />
                          <KalemCell
                            val={k.olcuBirimi}
                            width={COL[2]}
                            editable={isEditing}
                            onEdit={(v) => updateKalemField(i, "olcuBirimi", v)}
                            colors={colors}
                            center
                          />
                          <KalemCell
                            val={isEditing ? String(k.miktar) : trFmt(k.miktar)}
                            width={COL[3]}
                            editable={isEditing}
                            onEdit={(v) => updateKalemField(i, "miktar", v)}
                            colors={colors}
                            right
                            numeric
                          />
                          <KalemCell
                            val={isEditing ? String(k.birimFiyati) : trFmt(k.birimFiyati)}
                            width={COL[4]}
                            editable={isEditing}
                            onEdit={(v) => updateKalemField(i, "birimFiyati", v)}
                            colors={colors}
                            right
                            numeric
                          />
                          <View
                            style={[
                              st.td,
                              { width: COL[5], borderColor: colors.border, justifyContent: "flex-end" },
                            ]}
                          >
                            <Text
                              style={[
                                st.tdText,
                                { color: colors.foreground, textAlign: "right" },
                              ]}
                            >
                              {trFmt(k.tutar)}
                            </Text>
                          </View>
                          {isEditing && (
                            <TouchableOpacity
                              onPress={() => removeKalem(i)}
                              style={{ width: 32, alignItems: "center", justifyContent: "center" }}
                            >
                              <Feather name="trash-2" size={14} color="#e74c3c" />
                            </TouchableOpacity>
                          )}
                        </View>
                      ))}
                    </View>
                  );
                })}

                {/* Özet satırları */}
                <SummaryRow
                  label="Malzeme + İşçilik Tutarı"
                  value={trFmt(totals.malzemeIscilikToplami) + " TL"}
                  colors={colors}
                  totalColWidth={COL[0] + COL[1] + COL[2] + COL[3] + COL[4]}
                  valWidth={COL[5]}
                  isEditing={isEditing}
                />
                <SummaryRow
                  label={`%${displayAnaliz.yukleniciKarOrani} Yüklenici Karı ve Genel Giderler`}
                  value={trFmt(totals.yukleniciKarTutari) + " TL"}
                  colors={colors}
                  totalColWidth={COL[0] + COL[1] + COL[2] + COL[3] + COL[4]}
                  valWidth={COL[5]}
                  isEditing={isEditing}
                  editNode={
                    isEditing ? (
                      <View style={{ flexDirection: "row", alignItems: "center" }}>
                        <Text style={{ color: colors.mutedForeground, fontSize: 12 }}>Kar %</Text>
                        <TextInput
                          style={[
                            st.karInput,
                            { color: colors.foreground, borderColor: colors.border },
                          ]}
                          value={String(displayAnaliz.yukleniciKarOrani)}
                          onChangeText={(v) => updateDraftField("yukleniciKarOrani", parseN(v))}
                          keyboardType="numeric"
                        />
                        <Text style={{ color: colors.mutedForeground, fontSize: 12 }}>
                          = {trFmt(totals.yukleniciKarTutari)} TL
                        </Text>
                      </View>
                    ) : undefined
                  }
                />
                <SummaryRow
                  label={`1 ${displayAnaliz.olcuBirimi} Fiyatı`}
                  value={trFmt(totals.birimFiyati) + " TL"}
                  colors={colors}
                  totalColWidth={COL[0] + COL[1] + COL[2] + COL[3] + COL[4]}
                  valWidth={COL[5]}
                  bold
                  isEditing={isEditing}
                />
              </View>
            </ScrollView>
          </View>

          {/* Poz Tarifi, Yapım Şartları, Ölçüsü */}
          <MetinBolumu
            baslik="Poz Tarifi"
            deger={displayAnaliz.pozTarifi}
            editable={isEditing}
            onChange={(v) => updateDraftField("pozTarifi", v)}
            colors={colors}
          />
          <MetinBolumu
            baslik="Yapım Şartları"
            deger={displayAnaliz.yapimSartlari}
            editable={isEditing}
            onChange={(v) => updateDraftField("yapimSartlari", v)}
            colors={colors}
          />
          <MetinBolumu
            baslik="Ölçüsü"
            deger={displayAnaliz.olcusu}
            editable={isEditing}
            onChange={(v) => updateDraftField("olcusu", v)}
            colors={colors}
          />
        </ScrollView>

        {/* Alt aksiyon şeridi */}
        <View
          style={[
            st.bottomBar,
            {
              backgroundColor: colors.card,
              borderColor: colors.border,
              paddingBottom: insets.bottom + 8,
            },
          ]}
        >
          {!isEditing && (
            <ActionBtn
              icon="star"
              label={isFavorite(displayAnaliz.id) ? "Favoriden Çıkar" : "Favorile"}
              onPress={() => toggleFavorite(displayAnaliz.id)}
              colors={colors}
            />
          )}
          {!isEditing && resmi ? (
            <ActionBtn
              icon="copy"
              label="Kopyala ve Düzenle"
              onPress={handleCopyAndEdit}
              colors={colors}
            />
          ) : !isEditing ? (
            <ActionBtn icon="edit-2" label="Düzenle" onPress={startEdit} colors={colors} />
          ) : null}
          {!resmi && (
            <ActionBtn icon="copy" label="Kopyala" onPress={handleClone} colors={colors} />
          )}
          <ActionBtn
            icon="share"
            label="Dışa Aktar"
            onPress={() => setExportVisible(true)}
            colors={colors}
          />
          {!isEditing && (
            <ActionBtn
              icon="trash-2"
              label="Sil"
              onPress={handleDelete}
              colors={colors}
              danger
              disabled={resmi}
            />
          )}
        </View>

        <ExportFormatModal
          visible={exportVisible}
          onClose={() => setExportVisible(false)}
          analiz={displayAnaliz}
          onExport={handleExportFormat}
        />

        {/* Kopyalama modalı */}
        <CloneModal
          visible={cloneVisible}
          ad={cloneAd}
          onChangeAd={setCloneAd}
          onConfirm={doClone}
          onCancel={() => setCloneVisible(false)}
          colors={colors}
        />
      </View>
    );
  }

  // ── Liste görünümü ──
  if (catalogLoading) {
    return (
      <View style={{ flex: 1, backgroundColor: colors.background, justifyContent: "center", alignItems: "center" }}>
        <ActivityIndicator size="large" color={colors.primary} />
        <Text style={{ color: colors.mutedForeground, marginTop: 16, fontSize: 14 }}>
          Analiz tabloları yükleniyor…
        </Text>
      </View>
    );
  }

  if (catalogError) {
    return (
      <View style={{ flex: 1, backgroundColor: colors.background, justifyContent: "center", alignItems: "center", padding: 24 }}>
        <Feather name="alert-circle" size={40} color={colors.destructive} />
        <Text style={{ color: colors.foreground, marginTop: 16, fontSize: 16, textAlign: "center" }}>
          {catalogError}
        </Text>
      </View>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      {/* Header */}
      <View
        style={[st.header, { backgroundColor: colors.secondary, paddingTop: topPad + 12 }]}
      >
        <TouchableOpacity onPress={() => router.back()} style={st.backBtn}>
          <Feather name="arrow-left" size={22} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <View style={{ flex: 1, alignItems: "center" }}>
          <Text style={[st.headerTitle, { color: colors.secondaryForeground }]}>
            {screenTitle}
          </Text>
        </View>
        <TouchableOpacity onPress={toggleSelectMode} style={st.backBtn}>
          <Feather
            name={selectMode ? "x" : "check-square"}
            size={20}
            color={colors.secondaryForeground}
          />
        </TouchableOpacity>
      </View>

      {/* Seçim modu bilgi şeridi */}
      {selectMode && (
        <View style={[st.selectBar, { backgroundColor: colors.primary + "14", borderColor: colors.primary + "33" }]}>
          <Text style={[st.selectBarText, { color: colors.primary }]}>
            {selectedIds.size} analiz seçildi
          </Text>
          <TouchableOpacity onPress={toggleSelectMode}>
            <Text style={[st.selectBarAction, { color: colors.mutedForeground }]}>İptal</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* Arama */}
      <View
        style={[
          st.searchWrap,
          { backgroundColor: colors.card, borderColor: colors.border },
        ]}
      >
        <Feather name="search" size={20} color={colors.mutedForeground} />
        <TextInput
          style={[st.searchInput, { color: colors.foreground }]}
          placeholder="Poz No veya analiz adı ara..."
          placeholderTextColor={colors.mutedForeground}
          value={search}
          onChangeText={setSearch}
        />
        {search.length > 0 && (
          <TouchableOpacity onPress={() => setSearch("")}>
            <Feather name="x" size={20} color={colors.mutedForeground} />
          </TouchableOpacity>
        )}
      </View>

      {/* Kategori filtresi — açılır liste */}
      <View style={st.filterRow}>
        <Text style={[st.filterLabel, { color: colors.mutedForeground }]}>Kategori</Text>
        <TouchableOpacity
          style={[st.filterSelect, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={() => setCatPickerOpen(true)}
          activeOpacity={0.85}
        >
          <Text style={[st.filterSelectText, { color: colors.foreground }]} numberOfLines={1}>
            {catFilterLabel}
          </Text>
          <Feather name="chevron-down" size={18} color={colors.mutedForeground} />
        </TouchableOpacity>
      </View>

      <KategoriPickerModal
        visible={catPickerOpen}
        categories={categories}
        kategoriSayilari={kategoriSayilari}
        totalCount={modulAnalizleri.length}
        selected={catFilter}
        onSelect={selectCategory}
        onClose={() => setCatPickerOpen(false)}
        colors={colors}
      />

      {/* Tablo başlığı */}
      <View
        style={[
          st.listHeader,
          { backgroundColor: colors.card, borderColor: colors.border },
        ]}
      >
        {selectMode && <Text style={[st.listTh, { width: 32, color: colors.mutedForeground }]}> </Text>}
        <Text style={[st.listTh, { width: 36, color: colors.mutedForeground }]}>#</Text>
        <Text style={[st.listTh, { width: 104, color: colors.mutedForeground }]}>Poz No</Text>
        <Text style={[st.listTh, { flex: 1, color: colors.mutedForeground }]}>Analizin Adı</Text>
        <Text style={[st.listTh, { width: 44, textAlign: "right", color: colors.mutedForeground }]}>
          Birim
        </Text>
      </View>

      {/* Liste */}
      <FlatList
        data={filtered}
        keyExtractor={(item) => item.id}
        extraData={`${catFilter ?? ""}|${search}|${filtered.length}|${selectMode}|${selectedIds.size}`}
        initialNumToRender={20}
        windowSize={10}
        keyboardShouldPersistTaps="handled"
        contentContainerStyle={{ paddingBottom: selectMode ? insets.bottom + 80 : 0 }}
        renderItem={({ item, index }) => {
          const checked = selectedIds.has(item.id);
          return (
            <TouchableOpacity
              style={[
                st.listRow,
                {
                  borderColor: colors.border,
                  backgroundColor: checked
                    ? colors.primary + "12"
                    : index % 2 === 0
                      ? colors.background
                      : colors.card + "66",
                },
              ]}
              onPress={() => {
                if (selectMode) toggleSelected(item.id);
                else openDetail(item.id);
              }}
              onLongPress={() => {
                if (!selectMode) {
                  setSelectMode(true);
                  setSelectedIds(new Set([item.id]));
                }
              }}
              activeOpacity={0.75}
            >
              {selectMode && (
                <View style={st.checkCell}>
                  <Feather
                    name={checked ? "check-square" : "square"}
                    size={18}
                    color={checked ? colors.primary : colors.mutedForeground}
                  />
                </View>
              )}
              <Text style={[st.tdNo, { color: colors.mutedForeground }]}>{index + 1}</Text>
              <Text style={[st.tdPoz, { color: colors.primary }]}>{item.pozNo}</Text>
              <Text style={[st.tdAd, { color: colors.foreground }]} numberOfLines={2}>
                {item.analizAdi}
              </Text>
              <Text style={[st.tdBirim, { color: colors.mutedForeground }]}>{item.olcuBirimi}</Text>
            </TouchableOpacity>
          );
        }}
        ListEmptyComponent={
          <View style={{ alignItems: "center", paddingTop: 60 }}>
            <Feather name="inbox" size={40} color={colors.mutedForeground} />
            <Text style={{ color: colors.mutedForeground, marginTop: 12, fontSize: 14, textAlign: "center", paddingHorizontal: 24 }}>
              {modulAnalizleri.length === 0 && moduleDef.emptyHint
                ? moduleDef.emptyHint
                : "Analiz bulunamadı"}
            </Text>
          </View>
        }
      />

      {selectMode && (
        <View
          style={[
            st.bulkBar,
            {
              backgroundColor: colors.card,
              borderColor: colors.border,
              paddingBottom: insets.bottom + 8,
            },
          ]}
        >
          <TouchableOpacity
            style={[st.bulkBtn, { opacity: selectedIds.size >= 2 ? 1 : 0.45 }]}
            onPress={handleCompareSelected}
            disabled={selectedIds.size < 2}
          >
            <Feather name="layers" size={18} color={colors.foreground} />
            <Text style={[st.bulkBtnLabel, { color: colors.foreground }]}>Karşılaştır</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[st.bulkBtn, { opacity: selectedIds.size >= 1 ? 1 : 0.45 }]}
            onPress={() => setBulkExportVisible(true)}
            disabled={selectedIds.size < 1}
          >
            <Feather name="download" size={18} color={colors.primary} />
            <Text style={[st.bulkBtnLabel, { color: colors.primary }]}>Dışa Aktar</Text>
          </TouchableOpacity>
        </View>
      )}

      <BulkExportModal
        visible={bulkExportVisible}
        count={selectedIds.size}
        onClose={() => setBulkExportVisible(false)}
        onExport={handleBulkExportFormat}
        subtitle={`${selectedIds.size} analiz ZIP olarak indirilecek`}
        previewCaption="ZIP önizlemesi (ilk analiz)"
        webPdfVariant="bulk"
        getPreviewHtml={(format, orientation) => {
          const first = selectedAnalizler[0];
          if (!first) return "";
          return format === "excel"
            ? buildAnalizExcelHtml(first)
            : buildAnalizHtml(first, orientation);
        }}
      />

      {/* Yetkili roller: yeni analiz ekle FAB */}
      {canCreateAnaliz && !selectMode && (
      <TouchableOpacity
        style={[
          st.fab,
          { backgroundColor: colors.primary, bottom: insets.bottom + 16 },
        ]}
        onPress={() => setNewVisible(true)}
      >
        <Feather name="plus" size={24} color={colors.primaryForeground} />
      </TouchableOpacity>
      )}

      {canCreateAnaliz && (
      <NewAnalizModal
        visible={newVisible}
        form={newForm}
        onChange={(f) => setNewForm((prev) => ({ ...prev, ...f }))}
        onConfirm={() => {
          if (!newForm.analizAdi.trim()) {
            Alert.alert("Hata", "Analiz adı zorunlu");
            return;
          }
          const id = addPozAnaliz({
            pozNo: newForm.pozNo.trim() || "ÖZEL",
            analizAdi: newForm.analizAdi.trim(),
            olcuBirimi: newForm.olcuBirimi,
            kategori: newForm.kategori,
            kalemler: [],
            pozTarifi: "",
            yapimSartlari: "",
            olcusu: "",
            malzemeIscilikToplami: 0,
            yukleniciKarOrani: 25,
            yukleniciKarTutari: 0,
            birimFiyati: 0,
            kaynakTip: "kullanici",
            discipline: modul as BfaDiscipline,
          });
          setNewVisible(false);
          setNewForm({
            pozNo: "",
            analizAdi: "",
            olcuBirimi: "m²",
            kategori: IMALAT_POZ_KATEGORILERI[0] as string,
          });
          openDetail(id);
        }}
        onCancel={() => setNewVisible(false)}
        colors={colors}
      />
      )}
    </View>
  );
}

// ─── Sütun Genişlikleri ────────────────────────────────────────

const COL = [100, 200, 68, 72, 96, 96] as const;

function colWidth(i: number): { width: number } {
  return { width: COL[i] };
}

// ─── KalemCell ────────────────────────────────────────────────

interface KalemCellProps {
  val: string;
  width: number;
  editable: boolean;
  onEdit: (v: string) => void;
  colors: Colors;
  mono?: boolean;
  right?: boolean;
  center?: boolean;
  multiline?: boolean;
  numeric?: boolean;
}

function KalemCell({ val, width, editable, onEdit, colors, mono, right, center, multiline, numeric }: KalemCellProps) {
  const align = right ? "right" : center ? "center" : "left";
  return (
    <View style={[st.td, { width, borderColor: colors.border }]}>
      {editable ? (
        <TextInput
          style={[
            st.cellInput,
            { color: colors.foreground, textAlign: align, fontFamily: mono ? "monospace" : undefined },
          ]}
          value={val}
          onChangeText={onEdit}
          multiline={multiline}
          keyboardType={numeric ? "numeric" : "default"}
        />
      ) : (
        <Text
          style={[
            st.tdText,
            {
              color: colors.foreground,
              textAlign: align,
              fontFamily: mono ? "monospace" : undefined,
            },
          ]}
          numberOfLines={multiline ? 3 : 1}
        >
          {val}
        </Text>
      )}
    </View>
  );
}

// ─── SummaryRow ───────────────────────────────────────────────

function SummaryRow({
  label,
  value,
  colors,
  totalColWidth,
  valWidth,
  bold,
  isEditing,
  editNode,
}: {
  label: string;
  value: string;
  colors: Colors;
  totalColWidth: number;
  valWidth: number;
  bold?: boolean;
  isEditing?: boolean;
  editNode?: React.ReactNode;
}) {
  return (
    <View
      style={[
        st.tRow,
        { borderColor: colors.border, backgroundColor: colors.card + "99" },
      ]}
    >
      <View style={{ width: totalColWidth, paddingHorizontal: 6, paddingVertical: 4 }}>
        {isEditing && editNode ? (
          editNode
        ) : (
          <Text
            style={[
              st.sumLabel,
              { color: colors.foreground, fontWeight: bold ? "700" : "400" },
            ]}
          >
            {label}
          </Text>
        )}
      </View>
      <View style={[st.td, { width: valWidth, borderColor: colors.border, justifyContent: "flex-end" }]}>
        <Text
          style={[
            st.tdText,
            { color: colors.foreground, textAlign: "right", fontWeight: bold ? "700" : "600" },
          ]}
        >
          {value}
        </Text>
      </View>
    </View>
  );
}

// ─── MetinBolumu ──────────────────────────────────────────────

function MetinBolumu({
  baslik,
  deger,
  editable,
  onChange,
  colors,
}: {
  baslik: string;
  deger: string;
  editable: boolean;
  onChange: (v: string) => void;
  colors: Colors;
}) {
  if (!editable && !deger) return null;
  return (
    <View
      style={[
        st.metinCard,
        { backgroundColor: colors.card, borderColor: colors.border },
      ]}
    >
      <Text style={[st.metinBaslik, { color: colors.mutedForeground }]}>{baslik}</Text>
      {editable ? (
        <TextInput
          style={[st.metinInput, { color: colors.foreground, borderColor: colors.border }]}
          value={deger}
          onChangeText={onChange}
          multiline
          placeholder={`${baslik} girin...`}
          placeholderTextColor={colors.mutedForeground}
        />
      ) : (
        <Text style={[st.metinText, { color: colors.foreground }]}>{deger}</Text>
      )}
    </View>
  );
}

// ─── ActionBtn ────────────────────────────────────────────────

function ActionBtn({
  icon,
  label,
  onPress,
  colors,
  danger,
  disabled,
}: {
  icon: React.ComponentProps<typeof Feather>["name"];
  label: string;
  onPress: () => void;
  colors: Colors;
  danger?: boolean;
  disabled?: boolean;
}) {
  const col = disabled ? colors.mutedForeground : danger ? "#e74c3c" : colors.foreground;
  return (
    <TouchableOpacity
      style={st.actionBtn}
      onPress={onPress}
      disabled={disabled}
      activeOpacity={0.75}
    >
      <Feather name={icon} size={18} color={col} />
      <Text style={[st.actionLabel, { color: col }]}>{label}</Text>
    </TouchableOpacity>
  );
}

// ─── KategoriPickerModal ──────────────────────────────────────

function KategoriPickerModal({
  visible,
  categories,
  kategoriSayilari,
  totalCount,
  selected,
  onSelect,
  onClose,
  colors,
}: {
  visible: boolean;
  categories: string[];
  kategoriSayilari: Map<string, number>;
  totalCount: number;
  selected: string | null;
  onSelect: (cat: string) => void;
  onClose: () => void;
  colors: Colors;
}) {
  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <TouchableOpacity style={st.pickerOverlay} activeOpacity={1} onPress={onClose}>
        <TouchableOpacity
          activeOpacity={1}
          style={[st.pickerSheet, { backgroundColor: colors.card }]}
          onPress={() => {}}
        >
          <View style={[st.pickerHeader, { borderBottomColor: colors.border }]}>
            <Text style={[st.pickerTitle, { color: colors.foreground }]}>Kategori Seç</Text>
            <TouchableOpacity onPress={onClose} hitSlop={12}>
              <Feather name="x" size={22} color={colors.mutedForeground} />
            </TouchableOpacity>
          </View>
          <FlatList
            data={categories}
            keyExtractor={(item) => item}
            keyboardShouldPersistTaps="handled"
            style={{ maxHeight: 420 }}
            renderItem={({ item }) => {
              const active = item === "Tümü" ? selected === null : selected === item;
              const count =
                item === "Tümü" ? totalCount : (kategoriSayilari.get(item) ?? 0);
              return (
                <TouchableOpacity
                  style={[
                    st.pickerItem,
                    {
                      borderBottomColor: colors.border,
                      backgroundColor: active ? colors.primary + "14" : "transparent",
                    },
                  ]}
                  onPress={() => onSelect(item)}
                  activeOpacity={0.75}
                >
                  <Text
                    style={[
                      st.pickerItemText,
                      { color: active ? colors.primary : colors.foreground },
                    ]}
                    numberOfLines={2}
                  >
                    {item}
                  </Text>
                  <View style={st.pickerItemRight}>
                    <Text style={[st.pickerCount, { color: colors.mutedForeground }]}>
                      {count}
                    </Text>
                    {active ? (
                      <Feather name="check" size={18} color={colors.primary} />
                    ) : (
                      <View style={{ width: 18 }} />
                    )}
                  </View>
                </TouchableOpacity>
              );
            }}
          />
        </TouchableOpacity>
      </TouchableOpacity>
    </Modal>
  );
}

// ─── OlcuBirimiPickerModal ────────────────────────────────────

function OlcuBirimiPickerModal({
  visible,
  selected,
  onSelect,
  onClose,
  colors,
}: {
  visible: boolean;
  selected: string;
  onSelect: (unit: string) => void;
  onClose: () => void;
  colors: Colors;
}) {
  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <TouchableOpacity style={st.pickerOverlay} activeOpacity={1} onPress={onClose}>
        <TouchableOpacity
          activeOpacity={1}
          style={[st.pickerSheet, { backgroundColor: colors.card }]}
          onPress={() => {}}
        >
          <View style={[st.pickerHeader, { borderBottomColor: colors.border }]}>
            <Text style={[st.pickerTitle, { color: colors.foreground }]}>Ölçü Birimi Seç</Text>
            <TouchableOpacity onPress={onClose} hitSlop={12}>
              <Feather name="x" size={22} color={colors.mutedForeground} />
            </TouchableOpacity>
          </View>
          <FlatList
            data={[...OLCU_BIRIMLERI]}
            keyExtractor={(item) => item}
            keyboardShouldPersistTaps="handled"
            style={{ maxHeight: 420 }}
            renderItem={({ item }) => {
              const active = selected === item;
              return (
                <TouchableOpacity
                  style={[
                    st.pickerItem,
                    {
                      borderBottomColor: colors.border,
                      backgroundColor: active ? colors.primary + "14" : "transparent",
                    },
                  ]}
                  onPress={() => onSelect(item)}
                  activeOpacity={0.75}
                >
                  <Text
                    style={[
                      st.pickerItemText,
                      { color: active ? colors.primary : colors.foreground },
                    ]}
                  >
                    {item}
                  </Text>
                  {active ? (
                    <Feather name="check" size={18} color={colors.primary} />
                  ) : (
                    <View style={{ width: 18 }} />
                  )}
                </TouchableOpacity>
              );
            }}
          />
        </TouchableOpacity>
      </TouchableOpacity>
    </Modal>
  );
}

// ─── CloneModal ───────────────────────────────────────────────

function CloneModal({
  visible,
  ad,
  onChangeAd,
  onConfirm,
  onCancel,
  colors,
}: {
  visible: boolean;
  ad: string;
  onChangeAd: (v: string) => void;
  onConfirm: () => void;
  onCancel: () => void;
  colors: Colors;
}) {
  const insets = useSafeAreaInsets();

  if (!visible) return null;

  return (
    <View style={st.modalHost}>
      <TouchableOpacity
        style={st.modalBackdrop}
        activeOpacity={1}
        onPress={() => {
          Keyboard.dismiss();
          onCancel();
        }}
      />
      <KeyboardAvoidingView
        style={st.modalKav}
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        keyboardVerticalOffset={0}
      >
        <View
          style={[
            st.modalSheet,
            { backgroundColor: colors.card, paddingBottom: Math.max(insets.bottom, 16) },
          ]}
        >
          <Text style={[st.modalTitle, { color: colors.foreground }]}>Analizi Kopyala</Text>
          <Text style={[st.modalSub, { color: colors.mutedForeground }]}>
            Kopyalanan analizin adını belirleyin:
          </Text>
          <TextInput
            style={[
              st.modalInput,
              { color: colors.foreground, borderColor: colors.border, backgroundColor: colors.background },
            ]}
            value={ad}
            onChangeText={onChangeAd}
            multiline
            autoFocus
          />
          <View style={st.modalBtns}>
            <TouchableOpacity
              style={[st.modalBtn, { backgroundColor: colors.border }]}
              onPress={onCancel}
            >
              <Text style={{ color: colors.foreground }}>İptal</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[st.modalBtn, { backgroundColor: colors.primary }]}
              onPress={onConfirm}
            >
              <Text style={{ color: colors.primaryForeground, fontWeight: "700" }}>Kopyala</Text>
            </TouchableOpacity>
          </View>
        </View>
      </KeyboardAvoidingView>
    </View>
  );
}

// ─── NewAnalizModal ───────────────────────────────────────────
// iOS'ta RN Modal ayrı pencerede açıldığı için klavye kaçınması çalışmaz;
// ekran içi overlay + KeyboardAvoidingView kullanıyoruz.

function NewAnalizModal({
  visible,
  form,
  onChange,
  onConfirm,
  onCancel,
  colors,
}: {
  visible: boolean;
  form: { pozNo: string; analizAdi: string; olcuBirimi: string; kategori: string };
  onChange: (f: Partial<typeof form>) => void;
  onConfirm: () => void;
  onCancel: () => void;
  colors: Colors;
}) {
  const insets = useSafeAreaInsets();
  const scrollRef = React.useRef<ScrollView>(null);
  const [birimPickerOpen, setBirimPickerOpen] = useState(false);

  if (!visible) return null;

  const scrollToEnd = () => {
    requestAnimationFrame(() => {
      scrollRef.current?.scrollToEnd({ animated: true });
    });
  };

  return (
    <View style={st.modalHost}>
      <TouchableOpacity
        style={st.modalBackdrop}
        activeOpacity={1}
        onPress={() => {
          Keyboard.dismiss();
          onCancel();
        }}
      />
      <KeyboardAvoidingView
        style={st.modalKav}
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        keyboardVerticalOffset={0}
      >
        <View
          style={[
            st.modalSheet,
            { backgroundColor: colors.card, paddingBottom: Math.max(insets.bottom, 16) },
          ]}
        >
          <ScrollView
            ref={scrollRef}
            keyboardShouldPersistTaps="handled"
            keyboardDismissMode={Platform.OS === "ios" ? "interactive" : "on-drag"}
            showsVerticalScrollIndicator={false}
            bounces={false}
            contentContainerStyle={st.modalSheetScroll}
          >
            <Text style={[st.modalTitle, { color: colors.foreground }]}>Yeni Analiz</Text>
            <View style={{ marginBottom: 10 }}>
              <Text style={[st.modalSub, { color: colors.mutedForeground, marginBottom: 4 }]}>
                Poz No
              </Text>
              <TextInput
                style={[
                  st.modalInput,
                  {
                    color: colors.foreground,
                    borderColor: colors.border,
                    backgroundColor: colors.background,
                  },
                ]}
                value={form.pozNo}
                onChangeText={(v) => onChange({ pozNo: v })}
                onFocus={scrollToEnd}
                placeholder="ör. ÖZEL.001"
                placeholderTextColor={colors.mutedForeground}
              />
            </View>
            <View style={{ marginBottom: 10 }}>
              <Text style={[st.modalSub, { color: colors.mutedForeground, marginBottom: 4 }]}>
                Analiz Adı
              </Text>
              <TextInput
                style={[
                  st.modalInput,
                  {
                    color: colors.foreground,
                    borderColor: colors.border,
                    backgroundColor: colors.background,
                  },
                ]}
                value={form.analizAdi}
                onChangeText={(v) => onChange({ analizAdi: v })}
                onFocus={scrollToEnd}
                placeholder="Analiz başlığı"
                placeholderTextColor={colors.mutedForeground}
              />
            </View>
            <View style={{ marginBottom: 10 }}>
              <Text style={[st.modalSub, { color: colors.mutedForeground, marginBottom: 4 }]}>
                Ölçü Birimi
              </Text>
              <TouchableOpacity
                style={[
                  st.filterSelect,
                  {
                    backgroundColor: colors.background,
                    borderColor: colors.border,
                    minHeight: 44,
                  },
                ]}
                onPress={() => setBirimPickerOpen(true)}
                activeOpacity={0.85}
              >
                <Text style={[st.filterSelectText, { color: colors.foreground }]}>
                  {form.olcuBirimi}
                </Text>
                <Feather name="chevron-down" size={18} color={colors.mutedForeground} />
              </TouchableOpacity>
            </View>
            <View style={st.modalBtns}>
              <TouchableOpacity
                style={[st.modalBtn, { backgroundColor: colors.border }]}
                onPress={onCancel}
              >
                <Text style={{ color: colors.foreground }}>İptal</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[st.modalBtn, { backgroundColor: colors.primary }]}
                onPress={onConfirm}
              >
                <Text style={{ color: colors.primaryForeground, fontWeight: "700" }}>Oluştur</Text>
              </TouchableOpacity>
            </View>
          </ScrollView>
        </View>
      </KeyboardAvoidingView>
      <OlcuBirimiPickerModal
        visible={birimPickerOpen}
        selected={form.olcuBirimi}
        onSelect={(unit) => {
          onChange({ olcuBirimi: unit });
          setBirimPickerOpen(false);
        }}
        onClose={() => setBirimPickerOpen(false)}
        colors={colors}
      />
    </View>
  );
}

// ─── StyleSheet ───────────────────────────────────────────────

const st = StyleSheet.create({
  header: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingBottom: 14,
    gap: 8,
  },
  backBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: "center",
    justifyContent: "center",
  },
  headerTitle: {
    flex: 1,
    fontSize: 17,
    fontWeight: "700",
    textAlign: "center",
    fontFamily: "Inter_700Bold",
  },
  hBtn: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
    alignItems: "center",
    justifyContent: "center",
  },
  searchWrap: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    margin: 12,
    marginBottom: 8,
    borderRadius: 10,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 16,
    minHeight: 56,
  },
  searchInput: {
    flex: 1,
    fontSize: 16,
    fontFamily: "Inter_400Regular",
    padding: 0,
  },
  filterRow: {
    paddingHorizontal: 12,
    marginBottom: 8,
    gap: 6,
  },
  filterLabel: {
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
    textTransform: "uppercase",
    letterSpacing: 0.5,
    marginLeft: 2,
  },
  filterSelect: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    gap: 8,
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 11,
  },
  filterSelectText: {
    flex: 1,
    fontSize: 14,
    fontFamily: "Inter_500Medium",
  },
  selectBar: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginHorizontal: 12,
    marginBottom: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 10,
    borderWidth: 1,
  },
  selectBarText: {
    fontSize: 13,
    fontFamily: "Inter_600SemiBold",
  },
  selectBarAction: {
    fontSize: 13,
    fontFamily: "Inter_500Medium",
  },
  checkCell: {
    width: 32,
    alignItems: "center",
    justifyContent: "center",
  },
  bulkBar: {
    position: "absolute",
    left: 0,
    right: 0,
    bottom: 0,
    flexDirection: "row",
    borderTopWidth: 1,
    paddingTop: 10,
    paddingHorizontal: 16,
    gap: 12,
    justifyContent: "space-around",
  },
  bulkBtn: {
    flex: 1,
    alignItems: "center",
    gap: 4,
    paddingVertical: 6,
  },
  bulkBtnLabel: {
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
  },
  pickerOverlay: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.45)",
    justifyContent: "flex-end",
  },
  pickerSheet: {
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    paddingBottom: 8,
    maxHeight: "70%",
  },
  pickerHeader: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
  },
  pickerTitle: {
    fontSize: 16,
    fontFamily: "Inter_700Bold",
  },
  pickerItem: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: 16,
    paddingVertical: 13,
    borderBottomWidth: StyleSheet.hairlineWidth,
    gap: 12,
  },
  pickerItemText: {
    flex: 1,
    fontSize: 14,
    fontFamily: "Inter_500Medium",
  },
  pickerItemRight: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
  },
  pickerCount: {
    fontSize: 13,
    fontFamily: "Inter_600SemiBold",
    minWidth: 28,
    textAlign: "right",
  },
  listHeader: {
    flexDirection: "row",
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderTopWidth: 1,
  },
  listTh: { fontSize: 11, fontFamily: "Inter_600SemiBold", textTransform: "uppercase" },
  listRow: {
    flexDirection: "row",
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderBottomWidth: StyleSheet.hairlineWidth,
    alignItems: "center",
  },
  tdNo: { width: 36, fontSize: 12, fontFamily: "Inter_400Regular" },
  tdPoz: { width: 104, fontSize: 12, fontFamily: "Inter_600SemiBold" },
  tdAd: { flex: 1, fontSize: 13, fontFamily: "Inter_400Regular", lineHeight: 18 },
  tdBirim: { width: 44, fontSize: 12, fontFamily: "Inter_400Regular", textAlign: "right" },
  fab: {
    position: "absolute",
    right: 20,
    width: 52,
    height: 52,
    borderRadius: 26,
    alignItems: "center",
    justifyContent: "center",
    elevation: 4,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
  },
  infoCard: {
    margin: 12,
    borderRadius: 10,
    borderWidth: 1,
    overflow: "hidden",
  },
  resmiBadge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    margin: 10,
    marginBottom: 0,
    paddingHorizontal: 10,
    paddingVertical: 7,
    borderRadius: 8,
    borderWidth: 1,
  },
  resmiBadgeText: {
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
    color: "#2563eb",
  },
  metrajCard: {
    marginHorizontal: 12,
    marginBottom: 4,
    borderRadius: 10,
    borderWidth: 1,
    padding: 12,
    gap: 10,
  },
  metrajHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
  },
  metrajTitle: {
    fontSize: 14,
    fontFamily: "Inter_700Bold",
  },
  metrajRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
  },
  metrajLabel: {
    fontSize: 12,
    fontFamily: "Inter_600SemiBold",
    width: 52,
  },
  metrajInput: {
    flex: 1,
    fontSize: 16,
    fontFamily: "Inter_600SemiBold",
    borderWidth: 1,
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 8,
    textAlign: "right",
  },
  metrajUnit: {
    fontSize: 13,
    fontFamily: "Inter_500Medium",
    minWidth: 36,
  },
  metrajSummary: {
    gap: 4,
    paddingTop: 2,
  },
  metrajLine: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
  },
  metrajTotal: {
    fontSize: 16,
    fontFamily: "Inter_700Bold",
  },
  infoRow: {
    flexDirection: "row",
    alignItems: "flex-start",
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderBottomWidth: StyleSheet.hairlineWidth,
    gap: 8,
  },
  infoLabel: { width: 110, fontSize: 12, fontFamily: "Inter_600SemiBold", paddingTop: 2 },
  infoValue: { fontSize: 13, fontFamily: "Inter_400Regular", flex: 1 },
  infoInput: {
    flex: 1,
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    borderWidth: 1,
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 3,
  },
  tRow: {
    flexDirection: "row",
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  th: {
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
    paddingHorizontal: 4,
    paddingVertical: 6,
    borderRightWidth: StyleSheet.hairlineWidth,
    textAlign: "center",
  },
  td: {
    paddingHorizontal: 4,
    paddingVertical: 4,
    borderRightWidth: StyleSheet.hairlineWidth,
    justifyContent: "center",
  },
  tdText: { fontSize: 12, fontFamily: "Inter_400Regular" },
  cellInput: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    padding: 2,
    minHeight: 28,
  },
  groupRow: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 6,
    paddingVertical: 4,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  groupText: {
    fontSize: 12,
    fontFamily: "Inter_700Bold",
    fontStyle: "italic",
  },
  addRowBtn: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  sumLabel: { fontSize: 12, fontFamily: "Inter_500Medium" },
  karInput: {
    width: 44,
    fontSize: 12,
    borderWidth: 1,
    borderRadius: 4,
    paddingHorizontal: 4,
    marginHorizontal: 4,
    textAlign: "center",
  },
  metinCard: {
    marginHorizontal: 12,
    marginTop: 10,
    borderRadius: 10,
    borderWidth: 1,
    padding: 12,
  },
  metinBaslik: {
    fontSize: 11,
    fontFamily: "Inter_700Bold",
    textTransform: "uppercase",
    letterSpacing: 0.5,
    marginBottom: 6,
  },
  metinText: { fontSize: 13, fontFamily: "Inter_400Regular", lineHeight: 20 },
  metinInput: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    borderWidth: 1,
    borderRadius: 6,
    padding: 8,
    minHeight: 80,
    lineHeight: 20,
  },
  bottomBar: {
    flexDirection: "row",
    borderTopWidth: 1,
    paddingTop: 8,
    paddingHorizontal: 8,
    justifyContent: "space-around",
  },
  actionBtn: { alignItems: "center", paddingHorizontal: 10, paddingVertical: 6, gap: 4 },
  actionLabel: { fontSize: 11, fontFamily: "Inter_500Medium" },
  modalHost: {
    ...StyleSheet.absoluteFillObject,
    zIndex: 1000,
    elevation: 1000,
  },
  modalBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(0,0,0,0.5)",
  },
  modalKav: {
    flex: 1,
    justifyContent: "flex-end",
  },
  modalSheet: {
    width: "100%",
    maxHeight: "85%",
    borderTopLeftRadius: 18,
    borderTopRightRadius: 18,
    paddingHorizontal: 20,
    paddingTop: 18,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: -4 },
    shadowOpacity: 0.15,
    shadowRadius: 12,
    elevation: 8,
  },
  modalSheetScroll: {
    paddingBottom: 4,
  },
  modalTitle: {
    fontSize: 17,
    fontFamily: "Inter_700Bold",
    marginBottom: 6,
  },
  modalSub: { fontSize: 13, fontFamily: "Inter_400Regular", marginBottom: 10 },
  modalInput: {
    borderWidth: 1,
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 8,
    fontSize: 14,
    fontFamily: "Inter_400Regular",
    minHeight: 44,
  },
  modalBtns: { flexDirection: "row", gap: 10, marginTop: 16 },
  modalBtn: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: "center",
    justifyContent: "center",
  },
});
