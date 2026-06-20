import { Feather } from "@expo/vector-icons";
import React from "react";
import {
  Modal,
  Pressable,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import {
  BFA_MODULES,
  BfaDiscipline,
  isBfaDiscipline,
} from "@/constants/bfaModules";
import { useColors } from "@/hooks/useColors";

interface NewAnalizModulePickerModalProps {
  visible: boolean;
  onClose: () => void;
  onSelect: (modul: BfaDiscipline) => void;
}

const CREATE_MODULES = BFA_MODULES.filter((m) => isBfaDiscipline(m.modul));

export function NewAnalizModulePickerModal({
  visible,
  onClose,
  onSelect,
}: NewAnalizModulePickerModalProps) {
  const colors = useColors();

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.overlay} onPress={onClose}>
        <Pressable
          style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={(e) => e.stopPropagation()}
        >
          <Text style={[styles.title, { color: colors.foreground }]}>Yeni Analiz</Text>
          <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
            Analiz hangi modüle eklensin?
          </Text>

          {CREATE_MODULES.map((mod) => (
            <TouchableOpacity
              key={mod.modul}
              activeOpacity={0.85}
              style={[
                styles.option,
                { borderColor: mod.color + "44", backgroundColor: mod.color + "10" },
              ]}
              onPress={() => onSelect(mod.modul as BfaDiscipline)}
            >
              <View style={[styles.optionIcon, { backgroundColor: mod.color + "22" }]}>
                <Feather name={mod.icon} size={18} color={mod.color} />
              </View>
              <View style={styles.optionText}>
                <Text style={[styles.optionLabel, { color: colors.foreground }]}>{mod.label}</Text>
                <Text style={[styles.optionHint, { color: colors.mutedForeground }]}>
                  {mod.screenTitle}
                </Text>
              </View>
              <Feather name="chevron-right" size={16} color={mod.color} />
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
    letterSpacing: 0.3,
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
