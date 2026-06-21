import React from "react";
import { Platform, StyleSheet, Text, View } from "react-native";

import { useColors } from "@/hooks/useColors";

export type WebPdfExportVariant = "single" | "bulk" | "compare" | "kesif";

const MESSAGES: Record<WebPdfExportVariant, string> = {
  single:
    "Web'de PDF, tarayıcı yazdır penceresi ile oluşturulur (Yazdır → PDF olarak kaydet).",
  bulk:
    "Web'de toplu PDF, ZIP içinde HTML dosyaları olarak indirilir. Her dosyayı açıp yazdırarak PDF oluşturabilirsiniz.",
  compare:
    "Web'de PDF, tarayıcı yazdır penceresi ile oluşturulur (Yazdır → PDF olarak kaydet).",
  kesif:
    "Web'de PDF, tarayıcı yazdır penceresi ile oluşturulur (Yazdır → PDF olarak kaydet).",
};

interface WebPdfExportNoticeProps {
  variant: WebPdfExportVariant;
  format: "pdf" | "excel";
}

export function WebPdfExportNotice({ variant, format }: WebPdfExportNoticeProps) {
  const colors = useColors();

  if (Platform.OS !== "web" || format !== "pdf") return null;

  return (
    <View style={[styles.box, { backgroundColor: colors.primary + "12", borderColor: colors.primary + "33" }]}>
      <Text style={[styles.text, { color: colors.foreground }]}>{MESSAGES[variant]}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  box: {
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    marginBottom: 10,
  },
  text: {
    fontSize: 12,
    fontFamily: "Inter_500Medium",
    lineHeight: 18,
  },
});
