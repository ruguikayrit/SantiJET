import { Feather } from "@expo/vector-icons";
import React from "react";
import { StyleSheet, Text, TouchableOpacity, View } from "react-native";

import { useTheme } from "@/context/ThemeContext";

/** ŞantiJET marka renkleri — logo / varsayılan tema ile uyumlu */
const BRAND_ORANGE = "#e85d04";
const BRAND_NAVY = "#16213e";

interface CreateAnalizFabProps {
  onPress: () => void;
}

export function CreateAnalizFab({ onPress }: CreateAnalizFabProps) {
  const { theme } = useTheme();
  const titleColor = theme.isDark ? "#ffffff" : BRAND_NAVY;
  const subtitleColor = theme.isDark ? "#cbd5e1" : "#64748b";

  return (
    <TouchableOpacity
      activeOpacity={0.88}
      onPress={onPress}
      style={styles.wrap}
      accessibilityRole="button"
      accessibilityLabel="Yeni Analiz Oluştur"
    >
      <View style={styles.iconCircle}>
        <Feather name="plus" size={22} color="#ffffff" />
      </View>
      <View style={styles.textBlock}>
        <Text style={[styles.title, { color: titleColor }]}>Yeni Analiz Oluştur</Text>
        <Text style={[styles.subtitle, { color: subtitleColor }]}>Özel birim fiyat analizi ekle</Text>
      </View>
      <Feather name="chevron-right" size={18} color={BRAND_ORANGE} />
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    marginTop: 4,
    marginBottom: 4,
    paddingVertical: 12,
    paddingHorizontal: 14,
    borderRadius: 14,
    backgroundColor: "rgba(232, 93, 4, 0.07)",
    borderWidth: 1,
    borderColor: "rgba(232, 93, 4, 0.22)",
    shadowColor: BRAND_ORANGE,
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.12,
    shadowRadius: 8,
    elevation: 2,
  },
  iconCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: BRAND_ORANGE,
    alignItems: "center",
    justifyContent: "center",
    shadowColor: BRAND_ORANGE,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.35,
    shadowRadius: 4,
    elevation: 3,
  },
  textBlock: {
    flex: 1,
    gap: 2,
  },
  title: {
    fontSize: 14,
    fontFamily: "Inter_700Bold",
    letterSpacing: 0.2,
  },
  subtitle: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
  },
});
