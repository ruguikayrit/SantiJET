import { Feather } from "@expo/vector-icons";
import React from "react";
import { Alert, StyleSheet, Text, TouchableOpacity, View } from "react-native";

import { useColors } from "@/hooks/useColors";

interface Props {
  count: number;
  onCancel: () => void;
  onDelete: () => void;
  itemLabel?: string;
}

export default function MultiSelectBar({ count, onCancel, onDelete, itemLabel = "kayıt" }: Props) {
  const colors = useColors();
  const confirm = () => {
    if (count === 0) return;
    Alert.alert(
      "Seçilenleri sil",
      `${count} ${itemLabel} silinecek. Bu işlem geri alınamaz.`,
      [
        { text: "Vazgeç", style: "cancel" },
        { text: "Sil", style: "destructive", onPress: onDelete },
      ],
    );
  };
  return (
    <View
      style={[
        styles.bar,
        { backgroundColor: colors.card, borderBottomColor: colors.muted },
      ]}
    >
      <TouchableOpacity onPress={onCancel} style={styles.iconBtn} activeOpacity={0.7}>
        <Feather name="x" size={20} color={colors.foreground} />
      </TouchableOpacity>
      <Text style={[styles.count, { color: colors.foreground }]}>
        {count} seçili
      </Text>
      <TouchableOpacity
        onPress={confirm}
        disabled={count === 0}
        activeOpacity={0.85}
        style={[
          styles.delBtn,
          {
            backgroundColor: count === 0 ? colors.muted : "#dc2626",
            opacity: count === 0 ? 0.6 : 1,
          },
        ]}
      >
        <Feather name="trash-2" size={14} color={count === 0 ? colors.foreground : "#fff"} />
        <Text style={[styles.delText, { color: count === 0 ? colors.foreground : "#fff" }]}>
          Sil
        </Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingVertical: 10,
    gap: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  iconBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: "center",
    justifyContent: "center",
  },
  count: { flex: 1, fontSize: 14, fontFamily: "Inter_700Bold" },
  delBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 8,
  },
  delText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
});
