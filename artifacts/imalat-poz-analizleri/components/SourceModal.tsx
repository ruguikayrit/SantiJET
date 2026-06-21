import { Feather } from "@expo/vector-icons";
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

import { DATA_UPDATE_LABEL } from "@/constants/appInfo";
import {
  OFFICIAL_SOURCE_LINKS,
  OFFICIAL_SOURCE_PORTAL_URL,
  OFFICIAL_SOURCE_UPDATED_AT,
  SOURCE_DISTRIBUTION_NOTICE,
  SOURCE_VERIFICATION_TEXT,
} from "@/constants/officialSources";
import { useColors } from "@/hooks/useColors";
import { openOfficialSource } from "@/lib/openOfficialSource";

interface SourceModalProps {
  visible: boolean;
  onClose: () => void;
}

export function SourceModal({ visible, onClose }: SourceModalProps) {
  const colors = useColors();

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.overlay} onPress={onClose}>
        <Pressable
          style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={(e) => e.stopPropagation()}
        >
          <Text style={[styles.title, { color: colors.foreground }]}>Kaynak</Text>
          <Text style={[styles.updated, { color: colors.mutedForeground }]}>
            Son güncelleme: {OFFICIAL_SOURCE_UPDATED_AT}
          </Text>

          <ScrollView
            style={styles.scroll}
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
          >
            <View style={styles.section}>
              <Text style={[styles.heading, { color: colors.foreground }]}>
                Resmi Referans Kaynakları
              </Text>
              <Text style={[styles.body, { color: colors.mutedForeground }]}>
                Bu uygulamada kullanılan katalog verileri aşağıdaki resmi yayınlar referans
                alınarak hazırlanmıştır.
              </Text>
            </View>

            {OFFICIAL_SOURCE_LINKS.map((item) => (
              <TouchableOpacity
                key={item.id}
                activeOpacity={0.85}
                accessibilityRole="button"
                accessibilityLabel={`${item.title}, resmi kaynağı aç`}
                style={[
                  styles.sourceCard,
                  { borderColor: colors.border, backgroundColor: colors.background },
                ]}
                onPress={() => openOfficialSource(item.url)}
              >
                <View style={[styles.sourceIcon, { backgroundColor: colors.primary + "18" }]}>
                  <Feather name="file-text" size={18} color={colors.primary} />
                </View>
                <View style={styles.sourceText}>
                  <Text style={[styles.sourceTitle, { color: colors.foreground }]}>
                    {item.title}
                  </Text>
                  <Text style={[styles.sourceSubtitle, { color: colors.mutedForeground }]}>
                    {item.subtitle}
                  </Text>
                  <Text style={[styles.sourceAction, { color: colors.primary }]}>
                    → Resmi Kaynağı Aç
                  </Text>
                </View>
                <Feather name="external-link" size={15} color={colors.mutedForeground} />
              </TouchableOpacity>
            ))}

            <Text style={[styles.meta, { color: colors.mutedForeground }]}>
              Uygulama içi katalog son güncelleme: {DATA_UPDATE_LABEL}.
            </Text>

            <View style={[styles.verifyCard, { backgroundColor: colors.success + "18" }]}>
              <Text style={[styles.verifyTitle, { color: colors.foreground }]}>Veri Doğrulama</Text>
              <Text style={[styles.body, { color: colors.mutedForeground }]}>
                {SOURCE_VERIFICATION_TEXT}
              </Text>
              <TouchableOpacity
                activeOpacity={0.85}
                accessibilityRole="button"
                accessibilityLabel="Resmi kaynakları aç"
                style={[styles.verifyBtn, { backgroundColor: colors.primary }]}
                onPress={() => openOfficialSource(OFFICIAL_SOURCE_PORTAL_URL)}
              >
                <Text style={[styles.verifyBtnLabel, { color: colors.primaryForeground }]}>
                  Resmi Kaynakları Aç
                </Text>
                <Feather name="external-link" size={14} color={colors.primaryForeground} />
              </TouchableOpacity>
            </View>

            <Text style={[styles.notice, { color: colors.mutedForeground }]}>
              Bu uygulama resmi yayınların yerine geçmez. Nihai doğrulama için ilgili kurumların
              güncel yayınları esas alınmalıdır.
            </Text>

            <Text style={[styles.notice, { color: colors.mutedForeground }]}>
              {SOURCE_DISTRIBUTION_NOTICE}
            </Text>
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
    gap: 12,
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
  sourceCard: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    minHeight: 56,
    paddingVertical: 12,
    paddingHorizontal: 12,
    borderRadius: 12,
    borderWidth: 1,
  },
  sourceIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: "center",
    justifyContent: "center",
    flexShrink: 0,
  },
  sourceText: {
    flex: 1,
    gap: 3,
    minWidth: 0,
  },
  sourceTitle: {
    fontSize: 13,
    fontFamily: "Inter_700Bold",
    letterSpacing: 0.2,
  },
  sourceSubtitle: {
    fontSize: 11,
    fontFamily: "Inter_500Medium",
    lineHeight: 15,
  },
  sourceAction: {
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
  },
  meta: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    lineHeight: 16,
  },
  verifyCard: {
    gap: 8,
    padding: 12,
    borderRadius: 12,
  },
  verifyTitle: {
    fontSize: 13,
    fontFamily: "Inter_700Bold",
  },
  verifyBtn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    minHeight: 44,
    paddingHorizontal: 14,
    borderRadius: 10,
    marginTop: 2,
  },
  verifyBtnLabel: {
    fontSize: 13,
    fontFamily: "Inter_700Bold",
  },
  notice: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    lineHeight: 16,
    textAlign: "center",
  },
  closeBtn: {
    marginTop: 4,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: "center",
  },
});
