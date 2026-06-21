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
import { ModuleTile } from "@/components/ModuleTile";
import { BFA_MODULES, BfaDiscipline, resolveAnalizDiscipline } from "@/constants/bfaModules";
import { matchesPozAnalizSearch } from "@/constants/pozAnalizleri";
import { useKesif } from "@/context/KesifContext";
import { useBfaCatalog } from "@/hooks/useBfaCatalog";
import { useColors } from "@/hooks/useColors";
import { useRecentViews } from "@/hooks/useRecentViews";

const TILE_COLOR = "#d97706";
const RECENT_COLOR = "#6366f1";
const KESIF_COLOR = "#7c3aed";

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
    <Text
      style={[
        styles.sourceDisclaimer,
        { color, paddingBottom: bottomInset + 24, paddingTop: 20 },
      ]}
    >
      Veriler kamu kurumlarının yayımladığı kaynaklardan derlenmiştir. Nihai doğrulama için
      ilgili kurumların güncel resmi yayınları esas alınmalıdır.
    </Text>
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
        <View
          style={[
            styles.welcomeCard,
            { backgroundColor: colors.secondary, borderColor: "rgba(255,255,255,0.07)" },
          ]}
        >
          <View style={styles.welcomeMain}>
            <Text style={styles.welcomeGreet}>Hoş geldiniz</Text>
            <Text style={[styles.welcomeName, { color: colors.secondaryForeground }]}>
              ŞANTİJET B.F.A.
            </Text>
            <Text
              style={styles.welcomeRole}
              numberOfLines={1}
              adjustsFontSizeToFit
              minimumFontScale={0.85}
            >
              Resmi analiz tabloları, fiyat hesaplamaları ve özel analizler
            </Text>
          </View>

          <View style={styles.welcomeDateBlock}>
            <Feather name="calendar" size={14} color="#60a5fa" style={styles.welcomeDateIcon} />
            <View style={styles.welcomeDateTexts}>
              <Text style={[styles.welcomeDateMain, { color: colors.secondaryForeground }]}>
                {dateStr}
              </Text>
              <Text style={styles.welcomeDateSub}>{dayStr}</Text>
            </View>
          </View>
        </View>

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
            <Feather name="clock" size={23} color={RECENT_COLOR} />
          </View>
          <View style={styles.recentBtnBody}>
            <Text style={styles.recentBtnNum}>HIZLI ERİŞİM</Text>
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
            <Feather name="clipboard" size={23} color={KESIF_COLOR} />
          </View>
          <View style={styles.recentBtnBody}>
            <Text style={styles.recentBtnNum}>METRAJ / KEŞİF</Text>
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

        <Text style={[styles.sectionLabel, { color: colors.foreground }]}>Modüller</Text>

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
    paddingBottom: 12,
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
  scroll: { padding: 12, paddingTop: 7 },
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
  welcomeCard: {
    flexDirection: "row",
    alignItems: "flex-start",
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 10,
    marginBottom: 9,
    borderWidth: 1,
    gap: 10,
  },
  welcomeMain: {
    flex: 1,
    gap: 5,
  },
  welcomeGreet: {
    color: "#64748b",
    fontSize: 12,
    fontFamily: "Inter_400Regular",
  },
  welcomeName: {
    fontSize: 18,
    fontFamily: "Inter_700Bold",
    letterSpacing: 0.5,
  },
  welcomeRole: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    color: "#94a3b8",
    lineHeight: 14,
  },
  welcomeDateBlock: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 6,
    flexShrink: 0,
    paddingTop: 1,
  },
  welcomeDateIcon: {
    marginTop: 1,
  },
  welcomeDateTexts: {
    alignItems: "flex-end",
    gap: 2,
  },
  welcomeDateMain: {
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
    textAlign: "right",
  },
  welcomeDateSub: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    color: "#64748b",
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
    gap: 13,
    padding: 14,
    borderRadius: 13,
    borderWidth: 1,
    marginBottom: 11,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
  },
  recentBtnIcon: {
    width: 47,
    height: 47,
    borderRadius: 24,
    justifyContent: "center",
    alignItems: "center",
  },
  recentBtnBody: {
    flex: 1,
    gap: 3,
  },
  recentBtnNum: {
    fontSize: 9,
    fontFamily: "Inter_700Bold",
    color: "#334155",
    letterSpacing: 0.5,
  },
  recentBtnLabel: {
    fontSize: 12,
    fontFamily: "Inter_700Bold",
    letterSpacing: 0.4,
  },
  recentBtnFoot: {
    flexDirection: "row",
    alignItems: "center",
    gap: 5,
    marginTop: 1,
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
    width: 29,
    height: 29,
    borderRadius: 15,
    borderWidth: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  sourceDisclaimer: {
    fontSize: 10,
    fontFamily: "Inter_400Regular",
    lineHeight: 14,
    textAlign: "center",
    paddingHorizontal: 16,
  },
});
