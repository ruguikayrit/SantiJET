import { Feather } from "@expo/vector-icons";
import React from "react";
import { Modal, Pressable, StyleSheet, Text, TouchableOpacity, View } from "react-native";

import { AnalizExportFormat } from "@/lib/analizExport";
import { useColors } from "@/hooks/useColors";

interface ExportFormatModalProps {
  visible: boolean;
  onClose: () => void;
  onSelect: (format: AnalizExportFormat) => void;
}

const FORMATS: { id: AnalizExportFormat; label: string; hint: string; icon: keyof typeof Feather.glyphMap; color: string }[] = [
  { id: "pdf", label: "PDF", hint: "Resmi tablo düzeni, yazdırılabilir", icon: "file-text", color: "#dc2626" },
  { id: "excel", label: "Excel", hint: "Excel ve Numbers ile açılır", icon: "grid", color: "#059669" },
];

export function ExportFormatModal({ visible, onClose, onSelect }: ExportFormatModalProps) {
  const colors = useColors();

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.overlay} onPress={onClose}>
        <Pressable
          style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={(e) => e.stopPropagation()}
        >
          <Text style={[styles.title, { color: colors.foreground }]}>Dışa Aktar</Text>
          <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
            Dosya formatını seçin
          </Text>

          {FORMATS.map((f) => (
            <TouchableOpacity
              key={f.id}
              activeOpacity={0.85}
              style={[
                styles.option,
                { borderColor: f.color + "44", backgroundColor: f.color + "10" },
              ]}
              onPress={() => {
                onSelect(f.id);
                onClose();
              }}
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

          <TouchableOpacity
            style={[styles.cancelBtn, { backgroundColor: colors.border }]}
            onPress={onClose}
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
