import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useMemo, useState } from "react";
import {
  ActivityIndicator,
  FlatList,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { SantijetLogo } from "@/components/SantijetLogo";
import { matchesPozAnalizSearch } from "@/constants/pozAnalizleri";
import { useMergedPozAnalizleri } from "@/hooks/useMergedPozAnalizleri";
import { useColors } from "@/hooks/useColors";

const TILE_COLOR = "#d97706";

export default function HomeScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 67 : insets.top;

  const { pozAnalizleri, loading } = useMergedPozAnalizleri();
  const [search, setSearch] = useState("");

  const filtered = useMemo(() => {
    if (!search.trim()) return [];
    return pozAnalizleri
      .filter((a) => matchesPozAnalizSearch(a, search))
      .sort((a, b) => a.pozNo.localeCompare(b.pozNo, "tr"));
  }, [pozAnalizleri, search]);

  const searching = search.trim().length > 0;

  function openAnaliz(id: string) {
    router.push({ pathname: "/imalat-pozlari", params: { id } } as any);
  }

  function openAnalizListesi() {
    router.push({
      pathname: "/imalat-pozlari",
      params: searching ? { q: search.trim() } : undefined,
    } as any);
  }

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
          <SantijetLogo iconHeight={76} centered stacked />
          <Text style={styles.headerSubtitle}>BİRİM FİYAT ANALİZLERİ</Text>
        </View>
      </View>

      <View
        style={[
          styles.searchWrap,
          { backgroundColor: colors.card, borderColor: colors.border },
        ]}
      >
        <Feather name="search" size={16} color={colors.mutedForeground} />
        <TextInput
          style={[styles.searchInput, { color: colors.foreground }]}
          placeholder="Poz No veya analiz adı ara..."
          placeholderTextColor={colors.mutedForeground}
          value={search}
          onChangeText={setSearch}
        />
        {search.length > 0 && (
          <TouchableOpacity onPress={() => setSearch("")}>
            <Feather name="x" size={16} color={colors.mutedForeground} />
          </TouchableOpacity>
        )}
      </View>

      {searching ? (
        <>
          <View
            style={[
              styles.listHeader,
              { backgroundColor: colors.card, borderColor: colors.border },
            ]}
          >
            <Text style={[styles.listTh, { width: 36, color: colors.mutedForeground }]}>#</Text>
            <Text style={[styles.listTh, { width: 104, color: colors.mutedForeground }]}>
              Poz No
            </Text>
            <Text style={[styles.listTh, { flex: 1, color: colors.mutedForeground }]}>
              Analizin Adı
            </Text>
            <Text
              style={[
                styles.listTh,
                { width: 44, textAlign: "right", color: colors.mutedForeground },
              ]}
            >
              Birim
            </Text>
          </View>

          <FlatList
            data={filtered}
            keyExtractor={(item) => item.id}
            extraData={`${search}|${filtered.length}`}
            style={{ flex: 1 }}
            keyboardShouldPersistTaps="handled"
            contentContainerStyle={{ paddingBottom: insets.bottom + 24 }}
            renderItem={({ item, index }) => (
              <TouchableOpacity
                style={[
                  styles.listRow,
                  {
                    borderColor: colors.border,
                    backgroundColor: index % 2 === 0 ? colors.background : colors.card + "66",
                  },
                ]}
                onPress={() => openAnaliz(item.id)}
                activeOpacity={0.75}
              >
                <Text style={[styles.tdNo, { color: colors.mutedForeground }]}>{index + 1}</Text>
                <Text style={[styles.tdPoz, { color: colors.primary }]}>{item.pozNo}</Text>
                <Text style={[styles.tdAd, { color: colors.foreground }]} numberOfLines={2}>
                  {item.analizAdi}
                </Text>
                <Text style={[styles.tdBirim, { color: colors.mutedForeground }]}>
                  {item.olcuBirimi}
                </Text>
              </TouchableOpacity>
            )}
            ListEmptyComponent={
              loading ? (
                <View style={styles.emptyWrap}>
                  <ActivityIndicator size="small" color={TILE_COLOR} />
                </View>
              ) : (
                <View style={styles.emptyWrap}>
                  <Feather name="inbox" size={40} color={colors.mutedForeground} />
                  <Text style={{ color: colors.mutedForeground, marginTop: 12, fontSize: 14 }}>
                    Analiz bulunamadı
                  </Text>
                </View>
              )
            }
          />
        </>
      ) : (
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
              ŞANTİJET B.F.A.
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
          onPress={openAnalizListesi}
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
              BİRİM FİYAT ANALİZLERİ
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
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  hero: {
    width: "100%",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 16,
    paddingBottom: 12,
  },
  headerBrand: {
    alignItems: "center",
    justifyContent: "center",
    width: "100%",
    gap: 10,
  },
  headerSubtitle: {
    color: "#4a6080",
    fontSize: 18,
    fontFamily: "Inter_700Bold",
    letterSpacing: 5,
    textAlign: "center",
    marginTop: 2,
  },
  scroll: { padding: 12, paddingTop: 14 },
  searchWrap: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    marginHorizontal: 12,
    marginTop: 12,
    marginBottom: 8,
    borderRadius: 10,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  searchInput: {
    flex: 1,
    fontSize: 14,
    fontFamily: "Inter_400Regular",
    padding: 0,
  },
  listHeader: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    gap: 8,
  },
  listTh: {
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
    textTransform: "uppercase",
    letterSpacing: 0.4,
  },
  listRow: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderBottomWidth: 1,
    gap: 8,
  },
  tdNo: {
    width: 36,
    fontSize: 12,
    fontFamily: "Inter_400Regular",
  },
  tdPoz: {
    width: 104,
    fontSize: 12,
    fontFamily: "Inter_600SemiBold",
  },
  tdAd: {
    flex: 1,
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    lineHeight: 18,
  },
  tdBirim: {
    width: 44,
    fontSize: 11,
    fontFamily: "Inter_500Medium",
    textAlign: "right",
  },
  emptyWrap: {
    alignItems: "center",
    paddingTop: 60,
    paddingBottom: 24,
  },
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
