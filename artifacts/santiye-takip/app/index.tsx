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

import { PageKey, Permission, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

interface Section {
  key: PageKey;
  label: string;
  icon: string;
  route: string;
  color: string;
  bg: string;
  count: (a: ReturnType<typeof useApp>) => number;
}

const SECTIONS: Section[] = [
  { key: "proje",        label: "Proje",        icon: "briefcase",   route: "/proje",        color: "#e85d04", bg: "#fef3e2", count: (a) => a.projects.length },
  { key: "kesif",        label: "Keşif",         icon: "search",      route: "/kesif",        color: "#0ea5e9", bg: "#e0f2fe", count: (a) => a.surveys.length },
  { key: "is-programi",  label: "İş Programı",   icon: "calendar",    route: "/is-programi",  color: "#8b5cf6", bg: "#ede9fe", count: (a) => a.scheduleTasks.length },
  { key: "puantaj",      label: "Puantaj",       icon: "users",       route: "/puantaj",      color: "#16a34a", bg: "#dcfce7", count: (a) => a.attendance.length },
  { key: "gunluk-rapor", label: "Günlük Rapor",  icon: "file-text",   route: "/gunluk-rapor", color: "#0891b2", bg: "#cffafe", count: (a) => a.dailyReports.length },
  { key: "imalat",       label: "İmalat",        icon: "tool",        route: "/imalat",       color: "#d97706", bg: "#fef3c7", count: (a) => a.productions.length },
  { key: "gorev",        label: "Görev",         icon: "check-square",route: "/gorev",        color: "#dc2626", bg: "#fee2e2", count: (a) => a.tasks.length },
  { key: "malzeme",      label: "Malzeme",       icon: "package",     route: "/malzeme",      color: "#059669", bg: "#d1fae5", count: (a) => a.materials.length },
  { key: "butce",        label: "Bütçe",         icon: "dollar-sign", route: "/butce",        color: "#16213e", bg: "#e0e7ff", count: (a) => a.budget.length },
  { key: "hakedis",      label: "Hakediş",       icon: "file-text",   route: "/hakedis",      color: "#be185d", bg: "#fce7f3", count: (a) => a.hakedisler.length },
  { key: "kullanicilar", label: "Kullanıcılar",  icon: "shield",      route: "/kullanicilar", color: "#7c3aed", bg: "#ede9fe", count: (a) => a.appUsers.length },
];

export default function HomeScreen() {
  const colors = useColors();
  const router = useRouter();
  const app = useApp();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 67 : insets.top;

  const { currentRole, currentAppUser, logout } = app;

  function getPermission(key: PageKey): Permission {
    if (!currentRole) return "none";
    return currentRole.permissions[key] ?? "none";
  }

  const visibleSections = SECTIONS.filter(
    (s) => getPermission(s.key) !== "none"
  );

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <View
        style={[
          styles.hero,
          { backgroundColor: colors.secondary, paddingTop: topPad + 12 },
        ]}
      >
        <View style={styles.heroRow}>
          <View style={{ flex: 1 }}>
            <Text style={styles.heroSub}>Hoş Geldiniz</Text>
            <Text style={styles.heroTitle}>Şantiye Takip</Text>
            <Text style={styles.heroDesc}>
              {app.projects.length} aktif proje · {app.workers.length} personel
            </Text>
          </View>

          {currentAppUser ? (
            <View style={styles.userBadge}>
              <Text style={styles.userInitial}>
                {currentAppUser.name.charAt(0).toUpperCase()}
              </Text>
              <Text style={styles.userName} numberOfLines={1}>
                {currentAppUser.name}
              </Text>
              <Text style={styles.userRole} numberOfLines={1}>
                {currentRole?.name}
              </Text>
              <TouchableOpacity
                onPress={logout}
                style={styles.logoutBtn}
                hitSlop={8}
              >
                <Feather name="log-out" size={14} color="#94a3b8" />
                <Text style={styles.logoutText}>Çıkış</Text>
              </TouchableOpacity>
            </View>
          ) : null}
        </View>
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
          {visibleSections.map((s) => {
            const perm = getPermission(s.key);
            return (
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
                <View style={styles.tileBottom}>
                  <Text
                    style={[styles.tileCount, { color: colors.mutedForeground }]}
                  >
                    {s.count(app)} kayıt
                  </Text>
                  {perm === "view" ? (
                    <View style={styles.viewBadge}>
                      <Feather name="eye" size={10} color="#0ea5e9" />
                      <Text style={styles.viewBadgeText}>Salt okunur</Text>
                    </View>
                  ) : null}
                </View>
              </TouchableOpacity>
            );
          })}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  hero: {
    paddingHorizontal: 20,
    paddingBottom: 24,
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
  },
  heroRow: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 12,
  },
  heroSub: {
    color: "#cbd5e1",
    fontSize: 14,
    fontFamily: "Inter_400Regular",
  },
  heroTitle: {
    color: "#fff",
    fontSize: 24,
    fontFamily: "Inter_700Bold",
    marginTop: 2,
  },
  heroDesc: {
    color: "#94a3b8",
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    marginTop: 4,
  },
  userBadge: {
    alignItems: "center",
    minWidth: 80,
  },
  userInitial: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "#e85d0422",
    color: "#e85d04",
    fontSize: 18,
    fontFamily: "Inter_700Bold",
    textAlign: "center",
    lineHeight: 40,
    overflow: "hidden",
  },
  userName: {
    color: "#f1f5f9",
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
    marginTop: 4,
    maxWidth: 80,
  },
  userRole: {
    color: "#94a3b8",
    fontSize: 10,
    fontFamily: "Inter_400Regular",
    maxWidth: 80,
  },
  logoutBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 3,
    marginTop: 6,
  },
  logoutText: {
    color: "#94a3b8",
    fontSize: 11,
    fontFamily: "Inter_500Medium",
  },
  scroll: { padding: 16 },
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
    gap: 8,
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
  tileBottom: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    flexWrap: "wrap",
  },
  tileCount: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
  },
  viewBadge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 3,
    backgroundColor: "#e0f2fe",
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 999,
  },
  viewBadgeText: {
    fontSize: 9,
    fontFamily: "Inter_600SemiBold",
    color: "#0ea5e9",
  },
});
