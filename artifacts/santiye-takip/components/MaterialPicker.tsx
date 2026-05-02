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

import { ConstructionMaterial } from "@/constants/materials";
import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

interface Props {
  label: string;
  value: string;
  category?: string;
  onChange: (name: string, category: string, defaultUnit?: string) => void;
  placeholder?: string;
}

type Row =
  | { type: "header"; label: string }
  | { type: "item"; material: ConstructionMaterial };

export default function MaterialPicker({
  label,
  value,
  category,
  onChange,
  placeholder = "Malzeme seçin veya arayın",
}: Props) {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { materialList } = useApp();
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState("");
  const [activeCat, setActiveCat] = useState<string | null>(null);

  const lockedCat = category && category.trim().length > 0 ? category : null;
  const effectiveCat = lockedCat ?? activeCat;

  const matches = useMemo(() => {
    const q = search.trim().toLowerCase();
    let list = materialList;
    if (effectiveCat) list = list.filter((m) => m.category === effectiveCat);
    if (q) {
      list = list.filter(
        (m) =>
          m.name.toLowerCase().includes(q) ||
          m.category.toLowerCase().includes(q)
      );
    }
    return list;
  }, [search, effectiveCat, materialList]);

  const rows = useMemo<Row[]>(() => {
    if (effectiveCat) {
      return matches.map((m) => ({ type: "item" as const, material: m }));
    }
    const out: Row[] = [];
    let lastCat = "";
    for (const m of matches) {
      if (m.category !== lastCat) {
        out.push({ type: "header", label: m.category });
        lastCat = m.category;
      }
      out.push({ type: "item", material: m });
    }
    return out;
  }, [matches, effectiveCat]);

  const showCustomOption =
    search.trim().length >= 2 &&
    !materialList.some(
      (m) => m.name.toLowerCase() === search.trim().toLowerCase()
    );

  function pickMaterial(m: ConstructionMaterial) {
    onChange(m.name, m.category, m.defaultUnit);
    close();
  }

  function pickCustom() {
    const name = search.trim();
    if (!name) return;
    onChange(name, category || activeCat || "Diğer", undefined);
    close();
  }

  function close() {
    setOpen(false);
    setSearch("");
    setActiveCat(null);
  }

  return (
    <View style={styles.wrap}>
      <Text style={[styles.label, { color: colors.foreground }]}>{label}</Text>
      <TouchableOpacity
        activeOpacity={0.75}
        onPress={() => setOpen(true)}
        style={[
          styles.input,
          { backgroundColor: colors.background, borderColor: colors.border },
        ]}
      >
        <View style={{ flex: 1 }}>
          <Text
            style={[
              styles.value,
              { color: value ? colors.foreground : colors.mutedForeground },
            ]}
            numberOfLines={1}
          >
            {value || placeholder}
          </Text>
          {value && category ? (
            <Text style={[styles.subValue, { color: colors.mutedForeground }]}>
              {category}
            </Text>
          ) : null}
        </View>
        <Feather name="chevron-down" size={18} color={colors.mutedForeground} />
      </TouchableOpacity>

      <Modal
        visible={open}
        animationType="fade"
        transparent
        onRequestClose={close}
      >
        <Pressable style={styles.backdrop} onPress={close}>
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
                Malzeme Seç
              </Text>
              <TouchableOpacity onPress={close} hitSlop={10}>
                <Feather name="x" size={22} color={colors.mutedForeground} />
              </TouchableOpacity>
            </View>

            <View style={[styles.searchBox, { backgroundColor: colors.muted }]}>
              <Feather name="search" size={14} color={colors.mutedForeground} />
              <TextInput
                value={search}
                onChangeText={setSearch}
                placeholder="Malzeme ara: çimento, demir, gazbeton..."
                placeholderTextColor={colors.mutedForeground}
                style={[styles.searchInput, { color: colors.foreground }]}
                autoFocus
                autoCorrect={false}
                returnKeyType="search"
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

            {lockedCat ? (
              <View style={[styles.lockedCat, { backgroundColor: colors.primary + "15", borderColor: colors.primary + "40" }]}>
                <Feather name="filter" size={12} color={colors.primary} />
                <Text style={[styles.lockedCatText, { color: colors.primary }]} numberOfLines={1}>
                  {lockedCat}
                </Text>
              </View>
            ) : (
              <View style={styles.catRow}>
                <FlatList
                  horizontal
                  showsHorizontalScrollIndicator={false}
                  data={[null, ...materialList.map((m) => m.category).filter((c, i, a) => a.indexOf(c) === i)]}
                  keyExtractor={(c) => c ?? "__all"}
                  contentContainerStyle={{ gap: 6 }}
                  renderItem={({ item }) => {
                    const sel = item === activeCat;
                    return (
                      <TouchableOpacity
                        onPress={() => setActiveCat(item)}
                        style={[
                          styles.catChip,
                          {
                            backgroundColor: sel ? colors.primary : colors.muted,
                          },
                        ]}
                        activeOpacity={0.7}
                      >
                        <Text
                          style={[
                            styles.catChipText,
                            { color: sel ? "#fff" : colors.foreground },
                          ]}
                        >
                          {item ?? "Tümü"}
                        </Text>
                      </TouchableOpacity>
                    );
                  }}
                />
              </View>
            )}

            <FlatList
              data={rows}
              keyExtractor={(r, i) =>
                r.type === "header"
                  ? `h_${r.label}_${i}`
                  : `m_${r.material.category}::${r.material.name}_${i}`
              }
              keyboardShouldPersistTaps="handled"
              ListHeaderComponent={
                showCustomOption ? (
                  <TouchableOpacity
                    onPress={pickCustom}
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
                        styles.iconBadge,
                        { backgroundColor: colors.primary },
                      ]}
                    >
                      <Feather name="plus" size={14} color="#fff" />
                    </View>
                    <View style={{ flex: 1 }}>
                      <Text
                        style={[
                          styles.rowName,
                          { color: colors.primary },
                        ]}
                        numberOfLines={1}
                      >
                        "{search.trim()}" malzemesini ekle
                      </Text>
                      <Text
                        style={[
                          styles.rowCat,
                          { color: colors.mutedForeground },
                        ]}
                      >
                        Listede yok — özel olarak kullan
                      </Text>
                    </View>
                  </TouchableOpacity>
                ) : null
              }
              renderItem={({ item }) => {
                if (item.type === "header") {
                  return (
                    <View
                      style={[
                        styles.headerSection,
                        { backgroundColor: colors.background },
                      ]}
                    >
                      <Text
                        style={[
                          styles.headerSectionText,
                          { color: colors.mutedForeground },
                        ]}
                      >
                        {item.label}
                      </Text>
                    </View>
                  );
                }
                const m = item.material;
                const sel =
                  m.name.toLowerCase() === value.trim().toLowerCase();
                return (
                  <TouchableOpacity
                    onPress={() => pickMaterial(m)}
                    style={[
                      styles.row,
                      {
                        borderBottomColor: colors.border,
                        backgroundColor: sel
                          ? colors.primary + "12"
                          : "transparent",
                      },
                    ]}
                    activeOpacity={0.7}
                  >
                    <View
                      style={[
                        styles.iconBadge,
                        {
                          backgroundColor: sel
                            ? colors.primary
                            : colors.muted,
                        },
                      ]}
                    >
                      <Feather
                        name="package"
                        size={14}
                        color={sel ? "#fff" : colors.foreground}
                      />
                    </View>
                    <View style={{ flex: 1 }}>
                      <Text
                        style={[
                          styles.rowName,
                          {
                            color: sel ? colors.primary : colors.foreground,
                            fontFamily: sel
                              ? "Inter_600SemiBold"
                              : "Inter_500Medium",
                          },
                        ]}
                        numberOfLines={1}
                      >
                        {m.name}
                      </Text>
                      <Text
                        style={[
                          styles.rowCat,
                          { color: colors.mutedForeground },
                        ]}
                      >
                        {m.category}
                        {m.defaultUnit ? ` · ${m.defaultUnit}` : ""}
                      </Text>
                    </View>
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
                      Malzeme bulunamadı
                    </Text>
                  </View>
                )
              }
              style={{ maxHeight: 380 }}
            />
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { marginBottom: 14 },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 6 },
  input: {
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 10,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    minHeight: 50,
    gap: 8,
  },
  value: { fontSize: 15, fontFamily: "Inter_500Medium" },
  subValue: { fontSize: 11, fontFamily: "Inter_400Regular", marginTop: 2 },
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
  catRow: { marginBottom: 8 },
  lockedCat: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    alignSelf: "flex-start",
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    borderWidth: 1,
    marginBottom: 8,
  },
  lockedCatText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
  catChip: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 999,
  },
  catChipText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    paddingVertical: 10,
    paddingHorizontal: 4,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  iconBadge: {
    width: 36,
    height: 36,
    borderRadius: 8,
    alignItems: "center",
    justifyContent: "center",
  },
  rowName: { fontSize: 14, marginBottom: 2 },
  rowCat: { fontSize: 11, fontFamily: "Inter_400Regular" },
  headerSection: {
    paddingVertical: 6,
    paddingHorizontal: 4,
  },
  headerSectionText: {
    fontSize: 11,
    fontFamily: "Inter_700Bold",
    textTransform: "uppercase",
    letterSpacing: 0.5,
  },
  empty: { paddingVertical: 24, alignItems: "center" },
});
