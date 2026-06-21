import { Feather } from "@expo/vector-icons";
import { useLocalSearchParams, useRouter } from "expo-router";
import React, { useMemo, useRef, useState } from "react";
import {
  Alert,
  FlatList,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { Swipeable } from "react-native-gesture-handler";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { KesifExportModal } from "@/components/KesifExportModal";
import { KesifPozPickerModal } from "@/components/KesifPozPickerModal";
import { hesaplaKesifToplam, KesifSatiri, trFmtKesif } from "@/constants/kesif";
import { PozAnaliz } from "@/constants/pozAnalizleri";
import { useKesif } from "@/context/KesifContext";
import { useBfaCatalog } from "@/hooks/useBfaCatalog";
import { useColors } from "@/hooks/useColors";
import { AnalizExportFormat, waitForShareSheet } from "@/lib/analizExport";
import { exportKesif } from "@/lib/kesifExport";

const KESIF_COLOR = "#7c3aed";

const COL = {
  sira: 28,
  miktar: 64,
  birim: 44,
  tutar: 112,
  numGap: 6,
  tutarShift: 15,
} as const;

const SWIPE_DELETE_WIDTH = 72;

export default function KesifDetailScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;
  const params = useLocalSearchParams<{ id?: string }>();
  const projectId = params.id ? String(params.id) : "";

  const { getProject, addSatir, updateSatirMiktar, removeSatir, removeSatirlar, clearAllSatirlar, deleteProject } = useKesif();
  const { all } = useBfaCatalog();

  const project = getProject(projectId);
  const [pickerVisible, setPickerVisible] = useState(false);
  const [exportVisible, setExportVisible] = useState(false);
  const [tanimModal, setTanimModal] = useState<{ pozNo: string; analizAdi: string } | null>(null);
  const [selectMode, setSelectMode] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(() => new Set());

  const toplam = useMemo(
    () => (project ? hesaplaKesifToplam(project.satirlar) : 0),
    [project],
  );

  if (!project) {
    return (
      <View style={[styles.center, { backgroundColor: colors.background }]}>
        <Feather name="alert-circle" size={40} color={colors.mutedForeground} />
        <Text style={{ color: colors.mutedForeground, marginTop: 12 }}>Keşif bulunamadı</Text>
        <TouchableOpacity onPress={() => router.back()} style={{ marginTop: 16 }}>
          <Text style={{ color: colors.primary, fontFamily: "Inter_600SemiBold" }}>Geri dön</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const kesif = project;

  function resolveAnaliz(analizId: string): PozAnaliz | undefined {
    return all.find((a) => a.id === analizId);
  }

  function handleAddSatir(analiz: PozAnaliz, miktar: number) {
    const duplicate = kesif.satirlar.find(
      (s) => s.analizId === analiz.id || s.pozNo === analiz.pozNo,
    );
    if (duplicate) {
      Alert.alert(
        "Poz Zaten Mevcut",
        `${analiz.pozNo} bu keşifte zaten var. Yine de ayrı bir satır olarak eklemek istiyor musunuz?`,
        [
          { text: "İptal", style: "cancel" },
          {
            text: "Yine de Ekle",
            onPress: () => addSatir(projectId, analiz, miktar),
          },
        ],
      );
      return;
    }
    addSatir(projectId, analiz, miktar);
  }

  function handleDeleteSatir(satirId: string) {
    removeSatir(projectId, satirId);
  }

  function toggleSelectMode() {
    setSelectMode((prev) => {
      if (prev) setSelectedIds(new Set());
      return !prev;
    });
  }

  function toggleSelected(satirId: string) {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(satirId)) next.delete(satirId);
      else next.add(satirId);
      return next;
    });
  }

  function enterSelectModeWith(satirId: string) {
    setSelectMode(true);
    setSelectedIds(new Set([satirId]));
  }

  function handleDeleteSelected() {
    if (selectedIds.size === 0) return;
    Alert.alert(
      "Seçilen Pozları Sil",
      `${selectedIds.size} poz keşiften kaldırılsın mı?`,
      [
        { text: "İptal", style: "cancel" },
        {
          text: "Sil",
          style: "destructive",
          onPress: () => {
            removeSatirlar(projectId, [...selectedIds]);
            setSelectMode(false);
            setSelectedIds(new Set());
          },
        },
      ],
    );
  }

  function handleClearAllPoz() {
    if (kesif.satirlar.length === 0) {
      Alert.alert("Boş Keşif", "Silinecek poz bulunmuyor.");
      return;
    }
    Alert.alert(
      "Tüm Pozları Sil",
      `Keşifteki ${kesif.satirlar.length} poz kaldırılsın mı? Keşif projesi silinmez.`,
      [
        { text: "İptal", style: "cancel" },
        {
          text: "Pozları Sil",
          style: "destructive",
          onPress: () => clearAllSatirlar(projectId),
        },
      ],
    );
  }

  function handleDeleteProject() {
    Alert.alert("Keşifi Sil", `"${kesif.ad}" projesi tamamen silinsin mi?`, [
      { text: "İptal", style: "cancel" },
      {
        text: "Keşifi Sil",
        style: "destructive",
        onPress: () => {
          deleteProject(projectId);
          router.back();
        },
      },
    ]);
  }

  async function handleExport(format: AnalizExportFormat) {
    setExportVisible(false);
    await waitForShareSheet();
    await exportKesif(kesif, format);
  }

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      <View
        style={[styles.header, { backgroundColor: colors.secondary, paddingTop: topPad + 12 }]}
      >
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Feather name="arrow-left" size={22} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <View style={{ flex: 1 }}>
          <Text
            style={[styles.headerTitle, { color: colors.secondaryForeground }]}
            numberOfLines={1}
          >
            {kesif.ad}
          </Text>
          {kesif.aciklama ? (
            <Text
              style={[styles.headerSub, { color: colors.secondaryForeground + "aa" }]}
              numberOfLines={1}
            >
              {kesif.aciklama}
            </Text>
          ) : null}
        </View>
        <TouchableOpacity onPress={() => setExportVisible(true)} style={styles.backBtn}>
          <Feather name="download" size={20} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <TouchableOpacity onPress={toggleSelectMode} style={styles.backBtn}>
          <Feather
            name={selectMode ? "x" : "check-square"}
            size={20}
            color={colors.secondaryForeground}
          />
        </TouchableOpacity>
      </View>

      {selectMode && (
        <View
          style={[
            styles.selectBar,
            { backgroundColor: KESIF_COLOR + "14", borderColor: KESIF_COLOR + "33" },
          ]}
        >
          <Text style={[styles.selectBarText, { color: KESIF_COLOR }]}>
            {selectedIds.size} poz seçildi
          </Text>
          <TouchableOpacity onPress={toggleSelectMode}>
            <Text style={[styles.selectBarAction, { color: colors.mutedForeground }]}>İptal</Text>
          </TouchableOpacity>
        </View>
      )}

      <View style={[styles.summary, { backgroundColor: colors.card, borderColor: colors.border }]}>
        <View style={{ flex: 1 }}>
          <Text style={[styles.summaryLabel, { color: colors.mutedForeground }]}>Genel Toplam</Text>
          <Text style={[styles.summaryTotal, { color: KESIF_COLOR }]}>
            {trFmtKesif(toplam)} TL
          </Text>
        </View>
        <Text style={[styles.summaryMeta, { color: colors.mutedForeground }]}>
          {project.satirlar.length} poz
        </Text>
      </View>

      <View
        style={[styles.tableHeader, { backgroundColor: colors.card, borderColor: colors.border }]}
      >
        {selectMode && (
          <Text style={[styles.th, styles.colCheck, { color: colors.mutedForeground }]}> </Text>
        )}
        <Text style={[styles.th, styles.colSira, { color: colors.mutedForeground }]}>#</Text>
        <Text style={[styles.th, styles.colPoz, { color: colors.mutedForeground }]}>Poz</Text>
        <View style={styles.numCluster}>
          <View style={styles.numLeadGroup}>
            <Text style={[styles.th, styles.colMiktar, { color: colors.mutedForeground }]}>Miktar</Text>
            <Text style={[styles.th, styles.colBirim, { color: colors.mutedForeground }]}>Br.</Text>
          </View>
          <Text style={[styles.th, styles.colTutar, { color: colors.mutedForeground }]}>Tutar</Text>
        </View>
      </View>

      <FlatList
        data={project.satirlar}
        keyExtractor={(item) => item.id}
        extraData={`${selectMode}|${selectedIds.size}|${project.satirlar.length}`}
        contentContainerStyle={{
          paddingBottom: selectMode ? insets.bottom + 80 : insets.bottom + 88,
          flexGrow: 1,
        }}
        ListFooterComponent={
          <View
            style={[
              styles.dangerZone,
              { backgroundColor: colors.card, borderColor: colors.border },
            ]}
          >
            <Text style={[styles.dangerZoneTitle, { color: colors.mutedForeground }]}>
              Proje İşlemleri
            </Text>
            <TouchableOpacity
              onPress={handleClearAllPoz}
              style={[styles.dangerRow, { borderColor: colors.border }]}
              activeOpacity={0.85}
            >
              <Feather name="minus-circle" size={18} color="#d97706" />
              <View style={styles.dangerRowText}>
                <Text style={[styles.dangerRowLabel, { color: colors.foreground }]}>
                  Tüm Pozları Sil
                </Text>
                <Text style={[styles.dangerRowHint, { color: colors.mutedForeground }]}>
                  Satırlar temizlenir, proje kalır
                </Text>
              </View>
              <Feather name="chevron-right" size={16} color={colors.mutedForeground} />
            </TouchableOpacity>
            <TouchableOpacity
              onPress={handleDeleteProject}
              style={[styles.dangerRow, styles.dangerRowLast, { borderColor: "#e74c3c33" }]}
              activeOpacity={0.85}
            >
              <Feather name="trash-2" size={18} color="#e74c3c" />
              <View style={styles.dangerRowText}>
                <Text style={[styles.dangerRowLabel, { color: "#e74c3c" }]}>Keşifi Sil</Text>
                <Text style={[styles.dangerRowHint, { color: colors.mutedForeground }]}>
                  Proje ve tüm pozlar kalıcı olarak silinir
                </Text>
              </View>
              <Feather name="chevron-right" size={16} color="#e74c3c88" />
            </TouchableOpacity>
          </View>
        }
        ListEmptyComponent={
          <View style={styles.emptyList}>
            <Feather name="plus-circle" size={36} color={colors.mutedForeground} />
            <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>
              Katalogdan poz ekleyerek keşfe başlayın
            </Text>
          </View>
        }
        renderItem={({ item, index }) => (
          <KesifSatirRow
            item={item}
            index={index}
            colors={colors}
            selectMode={selectMode}
            selected={selectedIds.has(item.id)}
            onToggleSelect={() => toggleSelected(item.id)}
            onEnterSelectMode={() => enterSelectModeWith(item.id)}
            resolveAnaliz={resolveAnaliz}
            onUpdateMiktar={(miktar) => updateSatirMiktar(projectId, item.id, miktar)}
            onDelete={() => handleDeleteSatir(item.id)}
            onShowTanim={() => setTanimModal({ pozNo: item.pozNo, analizAdi: item.analizAdi })}
          />
        )}
      />

      {selectMode && (
        <View
          style={[
            styles.bulkBar,
            {
              backgroundColor: colors.card,
              borderTopColor: colors.border,
              paddingBottom: insets.bottom + 8,
            },
          ]}
        >
          <TouchableOpacity
            style={[styles.bulkBtn, { opacity: selectedIds.size >= 1 ? 1 : 0.45 }]}
            onPress={handleDeleteSelected}
            disabled={selectedIds.size < 1}
          >
            <Feather name="trash-2" size={18} color="#e74c3c" />
            <Text style={[styles.bulkBtnLabel, { color: "#e74c3c" }]}>Seçilenleri Sil</Text>
          </TouchableOpacity>
        </View>
      )}

      {!selectMode && (
      <TouchableOpacity
        style={[styles.fab, { backgroundColor: KESIF_COLOR, bottom: insets.bottom + 16 }]}
        onPress={() => setPickerVisible(true)}
      >
        <Feather name="plus" size={24} color="#fff" />
      </TouchableOpacity>
      )}

      <KesifPozPickerModal
        visible={pickerVisible}
        onClose={() => setPickerVisible(false)}
        onSelect={handleAddSatir}
      />

      <KesifExportModal
        visible={exportVisible}
        project={kesif}
        onClose={() => setExportVisible(false)}
        onExport={handleExport}
      />

      <Modal
        visible={tanimModal !== null}
        transparent
        animationType="fade"
        onRequestClose={() => setTanimModal(null)}
      >
        <Pressable style={styles.tanimOverlay} onPress={() => setTanimModal(null)}>
          <Pressable
            style={[styles.tanimCard, { backgroundColor: colors.card, borderColor: colors.border }]}
            onPress={(e) => e.stopPropagation()}
          >
            <View style={styles.tanimHeader}>
              <Text style={[styles.tanimPoz, { color: colors.primary }]}>{tanimModal?.pozNo}</Text>
              <TouchableOpacity onPress={() => setTanimModal(null)} hitSlop={12}>
                <Feather name="x" size={20} color={colors.mutedForeground} />
              </TouchableOpacity>
            </View>
            <Text style={[styles.tanimLabel, { color: colors.mutedForeground }]}>Tanım</Text>
            <ScrollView style={styles.tanimScroll} nestedScrollEnabled>
              <Text style={[styles.tanimBody, { color: colors.foreground }]}>
                {tanimModal?.analizAdi}
              </Text>
            </ScrollView>
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

function parseQty(s: string): number {
  const v = parseFloat(s.replace(",", "."));
  return Number.isFinite(v) ? v : 0;
}

type KesifSatirRowProps = {
  item: KesifSatiri;
  index: number;
  colors: ReturnType<typeof useColors>;
  selectMode: boolean;
  selected: boolean;
  onToggleSelect: () => void;
  onEnterSelectMode: () => void;
  resolveAnaliz: (analizId: string) => PozAnaliz | undefined;
  onUpdateMiktar: (miktar: number) => void;
  onDelete: () => void;
  onShowTanim: () => void;
};

function KesifSatirRow({
  item,
  index,
  colors,
  selectMode,
  selected,
  onToggleSelect,
  onEnterSelectMode,
  resolveAnaliz,
  onUpdateMiktar,
  onDelete,
  onShowTanim,
}: KesifSatirRowProps) {
  const router = useRouter();
  const swipeRef = useRef<Swipeable>(null);
  const confirmingRef = useRef(false);

  function requestDelete() {
    if (confirmingRef.current) return;
    confirmingRef.current = true;
    Alert.alert(
      "Poz Sil",
      `${item.pozNo} keşiften kaldırılsın mı?`,
      [
        {
          text: "İptal",
          style: "cancel",
          onPress: () => {
            confirmingRef.current = false;
            swipeRef.current?.close();
          },
        },
        {
          text: "Sil",
          style: "destructive",
          onPress: () => {
            confirmingRef.current = false;
            onDelete();
          },
        },
      ],
      {
        cancelable: true,
        onDismiss: () => {
          confirmingRef.current = false;
          swipeRef.current?.close();
        },
      },
    );
  }

  function renderRightActions() {
    return (
      <TouchableOpacity
        style={styles.swipeDelete}
        activeOpacity={0.85}
        onPress={requestDelete}
      >
        <Feather name="trash-2" size={18} color="#fff" />
        <Text style={styles.swipeDeleteText}>Sil</Text>
      </TouchableOpacity>
    );
  }

  const rowContent = (
    <Pressable
      onPress={() => {
        if (selectMode) onToggleSelect();
      }}
      onLongPress={() => {
        if (!selectMode) onEnterSelectMode();
      }}
      style={[
        styles.row,
        {
          borderColor: colors.border,
          backgroundColor: selected
            ? KESIF_COLOR + "18"
            : index % 2 === 0
              ? colors.background
              : colors.card + "66",
        },
      ]}
    >
      {selectMode && (
        <TouchableOpacity
          onPress={onToggleSelect}
          style={styles.colCheck}
          hitSlop={8}
          activeOpacity={0.8}
        >
          <Feather
            name={selected ? "check-square" : "square"}
            size={18}
            color={selected ? KESIF_COLOR : colors.mutedForeground}
          />
        </TouchableOpacity>
      )}

      <Text style={[styles.tdSira, { color: colors.mutedForeground }]}>{index + 1}</Text>

      <View style={styles.colPoz}>
        <TouchableOpacity
          activeOpacity={0.75}
          onPress={() => {
            if (selectMode) {
              onToggleSelect();
              return;
            }
            const analiz = resolveAnaliz(item.analizId);
            if (analiz) {
              router.push({
                pathname: "/imalat-pozlari",
                params: { id: analiz.id, modul: analiz.discipline ?? "insaat" },
              } as any);
            }
          }}
          {...(Platform.OS === "web" && !selectMode ? { onLongPress: requestDelete } : {})}
        >
          <Text style={[styles.tdPoz, { color: colors.primary }]}>{item.pozNo}</Text>
        </TouchableOpacity>
        {!selectMode && (
          <TouchableOpacity
            style={[styles.tanimBtn, { borderColor: colors.border, backgroundColor: colors.card }]}
            onPress={onShowTanim}
            activeOpacity={0.8}
          >
            <Feather name="file-text" size={11} color={colors.primary} />
            <Text style={[styles.tanimBtnText, { color: colors.primary }]}>Tanım</Text>
          </TouchableOpacity>
        )}
      </View>

      <View style={styles.numCluster}>
        <View style={styles.numLeadGroup}>
          <View style={styles.colMiktar}>
            <TextInput
              style={[
                styles.qtyInput,
                {
                  color: colors.foreground,
                  borderColor: colors.border,
                  backgroundColor: colors.card,
                  opacity: selectMode ? 0.55 : 1,
                },
              ]}
              value={String(item.miktar)}
              onChangeText={(v) => onUpdateMiktar(parseQty(v))}
              keyboardType="decimal-pad"
              selectTextOnFocus
              editable={!selectMode}
            />
          </View>

          <Text style={[styles.tdBirim, { color: colors.foreground }]} numberOfLines={2}>
            {item.olcuBirimi}
          </Text>
        </View>

        <Text style={[styles.tdTutar, { color: colors.foreground }]} numberOfLines={1}>
          {trFmtKesif(item.tutar)}
        </Text>
      </View>
    </Pressable>
  );

  if (selectMode) {
    return rowContent;
  }

  return (
    <Swipeable
      ref={swipeRef}
      renderRightActions={renderRightActions}
      onSwipeableOpen={requestDelete}
      overshootRight={false}
      friction={2}
      rightThreshold={40}
      enabled={Platform.OS !== "web"}
    >
      {rowContent}
    </Swipeable>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: "center", justifyContent: "center" },
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
  headerTitle: { fontSize: 16, fontFamily: "Inter_700Bold" },
  headerSub: { fontSize: 11, fontFamily: "Inter_400Regular", marginTop: 2 },
  selectBar: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginHorizontal: 12,
    marginBottom: 8,
    paddingHorizontal: 14,
    paddingVertical: 10,
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
  bulkBar: {
    position: "absolute",
    left: 0,
    right: 0,
    bottom: 0,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 16,
    paddingTop: 10,
    borderTopWidth: 1,
  },
  bulkBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingVertical: 10,
    paddingHorizontal: 20,
  },
  bulkBtnLabel: {
    fontSize: 14,
    fontFamily: "Inter_700Bold",
  },
  summary: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    margin: 12,
    marginBottom: 8,
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
  },
  summaryLabel: { fontSize: 11, fontFamily: "Inter_600SemiBold", textTransform: "uppercase" },
  summaryTotal: { fontSize: 22, fontFamily: "Inter_700Bold", marginTop: 2 },
  summaryMeta: { fontSize: 12, fontFamily: "Inter_500Medium", alignSelf: "flex-end" },
  dangerZone: {
    marginHorizontal: 12,
    marginTop: 20,
    marginBottom: 8,
    borderRadius: 12,
    borderWidth: 1,
    overflow: "hidden",
  },
  dangerZoneTitle: {
    fontSize: 10,
    fontFamily: "Inter_600SemiBold",
    textTransform: "uppercase",
    letterSpacing: 0.4,
    paddingHorizontal: 14,
    paddingTop: 12,
    paddingBottom: 6,
  },
  dangerRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderTopWidth: StyleSheet.hairlineWidth,
  },
  dangerRowLast: {
    backgroundColor: "#e74c3c08",
  },
  dangerRowText: {
    flex: 1,
    gap: 2,
  },
  dangerRowLabel: {
    fontSize: 14,
    fontFamily: "Inter_600SemiBold",
  },
  dangerRowHint: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    lineHeight: 15,
  },
  tableHeader: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    gap: 8,
  },
  th: { fontSize: 10, fontFamily: "Inter_600SemiBold", textTransform: "uppercase" },
  colCheck: { width: 28, alignItems: "center", justifyContent: "center" },
  colSira: { width: COL.sira, textAlign: "center" },
  colPoz: { flex: 1, minWidth: 0 },
  numCluster: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: COL.numGap,
    flexShrink: 0,
    paddingRight: COL.tutarShift,
  },
  numLeadGroup: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: COL.numGap,
    marginLeft: 13,
  },
  colMiktar: { width: COL.miktar, textAlign: "right" },
  colBirim: { width: COL.birim, textAlign: "center" },
  colTutar: { width: COL.tutar, textAlign: "right", marginLeft: -COL.tutarShift },
  row: {
    flexDirection: "row",
    alignItems: "flex-start",
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderBottomWidth: StyleSheet.hairlineWidth,
    gap: 8,
  },
  tdSira: {
    width: COL.sira,
    fontSize: 11,
    fontFamily: "Inter_500Medium",
    textAlign: "center",
    paddingTop: 2,
  },
  tdPoz: { fontSize: 11, fontFamily: "Inter_700Bold", lineHeight: 15 },
  tanimBtn: {
    flexDirection: "row",
    alignItems: "center",
    alignSelf: "flex-start",
    gap: 4,
    marginTop: 5,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    borderWidth: 1,
  },
  tanimBtnText: {
    fontSize: 10,
    fontFamily: "Inter_600SemiBold",
  },
  tdBirim: {
    width: COL.birim,
    fontSize: 10,
    fontFamily: "Inter_500Medium",
    textAlign: "center",
    paddingTop: 6,
    lineHeight: 13,
  },
  qtyInput: {
    width: "100%",
    fontSize: 12,
    fontFamily: "Inter_600SemiBold",
    borderWidth: 1,
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 5,
    textAlign: "right",
  },
  tdTutar: {
    width: COL.tutar,
    fontSize: 11,
    fontFamily: "Inter_700Bold",
    textAlign: "right",
    paddingTop: 6,
    letterSpacing: -0.2,
    marginLeft: -COL.tutarShift,
  },
  swipeDelete: {
    width: SWIPE_DELETE_WIDTH,
    backgroundColor: "#e74c3c",
    alignItems: "center",
    justifyContent: "center",
    gap: 4,
  },
  swipeDeleteText: {
    color: "#fff",
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
  },
  emptyList: { alignItems: "center", paddingTop: 60, gap: 10, paddingHorizontal: 24 },
  emptyText: { fontSize: 13, fontFamily: "Inter_400Regular", textAlign: "center" },
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
  tanimOverlay: {
    flex: 1,
    backgroundColor: "rgba(15, 23, 42, 0.45)",
    justifyContent: "center",
    padding: 24,
  },
  tanimCard: {
    maxHeight: "70%",
    borderRadius: 14,
    borderWidth: 1,
    padding: 16,
    gap: 8,
  },
  tanimHeader: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    gap: 12,
  },
  tanimPoz: { fontSize: 14, fontFamily: "Inter_700Bold", flex: 1 },
  tanimLabel: {
    fontSize: 10,
    fontFamily: "Inter_600SemiBold",
    textTransform: "uppercase",
    letterSpacing: 0.4,
  },
  tanimScroll: { maxHeight: 280 },
  tanimBody: {
    fontSize: 14,
    fontFamily: "Inter_400Regular",
    lineHeight: 22,
  },
});
