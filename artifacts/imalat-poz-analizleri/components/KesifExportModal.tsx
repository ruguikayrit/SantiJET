import { Feather } from "@expo/vector-icons";
import React, { useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  Modal,
  Pressable,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import { ExportPreviewPane } from "@/components/ExportPreviewPane";
import { WebPdfExportNotice } from "@/components/WebPdfExportNotice";
import { KesifProject } from "@/constants/kesif";
import { AnalizExportFormat, PDF_PAPER_ORIENTATION } from "@/lib/analizExport";
import { buildKesifExcelHtml, buildKesifHtml } from "@/lib/kesifExport";
import { useColors } from "@/hooks/useColors";

interface KesifExportModalProps {
  visible: boolean;
  project: KesifProject;
  onClose: () => void;
  onExport: (format: AnalizExportFormat) => void;
}

const FORMATS: {
  id: AnalizExportFormat;
  label: string;
  icon: keyof typeof Feather.glyphMap;
  color: string;
}[] = [
  { id: "pdf", label: "PDF", icon: "file-text", color: "#dc2626" },
  { id: "excel", label: "Excel", icon: "grid", color: "#059669" },
];

export function KesifExportModal({ visible, project, onClose, onExport }: KesifExportModalProps) {
  const colors = useColors();
  const [step, setStep] = useState<"format" | "preview">("format");
  const [selectedFormat, setSelectedFormat] = useState<AnalizExportFormat>("pdf");

  useEffect(() => {
    if (!visible) {
      setStep("format");
      setSelectedFormat("pdf");
    }
  }, [visible]);

  const previewHtml = useMemo(() => {
    if (step !== "preview") return "";
    if (selectedFormat === "excel") return buildKesifExcelHtml(project);
    return buildKesifHtml(project, PDF_PAPER_ORIENTATION);
  }, [project, step, selectedFormat]);

  const formatLabel = selectedFormat === "pdf" ? "PDF" : "Excel";

  function handleClose() {
    setStep("format");
    onClose();
  }

  function handleFormatSelect(format: AnalizExportFormat) {
    setSelectedFormat(format);
    setStep("preview");
  }

  function handleExport() {
    onExport(selectedFormat);
  }

  function handleBackFromPreview() {
    setStep("format");
  }

  const isPreview = step === "preview";

  return (
    <Modal
      visible={visible}
      transparent={!isPreview}
      animationType={isPreview ? "slide" : "fade"}
      onRequestClose={handleClose}
    >
      {isPreview ? (
        <View style={[styles.previewHost, { backgroundColor: colors.background }]}>
          <View style={[styles.previewHeader, { borderBottomColor: colors.border, backgroundColor: colors.card }]}>
            <TouchableOpacity onPress={handleBackFromPreview} style={styles.previewBack}>
              <Feather name="arrow-left" size={20} color={colors.primary} />
            </TouchableOpacity>
            <View style={{ flex: 1 }}>
              <Text style={[styles.previewTitle, { color: colors.foreground }]}>Önizleme</Text>
              <Text style={[styles.previewSub, { color: colors.mutedForeground }]}>
                {formatLabel}
                {selectedFormat === "pdf" ? " · Dikey A4" : ""}
                {" · "}
                {project.satirlar.length} poz
              </Text>
            </View>
            <TouchableOpacity onPress={handleClose} hitSlop={12}>
              <Feather name="x" size={22} color={colors.mutedForeground} />
            </TouchableOpacity>
          </View>

          <View style={styles.previewBody}>
            <WebPdfExportNotice variant="kesif" format={selectedFormat} />
            {previewHtml ? (
              <ExportPreviewPane html={previewHtml} formatLabel={formatLabel} />
            ) : (
              <ActivityIndicator size="large" color={colors.primary} />
            )}
          </View>

          <View style={[styles.previewFooter, { borderTopColor: colors.border, backgroundColor: colors.card }]}>
            <TouchableOpacity
              style={[styles.footerBtn, { backgroundColor: colors.border }]}
              onPress={handleBackFromPreview}
            >
              <Text style={{ color: colors.foreground, fontFamily: "Inter_500Medium" }}>Geri</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.footerBtn, { backgroundColor: colors.primary, flex: 1.4 }]}
              onPress={handleExport}
            >
              <Feather name="download" size={16} color={colors.primaryForeground} />
              <Text style={{ color: colors.primaryForeground, fontFamily: "Inter_700Bold" }}>Dışa Aktar</Text>
            </TouchableOpacity>
          </View>
        </View>
      ) : (
        <Pressable style={styles.overlay} onPress={handleClose}>
          <Pressable
            style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}
            onPress={(e) => e.stopPropagation()}
          >
            <Text style={[styles.title, { color: colors.foreground }]}>Keşifi Dışa Aktar</Text>
            <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
              Dosya formatını seçin, ardından önizleyin
            </Text>

            {FORMATS.map((f) => (
              <TouchableOpacity
                key={f.id}
                activeOpacity={0.85}
                style={[
                  styles.formatOption,
                  { borderColor: f.color + "44", backgroundColor: f.color + "10" },
                ]}
                onPress={() => handleFormatSelect(f.id)}
              >
                <View style={[styles.formatIcon, { backgroundColor: f.color + "22" }]}>
                  <Feather name={f.icon} size={24} color={f.color} />
                </View>
                <Text style={[styles.formatLabel, { color: colors.foreground }]}>{f.label}</Text>
                <Feather name="chevron-right" size={20} color={f.color} />
              </TouchableOpacity>
            ))}

            <TouchableOpacity
              style={[styles.cancelBtn, { backgroundColor: colors.border }]}
              onPress={handleClose}
            >
              <Text style={{ color: colors.foreground, fontFamily: "Inter_500Medium" }}>İptal</Text>
            </TouchableOpacity>
          </Pressable>
        </Pressable>
      )}
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
  formatOption: {
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
    paddingVertical: 18,
    paddingHorizontal: 16,
    borderRadius: 14,
    borderWidth: 1,
  },
  formatIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    alignItems: "center",
    justifyContent: "center",
  },
  formatLabel: {
    flex: 1,
    fontSize: 17,
    fontFamily: "Inter_700Bold",
  },
  cancelBtn: {
    marginTop: 4,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: "center",
  },
  previewHost: {
    flex: 1,
  },
  previewHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderBottomWidth: 1,
  },
  previewBack: {
    width: 36,
    height: 36,
    alignItems: "center",
    justifyContent: "center",
  },
  previewTitle: {
    fontSize: 16,
    fontFamily: "Inter_700Bold",
  },
  previewSub: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    marginTop: 2,
  },
  previewBody: {
    flex: 1,
    padding: 12,
  },
  previewFooter: {
    flexDirection: "row",
    gap: 10,
    padding: 12,
    borderTopWidth: 1,
  },
  footerBtn: {
    flex: 1,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    paddingVertical: 13,
    borderRadius: 10,
  },
});
