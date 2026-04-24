import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React from "react";
import {
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

interface Section {
  key: string;
  label: string;
  icon: string;
  route: string;
  color: string;
  bg: string;
  count: (a: ReturnType<typeof useApp>) => number;
}

const SECTIONS: Section[] = [
  { key: "proje",       label: "Proje",        icon: "briefcase",  route: "/proje",       color: "#e85d04", bg: "#fef3e2", count: (a) => a.projects.length },
  { key: "kesif",       label: "Keşif",         icon: "search",     route: "/kesif",       color: "#0ea5e9", bg: "#e0f2fe", count: (a) => a.surveys.length },
  { key: "is-programi", label: "İş Programı",   icon: "calendar",   route: "/is-programi", color: "#8b5cf6", bg: "#ede9fe", count: (a) => a.scheduleTasks.length },
  { key: "puantaj",     label: "Puantaj",       icon: "users",      route: "/puantaj",     color: "#16a34a", bg: "#dcfce7", count: (a) => a.attendance.length },
  { key: "gunluk-rapor",label: "Günlük Rapor",  icon: "file-text",  route: "/gunluk-rapor",color: "#0891b2", bg: "#cffafe", count: (a) => a.dailyReports.length },
  { key: "imalat",      label: "İmalat",        icon: "tool",       route: "/imalat",      color: "#d97706", bg: "#fef3c7", count: (a) => a.productions.length },
  { key: "gorev",       label: "Görev",         icon: "check-square",route: "/gorev",      color: "#dc2626", bg: "#fee2e2", count: (a) => a.tasks.length },
  { key: "malzeme",     label: "Malzeme",       icon: "package",    route: "/malzeme",     color: "#059669", bg: "#d1fae5", count: (a) => a.materials.length },
  { key: "butce",       label: "Bütçe",         icon: "dollar-sign",route: "/butce",       color: "#16213e", bg: "#e0e7ff", count: (a) => a.budget.length },
  { key: "hakedis",     label: "Hakediş",       icon: "file-text",  route: "/hakedis",     color: "#be185d", bg: "#fce7f3", count: (a) => a.hakedisler.length },
];

export default function HomeScreen() {
  const colors = useColors();
  const router = useRouter();
  const app = useApp();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 67 : insets.top;

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <View
        style={[
          styles.hero,
          { backgroundColor: colors.secondary, paddingTop: topPad + 16 },
        ]}
      >
        <Text style={styles.heroSub}>Hoş Geldiniz</Text>
        <Text style={styles.heroTitle}>Şantiye Takip</Text>
        <Text style={styles.heroDesc}>
          {app.projects.length} aktif proje · {app.workers.length} personel
        </Text>
      </View>

      <ScrollView
        contentContainerStyle={[
          styles.scroll,
          { paddingBottom: insets.bottom + 24 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        <Text style={[styles.sectionLabel, { color: colors.foreground }]}>
          Bölümler
        </Text>

        <View style={styles.grid}>
          {SECTIONS.map((s) => (
            <TouchableOpacity
              key={s.key}
              style={[styles.tile, { backgroundColor: colors.card }]}
              onPress={() => router.push(s.route as any)}
              activeOpacity={0.85}
            >
              <View style={[styles.tileIcon, { backgroundColor: s.bg }]}>
                <Feather name={s.icon as any} size={28} color={s.color} />
              </View>
              <Text
                style={[styles.tileLabel, { color: colors.foreground }]}
                numberOfLines={1}
              >
                {s.label}
              </Text>
              <Text style={[styles.tileCount, { color: colors.mutedForeground }]}>
                {s.count(app)} kayıt
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  hero: {
    paddingHorizontal: 20,
    paddingBottom: 28,
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
  },
  heroSub: {
    color: "#cbd5e1",
    fontSize: 14,
    fontFamily: "Inter_400Regular",
  },
  heroTitle: {
    color: "#fff",
    fontSize: 26,
    fontFamily: "Inter_700Bold",
    marginTop: 4,
  },
  heroDesc: {
    color: "#94a3b8",
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    marginTop: 6,
  },
  scroll: {
    padding: 16,
  },
  sectionLabel: {
    fontSize: 16,
    fontFamily: "Inter_700Bold",
    marginBottom: 12,
    marginLeft: 4,
  },
  grid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 12,
  },
  tile: {
    width: "47.5%",
    paddingVertical: 18,
    paddingHorizontal: 16,
    borderRadius: 14,
    justifyContent: "flex-start",
    gap: 10,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 2,
  },
  tileIcon: {
    width: 50,
    height: 50,
    borderRadius: 25,
    justifyContent: "center",
    alignItems: "center",
  },
  tileLabel: {
    fontSize: 15,
    fontFamily: "Inter_600SemiBold",
  },
  tileCount: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
  },
});
