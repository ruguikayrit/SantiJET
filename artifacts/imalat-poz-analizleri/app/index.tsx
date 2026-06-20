import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React from "react";
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

import { SantijetLogo } from "@/components/SantijetLogo";
import { useMergedPozAnalizleri } from "@/hooks/useMergedPozAnalizleri";
import { useColors } from "@/hooks/useColors";

const TILE_COLOR = "#d97706";

export default function HomeScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 67 : insets.top;

  const { pozAnalizleri, loading } = useMergedPozAnalizleri();

  const today = new Date();
  const dateStr = today.toLocaleDateString("tr-TR", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
  const dayStr = today.toLocaleDateString("tr-TR", { weekday: "long" });

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <View
        style={[
          styles.appHeader,
          { backgroundColor: colors.secondary, paddingTop: topPad + 8 },
        ]}
      >
        <View style={styles.headerSpacer} />
        <View style={styles.headerLogoArea}>
          <SantijetLogo iconHeight={34} />
          <Text style={styles.headerSubtitle}>İMALAT POZ ANALİZLERİ</Text>
        </View>
        <View style={styles.headerSpacer} />
      </View>

      <ScrollView
        contentContainerStyle={[styles.scroll, { paddingBottom: insets.bottom + 24 }]}
        showsVerticalScrollIndicator={false}
      >
        <View
          style={[
            styles.welcomeCard,
            { backgroundColor: colors.secondary, borderColor: "rgba(255,255,255,0.07)" },
          ]}
        >
          <View style={styles.welcomeLeft}>
            <Text style={styles.welcomeGreet}>Hoş geldiniz</Text>
            <Text style={[styles.welcomeName, { color: colors.secondaryForeground }]}>
              ŞANTİJET İPA
            </Text>
            <Text style={styles.welcomeRole}>
              Resmi analiz tabloları, fiyat hesaplamaları ve özel analizler
            </Text>
          </View>

          <View style={styles.welcomeDateBlock}>
            <Feather name="calendar" size={16} color="#60a5fa" />
            <Text style={[styles.welcomeDateMain, { color: colors.secondaryForeground }]}>
              {dateStr}
            </Text>
            <Text style={styles.welcomeDateSub}>{dayStr}</Text>
          </View>
        </View>

        <Text style={[styles.sectionLabel, { color: colors.foreground }]}>Modüller</Text>

        <TouchableOpacity
          activeOpacity={0.85}
          onPress={() => router.push("/imalat-pozlari" as any)}
          style={styles.tileWrap}
        >
          <View
            style={[
              styles.tileInner,
              {
                backgroundColor: colors.card,
                borderColor: TILE_COLOR + "33",
              },
            ]}
          >
            <View style={styles.tileTopRow}>
              <Text style={styles.tileNum}>01</Text>
            </View>

            <View style={styles.tileIconWrap}>
              <View style={[styles.tileIconCircle, { backgroundColor: TILE_COLOR + "1e" }]}>
                <Feather name="layers" size={26} color={TILE_COLOR} />
              </View>
            </View>

            <Text style={[styles.tileLabel, { color: colors.cardForeground }]}>
              İMALAT POZ ANALİZLERİ
            </Text>

            <View style={styles.tileFootRow}>
              <View style={[styles.tileDot, { backgroundColor: TILE_COLOR }]} />
              {loading ? (
                <ActivityIndicator size="small" color={TILE_COLOR} style={{ flex: 1 }} />
              ) : (
                <Text style={[styles.tileInfo, { color: TILE_COLOR }]} numberOfLines={1}>
                  {pozAnalizleri.length} Analiz
                </Text>
              )}
              <View style={[styles.tileChevCircle, { borderColor: TILE_COLOR + "55" }]}>
                <Feather name="chevron-right" size={9} color={TILE_COLOR} />
              </View>
            </View>
          </View>
        </TouchableOpacity>

        <TouchableOpacity
          style={[
            styles.infoBtn,
            { backgroundColor: colors.card, borderColor: colors.primary + "40" },
          ]}
          onPress={() => router.push("/imalat-pozlari" as any)}
          activeOpacity={0.85}
        >
          <View style={[styles.infoIcon, { backgroundColor: colors.primary + "20" }]}>
            <Feather name="book-open" size={20} color={colors.primary} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={[styles.infoTitle, { color: colors.foreground }]}>
              Analiz Kataloğu
            </Text>
            <Text style={[styles.infoSub, { color: colors.mutedForeground }]}>
              Resmi tablolar, arama, düzenleme ve dışa aktarma
            </Text>
          </View>
          <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  appHeader: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 16,
    paddingBottom: 12,
    gap: 12,
  },
  headerSpacer: { width: 36 },
  headerLogoArea: {
    flex: 1,
    alignItems: "center",
    gap: 2,
  },
  headerSubtitle: {
    color: "#4a6080",
    fontSize: 8,
    fontFamily: "Inter_700Bold",
    letterSpacing: 2,
  },
  scroll: { padding: 12, paddingTop: 14 },
  welcomeCard: {
    flexDirection: "row",
    alignItems: "flex-start",
    borderRadius: 16,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    gap: 12,
  },
  welcomeLeft: { flex: 1 },
  welcomeGreet: {
    color: "#64748b",
    fontSize: 13,
    fontFamily: "Inter_400Regular",
  },
  welcomeName: {
    fontSize: 20,
    fontFamily: "Inter_700Bold",
    letterSpacing: 0.5,
    marginTop: 3,
  },
  welcomeRole: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    marginTop: 6,
    color: "#94a3b8",
    lineHeight: 18,
  },
  welcomeDateBlock: {
    alignItems: "flex-end",
    gap: 3,
    paddingTop: 2,
  },
  welcomeDateMain: {
    fontSize: 12,
    fontFamily: "Inter_600SemiBold",
    marginTop: 4,
    textAlign: "right",
  },
  welcomeDateSub: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    color: "#64748b",
  },
  sectionLabel: {
    fontSize: 16,
    fontFamily: "Inter_700Bold",
    marginBottom: 12,
    marginLeft: 4,
  },
  tileWrap: {
    width: "48%",
    minWidth: 140,
    aspectRatio: 0.92,
    marginBottom: 12,
  },
  tileInner: {
    flex: 1,
    padding: 10,
    borderRadius: 14,
    borderWidth: 1,
    overflow: "hidden",
    justifyContent: "space-between",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
  },
  tileTopRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  tileNum: {
    fontSize: 10,
    fontFamily: "Inter_700Bold",
    color: "#334155",
    letterSpacing: 0.5,
  },
  tileIconWrap: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    paddingVertical: 4,
  },
  tileIconCircle: {
    width: 50,
    height: 50,
    borderRadius: 25,
    justifyContent: "center",
    alignItems: "center",
  },
  tileLabel: {
    fontSize: 10,
    fontFamily: "Inter_700Bold",
    textAlign: "center",
    letterSpacing: 0.4,
  },
  tileFootRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
  },
  tileDot: {
    width: 5,
    height: 5,
    borderRadius: 3,
  },
  tileInfo: {
    flex: 1,
    fontSize: 9,
    fontFamily: "Inter_500Medium",
  },
  tileChevCircle: {
    width: 18,
    height: 18,
    borderRadius: 9,
    borderWidth: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  infoBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    padding: 14,
    borderRadius: 14,
    borderWidth: 1,
    marginTop: 4,
  },
  infoIcon: {
    width: 44,
    height: 44,
    borderRadius: 12,
    alignItems: "center",
    justifyContent: "center",
  },
  infoTitle: {
    fontSize: 15,
    fontFamily: "Inter_600SemiBold",
  },
  infoSub: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    marginTop: 2,
  },
});
