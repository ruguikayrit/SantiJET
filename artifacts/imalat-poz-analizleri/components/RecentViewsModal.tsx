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

import { PozAnaliz } from "@/constants/pozAnalizleri";
import { useColors } from "@/hooks/useColors";

interface RecentViewsModalProps {
  visible: boolean;
  onClose: () => void;
  items: PozAnaliz[];
  onSelect: (id: string) => void;
}

export function RecentViewsModal({
  visible,
  onClose,
  items,
  onSelect,
}: RecentViewsModalProps) {
  const colors = useColors();

  function handleSelect(id: string) {
    onSelect(id);
    onClose();
  }

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.overlay} onPress={onClose}>
        <Pressable
          style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={(e) => e.stopPropagation()}
        >
          <Text style={[styles.title, { color: colors.foreground }]}>Son Görüntülenenler</Text>
          <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
            {items.length > 0
              ? `${items.length} analiz — dokunarak açın`
              : "Henüz görüntülenen analiz yok"}
          </Text>

          {items.length > 0 ? (
            <ScrollView
              style={styles.list}
              contentContainerStyle={styles.listContent}
              showsVerticalScrollIndicator={false}
              keyboardShouldPersistTaps="handled"
            >
              {items.map((item, index) => (
                <TouchableOpacity
                  key={item.id}
                  activeOpacity={0.85}
                  style={[
                    styles.row,
                    {
                      borderColor: colors.border,
                      backgroundColor: index % 2 === 0 ? colors.background : colors.card + "88",
                    },
                  ]}
                  onPress={() => handleSelect(item.id)}
                >
                  <View style={[styles.rowNo, { backgroundColor: "#6366f118" }]}>
                    <Text style={[styles.rowNoText, { color: "#6366f1" }]}>{index + 1}</Text>
                  </View>
                  <View style={styles.rowMain}>
                    <Text style={[styles.rowPoz, { color: colors.primary }]}>{item.pozNo}</Text>
                    <Text style={[styles.rowAd, { color: colors.foreground }]} numberOfLines={2}>
                      {item.analizAdi}
                    </Text>
                    <Text style={[styles.rowBirim, { color: colors.mutedForeground }]}>
                      {item.olcuBirimi}
                    </Text>
                  </View>
                  <Feather name="chevron-right" size={16} color={colors.mutedForeground} />
                </TouchableOpacity>
              ))}
            </ScrollView>
          ) : (
            <View style={styles.empty}>
              <Feather name="clock" size={36} color={colors.mutedForeground} />
              <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>
                Modüllerden bir analiz açtığınızda burada listelenir.
              </Text>
            </View>
          )}

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
    maxHeight: "82%",
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
  list: {
    flexGrow: 0,
  },
  listContent: {
    gap: 8,
    paddingBottom: 4,
  },
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    paddingVertical: 10,
    paddingHorizontal: 10,
    borderRadius: 10,
    borderWidth: 1,
  },
  rowNo: {
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: "center",
    justifyContent: "center",
  },
  rowNoText: {
    fontSize: 12,
    fontFamily: "Inter_700Bold",
  },
  rowMain: {
    flex: 1,
    gap: 2,
  },
  rowPoz: {
    fontSize: 12,
    fontFamily: "Inter_700Bold",
  },
  rowAd: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    lineHeight: 17,
  },
  rowBirim: {
    fontSize: 11,
    fontFamily: "Inter_500Medium",
  },
  empty: {
    alignItems: "center",
    paddingVertical: 28,
    paddingHorizontal: 12,
    gap: 12,
  },
  emptyText: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    textAlign: "center",
    lineHeight: 18,
  },
  cancelBtn: {
    marginTop: 4,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: "center",
  },
});
