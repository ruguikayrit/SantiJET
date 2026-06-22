import { Feather } from "@expo/vector-icons";
import React, { useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  FlatList,
  Modal,
  Platform,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { PozAnaliz, matchesPozAnalizSearch } from "@/constants/pozAnalizleri";
import { useBfaCatalog } from "@/hooks/useBfaCatalog";
import { useColors } from "@/hooks/useColors";

interface KesifPozPickerModalProps {
  visible: boolean;
  onClose: () => void;
  onSelect: (analiz: PozAnaliz, miktar: number) => void;
}

export function KesifPozPickerModal({ visible, onClose, onSelect }: KesifPozPickerModalProps) {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;
  const { all, loading } = useBfaCatalog();
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<PozAnaliz | null>(null);
  const [miktar, setMiktar] = useState("1");

  useEffect(() => {
    if (!visible) {
      setSearch("");
      setSelected(null);
      setMiktar("1");
    }
  }, [visible]);

  const filtered = useMemo(() => {
    if (!search.trim()) return all.slice(0, 50);
    return all
      .filter((a) => matchesPozAnalizSearch(a, search))
      .sort((a, b) => a.pozNo.localeCompare(b.pozNo, "tr"))
      .slice(0, 80);
  }, [all, search]);

  function handleClose() {
    setSearch("");
    setSelected(null);
    setMiktar("1");
    onClose();
  }

  function parseQty(s: string): number {
    const v = parseFloat(s.replace(",", "."));
    return Number.isFinite(v) ? v : 0;
  }

  function handleConfirm() {
    if (!selected) return;
    onSelect(selected, parseQty(miktar));
    handleClose();
  }

  return (
    <Modal
      visible={visible}
      animationType="slide"
      onRequestClose={handleClose}
      presentationStyle="pageSheet"
    >
      <View style={[styles.host, { backgroundColor: colors.background }]}>
        <View
          style={[
            styles.header,
            {
              backgroundColor: colors.secondary,
              borderBottomColor: colors.border,
              paddingTop: topPad + 8,
            },
          ]}
        >
          <View style={styles.headerSide} />
          <Text style={[styles.headerTitle, { color: colors.secondaryForeground }]}>
            {selected ? "Miktar Gir" : "Poz Seç"}
          </Text>
          <TouchableOpacity onPress={handleClose} style={styles.iconBtn} accessibilityLabel="Kapat">
            <Feather name="x" size={22} color={colors.secondaryForeground} />
          </TouchableOpacity>
        </View>

        {selected ? (
          <View style={styles.qtyPane}>
            <Text style={[styles.selectedPoz, { color: colors.primary }]}>{selected.pozNo}</Text>
            <Text style={[styles.selectedAd, { color: colors.foreground }]}>{selected.analizAdi}</Text>
            <Text style={[styles.selectedUnit, { color: colors.mutedForeground }]}>
              Birim: {selected.olcuBirimi}
            </Text>
            <Text style={[styles.qtyLabel, { color: colors.mutedForeground }]}>Miktar</Text>
            <TextInput
              style={[
                styles.qtyInput,
                { color: colors.foreground, borderColor: colors.border, backgroundColor: colors.card },
              ]}
              value={miktar}
              onChangeText={setMiktar}
              keyboardType="decimal-pad"
              autoFocus
              selectTextOnFocus
            />
            <View style={styles.qtyBtns}>
              <TouchableOpacity
                style={[styles.btn, { backgroundColor: colors.border }]}
                onPress={() => setSelected(null)}
              >
                <Text style={{ color: colors.foreground, fontFamily: "Inter_500Medium" }}>Geri</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.btn, { backgroundColor: colors.border }]}
                onPress={handleClose}
              >
                <Text style={{ color: colors.foreground, fontFamily: "Inter_500Medium" }}>İptal</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.btn, { backgroundColor: colors.primary, flex: 1.2 }]}
                onPress={handleConfirm}
              >
                <Text style={{ color: colors.primaryForeground, fontFamily: "Inter_700Bold" }}>Ekle</Text>
              </TouchableOpacity>
            </View>
          </View>
        ) : (
          <View style={styles.listPane}>
            <View
              style={[
                styles.searchWrap,
                { backgroundColor: colors.card, borderColor: colors.border },
              ]}
            >
              <Feather name="search" size={18} color={colors.mutedForeground} />
              <TextInput
                style={[styles.searchInput, { color: colors.foreground }]}
                placeholder="Poz No veya analiz adı ara..."
                placeholderTextColor={colors.mutedForeground}
                value={search}
                onChangeText={setSearch}
                autoFocus
              />
              {search.length > 0 && (
                <TouchableOpacity onPress={() => setSearch("")}>
                  <Feather name="x" size={18} color={colors.mutedForeground} />
                </TouchableOpacity>
              )}
            </View>

            {loading ? (
              <ActivityIndicator style={{ marginTop: 40 }} color={colors.primary} />
            ) : (
              <FlatList
                style={styles.list}
                data={filtered}
                keyExtractor={(item) => item.id}
                keyboardShouldPersistTaps="handled"
                contentContainerStyle={{ paddingBottom: 12 }}
                renderItem={({ item }) => (
                  <TouchableOpacity
                    style={[styles.row, { borderColor: colors.border, backgroundColor: colors.card }]}
                    onPress={() => setSelected(item)}
                    activeOpacity={0.8}
                  >
                    <Text style={[styles.rowPoz, { color: colors.primary }]}>{item.pozNo}</Text>
                    <Text style={[styles.rowAd, { color: colors.foreground }]} numberOfLines={2}>
                      {item.analizAdi}
                    </Text>
                    <Text style={[styles.rowUnit, { color: colors.mutedForeground }]}>
                      {item.olcuBirimi}
                    </Text>
                  </TouchableOpacity>
                )}
                ListEmptyComponent={
                  <Text style={[styles.empty, { color: colors.mutedForeground }]}>
                    Analiz bulunamadı
                  </Text>
                }
              />
            )}

            <View
              style={[
                styles.footer,
                {
                  borderTopColor: colors.border,
                  backgroundColor: colors.card,
                  paddingBottom: Math.max(insets.bottom, 12),
                },
              ]}
            >
              <TouchableOpacity
                style={[styles.footerBtn, { backgroundColor: colors.border }]}
                onPress={handleClose}
              >
                <Text style={{ color: colors.foreground, fontFamily: "Inter_600SemiBold" }}>
                  Seçim yapmadan çık
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  host: { flex: 1 },
  listPane: { flex: 1 },
  list: { flex: 1 },
  header: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingVertical: 14,
    borderBottomWidth: 1,
  },
  iconBtn: {
    width: 40,
    height: 40,
    alignItems: "center",
    justifyContent: "center",
  },
  headerSide: {
    width: 40,
    height: 40,
  },
  headerTitle: {
    flex: 1,
    textAlign: "center",
    fontSize: 16,
    fontFamily: "Inter_700Bold",
  },
  searchWrap: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    margin: 12,
    borderRadius: 10,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 12,
  },
  searchInput: {
    flex: 1,
    fontSize: 15,
    fontFamily: "Inter_400Regular",
    padding: 0,
  },
  row: {
    marginHorizontal: 12,
    marginBottom: 8,
    borderRadius: 10,
    borderWidth: 1,
    padding: 12,
    gap: 4,
  },
  rowPoz: { fontSize: 12, fontFamily: "Inter_700Bold" },
  rowAd: { fontSize: 13, fontFamily: "Inter_400Regular", lineHeight: 18 },
  rowUnit: { fontSize: 11, fontFamily: "Inter_500Medium" },
  empty: { textAlign: "center", marginTop: 40, fontSize: 14 },
  qtyPane: { padding: 20, gap: 10 },
  selectedPoz: { fontSize: 14, fontFamily: "Inter_700Bold" },
  selectedAd: { fontSize: 15, fontFamily: "Inter_500Medium", lineHeight: 22 },
  selectedUnit: { fontSize: 12, fontFamily: "Inter_400Regular" },
  qtyLabel: {
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
    textTransform: "uppercase",
    marginTop: 8,
  },
  qtyInput: {
    fontSize: 22,
    fontFamily: "Inter_700Bold",
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    textAlign: "right",
  },
  qtyBtns: { flexDirection: "row", gap: 10, marginTop: 16 },
  btn: {
    flex: 1,
    paddingVertical: 13,
    borderRadius: 10,
    alignItems: "center",
  },
  footer: {
    borderTopWidth: 1,
    paddingHorizontal: 12,
    paddingTop: 12,
  },
  footerBtn: {
    paddingVertical: 14,
    borderRadius: 10,
    alignItems: "center",
  },
});
