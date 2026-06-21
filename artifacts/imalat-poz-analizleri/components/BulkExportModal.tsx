import { Feather } from "@expo/vector-icons";
import React, { useEffect, useState } from "react";
import { Modal, Pressable, StyleSheet, Text, TouchableOpacity, View } from "react-native";

import { AnalizExportFormat, PdfPaperOrientation } from "@/lib/analizExport";
import { useColors } from "@/hooks/useColors";

interface BulkExportModalProps {
  visible: boolean;
  count: number;
  onClose: () => void;
  onSelect: (format: AnalizExportFormat, pdfOrientation?: PdfPaperOrientation) => void;
}

const FORMATS: {
  id: AnalizExportFormat;
  label: string;
  hint: string;
  icon: keyof typeof Feather.glyphMap;
  color: string;
}[] = [
  { id: "pdf", label: "PDF", hint: "ZIP içinde PDF dosyaları", icon: "file-text", color: "#dc2626" },
  { id: "excel", label: "Excel", hint: "ZIP içinde .xls dosyaları", icon: "grid", color: "#059669" },
];

const ORIENTATIONS: {
  id: PdfPaperOrientation;
  label: string;
  hint: string;
  icon: keyof typeof Feather.glyphMap;
}[] = [
  { id: "landscape", label: "Yatay (A4)", hint: "Geniş tablo için önerilir", icon: "maximize-2" },
  { id: "portrait", label: "Dikey (A4)", hint: "Standart dikey kağıt", icon: "smartphone" },
];

export function BulkExportModal({ visible, count, onClose, onSelect }: BulkExportModalProps) {
  const colors = useColors();
  const [step, setStep] = useState<"format" | "pdf-orientation">("format");

  useEffect(() => {
    if (!visible) setStep("format");
  }, [visible]);

  function handleClose() {
    setStep("format");
    onClose();
  }

  function handleFormatSelect(format: AnalizExportFormat) {
    if (format === "pdf") {
      setStep("pdf-orientation");
      return;
    }
    onSelect(format);
  }

  function handleOrientationSelect(orientation: PdfPaperOrientation) {
    onSelect("pdf", orientation);
  }

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={handleClose}>
      <Pressable style={styles.overlay} onPress={handleClose}>
        <Pressable
          style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={(e) => e.stopPropagation()}
        >
          {step === "format" ? (
            <>
              <Text style={[styles.title, { color: colors.foreground }]}>Toplu Dışa Aktar</Text>
              <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
                {count} analiz ZIP olarak indirilecek
              </Text>

              {FORMATS.map((f) => (
                <TouchableOpacity
                  key={f.id}
                  activeOpacity={0.85}
                  style={[
                    styles.option,
                    { borderColor: f.color + "44", backgroundColor: f.color + "10" },
                  ]}
                  onPress={() => handleFormatSelect(f.id)}
                >
                  <View style={[styles.optionIcon, { backgroundColor: f.color + "22" }]}>
                    <Feather name={f.icon} size={18} color={f.color} />
                  </View>
                  <View style={styles.optionText}>
                    <Text style={[styles.optionLabel, { color: colors.foreground }]}>{f.label}</Text>
                    <Text style={[styles.optionHint, { color: colors.mutedForeground }]}>{f.hint}</Text>
                  </View>
                  <Feather name="chevron-right" size={16} color={f.color} />
                </TouchableOpacity>
              ))}
            </>
          ) : (
            <>
              <TouchableOpacity style={styles.backLink} onPress={() => setStep("format")}>
                <Feather name="arrow-left" size={16} color={colors.primary} />
                <Text style={[styles.backText, { color: colors.primary }]}>Format seçimi</Text>
              </TouchableOpacity>

              <Text style={[styles.title, { color: colors.foreground }]}>PDF Kağıt Yönü</Text>
              <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
                {count} analiz için yön seçin
              </Text>

              {ORIENTATIONS.map((o) => (
                <TouchableOpacity
                  key={o.id}
                  activeOpacity={0.85}
                  style={[
                    styles.option,
                    { borderColor: colors.primary + "44", backgroundColor: colors.primary + "10" },
                  ]}
                  onPress={() => handleOrientationSelect(o.id)}
                >
                  <View style={[styles.optionIcon, { backgroundColor: colors.primary + "22" }]}>
                    <Feather name={o.icon} size={18} color={colors.primary} />
                  </View>
                  <View style={styles.optionText}>
                    <Text style={[styles.optionLabel, { color: colors.foreground }]}>{o.label}</Text>
                    <Text style={[styles.optionHint, { color: colors.mutedForeground }]}>{o.hint}</Text>
                  </View>
                  <Feather name="chevron-right" size={16} color={colors.primary} />
                </TouchableOpacity>
              ))}
            </>
          )}

          <TouchableOpacity
            style={[styles.cancelBtn, { backgroundColor: colors.border }]}
            onPress={handleClose}
          >
            <Text style={{ color: colors.foreground, fontFamily: "Inter_500Medium" }}>İptal</Text>
          </TouchableOpacity>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: "rgba(15, 23, 42, 0.45)",
    justifyContent: "center",
    alignItems: "center",
    padding: 24,
  },
  card: {
    width: "100%",
    maxWidth: 400,
    borderRadius: 16,
    borderWidth: 1,
    padding: 18,
    gap: 10,
  },
  title: {
    fontSize: 17,
    fontFamily: "Inter_700Bold",
  },
  subtitle: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    marginBottom: 4,
  },
  backLink: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginBottom: 2,
  },
  backText: {
    fontSize: 13,
    fontFamily: "Inter_500Medium",
  },
  option: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    paddingVertical: 12,
    paddingHorizontal: 12,
    borderRadius: 12,
    borderWidth: 1,
  },
  optionIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: "center",
    justifyContent: "center",
  },
  optionText: {
    flex: 1,
    gap: 2,
  },
  optionLabel: {
    fontSize: 13,
    fontFamily: "Inter_700Bold",
  },
  optionHint: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
  },
  cancelBtn: {
    marginTop: 4,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: "center",
  },
});
