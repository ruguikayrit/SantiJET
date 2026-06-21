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
import { WebPdfExportNotice, WebPdfExportVariant } from "@/components/WebPdfExportNotice";
import { AnalizExportFormat, PdfPaperOrientation } from "@/lib/analizExport";
import { useColors } from "@/hooks/useColors";

interface BulkExportModalProps {
  visible: boolean;
  count: number;
  onClose: () => void;
  onExport: (format: AnalizExportFormat, pdfOrientation?: PdfPaperOrientation) => void;
  title?: string;
  subtitle?: string;
  orientationHint?: string;
  previewCaption?: string;
  getPreviewHtml: (
    format: AnalizExportFormat,
    pdfOrientation: PdfPaperOrientation,
  ) => string;
  webPdfVariant?: WebPdfExportVariant;
}

const ORIENTATIONS: {
  id: PdfPaperOrientation;
  label: string;
  hint: string;
  icon: keyof typeof Feather.glyphMap;
}[] = [
  { id: "landscape", label: "Yatay (A4)", hint: "Geniş tablo için önerilir", icon: "maximize-2" },
  { id: "portrait", label: "Dikey (A4)", hint: "Standart dikey kağıt", icon: "smartphone" },
];

export function BulkExportModal({
  visible,
  count,
  onClose,
  onExport,
  title = "Toplu Dışa Aktar",
  subtitle,
  orientationHint,
  previewCaption,
  getPreviewHtml,
  webPdfVariant = "bulk",
}: BulkExportModalProps) {
  const colors = useColors();
  const [step, setStep] = useState<"format" | "pdf-orientation" | "preview">("format");
  const [selectedFormat, setSelectedFormat] = useState<AnalizExportFormat>("pdf");
  const [selectedOrientation, setSelectedOrientation] = useState<PdfPaperOrientation>("landscape");

  const formats = [
    { id: "pdf" as const, label: "PDF", icon: "file-text" as const, color: "#dc2626" },
    { id: "excel" as const, label: "Excel", icon: "grid" as const, color: "#059669" },
  ];

  useEffect(() => {
    if (!visible) {
      setStep("format");
      setSelectedFormat("pdf");
      setSelectedOrientation("landscape");
    }
  }, [visible]);

  const previewHtml = useMemo(() => {
    if (step !== "preview") return "";
    return getPreviewHtml(selectedFormat, selectedOrientation);
  }, [step, selectedFormat, selectedOrientation, getPreviewHtml]);

  const formatLabel = selectedFormat === "pdf" ? "PDF" : "Excel";

  function handleClose() {
    setStep("format");
    onClose();
  }

  function handleFormatSelect(format: AnalizExportFormat) {
    setSelectedFormat(format);
    if (format === "pdf") {
      setStep("pdf-orientation");
      return;
    }
    setStep("preview");
  }

  function handleOrientationSelect(orientation: PdfPaperOrientation) {
    setSelectedOrientation(orientation);
    setStep("preview");
  }

  function handleExport() {
    onExport(selectedFormat, selectedFormat === "pdf" ? selectedOrientation : undefined);
  }

  function handleBackFromPreview() {
    setStep(selectedFormat === "pdf" ? "pdf-orientation" : "format");
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
                {selectedFormat === "pdf"
                  ? selectedOrientation === "landscape"
                    ? " · Yatay A4"
                    : " · Dikey A4"
                  : ""}
                {previewCaption ? ` · ${previewCaption}` : ""}
              </Text>
            </View>
            <TouchableOpacity onPress={handleClose} hitSlop={12}>
              <Feather name="x" size={22} color={colors.mutedForeground} />
            </TouchableOpacity>
          </View>

          <View style={styles.previewBody}>
            <WebPdfExportNotice variant={webPdfVariant} format={selectedFormat} />
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
            {step === "format" ? (
              <>
                <Text style={[styles.title, { color: colors.foreground }]}>{title}</Text>
                <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
                  {subtitle ?? `${count} analiz — format seçin, ardından önizleyin`}
                </Text>

                {formats.map((f) => (
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
              </>
            ) : (
              <>
                <TouchableOpacity style={styles.backLink} onPress={() => setStep("format")}>
                  <Feather name="arrow-left" size={16} color={colors.primary} />
                  <Text style={[styles.backText, { color: colors.primary }]}>Format seçimi</Text>
                </TouchableOpacity>

                <Text style={[styles.title, { color: colors.foreground }]}>PDF Kağıt Yönü</Text>
                <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
                  {orientationHint ?? "Kağıt yönünü seçin"}
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
