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

import { useI18n } from "@/context/I18nContext";
import { useTheme } from "@/context/ThemeContext";
import { useColors } from "@/hooks/useColors";

export default function TemalarScreen() {
  const colors = useColors();
  const router = useRouter();
  const { themeId, themes, setThemeId } = useTheme();
  const { t } = useI18n();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;

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
          accessibilityLabel="Geri"
        >
          <Feather name="arrow-left" size={22} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.secondaryForeground }]}>
          {t("settings.theme.title")}
        </Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView
        contentContainerStyle={[
          styles.scroll,
          { paddingBottom: insets.bottom + 24 },
        ]}
      >
        <Text style={[styles.intro, { color: colors.mutedForeground }]}>
          {t("settings.theme.intro")}
        </Text>

        {themes.map((th) => {
          const selected = th.id === themeId;
          return (
            <TouchableOpacity
              key={th.id}
              activeOpacity={0.85}
              onPress={() => setThemeId(th.id)}
              style={[
                styles.card,
                {
                  backgroundColor: colors.card,
                  borderColor: selected ? colors.primary : colors.border,
                  borderWidth: selected ? 2 : 1,
                },
              ]}
            >
              <View style={styles.previewRow}>
                <View
                  style={[
                    styles.previewBox,
                    {
                      backgroundColor: th.preview.bg,
                      borderColor: colors.border,
                    },
                  ]}
                >
                  <View
                    style={[
                      styles.previewBar,
                      { backgroundColor: th.preview.secondary },
                    ]}
                  />
                  <View style={styles.previewBody}>
                    <View
                      style={[
                        styles.previewChip,
                        { backgroundColor: th.preview.primary },
                      ]}
                    />
                    <View
                      style={[
                        styles.previewLine,
                        {
                          backgroundColor: th.isDark
                            ? "rgba(255,255,255,0.4)"
                            : "rgba(0,0,0,0.15)",
                        },
                      ]}
                    />
                    <View
                      style={[
                        styles.previewLineShort,
                        {
                          backgroundColor: th.isDark
                            ? "rgba(255,255,255,0.25)"
                            : "rgba(0,0,0,0.1)",
                        },
                      ]}
                    />
                  </View>
                </View>

                <View style={styles.cardTextBlock}>
                  <View style={styles.titleRow}>
                    <Text style={[styles.cardTitle, { color: colors.foreground }]}>
                      {th.name}
                    </Text>
                    {selected ? (
                      <View
                        style={[
                          styles.badge,
                          { backgroundColor: colors.primary },
                        ]}
                      >
                        <Feather
                          name="check"
                          size={12}
                          color={colors.primaryForeground}
                        />
                        <Text
                          style={[
                            styles.badgeText,
                            { color: colors.primaryForeground },
                          ]}
                        >
                          {t("settings.theme.active")}
                        </Text>
                      </View>
                    ) : null}
                  </View>
                  <Text
                    style={[
                      styles.cardDesc,
                      { color: colors.mutedForeground },
                    ]}
                  >
                    {th.description}
                  </Text>
                  <View style={styles.swatches}>
                    <View
                      style={[
                        styles.swatch,
                        { backgroundColor: th.colors.navy },
                      ]}
                    />
                    <View
                      style={[
                        styles.swatch,
                        { backgroundColor: th.colors.orange },
                      ]}
                    />
                    <View
                      style={[
                        styles.swatch,
                        {
                          backgroundColor: th.colors.background,
                          borderWidth: 1,
                          borderColor: colors.border,
                        },
                      ]}
                    />
                    {th.isDark ? (
                      <View
                        style={[
                          styles.darkPill,
                          { backgroundColor: colors.muted },
                        ]}
                      >
                        <Feather
                          name="moon"
                          size={10}
                          color={colors.mutedForeground}
                        />
                        <Text
                          style={[
                            styles.darkPillText,
                            { color: colors.mutedForeground },
                          ]}
                        >
                          {t("settings.theme.dark")}
                        </Text>
                      </View>
                    ) : null}
                  </View>
                </View>
              </View>
            </TouchableOpacity>
          );
        })}
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
  scroll: { padding: 16, gap: 12 },
  intro: {
    fontSize: 13,
    lineHeight: 18,
    marginBottom: 12,
    fontFamily: "Inter_400Regular",
  },
  card: {
    borderRadius: 14,
    padding: 14,
    marginBottom: 12,
  },
  previewRow: { flexDirection: "row", gap: 14, alignItems: "center" },
  previewBox: {
    width: 92,
    height: 110,
    borderRadius: 10,
    overflow: "hidden",
    borderWidth: 1,
  },
  previewBar: { height: 24, width: "100%" },
  previewBody: { padding: 8, gap: 6 },
  previewChip: { width: 26, height: 26, borderRadius: 6 },
  previewLine: { height: 6, borderRadius: 3, width: "85%" },
  previewLineShort: { height: 6, borderRadius: 3, width: "55%" },
  cardTextBlock: { flex: 1, gap: 4 },
  titleRow: { flexDirection: "row", alignItems: "center", gap: 8 },
  cardTitle: {
    fontSize: 16,
    fontWeight: "700",
    fontFamily: "Inter_700Bold",
  },
  cardDesc: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
  },
  swatches: { flexDirection: "row", gap: 6, marginTop: 8, alignItems: "center" },
  swatch: { width: 18, height: 18, borderRadius: 9 },
  badge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 999,
  },
  badgeText: { fontSize: 11, fontWeight: "700", fontFamily: "Inter_700Bold" },
  darkPill: {
    flexDirection: "row",
    alignItems: "center",
    gap: 3,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 999,
    marginLeft: 4,
  },
  darkPillText: {
    fontSize: 10,
    fontWeight: "600",
    fontFamily: "Inter_600SemiBold",
  },
});
