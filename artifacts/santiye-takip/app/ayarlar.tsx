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
import { useI18n } from "@/context/I18nContext";
import { useColors } from "@/hooks/useColors";

type Row = {
  key: string;
  icon: React.ComponentProps<typeof Feather>["name"];
  title: string;
  sub: string;
  route: string;
};

export default function AyarlarScreen() {
  const colors = useColors();
  const router = useRouter();
  const { t } = useI18n();
  const { currentRole } = useApp();
  const isAdmin = currentRole?.isAdmin === true;
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;

  const general: Row[] = [
    {
      key: "tema",
      icon: "droplet",
      title: t("home.theme.title"),
      sub: t("home.theme.sub"),
      route: "/temalar",
    },
    {
      key: "dil",
      icon: "globe",
      title: t("settings.language.title"),
      sub: t("settings.language.intro"),
      route: "/dil",
    },
  ];

  const material: Row[] = [
    {
      key: "matCat",
      icon: "grid",
      title: t("settings.matCat.title"),
      sub: t("settings.matCat.sub"),
      route: "/malzeme-kategorisi",
    },
    {
      key: "matList",
      icon: "package",
      title: t("settings.matList.title"),
      sub: t("settings.matList.sub"),
      route: "/malzeme-listesi",
    },
    {
      key: "matUnit",
      icon: "hash",
      title: t("settings.matUnit.title"),
      sub: t("settings.matUnit.sub"),
      route: "/malzeme-birimi",
    },
  ];

  function renderRow(r: Row, first: boolean) {
    return (
      <TouchableOpacity
        key={r.key}
        style={[
          styles.row,
          {
            backgroundColor: colors.card,
            borderColor: colors.secondary + "40",
            marginTop: first ? 0 : 10,
          },
        ]}
        onPress={() => router.push(r.route as any)}
        activeOpacity={0.85}
      >
        <View style={[styles.icon, { backgroundColor: colors.secondary + "20" }]}>
          <Feather name={r.icon} size={20} color={colors.secondary} />
        </View>
        <View style={{ flex: 1 }}>
          <Text style={[styles.title, { color: colors.foreground }]}>{r.title}</Text>
          <Text style={[styles.sub, { color: colors.mutedForeground }]}>{r.sub}</Text>
        </View>
        <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
      </TouchableOpacity>
    );
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <View
        style={[
          styles.header,
          { backgroundColor: colors.secondary, paddingTop: topPad + 12 },
        ]}
      >
        <TouchableOpacity
          onPress={() => {
            if (router.canGoBack()) router.back();
            else router.replace("/" as any);
          }}
          style={styles.backBtn}
          accessibilityLabel={t("common.back")}
        >
          <Feather name="arrow-left" size={22} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.secondaryForeground }]}>
          {t("settings.title")}
        </Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView
        contentContainerStyle={[styles.scroll, { paddingBottom: insets.bottom + 24 }]}
      >
        <Text style={[styles.section, { color: colors.foreground }]}>
          {t("settings.general")}
        </Text>
        {general.map((r, i) => renderRow(r, i === 0))}

        {isAdmin ? (
          <>
            <Text style={[styles.section, { color: colors.foreground, marginTop: 24 }]}>
              {t("home.materialSettings")}
            </Text>
            {material.map((r, i) => renderRow(r, i === 0))}
          </>
        ) : null}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
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
    fontSize: 18,
    fontWeight: "700",
    textAlign: "center",
    fontFamily: "Inter_700Bold",
  },
  scroll: { padding: 16 },
  section: {
    fontSize: 13,
    fontFamily: "Inter_700Bold",
    textTransform: "uppercase",
    letterSpacing: 0.5,
    marginBottom: 10,
  },
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    borderRadius: 14,
    padding: 14,
    borderWidth: 1,
  },
  icon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: "center",
    justifyContent: "center",
  },
  title: { fontSize: 15, fontFamily: "Inter_600SemiBold" },
  sub: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
});
