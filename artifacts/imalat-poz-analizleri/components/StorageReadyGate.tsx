import React from "react";
import { ActivityIndicator, StyleSheet, Text, View } from "react-native";

import { useApp } from "@/context/AppContext";
import { useKesif } from "@/context/KesifContext";
import { useTheme } from "@/context/ThemeContext";
import { useColors } from "@/hooks/useColors";

export function StorageReadyGate({ children }: { children: React.ReactNode }) {
  const colors = useColors();
  const { loaded: appLoaded } = useApp();
  const { loaded: kesifLoaded } = useKesif();
  const { loaded: themeLoaded } = useTheme();

  const ready = appLoaded && kesifLoaded && themeLoaded;

  if (!ready) {
    return (
      <View style={[styles.host, { backgroundColor: colors.background }]}>
        <ActivityIndicator size="large" color={colors.primary} />
        <Text style={[styles.label, { color: colors.mutedForeground }]}>Veriler yükleniyor…</Text>
      </View>
    );
  }

  return <>{children}</>;
}

const styles = StyleSheet.create({
  host: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    gap: 12,
  },
  label: {
    fontSize: 14,
    fontFamily: "Inter_500Medium",
  },
});
