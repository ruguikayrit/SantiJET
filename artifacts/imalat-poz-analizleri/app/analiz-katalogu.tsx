import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useMemo, useState } from "react";
import {
  ActivityIndicator,
  FlatList,
  Platform,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { buildPozKategoriFiltreleri, normalizeTrSearch } from "@/constants/pozAnalizleri";
import { useBfaCatalog } from "@/hooks/useBfaCatalog";
import { useColors } from "@/hooks/useColors";

const TILE_COLOR = "#16a34a";

export default function AnalizKataloguScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;

  const { getModuleAnalizleri, loading, error } = useBfaCatalog();
  const pozAnalizleri = getModuleAnalizleri("insaat");
  const [search, setSearch] = useState("");

  const kategoriSayilari = useMemo(() => {
    const counts = new Map<string, number>();
    for (const a of pozAnalizleri) {
      const k = (a.kategori || "").trim();
      if (!k) continue;
      counts.set(k, (counts.get(k) ?? 0) + 1);
    }
    return counts;
  }, [pozAnalizleri]);

  const categories = useMemo(() => {
    const q = normalizeTrSearch(search);
    return buildPozKategoriFiltreleri(pozAnalizleri).filter((k) =>
      !q ? true : normalizeTrSearch(k).includes(q),
    );
  }, [pozAnalizleri, search]);

  function openCategory(cat: string) {
    router.push({
      pathname: "/imalat-pozlari",
      params: { modul: "insaat", cat },
    } as any);
  }

  if (error) {
    return (
      <View style={[styles.center, { backgroundColor: colors.background, padding: 24 }]}>
        <Feather name="alert-circle" size={40} color={colors.destructive} />
        <Text style={{ color: colors.foreground, marginTop: 16, textAlign: "center" }}>{error}</Text>
      </View>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      <View
        style={[styles.header, { backgroundColor: colors.secondary, paddingTop: topPad + 12 }]}
      >
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Feather name="arrow-left" size={22} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <View style={{ flex: 1, alignItems: "center" }}>
          <Text style={[styles.headerTitle, { color: colors.secondaryForeground }]}>
            Analiz Kataloğu
          </Text>
        </View>
        <View style={{ width: 40 }} />
      </View>

      <View
        style={[styles.searchWrap, { backgroundColor: colors.card, borderColor: colors.border }]}
      >
        <Feather name="search" size={20} color={colors.mutedForeground} />
        <TextInput
          style={[styles.searchInput, { color: colors.foreground }]}
          placeholder="Kategori ara..."
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

      <View
        style={[styles.listHeader, { backgroundColor: colors.card, borderColor: colors.border }]}
      >
        <Text style={[styles.listTh, { width: 36, color: colors.mutedForeground }]}>#</Text>
        <Text style={[styles.listTh, { flex: 1, color: colors.mutedForeground }]}>Kategori</Text>
        <Text
          style={[styles.listTh, { width: 72, textAlign: "right", color: colors.mutedForeground }]}
        >
          Analiz
        </Text>
      </View>

      {loading ? (
        <View style={styles.center}>
          <ActivityIndicator size="small" color={TILE_COLOR} />
        </View>
      ) : (
        <FlatList
          data={categories}
          keyExtractor={(item) => item}
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
              onPress={() => openCategory(item)}
              activeOpacity={0.75}
            >
              <Text style={[styles.tdNo, { color: colors.mutedForeground }]}>{index + 1}</Text>
              <Text style={[styles.tdAd, { color: colors.foreground }]} numberOfLines={2}>
                {item}
              </Text>
              <Text style={[styles.tdCount, { color: TILE_COLOR }]}>
                {kategoriSayilari.get(item) ?? 0}
              </Text>
            </TouchableOpacity>
          )}
          ListEmptyComponent={
            <View style={styles.center}>
              <Feather name="inbox" size={40} color={colors.mutedForeground} />
              <Text style={{ color: colors.mutedForeground, marginTop: 12, fontSize: 14 }}>
                Kategori bulunamadı
              </Text>
            </View>
          }
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingTop: 60,
    paddingBottom: 24,
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
    fontSize: 17,
    fontFamily: "Inter_700Bold",
    textAlign: "center",
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
    paddingVertical: 12,
    borderBottomWidth: 1,
    gap: 8,
  },
  tdNo: {
    width: 36,
    fontSize: 12,
    fontFamily: "Inter_400Regular",
  },
  tdAd: {
    flex: 1,
    fontSize: 13,
    fontFamily: "Inter_500Medium",
    lineHeight: 18,
  },
  tdCount: {
    width: 72,
    fontSize: 13,
    fontFamily: "Inter_700Bold",
    textAlign: "right",
  },
});
