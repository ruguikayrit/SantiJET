import { Feather } from "@expo/vector-icons";
import React, { useState } from "react";
import {
  ActivityIndicator,
  Modal,
  Pressable,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import { useApp } from "@/context/AppContext";
import { useTheme } from "@/context/ThemeContext";
import { useColors } from "@/hooks/useColors";
import { buildUserDataBackup, shareUserDataBackup } from "@/lib/userDataBackup";

interface SettingsModalProps {
  visible: boolean;
  onClose: () => void;
}

export function SettingsModal({ visible, onClose }: SettingsModalProps) {
  const colors = useColors();
  const { pozAnalizleri, favoriteIds } = useApp();
  const { themeId } = useTheme();
  const [saving, setSaving] = useState(false);

  async function handleSaveData() {
    if (saving) return;
    setSaving(true);
    try {
      const backup = buildUserDataBackup(pozAnalizleri, favoriteIds, themeId);
      await shareUserDataBackup(backup);
    } finally {
      setSaving(false);
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

          <TouchableOpacity
            activeOpacity={0.85}
            style={[
              styles.actionRow,
              { borderColor: colors.primary + "44", backgroundColor: colors.primary + "10" },
            ]}
            onPress={handleSaveData}
            disabled={saving}
          >
            <View style={[styles.actionIcon, { backgroundColor: colors.primary + "22" }]}>
              {saving ? (
                <ActivityIndicator size="small" color={colors.primary} />
              ) : (
                <Feather name="download" size={18} color={colors.primary} />
              )}
            </View>
            <View style={styles.actionText}>
              <Text style={[styles.actionLabel, { color: colors.foreground }]}>
                Verileri Kaydet
              </Text>
              <Text style={[styles.actionHint, { color: colors.mutedForeground }]}>
                {pozAnalizleri.length} özel analiz, {favoriteIds.length} favori — JSON yedek dosyası
              </Text>
            </View>
            <Feather name="chevron-right" size={16} color={colors.primary} />
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.cancelBtn, { backgroundColor: colors.border }]}
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
    borderRadius: 16,
    borderWidth: 1,
    padding: 18,
    gap: 10,
  },
  title: {
    fontSize: 17,
    fontFamily: "Inter_700Bold",
    marginBottom: 4,
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
  cancelBtn: {
    marginTop: 4,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: "center",
  },
});
