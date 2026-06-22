import React from "react";
import {
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import type { LegalDocument } from "@/constants/appInfo";
import { useColors } from "@/hooks/useColors";

interface LegalDocumentModalProps {
  visible: boolean;
  document: LegalDocument | null;
  onClose: () => void;
}

export function LegalDocumentModal({ visible, document, onClose }: LegalDocumentModalProps) {
  const colors = useColors();
  if (!document) return null;

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.overlay} onPress={onClose}>
        <Pressable
          style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={(e) => e.stopPropagation()}
        >
          <Text style={[styles.title, { color: colors.foreground }]}>{document.title}</Text>
          <Text style={[styles.updated, { color: colors.mutedForeground }]}>
            Son güncelleme: {document.updatedAt}
          </Text>

          <ScrollView
            style={styles.scroll}
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
          >
            {document.sections.map((section) => (
              <View key={section.heading} style={styles.section}>
                <Text style={[styles.heading, { color: colors.foreground }]}>{section.heading}</Text>
                <Text style={[styles.body, { color: colors.mutedForeground }]}>{section.body}</Text>
              </View>
            ))}
          </ScrollView>

          <TouchableOpacity
            style={[styles.closeBtn, { backgroundColor: colors.border }]}
            onPress={onClose}
          >
            <Text style={{ color: colors.foreground, fontFamily: "Inter_500Medium" }}>Kapat</Text>
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
    maxHeight: "84%",
    borderRadius: 16,
    borderWidth: 1,
    padding: 18,
    gap: 8,
  },
  title: {
    fontSize: 17,
    fontFamily: "Inter_700Bold",
  },
  updated: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    marginBottom: 4,
  },
  scroll: {
    flexGrow: 0,
  },
  scrollContent: {
    gap: 14,
    paddingBottom: 4,
  },
  section: {
    gap: 4,
  },
  heading: {
    fontSize: 13,
    fontFamily: "Inter_700Bold",
  },
  body: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    lineHeight: 18,
  },
  closeBtn: {
    marginTop: 4,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: "center",
  },
});
