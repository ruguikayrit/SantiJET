import React from "react";
import { Platform, ScrollView, StyleSheet, Text, View } from "react-native";
import { WebView } from "react-native-webview";

import { useColors } from "@/hooks/useColors";

interface ExportPreviewPaneProps {
  html: string;
  formatLabel: string;
}

export function ExportPreviewPane({ html, formatLabel }: ExportPreviewPaneProps) {
  const colors = useColors();

  if (Platform.OS === "web") {
    return (
      <View style={styles.container}>
        <Text style={[styles.hint, { color: colors.mutedForeground }]}>
          {formatLabel} önizlemesi
        </Text>
        <ScrollView style={[styles.webScroll, { borderColor: colors.border }]} nestedScrollEnabled>
          {/* eslint-disable-next-line react/no-danger */}
          <iframe
            title="export-preview"
            srcDoc={html}
            style={{
              width: "100%",
              minHeight: 480,
              border: "none",
              backgroundColor: "#fff",
            }}
          />
        </ScrollView>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={[styles.hint, { color: colors.mutedForeground }]}>{formatLabel} önizlemesi</Text>
      <View style={[styles.nativeFrame, { borderColor: colors.border }]}>
        <WebView
          originWhitelist={["*"]}
          source={{ html }}
          style={styles.webview}
          scrollEnabled
          showsVerticalScrollIndicator
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: 8,
    flex: 1,
    minHeight: 280,
  },
  hint: {
    fontSize: 12,
    fontFamily: "Inter_500Medium",
  },
  webScroll: {
    flex: 1,
    borderWidth: 1,
    borderRadius: 10,
    overflow: "hidden",
    backgroundColor: "#fff",
    minHeight: 320,
  },
  nativeFrame: {
    flex: 1,
    borderWidth: 1,
    borderRadius: 10,
    overflow: "hidden",
    minHeight: 320,
    backgroundColor: "#fff",
  },
  webview: {
    flex: 1,
    backgroundColor: "#fff",
  },
});
