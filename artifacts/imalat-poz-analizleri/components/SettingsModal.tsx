import { Feather } from "@expo/vector-icons";
import React, { useState } from "react";
import {
  ActivityIndicator,
  Alert,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import { LegalDocumentModal } from "@/components/LegalDocumentModal";
import { THEMES } from "@/constants/colors";
import {
  APP_DISPLAY_NAME,
  DATA_SOURCE_LABEL,
  DATA_SOURCES,
  DATA_UPDATE_LABEL,
  getAppVersion,
  LOCAL_DATA_NOTE,
  PRIVACY_POLICY,
  TERMS_OF_USE,
  type LegalDocument,
} from "@/constants/appInfo";
import { useApp } from "@/context/AppContext";
import { useKesif } from "@/context/KesifContext";
import { useTheme } from "@/context/ThemeContext";
import { useColors } from "@/hooks/useColors";
import {
  buildUserDataBackup,
  confirmImportMode,
  pickUserDataBackup,
  shareUserDataBackup,
  UserDataBackup,
} from "@/lib/userDataBackup";

interface SettingsModalProps {
  visible: boolean;
  onClose: () => void;
}

export function SettingsModal({ visible, onClose }: SettingsModalProps) {
  const colors = useColors();
  const { pozAnalizleri, favoriteIds, importUserData } = useApp();
  const { projects: kesifProjects, importProjects } = useKesif();
  const { themeId, setThemeId, theme } = useTheme();
  const [exporting, setExporting] = useState(false);
  const [importing, setImporting] = useState(false);
  const [legalDoc, setLegalDoc] = useState<LegalDocument | null>(null);

  async function handleExport() {
    if (exporting || importing) return;
    setExporting(true);
    try {
      const backup = buildUserDataBackup(pozAnalizleri, favoriteIds, themeId, kesifProjects);
      await shareUserDataBackup(backup);
    } finally {
      setExporting(false);
    }
  }

  function applyImport(backup: UserDataBackup, mode: "merge" | "replace") {
    importUserData(
      { pozAnalizleri: backup.pozAnalizleri, favoriteIds: backup.favoriteIds },
      mode,
    );
    importProjects(backup.kesifProjects ?? [], mode);
    if (backup.themeId) {
      setThemeId(backup.themeId);
    }
    Alert.alert(
      "İçe Aktarma Tamamlandı",
      `${backup.pozAnalizleri.length} analiz, ${backup.favoriteIds.length} favori, ${backup.kesifProjects?.length ?? 0} keşif yüklendi.`,
    );
  }

  async function handleImport() {
    if (exporting || importing) return;
    setImporting(true);
    try {
      const backup = await pickUserDataBackup();
      if (!backup) return;

      const hasExistingData =
        pozAnalizleri.length > 0 || favoriteIds.length > 0 || kesifProjects.length > 0;
      confirmImportMode((mode) => applyImport(backup, mode), hasExistingData);
    } finally {
      setImporting(false);
    }
  }

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.overlay} onPress={onClose}>
        <Pressable
          style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={(e) => e.stopPropagation()}
        >
          <Text style={[styles.title, { color: colors.foreground }]}>Ayarlar</Text>

          <ScrollView
            style={styles.scroll}
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
            bounces={false}
          >
            <Text style={[styles.sectionLabel, { color: colors.mutedForeground }]}>Tema</Text>
            <Text style={[styles.sectionHint, { color: colors.mutedForeground }]}>
              Aktif: {theme.name}
            </Text>
            <View style={styles.themeGrid}>
              {THEMES.map((t) => {
                const active = t.id === themeId;
                return (
                  <TouchableOpacity
                    key={t.id}
                    activeOpacity={0.85}
                    style={[
                      styles.themeChip,
                      {
                        borderColor: active ? colors.primary : colors.border,
                        backgroundColor: active ? colors.primary + "14" : colors.background,
                      },
                    ]}
                    onPress={() => setThemeId(t.id)}
                  >
                    <View style={styles.themePreviewRow}>
                      <View style={[styles.themeDot, { backgroundColor: t.preview.bg }]} />
                      <View style={[styles.themeDot, { backgroundColor: t.preview.primary }]} />
                      <View style={[styles.themeDot, { backgroundColor: t.preview.secondary }]} />
                    </View>
                    <Text
                      style={[
                        styles.themeName,
                        { color: active ? colors.primary : colors.foreground },
                      ]}
                      numberOfLines={1}
                    >
                      {t.name}
                    </Text>
                    {active && <Feather name="check" size={14} color={colors.primary} />}
                  </TouchableOpacity>
                );
              })}
            </View>

            <Text style={[styles.sectionLabel, { color: colors.mutedForeground, marginTop: 8 }]}>
              Veri Yedekleme
            </Text>

            <TouchableOpacity
              activeOpacity={0.85}
              style={[
                styles.actionRow,
                { borderColor: colors.primary + "44", backgroundColor: colors.primary + "10" },
              ]}
              onPress={handleExport}
              disabled={exporting || importing}
            >
              <View style={[styles.actionIcon, { backgroundColor: colors.primary + "22" }]}>
                {exporting ? (
                  <ActivityIndicator size="small" color={colors.primary} />
                ) : (
                  <Feather name="upload" size={18} color={colors.primary} />
                )}
              </View>
              <View style={styles.actionText}>
                <Text style={[styles.actionLabel, { color: colors.foreground }]}>Dışa Aktar</Text>
                <Text style={[styles.actionHint, { color: colors.mutedForeground }]}>
                  {pozAnalizleri.length} özel analiz, {favoriteIds.length} favori, {kesifProjects.length} keşif — JSON
                </Text>
              </View>
              <Feather name="chevron-right" size={16} color={colors.primary} />
            </TouchableOpacity>

            <TouchableOpacity
              activeOpacity={0.85}
              style={[
                styles.actionRow,
                { borderColor: "#05966944", backgroundColor: "#05966910" },
              ]}
              onPress={handleImport}
              disabled={exporting || importing}
            >
              <View style={[styles.actionIcon, { backgroundColor: "#05966922" }]}>
                {importing ? (
                  <ActivityIndicator size="small" color="#059669" />
                ) : (
                  <Feather name="download" size={18} color="#059669" />
                )}
              </View>
              <View style={styles.actionText}>
                <Text style={[styles.actionLabel, { color: colors.foreground }]}>İçe Aktar</Text>
                <Text style={[styles.actionHint, { color: colors.mutedForeground }]}>
                  JSON yedek dosyasından geri yükle
                </Text>
              </View>
              <Feather name="chevron-right" size={16} color="#059669" />
            </TouchableOpacity>

            <Text style={[styles.sectionLabel, { color: colors.mutedForeground, marginTop: 8 }]}>
              Uygulama
            </Text>

            <View style={[styles.aboutBox, { backgroundColor: colors.background, borderColor: colors.border }]}>
              <Text style={[styles.aboutName, { color: colors.foreground }]}>{APP_DISPLAY_NAME}</Text>
              <Text style={[styles.aboutMeta, { color: colors.mutedForeground }]}>
                Sürüm {getAppVersion()}
              </Text>
              <Text style={[styles.aboutMeta, { color: colors.mutedForeground }]}>
                Veri kaynağı: {DATA_SOURCE_LABEL}
              </Text>
              <Text style={[styles.aboutMeta, { color: colors.mutedForeground }]}>
                Son veri güncellemesi: {DATA_UPDATE_LABEL}
              </Text>
              <Text style={[styles.aboutNote, { color: colors.mutedForeground }]}>{LOCAL_DATA_NOTE}</Text>
            </View>

            <TouchableOpacity
              activeOpacity={0.85}
              style={[styles.actionRow, { borderColor: colors.border, backgroundColor: colors.background }]}
              onPress={() => setLegalDoc(PRIVACY_POLICY)}
            >
              <View style={[styles.actionIcon, { backgroundColor: colors.foreground + "12" }]}>
                <Feather name="shield" size={18} color={colors.foreground} />
              </View>
              <View style={styles.actionText}>
                <Text style={[styles.actionLabel, { color: colors.foreground }]}>Gizlilik Politikası</Text>
                <Text style={[styles.actionHint, { color: colors.mutedForeground }]}>
                  Veri saklama ve gizlilik bilgileri
                </Text>
              </View>
              <Feather name="chevron-right" size={16} color={colors.mutedForeground} />
            </TouchableOpacity>

            <TouchableOpacity
              activeOpacity={0.85}
              style={[styles.actionRow, { borderColor: colors.border, backgroundColor: colors.background }]}
              onPress={() => setLegalDoc(TERMS_OF_USE)}
            >
              <View style={[styles.actionIcon, { backgroundColor: colors.foreground + "12" }]}>
                <Feather name="file-text" size={18} color={colors.foreground} />
              </View>
              <View style={styles.actionText}>
                <Text style={[styles.actionLabel, { color: colors.foreground }]}>Kullanım Koşulları</Text>
                <Text style={[styles.actionHint, { color: colors.mutedForeground }]}>
                  Sorumluluk ve kullanım şartları
                </Text>
              </View>
              <Feather name="chevron-right" size={16} color={colors.mutedForeground} />
            </TouchableOpacity>

            <TouchableOpacity
              activeOpacity={0.85}
              style={[styles.actionRow, { borderColor: colors.border, backgroundColor: colors.background }]}
              onPress={() => setLegalDoc(DATA_SOURCES)}
            >
              <View style={[styles.actionIcon, { backgroundColor: colors.foreground + "12" }]}>
                <Feather name="book-open" size={18} color={colors.foreground} />
              </View>
              <View style={styles.actionText}>
                <Text style={[styles.actionLabel, { color: colors.foreground }]}>Kaynak</Text>
                <Text style={[styles.actionHint, { color: colors.mutedForeground }]}>
                  Veri kaynağı ve katalog bilgileri
                </Text>
              </View>
              <Feather name="chevron-right" size={16} color={colors.mutedForeground} />
            </TouchableOpacity>
          </ScrollView>

          <TouchableOpacity
            style={[styles.cancelBtn, { backgroundColor: colors.border }]}
            onPress={onClose}
          >
            <Text style={{ color: colors.foreground, fontFamily: "Inter_500Medium" }}>Kapat</Text>
          </TouchableOpacity>
        </Pressable>
      </Pressable>

      <LegalDocumentModal
        visible={legalDoc != null}
        document={legalDoc}
        onClose={() => setLegalDoc(null)}
      />
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
    maxHeight: "88%",
    borderRadius: 16,
    borderWidth: 1,
    padding: 18,
    gap: 10,
  },
  title: {
    fontSize: 17,
    fontFamily: "Inter_700Bold",
  },
  scroll: {
    flexGrow: 0,
  },
  scrollContent: {
    gap: 10,
    paddingBottom: 4,
  },
  sectionLabel: {
    fontSize: 12,
    fontFamily: "Inter_600SemiBold",
    textTransform: "uppercase",
    letterSpacing: 0.5,
  },
  sectionHint: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    marginTop: -4,
  },
  themeGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  themeChip: {
    width: "48%",
    flexGrow: 1,
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingVertical: 10,
    paddingHorizontal: 10,
    borderRadius: 10,
    borderWidth: 1,
  },
  themePreviewRow: {
    flexDirection: "row",
    gap: 2,
  },
  themeDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: "rgba(0,0,0,0.12)",
  },
  themeName: {
    flex: 1,
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
  },
  actionRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    paddingVertical: 12,
    paddingHorizontal: 12,
    borderRadius: 12,
    borderWidth: 1,
  },
  actionIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: "center",
    justifyContent: "center",
  },
  actionText: {
    flex: 1,
    gap: 2,
  },
  actionLabel: {
    fontSize: 13,
    fontFamily: "Inter_700Bold",
    letterSpacing: 0.3,
  },
  actionHint: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    lineHeight: 15,
  },
  aboutBox: {
    borderWidth: 1,
    borderRadius: 12,
    padding: 12,
    gap: 4,
  },
  aboutName: {
    fontSize: 13,
    fontFamily: "Inter_700Bold",
    marginBottom: 2,
  },
  aboutMeta: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    lineHeight: 15,
  },
  aboutNote: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    lineHeight: 15,
    marginTop: 4,
  },
  cancelBtn: {
    marginTop: 4,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: "center",
  },
});
