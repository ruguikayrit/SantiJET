import { Feather } from "@expo/vector-icons";
import React, { useMemo, useState } from "react";
import {
  FlatList,
  Modal,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { MATERIAL_UNITS } from "@/constants/units";
import { useColors } from "@/hooks/useColors";

interface Props {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
}

export default function UnitPicker({
  label,
  value,
  onChange,
  placeholder = "Birim seçin",
}: Props) {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState("");

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return MATERIAL_UNITS;
    return MATERIAL_UNITS.filter(
      (u) =>
        u.code.toLowerCase().includes(q) ||
        u.label.toLowerCase().includes(q)
    );
  }, [search]);

  const showCustomOption =
    search.trim().length > 0 &&
    !MATERIAL_UNITS.some(
      (u) => u.code.toLowerCase() === search.trim().toLowerCase()
    );

  function pick(code: string) {
    onChange(code);
    setOpen(false);
    setSearch("");
  }

  return (
    <View style={styles.wrap}>
      <Text style={[styles.label, { color: colors.foreground }]}>{label}</Text>
      <TouchableOpacity
        activeOpacity={0.75}
        onPress={() => setOpen(true)}
        style={[
          styles.input,
          {
            backgroundColor: colors.background,
            borderColor: colors.border,
          },
        ]}
      >
        <Text
          style={[
            styles.value,
            {
              color: value ? colors.foreground : colors.mutedForeground,
            },
          ]}
        >
          {value || placeholder}
        </Text>
        <Feather name="chevron-down" size={18} color={colors.mutedForeground} />
      </TouchableOpacity>

      <Modal
        visible={open}
        animationType="fade"
        transparent
        onRequestClose={() => setOpen(false)}
      >
        <Pressable
          style={styles.backdrop}
          onPress={() => {
            setOpen(false);
            setSearch("");
          }}
        >
          <Pressable
            onPress={() => {}}
            style={[
              styles.sheet,
              {
                backgroundColor: colors.card,
                paddingBottom: Math.max(insets.bottom, 12),
              },
            ]}
          >
            <View style={styles.handle} />
            <View style={styles.headerRow}>
              <Text style={[styles.title, { color: colors.foreground }]}>
                Birim Seç
              </Text>
              <TouchableOpacity
                onPress={() => {
                  setOpen(false);
                  setSearch("");
                }}
                hitSlop={10}
              >
                <Feather name="x" size={22} color={colors.mutedForeground} />
              </TouchableOpacity>
            </View>

            <View style={[styles.searchBox, { backgroundColor: colors.muted }]}>
              <Feather name="search" size={14} color={colors.mutedForeground} />
              <TextInput
                value={search}
                onChangeText={setSearch}
                placeholder="Ara veya yaz: kg, m3, torba..."
                placeholderTextColor={colors.mutedForeground}
                style={[styles.searchInput, { color: colors.foreground }]}
                autoFocus
                autoCorrect={false}
                autoCapitalize="characters"
                returnKeyType="done"
                onSubmitEditing={() => {
                  if (filtered.length > 0) pick(filtered[0].code);
                  else if (search.trim()) pick(search.trim().toUpperCase());
                }}
              />
              {search.length > 0 ? (
                <TouchableOpacity onPress={() => setSearch("")} hitSlop={10}>
                  <Feather
                    name="x-circle"
                    size={14}
                    color={colors.mutedForeground}
                  />
                </TouchableOpacity>
              ) : null}
            </View>

            <FlatList
              data={filtered}
              keyExtractor={(u) => u.code}
              keyboardShouldPersistTaps="handled"
              ListHeaderComponent={
                showCustomOption ? (
                  <TouchableOpacity
                    onPress={() => pick(search.trim().toUpperCase())}
                    style={[
                      styles.row,
                      {
                        borderBottomColor: colors.border,
                        backgroundColor: colors.primary + "10",
                      },
                    ]}
                    activeOpacity={0.7}
                  >
                    <View
                      style={[
                        styles.codeBadge,
                        { backgroundColor: colors.primary },
                      ]}
                    >
                      <Feather name="plus" size={14} color="#fff" />
                    </View>
                    <View style={{ flex: 1 }}>
                      <Text style={[styles.rowCode, { color: colors.primary }]}>
                        "{search.trim().toUpperCase()}" birimini ekle
                      </Text>
                      <Text
                        style={[
                          styles.rowLabel,
                          { color: colors.mutedForeground },
                        ]}
                      >
                        Listede yok — özel birim olarak kullan
                      </Text>
                    </View>
                  </TouchableOpacity>
                ) : null
              }
              renderItem={({ item }) => {
                const sel = item.code === value;
                return (
                  <TouchableOpacity
                    onPress={() => pick(item.code)}
                    style={[
                      styles.row,
                      {
                        borderBottomColor: colors.border,
                        backgroundColor: sel ? colors.primary + "12" : "transparent",
                      },
                    ]}
                    activeOpacity={0.7}
                  >
                    <View
                      style={[
                        styles.codeBadge,
                        {
                          backgroundColor: sel
                            ? colors.primary
                            : colors.muted,
                        },
                      ]}
                    >
                      <Text
                        style={[
                          styles.codeText,
                          { color: sel ? "#fff" : colors.foreground },
                        ]}
                      >
                        {item.code}
                      </Text>
                    </View>
                    <Text
                      style={[
                        styles.rowLabel,
                        {
                          color: sel ? colors.primary : colors.foreground,
                          flex: 1,
                          fontFamily: sel
                            ? "Inter_600SemiBold"
                            : "Inter_400Regular",
                        },
                      ]}
                    >
                      {item.label}
                    </Text>
                    {sel ? (
                      <Feather name="check" size={18} color={colors.primary} />
                    ) : null}
                  </TouchableOpacity>
                );
              }}
              ListEmptyComponent={
                showCustomOption ? null : (
                  <View style={styles.empty}>
                    <Text style={{ color: colors.mutedForeground }}>
                      Birim bulunamadı
                    </Text>
                  </View>
                )
              }
              style={{ maxHeight: 360 }}
            />
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { marginBottom: 14 },
  label: {
    fontSize: 14,
    fontFamily: "Inter_600SemiBold",
    marginBottom: 6,
  },
  input: {
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    minHeight: 46,
  },
  value: { fontSize: 15, fontFamily: "Inter_500Medium", flex: 1 },
  backdrop: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.45)",
    justifyContent: "flex-end",
  },
  sheet: {
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    paddingTop: 8,
    paddingHorizontal: 16,
  },
  handle: {
    width: 40,
    height: 4,
    borderRadius: 2,
    backgroundColor: "#cbd5e1",
    alignSelf: "center",
    marginBottom: 12,
  },
  headerRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 12,
  },
  title: { fontSize: 17, fontFamily: "Inter_700Bold" },
  searchBox: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 10,
    marginBottom: 8,
  },
  searchInput: {
    flex: 1,
    fontSize: 15,
    fontFamily: "Inter_500Medium",
    padding: 0,
  },
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    paddingVertical: 12,
    paddingHorizontal: 4,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  codeBadge: {
    minWidth: 56,
    paddingHorizontal: 10,
    height: 32,
    borderRadius: 8,
    alignItems: "center",
    justifyContent: "center",
  },
  codeText: { fontSize: 12, fontFamily: "Inter_700Bold" },
  rowCode: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 2 },
  rowLabel: { fontSize: 14 },
  empty: { paddingVertical: 24, alignItems: "center" },
});
