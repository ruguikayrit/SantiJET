import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React from "react";
import {
  ActivityIndicator,
  Dimensions,
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
const SCREEN_H = Dimensions.get("window").height;

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
          styles.hero,
          { backgroundColor: colors.secondary, paddingTop: topPad },
        ]}
      >
        <View style={styles.headerBrand}>
          <SantijetLogo iconHeight={40} centered />
          <Text style={styles.headerSubtitle}>İMALAT POZ ANALİZLERİ</Text>
        </View>
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
            <Text style={styles.buildTag}>Sürüm 1.0.2 · edcafbe</Text>
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
          style={[
            styles.tileInner,
            {
              backgroundColor: colors.card,
              borderColor: TILE_COLOR + "33",
            },
          ]}
        >
          <View style={[styles.tileIconCircle, { backgroundColor: TILE_COLOR + "1e" }]}>
            <Feather name="layers" size={26} color={TILE_COLOR} />
          </View>
          <View style={styles.tileBody}>
            <Text style={styles.tileNum}>01</Text>
            <Text style={[styles.tileLabel, { color: colors.cardForeground }]}>
              İMALAT POZ ANALİZLERİ
            </Text>
            <View style={styles.tileFootRow}>
              <View style={[styles.tileDot, { backgroundColor: TILE_COLOR }]} />
              {loading ? (
                <ActivityIndicator size="small" color={TILE_COLOR} />
              ) : (
                <Text style={[styles.tileInfo, { color: TILE_COLOR }]} numberOfLines={1}>
                  {pozAnalizleri.length} Analiz
                </Text>
              )}
            </View>
          </View>
          <View style={[styles.tileChevCircle, { borderColor: TILE_COLOR + "55" }]}>
            <Feather name="chevron-right" size={14} color={TILE_COLOR} />
          </View>
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  hero: {
    width: "100%",
    minHeight: Math.min(SCREEN_H * 0.34, 280),
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 16,
    paddingBottom: 20,
  },
  headerBrand: {
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
  },
  headerSubtitle: {
    color: "#4a6080",
    fontSize: 9,
    fontFamily: "Inter_700Bold",
    letterSpacing: 2.5,
    textAlign: "center",
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
  buildTag: {
    marginTop: 10,
    fontSize: 10,
    fontFamily: "Inter_600SemiBold",
    color: "#64748b",
    letterSpacing: 0.4,
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
  tileInner: {
    width: "100%",
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
    padding: 16,
    borderRadius: 14,
    borderWidth: 1,
    marginBottom: 12,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
  },
  tileBody: {
    flex: 1,
    gap: 4,
  },
  tileNum: {
    fontSize: 10,
    fontFamily: "Inter_700Bold",
    color: "#334155",
    letterSpacing: 0.5,
  },
  tileIconCircle: {
    width: 52,
    height: 52,
    borderRadius: 26,
    justifyContent: "center",
    alignItems: "center",
  },
  tileLabel: {
    fontSize: 13,
    fontFamily: "Inter_700Bold",
    letterSpacing: 0.4,
  },
  tileFootRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginTop: 2,
  },
  tileDot: {
    width: 5,
    height: 5,
    borderRadius: 3,
  },
  tileInfo: {
    fontSize: 12,
    fontFamily: "Inter_500Medium",
  },
  tileChevCircle: {
    width: 32,
    height: 32,
    borderRadius: 16,
    borderWidth: 1,
    justifyContent: "center",
    alignItems: "center",
  },
});
