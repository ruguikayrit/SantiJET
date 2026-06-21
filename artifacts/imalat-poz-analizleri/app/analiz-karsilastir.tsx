import { Feather } from "@expo/vector-icons";
import { useLocalSearchParams, useRouter } from "expo-router";
import React, { useMemo, useState } from "react";
import {
  ActivityIndicator,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { BulkExportModal } from "@/components/BulkExportModal";
import { buildAnalizCompare, trFmtCompare } from "@/lib/analizCompare";
import { AnalizExportFormat, PdfPaperOrientation, waitForShareSheet } from "@/lib/analizExport";
import { exportCompare } from "@/lib/compareExport";
import { useBfaCatalog } from "@/hooks/useBfaCatalog";
import { useColors } from "@/hooks/useColors";

const TIP_LABEL: Record<string, string> = {
  malzeme: "Malzeme",
  iscilik: "İşçilik",
  ekipman: "Ekipman",
};

export default function AnalizKarsilastirScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;
  const params = useLocalSearchParams<{ ids?: string }>();
  const [exportVisible, setExportVisible] = useState(false);

  const { all, loading, error } = useBfaCatalog();

  const analizIds = useMemo(() => {
    const raw = params.ids ? String(params.ids) : "";
    return raw.split(",").map((s) => s.trim()).filter(Boolean);
  }, [params.ids]);

  const analizler = useMemo(() => {
    return analizIds.map((id) => all.find((a) => a.id === id)).filter(Boolean) as typeof all;
  }, [analizIds, all]);

  const compare = useMemo(() => {
    if (analizler.length < 2) return null;
    return buildAnalizCompare(analizler);
  }, [analizler]);

  async function handleExportCompare(format: AnalizExportFormat, pdfOrientation?: PdfPaperOrientation) {
    setExportVisible(false);
    await waitForShareSheet();
    await exportCompare(analizler, format, { pdfOrientation });
  }

  if (loading) {
    return (
      <View style={[styles.center, { backgroundColor: colors.background }]}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  if (error) {
    return (
      <View style={[styles.center, { backgroundColor: colors.background, padding: 24 }]}>
        <Feather name="alert-circle" size={40} color={colors.destructive} />
        <Text style={{ color: colors.foreground, marginTop: 16, textAlign: "center" }}>{error}</Text>
      </View>
    );
  }

  if (analizler.length < 2) {
    return (
      <View style={{ flex: 1, backgroundColor: colors.background }}>
        <Header colors={colors} topPad={topPad} onBack={() => router.back()} />
        <View style={[styles.center, { flex: 1, padding: 24 }]}>
          <Feather name="layers" size={40} color={colors.mutedForeground} />
          <Text style={{ color: colors.mutedForeground, marginTop: 12, textAlign: "center" }}>
            Karşılaştırma için en az 2 analiz seçin.
          </Text>
        </View>
      </View>
    );
  }

  if (!compare) return null;

  const colMin = 140;

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      <Header
        colors={colors}
        topPad={topPad}
        onBack={() => router.back()}
        onExport={() => setExportVisible(true)}
      />

      <BulkExportModal
        visible={exportVisible}
        count={analizler.length}
        title="Karşılaştırmayı Dışa Aktar"
        subtitle={`${analizler.length} analizin karşılaştırma raporu`}
        onClose={() => setExportVisible(false)}
        onSelect={handleExportCompare}
      />

      <ScrollView
        horizontal
        showsHorizontalScrollIndicator
        contentContainerStyle={{ paddingBottom: insets.bottom + 16 }}
      >
        <View>
          {/* Özet kartları */}
          <View style={[styles.section, { borderColor: colors.border, backgroundColor: colors.card }]}>
            <Text style={[styles.sectionTitle, { color: colors.foreground }]}>Birim Fiyat Özeti</Text>
            <View style={[styles.summaryHeader, { borderColor: colors.border }]}>
              <Text style={[styles.th, { width: 180, color: colors.mutedForeground }]}>Analiz</Text>
              {compare.analizler.map((a) => (
                <View key={a.id} style={[styles.summaryCol, { width: colMin, borderColor: colors.border }]}>
                  <Text style={[styles.pozNo, { color: colors.primary }]} numberOfLines={1}>
                    {a.pozNo}
                  </Text>
                  <Text style={[styles.analizAd, { color: colors.foreground }]} numberOfLines={2}>
                    {a.analizAdi}
                  </Text>
                </View>
              ))}
            </View>

            {[
              { label: "Malzeme + İşçilik", key: "malzemeIscilikToplami" as const },
              { label: "Yüklenici Karı", key: "yukleniciKarTutari" as const },
              { label: "1 Birim Fiyatı", key: "birimFiyati" as const, highlight: true },
            ].map((row) => (
              <View key={row.key} style={[styles.summaryRow, { borderColor: colors.border }]}>
                <Text style={[styles.rowLabel, { width: 180, color: colors.foreground }]}>{row.label}</Text>
                {compare.analizler.map((a) => {
                  const val = a[row.key];
                  const isMin = row.highlight && val === compare.minBirimFiyati && compare.analizler.length > 1;
                  const isMax = row.highlight && val === compare.maxBirimFiyati && compare.analizler.length > 1;
                  const bg =
                    isMin ? "#05966918" : isMax ? "#dc262618" : "transparent";
                  return (
                    <View
                      key={a.id}
                      style={[
                        styles.summaryVal,
                        { width: colMin, borderColor: colors.border, backgroundColor: bg },
                      ]}
                    >
                      <Text
                        style={[
                          styles.valText,
                          {
                            color: row.highlight ? colors.primary : colors.foreground,
                            fontFamily: row.highlight ? "Inter_700Bold" : "Inter_500Medium",
                          },
                        ]}
                      >
                        {trFmtCompare(val)} TL
                      </Text>
                      {row.key === "birimFiyati" && (
                        <Text style={[styles.unitHint, { color: colors.mutedForeground }]}>
                          / {a.olcuBirimi}
                        </Text>
                      )}
                    </View>
                  );
                })}
              </View>
            ))}
          </View>

          {/* Kalem karşılaştırma */}
          <View style={[styles.section, { borderColor: colors.border, backgroundColor: colors.card, marginTop: 12 }]}>
            <Text style={[styles.sectionTitle, { color: colors.foreground }]}>Kalem Karşılaştırması</Text>
            <Text style={[styles.sectionSub, { color: colors.mutedForeground }]}>
              Yeşil: en düşük tutar · Kırmızı: en yüksek tutar
            </Text>

            <View style={[styles.kalemHeader, { borderColor: colors.border, backgroundColor: colors.background }]}>
              <Text style={[styles.th, { width: 72, color: colors.mutedForeground }]}>Tip</Text>
              <Text style={[styles.th, { width: 88, color: colors.mutedForeground }]}>Poz</Text>
              <Text style={[styles.th, { width: 160, color: colors.mutedForeground }]}>Tanım</Text>
              {compare.analizler.map((a) => (
                <Text
                  key={a.id}
                  style={[styles.th, { width: colMin, color: colors.mutedForeground, textAlign: "center" }]}
                  numberOfLines={1}
                >
                  {a.pozNo}
                </Text>
              ))}
            </View>

            {compare.kalemRows.map((row) => {
              const tutarlar = compare.analizler
                .map((a) => row.values[a.id]?.tutar ?? null)
                .filter((v): v is number => v !== null);
              const minT = tutarlar.length ? Math.min(...tutarlar) : null;
              const maxT = tutarlar.length ? Math.max(...tutarlar) : null;

              return (
                <View key={row.key} style={[styles.kalemRow, { borderColor: colors.border }]}>
                  <Text style={[styles.td, { width: 72, color: colors.mutedForeground }]}>
                    {TIP_LABEL[row.tip]}
                  </Text>
                  <Text style={[styles.td, { width: 88, color: colors.primary, fontFamily: "Inter_600SemiBold" }]}>
                    {row.pozNo || "—"}
                  </Text>
                  <Text style={[styles.td, { width: 160, color: colors.foreground }]} numberOfLines={2}>
                    {row.tanim || "—"}
                  </Text>
                  {compare.analizler.map((a) => {
                    const v = row.values[a.id];
                    const bg =
                      v && minT !== null && maxT !== null && minT !== maxT
                        ? v.tutar === minT
                          ? "#05966914"
                          : v.tutar === maxT
                            ? "#dc262614"
                            : "transparent"
                        : "transparent";
                    return (
                      <View
                        key={a.id}
                        style={[styles.kalemVal, { width: colMin, borderColor: colors.border, backgroundColor: bg }]}
                      >
                        {v ? (
                          <>
                            <Text style={[styles.kalemTutar, { color: colors.foreground }]}>
                              {trFmtCompare(v.tutar)} TL
                            </Text>
                            <Text style={[styles.kalemDetail, { color: colors.mutedForeground }]}>
                              {trFmtCompare(v.miktar)} × {trFmtCompare(v.birimFiyati)}
                            </Text>
                          </>
                        ) : (
                          <Text style={[styles.kalemDetail, { color: colors.mutedForeground }]}>—</Text>
                        )}
                      </View>
                    );
                  })}
                </View>
              );
            })}

            {!compare.kalemRows.length && (
              <Text style={[styles.empty, { color: colors.mutedForeground }]}>
                Ortak kalem bulunamadı.
              </Text>
            )}
          </View>
        </View>
      </ScrollView>
    </View>
  );
}

function Header({
  colors,
  topPad,
  onBack,
  onExport,
}: {
  colors: ReturnType<typeof useColors>;
  topPad: number;
  onBack: () => void;
  onExport?: () => void;
}) {
  return (
    <View
      style={[
        styles.header,
        { backgroundColor: colors.secondary, paddingTop: topPad + 12 },
      ]}
    >
      <TouchableOpacity onPress={onBack} style={styles.backBtn}>
        <Feather name="arrow-left" size={22} color={colors.secondaryForeground} />
      </TouchableOpacity>
      <Text style={[styles.headerTitle, { color: colors.secondaryForeground }]}>
        Analiz Karşılaştırma
      </Text>
      {onExport ? (
        <TouchableOpacity onPress={onExport} style={styles.backBtn}>
          <Feather name="download" size={20} color={colors.secondaryForeground} />
        </TouchableOpacity>
      ) : (
        <View style={{ width: 40 }} />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  center: {
    justifyContent: "center",
    alignItems: "center",
  },
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
  section: {
    margin: 12,
    borderRadius: 12,
    borderWidth: 1,
    padding: 12,
    gap: 8,
  },
  sectionTitle: {
    fontSize: 15,
    fontFamily: "Inter_700Bold",
  },
  sectionSub: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    marginBottom: 4,
  },
  summaryHeader: {
    flexDirection: "row",
    borderBottomWidth: 1,
    paddingBottom: 8,
    marginTop: 4,
  },
  summaryCol: {
    paddingHorizontal: 8,
    borderLeftWidth: StyleSheet.hairlineWidth,
    gap: 2,
  },
  pozNo: {
    fontSize: 11,
    fontFamily: "Inter_700Bold",
  },
  analizAd: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    lineHeight: 15,
  },
  summaryRow: {
    flexDirection: "row",
    borderBottomWidth: StyleSheet.hairlineWidth,
    alignItems: "center",
    minHeight: 40,
  },
  rowLabel: {
    fontSize: 12,
    fontFamily: "Inter_600SemiBold",
    paddingHorizontal: 4,
  },
  summaryVal: {
    paddingHorizontal: 8,
    paddingVertical: 6,
    borderLeftWidth: StyleSheet.hairlineWidth,
    justifyContent: "center",
  },
  valText: {
    fontSize: 12,
    textAlign: "right",
  },
  unitHint: {
    fontSize: 10,
    textAlign: "right",
    marginTop: 2,
  },
  th: {
    fontSize: 10,
    fontFamily: "Inter_600SemiBold",
    textTransform: "uppercase",
    paddingHorizontal: 4,
    paddingVertical: 6,
  },
  kalemHeader: {
    flexDirection: "row",
    borderWidth: 1,
    borderRadius: 8,
    marginTop: 4,
  },
  kalemRow: {
    flexDirection: "row",
    borderBottomWidth: StyleSheet.hairlineWidth,
    alignItems: "stretch",
  },
  td: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    paddingHorizontal: 4,
    paddingVertical: 8,
  },
  kalemVal: {
    paddingHorizontal: 6,
    paddingVertical: 6,
    borderLeftWidth: StyleSheet.hairlineWidth,
    justifyContent: "center",
  },
  kalemTutar: {
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
    textAlign: "right",
  },
  kalemDetail: {
    fontSize: 9,
    fontFamily: "Inter_400Regular",
    textAlign: "right",
    marginTop: 2,
  },
  empty: {
    textAlign: "center",
    paddingVertical: 24,
    fontSize: 13,
    fontFamily: "Inter_400Regular",
  },
});
