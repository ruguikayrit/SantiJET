import { Feather } from "@expo/vector-icons";
import { useLocalSearchParams, useRouter } from "expo-router";
import React, { useMemo, useState } from "react";
import {
  Alert,
  FlatList,
  Platform,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { BulkExportModal } from "@/components/BulkExportModal";
import { KesifPozPickerModal } from "@/components/KesifPozPickerModal";
import { hesaplaKesifToplam, trFmtKesif } from "@/constants/kesif";
import { PozAnaliz } from "@/constants/pozAnalizleri";
import { useKesif } from "@/context/KesifContext";
import { useBfaCatalog } from "@/hooks/useBfaCatalog";
import { useColors } from "@/hooks/useColors";
import { AnalizExportFormat, PdfPaperOrientation, waitForShareSheet } from "@/lib/analizExport";
import { exportKesif } from "@/lib/kesifExport";

const KESIF_COLOR = "#7c3aed";

export default function KesifDetailScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;
  const params = useLocalSearchParams<{ id?: string }>();
  const projectId = params.id ? String(params.id) : "";

  const { getProject, addSatir, updateSatirMiktar, removeSatir, deleteProject } = useKesif();
  const { all } = useBfaCatalog();

  const project = getProject(projectId);
  const [pickerVisible, setPickerVisible] = useState(false);
  const [exportVisible, setExportVisible] = useState(false);

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
    addSatir(projectId, analiz, miktar);
  }

  function handleDeleteSatir(satirId: string) {
    removeSatir(projectId, satirId);
  }

  function handleDeleteProject() {
    Alert.alert("Keşifi Sil", `"${kesif.ad}" silinsin mi?`, [
      { text: "İptal", style: "cancel" },
      {
        text: "Sil",
        style: "destructive",
        onPress: () => {
          deleteProject(projectId);
          router.back();
        },
      },
    ]);
  }

  async function handleExport(format: AnalizExportFormat, pdfOrientation?: PdfPaperOrientation) {
    setExportVisible(false);
    await waitForShareSheet();
    await exportKesif(kesif, format, { pdfOrientation });
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
      </View>

      <View style={[styles.summary, { backgroundColor: colors.card, borderColor: colors.border }]}>
        <View>
          <Text style={[styles.summaryLabel, { color: colors.mutedForeground }]}>Genel Toplam</Text>
          <Text style={[styles.summaryTotal, { color: KESIF_COLOR }]}>
            {trFmtKesif(toplam)} TL
          </Text>
        </View>
        <View style={styles.summaryRight}>
          <Text style={[styles.summaryMeta, { color: colors.mutedForeground }]}>
            {project.satirlar.length} poz
          </Text>
          <TouchableOpacity onPress={handleDeleteProject} hitSlop={8}>
            <Feather name="trash-2" size={16} color="#e74c3c" />
          </TouchableOpacity>
        </View>
      </View>

      <View
        style={[styles.tableHeader, { backgroundColor: colors.card, borderColor: colors.border }]}
      >
        <Text style={[styles.th, { width: 28, color: colors.mutedForeground }]}>#</Text>
        <Text style={[styles.th, { width: 88, color: colors.mutedForeground }]}>Poz</Text>
        <Text style={[styles.th, { flex: 1, color: colors.mutedForeground }]}>Tanım</Text>
        <Text style={[styles.th, { width: 64, color: colors.mutedForeground, textAlign: "right" }]}>
          Miktar
        </Text>
        <Text style={[styles.th, { width: 72, color: colors.mutedForeground, textAlign: "right" }]}>
          Tutar
        </Text>
        <View style={{ width: 28 }} />
      </View>

      <FlatList
        data={project.satirlar}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ paddingBottom: insets.bottom + 88 }}
        ListEmptyComponent={
          <View style={styles.emptyList}>
            <Feather name="plus-circle" size={36} color={colors.mutedForeground} />
            <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>
              Katalogdan poz ekleyerek keşfe başlayın
            </Text>
          </View>
        }
        renderItem={({ item, index }) => (
          <View
            style={[
              styles.row,
              {
                borderColor: colors.border,
                backgroundColor: index % 2 === 0 ? colors.background : colors.card + "66",
              },
            ]}
          >
            <Text style={[styles.td, { width: 28, color: colors.mutedForeground }]}>{index + 1}</Text>
            <TouchableOpacity
              style={{ width: 88 }}
              onPress={() => {
                const analiz = resolveAnaliz(item.analizId);
                if (analiz) {
                  router.push({
                    pathname: "/imalat-pozlari",
                    params: { id: analiz.id, modul: analiz.discipline ?? "insaat" },
                  } as any);
                }
              }}
            >
              <Text style={[styles.tdPoz, { color: colors.primary }]}>{item.pozNo}</Text>
            </TouchableOpacity>
            <View style={{ flex: 1, paddingRight: 4 }}>
              <Text style={[styles.tdAd, { color: colors.foreground }]} numberOfLines={2}>
                {item.analizAdi}
              </Text>
              <Text style={[styles.tdUnit, { color: colors.mutedForeground }]}>
                {trFmtKesif(item.birimFiyati)} TL / {item.olcuBirimi}
              </Text>
            </View>
            <TextInput
              style={[
                styles.qtyInput,
                { color: colors.foreground, borderColor: colors.border, backgroundColor: colors.card },
              ]}
              value={String(item.miktar)}
              onChangeText={(v) => updateSatirMiktar(projectId, item.id, parseQty(v))}
              keyboardType="decimal-pad"
              selectTextOnFocus
            />
            <Text style={[styles.tdTutar, { width: 72, color: colors.foreground }]}>
              {trFmtKesif(item.tutar)}
            </Text>
            <TouchableOpacity
              onPress={() => handleDeleteSatir(item.id)}
              style={styles.delBtn}
              hitSlop={8}
            >
              <Feather name="x" size={16} color={colors.mutedForeground} />
            </TouchableOpacity>
          </View>
        )}
      />

      <TouchableOpacity
        style={[styles.fab, { backgroundColor: KESIF_COLOR, bottom: insets.bottom + 16 }]}
        onPress={() => setPickerVisible(true)}
      >
        <Feather name="plus" size={24} color="#fff" />
      </TouchableOpacity>

      <KesifPozPickerModal
        visible={pickerVisible}
        onClose={() => setPickerVisible(false)}
        onSelect={handleAddSatir}
      />

      <BulkExportModal
        visible={exportVisible}
        count={project.satirlar.length}
        title="Keşifi Dışa Aktar"
        subtitle="Metraj cetveli PDF veya Excel olarak"
        pdfHint="Yazdırılabilir keşif cetveli"
        excelHint="Excel ve Numbers ile açılır"
        orientationHint="Keşif cetveli için kağıt yönü"
        onClose={() => setExportVisible(false)}
        onSelect={handleExport}
      />
    </View>
  );
}

function parseQty(s: string): number {
  const v = parseFloat(s.replace(",", "."));
  return Number.isFinite(v) ? v : 0;
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
  summaryRight: { alignItems: "flex-end", gap: 8 },
  summaryMeta: { fontSize: 12, fontFamily: "Inter_500Medium" },
  tableHeader: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    gap: 4,
  },
  th: { fontSize: 10, fontFamily: "Inter_600SemiBold", textTransform: "uppercase" },
  row: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderBottomWidth: StyleSheet.hairlineWidth,
    gap: 4,
  },
  td: { fontSize: 11, fontFamily: "Inter_400Regular" },
  tdPoz: { fontSize: 11, fontFamily: "Inter_700Bold" },
  tdAd: { fontSize: 12, fontFamily: "Inter_400Regular", lineHeight: 16 },
  tdUnit: { fontSize: 10, fontFamily: "Inter_400Regular", marginTop: 2 },
  qtyInput: {
    width: 64,
    fontSize: 12,
    fontFamily: "Inter_600SemiBold",
    borderWidth: 1,
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 4,
    textAlign: "right",
  },
  tdTutar: {
    fontSize: 12,
    fontFamily: "Inter_700Bold",
    textAlign: "right",
  },
  delBtn: { width: 28, alignItems: "center" },
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
});
