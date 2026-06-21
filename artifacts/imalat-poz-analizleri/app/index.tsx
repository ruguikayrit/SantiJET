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
import { CreateAnalizFab } from "@/components/CreateAnalizFab";
import { NewAnalizModulePickerModal } from "@/components/NewAnalizModulePickerModal";
import { RecentViewsModal } from "@/components/RecentViewsModal";
import { SettingsModal } from "@/components/SettingsModal";
import { ModuleGrid } from "@/components/ModuleGrid";
import { ModuleTile } from "@/components/ModuleTile";
import { BFA_DISCIPLINES, BFA_MODULES, BfaDiscipline, resolveAnalizDiscipline, stripModuleLabelSuffix } from "@/constants/bfaModules";
import { matchesPozAnalizSearch } from "@/constants/pozAnalizleri";
import { useKesif } from "@/context/KesifContext";
import { useBfaCatalog } from "@/hooks/useBfaCatalog";
import { useColors } from "@/hooks/useColors";
import { useRecentViews } from "@/hooks/useRecentViews";

const TILE_COLOR = "#d97706";
const RECENT_COLOR = "#6366f1";
const KESIF_COLOR = "#7c3aed";
const KATALOG_COLOR = "#16a34a";

function moduleRouteParams(
  mod: (typeof BFA_MODULES)[number],
  searchQuery: string,
): Record<string, string> | undefined {
  const base = mod.route.params ? { ...mod.route.params } : undefined;
  if (!searchQuery || mod.route.pathname !== "/imalat-pozlari") return base;
  return { ...(base ?? {}), q: searchQuery };
}

function SourceDisclaimer({
  color,
  bottomInset,
}: {
  color: string;
  bottomInset: number;
}) {
  return (
    <View
      style={[
        styles.sourceDisclaimerWrap,
        { paddingBottom: bottomInset + 24, paddingTop: 20 },
      ]}
    >
      <Text style={[styles.sourceDisclaimer, { color }]}>
        Bu uygulama resmi kurumlarla bağlantılı değildir.
      </Text>
      <Text style={[styles.sourceDisclaimer, { color }]}>
        Veriler kamu kurumlarının yayımladığı resmi kaynaklardan derlenmiştir.
      </Text>
      <Text style={[styles.sourceDisclaimer, { color }]}>
        Nihai doğrulama için ilgili kurumların güncel yayınları esas alınmalıdır.
      </Text>
    </View>
  );
}

export default function HomeScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 67 : insets.top;

  const { stats, all, loading } = useBfaCatalog();
  const { projects: kesifProjects, loaded: kesifLoaded } = useKesif();
  const { entries: recentEntries, loaded: recentLoaded, recordView } = useRecentViews();
  const [search, setSearch] = useState("");
  const [newAnalizPickerVisible, setNewAnalizPickerVisible] = useState(false);
  const [settingsVisible, setSettingsVisible] = useState(false);
  const [recentVisible, setRecentVisible] = useState(false);

  const filtered = useMemo(() => {
    if (!search.trim()) return [];
    return all
      .filter((a) => matchesPozAnalizSearch(a, search))
      .sort((a, b) => a.pozNo.localeCompare(b.pozNo, "tr"));
  }, [all, search]);

  const searching = search.trim().length > 0;

  function openAnaliz(id: string) {
    void recordView(id);
    const analiz = all.find((a) => a.id === id);
    const modul = analiz ? resolveAnalizDiscipline(analiz) : "insaat";
    router.push({ pathname: "/imalat-pozlari", params: { id, modul } } as any);
  }

  const recentAnalizler = useMemo(() => {
    if (!recentLoaded) return [];
    return recentEntries
      .map((e) => all.find((a) => a.id === e.id))
      .filter((a): a is NonNullable<typeof a> => a != null);
  }, [recentEntries, recentLoaded, all]);

  const katalogOzet = useMemo(() => {
    if (loading) return "Yükleniyor…";
    const parts = BFA_DISCIPLINES.map((d) => {
      const mod = BFA_MODULES.find((m) => m.modul === d);
      const short = stripModuleLabelSuffix(mod?.label ?? d).replace(" TESİSAT", "");
      const catSet = new Set<string>();
      for (const a of stats[d]) {
        const k = a.kategori?.trim();
        if (k) catSet.add(k);
      }
      return `${short} ${catSet.size}`;
    });
    return parts.join(" · ");
  }, [loading, stats]);

  function openNewAnaliz() {
    setNewAnalizPickerVisible(true);
  }

  function startNewAnalizInModule(modul: BfaDiscipline) {
    setNewAnalizPickerVisible(false);
    router.push({
      pathname: "/imalat-pozlari",
      params: { modul, new: "1" },
    } as any);
  }

  function openModule(mod: (typeof BFA_MODULES)[number]) {
    router.push({
      pathname: mod.route.pathname,
      params: moduleRouteParams(mod, searching ? search.trim() : ""),
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
        <TouchableOpacity
          style={[styles.settingsBtn, { top: topPad + 4 }]}
          onPress={() => setSettingsVisible(true)}
          hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
          accessibilityLabel="Ayarlar"
        >
          <Feather name="settings" size={22} color="#94a3b8" />
        </TouchableOpacity>
        <View style={styles.headerBrand}>
          <SantijetLogo iconHeight={61} centered stacked />
          <Text style={styles.headerSubtitle}>BİRİM FİYAT ANALİZLERİ</Text>
          <View style={styles.headerDateRow}>
            <Feather name="calendar" size={12} color="#60a5fa" />
            <Text style={styles.headerDateMain}>{dateStr}</Text>
            <Text style={styles.headerDateSep}>·</Text>
            <Text style={styles.headerDateSub}>{dayStr}</Text>
          </View>
        </View>
      </View>

      <View
        style={[
          styles.searchWrap,
          { backgroundColor: colors.card, borderColor: colors.border },
        ]}
      >
        <Feather name="search" size={20} color={colors.mutedForeground} />
        <TextInput
          style={[styles.searchInput, { color: colors.foreground }]}
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
            ListFooterComponent={
              filtered.length > 0 ? (
                <SourceDisclaimer color={colors.mutedForeground} bottomInset={insets.bottom} />
              ) : null
            }
          />
        </>
      ) : (
      <ScrollView
        contentContainerStyle={styles.scroll}
        showsVerticalScrollIndicator={false}
      >
        <TouchableOpacity
          activeOpacity={0.85}
          onPress={() => setRecentVisible(true)}
          style={[
            styles.recentBtn,
            {
              backgroundColor: colors.card,
              borderColor: RECENT_COLOR + "33",
            },
          ]}
        >
          <View style={[styles.recentBtnIcon, { backgroundColor: RECENT_COLOR + "1e" }]}>
            <Feather name="clock" size={21} color={RECENT_COLOR} />
          </View>
          <View style={styles.recentBtnBody}>
            <Text style={[styles.recentBtnLabel, { color: colors.cardForeground }]}>
              Son Görüntülenenler
            </Text>
            <View style={styles.recentBtnFoot}>
              <View style={[styles.recentBtnDot, { backgroundColor: RECENT_COLOR }]} />
              <Text style={[styles.recentBtnInfo, { color: RECENT_COLOR }]}>
                {recentLoaded
                  ? recentAnalizler.length > 0
                    ? `${recentAnalizler.length} analiz`
                    : "Henüz kayıt yok"
                  : "Yükleniyor…"}
              </Text>
            </View>
          </View>
          <View style={[styles.recentBtnChev, { borderColor: RECENT_COLOR + "55" }]}>
            <Feather name="chevron-right" size={13} color={RECENT_COLOR} />
          </View>
        </TouchableOpacity>

        <TouchableOpacity
          activeOpacity={0.85}
          onPress={() => router.push("/kesif" as any)}
          style={[
            styles.recentBtn,
            {
              backgroundColor: colors.card,
              borderColor: KESIF_COLOR + "33",
            },
          ]}
        >
          <View style={[styles.recentBtnIcon, { backgroundColor: KESIF_COLOR + "1e" }]}>
            <Feather name="clipboard" size={21} color={KESIF_COLOR} />
          </View>
          <View style={styles.recentBtnBody}>
            <Text style={[styles.recentBtnLabel, { color: colors.cardForeground }]}>
              Keşif Projeleri
            </Text>
            <View style={styles.recentBtnFoot}>
              <View style={[styles.recentBtnDot, { backgroundColor: KESIF_COLOR }]} />
              <Text style={[styles.recentBtnInfo, { color: KESIF_COLOR }]}>
                {kesifLoaded
                  ? kesifProjects.length > 0
                    ? `${kesifProjects.length} proje`
                    : "Yeni keşif oluştur"
                  : "Yükleniyor…"}
              </Text>
            </View>
          </View>
          <View style={[styles.recentBtnChev, { borderColor: KESIF_COLOR + "55" }]}>
            <Feather name="chevron-right" size={13} color={KESIF_COLOR} />
          </View>
        </TouchableOpacity>

        <TouchableOpacity
          activeOpacity={0.85}
          onPress={() => router.push("/analiz-katalogu" as any)}
          style={[
            styles.recentBtn,
            {
              backgroundColor: colors.card,
              borderColor: KATALOG_COLOR + "33",
            },
          ]}
        >
          <View style={[styles.recentBtnIcon, { backgroundColor: KATALOG_COLOR + "1e" }]}>
            <Feather name="book-open" size={21} color={KATALOG_COLOR} />
          </View>
          <View style={styles.recentBtnBody}>
            <Text style={[styles.recentBtnLabel, { color: colors.cardForeground }]}>
              Analiz Kataloğu
            </Text>
            <View style={styles.recentBtnFoot}>
              <View style={[styles.recentBtnDot, { backgroundColor: KATALOG_COLOR }]} />
              <Text style={[styles.recentBtnInfo, { color: KATALOG_COLOR }]} numberOfLines={1}>
                {katalogOzet}
              </Text>
            </View>
          </View>
          <View style={[styles.recentBtnChev, { borderColor: KATALOG_COLOR + "55" }]}>
            <Feather name="chevron-right" size={13} color={KATALOG_COLOR} />
          </View>
        </TouchableOpacity>

        <Text style={[styles.sectionLabel, { color: colors.foreground }]}>Modüller</Text>

        <ModuleGrid cols={2}>
          {BFA_MODULES.map((mod) => {
            const count = mod.count(stats);
            return (
              <ModuleTile
                key={mod.num}
                num={mod.num}
                label={mod.label}
                icon={mod.icon}
                color={mod.color}
                info={`${count} ${mod.infoSuffix}`}
                loading={loading}
                cardForeground={colors.cardForeground}
                cardBackground={colors.card}
                onPress={() => openModule(mod)}
              />
            );
          })}
        </ModuleGrid>

        <CreateAnalizFab onPress={openNewAnaliz} />

        <SourceDisclaimer color={colors.mutedForeground} bottomInset={insets.bottom} />
      </ScrollView>
      )}

      <NewAnalizModulePickerModal
        visible={newAnalizPickerVisible}
        onClose={() => setNewAnalizPickerVisible(false)}
        onSelect={startNewAnalizInModule}
      />

      <SettingsModal visible={settingsVisible} onClose={() => setSettingsVisible(false)} />

      <RecentViewsModal
        visible={recentVisible}
        onClose={() => setRecentVisible(false)}
        items={recentAnalizler}
        onSelect={openAnaliz}
      />
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
    paddingBottom: 14,
    position: "relative",
  },
  settingsBtn: {
    position: "absolute",
    top: 0,
    right: 12,
    zIndex: 2,
    width: 40,
    height: 40,
    alignItems: "center",
    justifyContent: "center",
    borderRadius: 20,
  },
  headerBrand: {
    alignItems: "center",
    justifyContent: "center",
    width: "100%",
    gap: 8,
  },
  headerSubtitle: {
    color: "#4a6080",
    fontSize: 14,
    fontFamily: "Inter_700Bold",
    letterSpacing: 4,
    textAlign: "center",
    marginTop: 2,
  },
  headerDateRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    flexWrap: "wrap",
    gap: 6,
    marginTop: 2,
    paddingHorizontal: 8,
  },
  headerDateMain: {
    color: "#cbd5e1",
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
    textAlign: "center",
  },
  headerDateSep: {
    color: "#64748b",
    fontSize: 11,
    fontFamily: "Inter_400Regular",
  },
  headerDateSub: {
    color: "#94a3b8",
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    textAlign: "center",
  },
  scroll: { padding: 12, paddingTop: 10 },
  searchWrap: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    marginHorizontal: 12,
    marginTop: 12,
    marginBottom: 4,
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
  sectionLabel: {
    fontSize: 16,
    fontFamily: "Inter_700Bold",
    marginBottom: 12,
    marginLeft: 4,
  },
  recentBtn: {
    width: "100%",
    flexDirection: "row",
    alignItems: "center",
    gap: 11,
    paddingHorizontal: 12,
    paddingVertical: 11,
    borderRadius: 13,
    borderWidth: 1,
    marginBottom: 9,
    minHeight: 64,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
  },
  recentBtnIcon: {
    width: 42,
    height: 42,
    borderRadius: 21,
    justifyContent: "center",
    alignItems: "center",
  },
  recentBtnBody: {
    flex: 1,
    gap: 4,
    justifyContent: "center",
  },
  recentBtnLabel: {
    fontSize: 13,
    fontFamily: "Inter_700Bold",
    letterSpacing: 0.3,
  },
  recentBtnFoot: {
    flexDirection: "row",
    alignItems: "center",
    gap: 5,
  },
  recentBtnDot: {
    width: 5,
    height: 5,
    borderRadius: 3,
  },
  recentBtnInfo: {
    fontSize: 11,
    fontFamily: "Inter_500Medium",
  },
  recentBtnChev: {
    width: 26,
    height: 26,
    borderRadius: 13,
    borderWidth: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  sourceDisclaimerWrap: {
    paddingHorizontal: 16,
    gap: 6,
  },
  sourceDisclaimer: {
    fontSize: 10,
    fontFamily: "Inter_400Regular",
    lineHeight: 14,
    textAlign: "center",
  },
});
